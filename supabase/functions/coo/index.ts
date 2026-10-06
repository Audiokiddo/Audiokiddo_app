// The AI director (COO) for the CRM in Studio. Body: { mode, note?, focus_id? }
//   mode: brief | packs | scenario | ads | newsletter | improve (admins)
//   mode: auto (the daily pg_cron rhythm with the Vault secret: crm_settings.coo_rhythm)
// Gathers the state of the business (numbers, board, ideas, calendar, past decisions), asks
// Claude, and saves every proposal as a pending decision. Returns { summary, proposals }.
// Secrets: ANTHROPIC_API_KEY or GEMINI_API_KEY (see _shared/claude.ts), COO_MODEL (optional).
import { dueModes, MODES, releaseWindow, type Mode, parseAnswer, prompt, storable, SYSTEM, toRow } from "../_shared/coo.ts";
import { askClaude, ClaudeError, hasAi } from "../_shared/claude.ts";
import { withCors } from "../_shared/cors.ts";
import { adminClient, json, requestUser } from "../_shared/supabase.ts";
import type { SupabaseClient } from "npm:@supabase/supabase-js@2";


Deno.serve(withCors(async (req) => {
  if (req.method !== "POST") return json({ error: "method" }, 405);
  const admin = adminClient();
  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json({ error: "body" }, 400);
  }

  // The daily rhythm comes from pg_cron with the Vault secret (the same one as the ads cycle).
  const cronSecret = req.headers.get("x-cron-secret");
  if (cronSecret) {
    const { data: ok } = await admin.rpc("ads_cron_ok", { p_secret: cronSecret });
    if (ok !== true || body.mode !== "auto") return json({ error: "unauthorized" }, 401);
    return json(await rhythm(admin, new Date()));
  }

  const user = await requestUser(req, admin);
  if (!user) return json({ error: "unauthorized" }, 401);
  const { data: isAdmin } = await admin.from("admins").select("user_id").eq("user_id", user.id).maybeSingle();
  if (!isAdmin) return json({ error: "forbidden" }, 403);

  const mode = String(body.mode) as Mode;
  if (!MODES.includes(mode)) return json({ error: "mode" }, 400);
  const note = typeof body.note === "string" && body.note.trim() ? body.note.trim().slice(0, 2000) : null;
  const focusId = typeof body.focus_id === "string" ? body.focus_id : null;

  // Without an API key: Studio copies this text into Claude or ChatGPT and brings the answer back.
  if (body.manual === "prompt") {
    const { context, focus } = await gather(admin, focusId);
    return json({ prompt: `${SYSTEM}\n\n${prompt(mode, context, note, focus)}` });
  }
  if (body.manual === "answer") {
    const text = typeof body.text === "string" ? body.text.slice(0, 200_000) : "";
    const saved = await save(admin, mode, text, note, focusId);
    if ("error" in saved) return json(saved, saved.error === "save" ? 503 : 400);
    return json(saved);
  }

  const result = await run(admin, mode, note, focusId);
  if ("error" in result) return json(result, result.error === "no_key" ? 412 : result.error === "save" ? 503 : 502);
  return json(result);
}));

/** What the morning brings: the report every day, ad ideas on Mondays, a newsletter draft
 * every other Thursday (crm_settings.coo_rhythm). Skips what already ran today. */
async function rhythm(admin: SupabaseClient, now: Date) {
  const { data: setting } = await admin.from("crm_settings").select("value").eq("key", "coo_rhythm").maybeSingle();
  const due = dueModes(setting?.value, now);
  const today = now.toISOString().slice(0, 10);
  const done: Record<string, string> = {};
  for (const mode of due) {
    const { count } = await admin.from("crm_items").select("id", { count: "exact", head: true })
      .eq("kind", "briefing").eq("area", mode).gte("created_at", `${today}T00:00:00Z`);
    if ((count ?? 0) > 0) {
      done[mode] = "already";
      continue;
    }
    const result = await run(admin, mode, null, null);
    done[mode] = "error" in result ? result.error : "ok";
  }
  // A newsletter for every premiere in the next two days, once.
  if ((setting?.value as Record<string, unknown> | undefined)?.release_newsletter !== false) {
    const { from, to } = releaseWindow(now);
    const { data: releases } = await admin.from("crm_items").select("id, title, body, due, data")
      .eq("kind", "calendar").eq("area", "release").gte("due", from).lte("due", to)
      // Dawid's own entries (no decision) and approved ones; NOT IN would drop the nulls.
      .or("decision.is.null,decision.eq.approved");
    for (const r of releases ?? []) {
      const { count } = await admin.from("crm_items").select("id", { count: "exact", head: true })
        .eq("kind", "briefing").eq("area", "release").eq("data->>focus_id", r.id);
      if ((count ?? 0) > 0) continue;
      const result = await run(admin, "release", null, r.id);
      done[`release:${r.title}`] = "error" in result ? result.error : "ok";
    }
  }
  return { due, done };
}

/** The state of the business for the agent (no e-mails), and the item it should focus on. */
async function gather(admin: SupabaseClient, focusId: string | null) {
  let focus: Record<string, unknown> | null = null;
  if (focusId) {
    const { data } = await admin.from("crm_items").select("title, body, due, data").eq("id", focusId).maybeSingle();
    focus = data;
  }

  // The state of the business, trimmed to what helps decide.
  const since = new Date(Date.now() - 45 * 864e5).toISOString();
  await admin.rpc("crm_watch");
  const [numbers, stats, catalog, open, ideas, calendar, decided, alerts] = await Promise.all([
    admin.rpc("crm_numbers"),
    admin.rpc("admin_stats", { p_days: 30 }),
    admin.rpc("published_catalog"),
    admin.from("crm_items").select("title, status, owner, due, priority").eq("kind", "task")
      .not("status", "in", "(done,archived)").order("priority").limit(40),
    admin.from("crm_items").select("title, area, status").eq("kind", "idea").neq("decision", "rejected")
      .order("created_at", { ascending: false }).limit(30),
    admin.from("crm_items").select("title, area, due, status").eq("kind", "calendar")
      .gte("due", new Date().toISOString().slice(0, 10)).order("due").limit(30),
    admin.from("crm_items").select("title, kind, area, decision").in("decision", ["approved", "rejected"])
      .gte("updated_at", since).order("updated_at", { ascending: false }).limit(40),
    admin.from("crm_alerts").select("level, title, detail").is("resolved_at", null),
  ]);
  const numbersData = { ...(numbers.data ?? {}) } as Record<string, unknown>;
  delete numbersData.recent_users; // no e-mails to the model
  const manifest = (catalog.data as { manifest?: { packs?: unknown[]; items?: { title?: string; pack_id?: string }[] } })
    ?.manifest;
  const context = {
    numbers: numbersData,
    analytics: (stats.data as Record<string, unknown> | null)?.analytics ?? null,
    events: (stats.data as Record<string, unknown> | null)?.events ?? null,
    catalog: manifest
      ? { packs: manifest.packs, plays: (manifest.items ?? []).map((i) => `${i.pack_id ?? "-"}: ${i.title}`) }
      : null,
    open_tasks: open.data ?? [],
    ideas: ideas.data ?? [],
    calendar: calendar.data ?? [],
    recent_decisions: decided.data ?? [],
    // What the hourly watchdog sees now: the report says what to do about it first.
    alerts: alerts.data ?? [],
  };
  return { context, focus };
}

async function run(admin: SupabaseClient, mode: Mode, note: string | null, focusId: string | null) {
  if (!hasAi()) return { error: "no_key" as const };
  const { context, focus } = await gather(admin, focusId);
  let text: string;
  try {
    text = await askClaude(SYSTEM, prompt(mode, context, note, focus), mode === "scenario" ? 12000 : 8000);
  } catch (e) {
    // The reason (bad key, no credit, limit…) goes back to Studio, which says what to do.
    return { error: "model" as const, reason: e instanceof ClaudeError ? e.reason : "model", detail: e instanceof ClaudeError ? e.detail : String(e).slice(0, 200) };
  }

  return await save(admin, mode, text, note, focusId);
}

/** Reads the agent's answer (from the API or pasted from a chat) and saves it as decisions. */
async function save(admin: SupabaseClient, mode: Mode, text: string, note: string | null, focusId: string | null) {
  let parsed;
  try {
    parsed = parseAnswer(text);
  } catch (e) {
    console.error("coo: answer", e, text.slice(0, 500));
    return { error: "answer" as const };
  }

  const rows: Record<string, unknown>[] = [
    {
      kind: "briefing",
      area: mode,
      title: `${labels[mode]}: ${new Date().toLocaleDateString("pl-PL")}`,
      body: parsed.summary,
      status: "done",
      source: "ai",
      data: { note, focus_id: focusId },
    },
    ...parsed.proposals.map(toRow),
  ];
  const { error } = await admin.from("crm_items").insert(storable(rows));
  if (error) {
    // One odd row should not lose the rest: save them one by one and keep what goes in.
    console.error("coo: save", error.message);
    const failed: string[] = [];
    for (const row of rows) {
      const { error: one } = await admin.from("crm_items").insert(storable(row));
      if (one) failed.push(`${row.title}: ${one.message}`);
    }
    if (failed.length === rows.length) return { error: "save" as const, detail: failed[0].slice(0, 300) };
    if (failed.length) console.error("coo: skipped", failed);
  }
  return parsed;
}

const labels: Record<Mode, string> = {
  brief: "Raport COO",
  packs: "Pomysły na pakiety",
  scenario: "Scenariusz zabawy",
  ads: "Pomysły na reklamy",
  newsletter: "Newsletter",
  improve: "Propozycje zmian",
  release: "Newsletter o premierze",
};

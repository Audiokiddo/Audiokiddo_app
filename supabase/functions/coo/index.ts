// The AI director (COO) for the CRM in Studio. Body: { mode, note?, focus_id? }
//   mode: brief | packs | scenario | ads | newsletter | improve (admins)
//   mode: auto (the daily pg_cron rhythm with the Vault secret: crm_settings.coo_rhythm)
// Gathers the state of the business (numbers, board, ideas, calendar, past decisions), asks
// Claude, and saves every proposal as a pending decision. Returns { summary, proposals }.
// Secrets: ANTHROPIC_API_KEY (required), COO_MODEL (optional).
import { dueModes, MODES, type Mode, parseAnswer, prompt, SYSTEM, toRow } from "../_shared/coo.ts";
import { withCors } from "../_shared/cors.ts";
import { adminClient, json, requestUser } from "../_shared/supabase.ts";
import type { SupabaseClient } from "npm:@supabase/supabase-js@2";

const MODEL = Deno.env.get("COO_MODEL") ?? "claude-sonnet-5-5";

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
  const result = await run(admin, mode, note, typeof body.focus_id === "string" ? body.focus_id : null);
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
  return { due, done };
}

async function run(admin: SupabaseClient, mode: Mode, note: string | null, focusId: string | null) {
  const key = Deno.env.get("ANTHROPIC_API_KEY");
  if (!key) return { error: "no_key" as const };

  let focus: Record<string, unknown> | null = null;
  if (focusId) {
    const { data } = await admin.from("crm_items").select("title, body, data").eq("id", focusId).maybeSingle();
    focus = data;
  }

  // The state of the business, trimmed to what helps decide.
  const since = new Date(Date.now() - 45 * 864e5).toISOString();
  const [numbers, stats, catalog, open, ideas, calendar, decided] = await Promise.all([
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
  };

  const response = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: { "x-api-key": key, "anthropic-version": "2023-06-01", "content-type": "application/json" },
    body: JSON.stringify({
      model: MODEL,
      max_tokens: mode === "scenario" ? 12000 : 6000,
      system: SYSTEM,
      messages: [{ role: "user", content: prompt(mode, context, note, focus) }],
    }),
  });
  if (!response.ok) {
    console.error("coo: model", response.status, await response.text());
    return { error: "model" as const };
  }
  const answer = await response.json() as { content?: { type: string; text?: string }[] };
  const text = (answer.content ?? []).filter((c) => c.type === "text").map((c) => c.text ?? "").join("");

  let parsed;
  try {
    parsed = parseAnswer(text);
  } catch (e) {
    console.error("coo: answer", e, text.slice(0, 500));
    return { error: "answer" as const };
  }

  const rows = [
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
  const { error } = await admin.from("crm_items").insert(rows);
  if (error) {
    console.error("coo: save", error.message);
    return { error: "save" as const };
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
};

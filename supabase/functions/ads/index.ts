// Ads in Studio (CRM → Kampanie): Meta Ads, Meta Pixel, Google Ads, Google Analytics 4.
// Body: { action, ... }
//   overview                      admins: everything Studio shows
//   sync                          admins or the daily cron: campaigns and numbers from the platforms
//   propose { note? }             admins or the daily cron: the ads agent proposes changes
//   cycle                         the daily cron: sync, then propose when the agent is on
//   decide { id, approve, daily_budget? }   admins: approve (applies it now) or reject a proposal
//   apply { platform, entity_id, action_kind, daily_budget? }   admins: a change made by hand in Studio
// Nothing changes on a platform unless an admin approves it or makes it by hand; every change
// passes the limits in crm_settings.ads (checkAction) right before it is applied.
// Secrets (Supabase → Edge Functions → Secrets), each source works on its own:
//   Meta: META_ACCESS_TOKEN, META_AD_ACCOUNT_ID, META_PIXEL_ID (optional), META_API_VERSION (optional)
//   Google: GOOGLE_CLIENT_ID, GOOGLE_CLIENT_SECRET, GOOGLE_REFRESH_TOKEN
//     Ads: GOOGLE_ADS_DEVELOPER_TOKEN, GOOGLE_ADS_CUSTOMER_ID, GOOGLE_ADS_LOGIN_CUSTOMER_ID (optional),
//          GOOGLE_ADS_API_VERSION (optional)
//     Analytics: GA4_PROPERTY_ID
//   Agent: ANTHROPIC_API_KEY, ADS_MODEL (optional)
import {
  ADS_SYSTEM,
  adsPrompt,
  checkAction,
  cleanSettings,
  describe,
  type Entity,
  GA4_REPORT,
  GOOGLE_ADS_QUERY,
  type Metric,
  parseAdsAnswer,
  parseGa4,
  parseGoogleAds,
  parseMetaEntities,
  parseMetaInsights,
  type ProposedAction,
  summarize,
} from "../_shared/ads.ts";
import { cleanCreative } from "../_shared/ads_growth.ts";
import { answerText, ClaudeError, failWith } from "../_shared/claude.ts";
import { withCors } from "../_shared/cors.ts";
import {
  applyGrowthAction,
  createRsa,
  dailyContext,
  growthOverview,
  syncGoogleAdsDetail,
  syncMetaAds,
  weekly,
} from "./growth.ts";
import {
  adsHeaders,
  call,
  configured,
  customer,
  env,
  GOOGLE_ADS,
  googleSearch,
  googleToken,
  META,
  metaAccount,
  metaHeaders,
  metaPages,
  SourceError,
} from "./platforms.ts";
import { adminClient, json, requestUser } from "../_shared/supabase.ts";
import type { SupabaseClient } from "npm:@supabase/supabase-js@2";

const MODEL = env("ADS_MODEL") ?? env("COO_MODEL") ?? "claude-sonnet-5-5";
// Meta ---------------------------------------------------------------------------------------

async function syncMeta(): Promise<{ entities: Entity[]; metrics: Metric[]; info: Record<string, unknown> }> {
  const act = metaAccount();
  const account = await call(`${META}/${act}?fields=name,currency,account_status`, { headers: metaHeaders() }, "Meta konto");
  const currency = typeof account.currency === "string" ? account.currency : "PLN";
  const [campaigns, adsets, insights] = await Promise.all([
    metaPages(`${META}/${act}/campaigns?fields=id,name,status,effective_status,daily_budget,objective&limit=200`, "Meta kampanie"),
    metaPages(`${META}/${act}/adsets?fields=id,name,status,effective_status,daily_budget,campaign_id&limit=500`, "Meta zestawy"),
    metaPages(
      `${META}/${act}/insights?level=campaign&time_increment=1&date_preset=last_30d` +
        "&fields=campaign_id,campaign_name,spend,impressions,clicks,inline_link_clicks,actions,action_values&limit=500",
      "Meta statystyki",
    ),
  ]);
  return {
    entities: parseMetaEntities(campaigns, adsets, currency),
    metrics: parseMetaInsights(insights),
    info: { account: account.name ?? null, currency },
  };
}

async function pixelHealth(): Promise<{ ok: boolean; message: string; data: Record<string, unknown> }> {
  const pixel = env("META_PIXEL_ID")!;
  const body = await call(`${META}/${pixel}?fields=name,last_fired_time,is_unavailable`, { headers: metaHeaders() }, "Meta Pixel");
  const last = typeof body.last_fired_time === "string" ? Date.parse(body.last_fired_time) : NaN;
  const hours = Number.isFinite(last) ? Math.round((Date.now() - last) / 36e5) : null;
  const ok = body.is_unavailable !== true && hours !== null && hours <= 48;
  return {
    ok,
    message: hours === null
      ? "Pixel jeszcze nie wysłał żadnego zdarzenia."
      : ok
      ? `Pixel działa: ostatnie zdarzenie ${hours} h temu.`
      : `Pixel milczy od ${hours} h: sprawdź wtyczkę na audiokiddo.pl.`,
    data: { name: body.name ?? null, last_fired_time: body.last_fired_time ?? null },
  };
}

async function applyMeta(a: ProposedAction): Promise<Record<string, unknown>> {
  const form = new URLSearchParams();
  if (a.action === "set_budget") form.set("daily_budget", String(Math.round(a.params.daily_budget! * 100)));
  else form.set("status", a.action === "pause" ? "PAUSED" : "ACTIVE");
  return await call(`${META}/${a.entity_id}`, { method: "POST", headers: metaHeaders(), body: form }, "Meta zmiana");
}

// Google -------------------------------------------------------------------------------------

async function syncGoogleAds(token: string) {
  return parseGoogleAds(await googleSearch(token, GOOGLE_ADS_QUERY, "Google Ads"));
}

async function applyGoogleAds(a: ProposedAction, entity: Entity, token: string) {
  const id = customer();
  if (a.action === "set_budget") {
    return await call(`${GOOGLE_ADS}/customers/${id}/campaignBudgets:mutate`, {
      method: "POST",
      headers: adsHeaders(token),
      body: JSON.stringify({
        operations: [{
          update: { resourceName: entity.data.budget, amountMicros: String(Math.round(a.params.daily_budget! * 1e6)) },
          updateMask: "amount_micros",
        }],
      }),
    }, "Google Ads zmiana");
  }
  return await call(`${GOOGLE_ADS}/customers/${id}/campaigns:mutate`, {
    method: "POST",
    headers: adsHeaders(token),
    body: JSON.stringify({
      operations: [{
        update: { resourceName: `customers/${id}/campaigns/${a.entity_id}`, status: a.action === "pause" ? "PAUSED" : "ENABLED" },
        updateMask: "status",
      }],
    }),
  }, "Google Ads zmiana");
}

async function syncGa4(token: string): Promise<Metric[]> {
  const body = await call(
    `https://analyticsdata.googleapis.com/v1beta/properties/${env("GA4_PROPERTY_ID")}:runReport`,
    { method: "POST", headers: { Authorization: `Bearer ${token}`, "content-type": "application/json" }, body: JSON.stringify(GA4_REPORT) },
    "Google Analytics",
  );
  return parseGa4(body);
}

// Storage ------------------------------------------------------------------------------------

async function status(admin: SupabaseClient, source: string, ok: boolean, message: string, data: Record<string, unknown> = {}) {
  await admin.from("ads_status").upsert({ source, ok, message: message.slice(0, 8000), data, updated_at: new Date().toISOString() });
}

/** The platform's campaigns now: replaces what was there, so removed ones disappear. */
async function saveEntities(admin: SupabaseClient, platform: string, entities: Entity[]) {
  const now = new Date().toISOString();
  if (entities.length) {
    const { error } = await admin.from("ads_entities").upsert(entities.map((e) => ({ ...e, synced_at: now })));
    if (error) throw new Error(`save entities: ${error.message}`);
  }
  await admin.from("ads_entities").delete().eq("platform", platform).lt("synced_at", now);
}

async function saveMetrics(admin: SupabaseClient, metrics: Metric[]) {
  for (let i = 0; i < metrics.length; i += 500) {
    const { error } = await admin.from("ads_metrics").upsert(metrics.slice(i, i + 500));
    if (error) throw new Error(`save metrics: ${error.message}`);
  }
}

async function sync(admin: SupabaseClient) {
  const on = configured();
  const report: Record<string, string> = {};
  const run = async (source: string, enabled: boolean, job: () => Promise<string>) => {
    if (!enabled) return;
    try {
      report[source] = await job();
    } catch (e) {
      report[source] = e instanceof SourceError ? e.message : "błąd zapisu";
      if (!(e instanceof SourceError)) console.error(`ads: ${source}`, e);
      await status(admin, source, false, report[source]);
    }
  };
  await run("meta", on.meta, async () => {
    const { entities, metrics, info } = await syncMeta();
    await saveEntities(admin, "meta", entities);
    await saveMetrics(admin, metrics);
    // Single ads come second: a failure there must not hide the campaigns.
    const detail = await syncMetaAds(admin).catch((e) => {
      console.error("ads: meta ads", e);
      return e instanceof SourceError ? e.message : "reklamy: błąd";
    });
    const message = `${entities.length} kampanii i zestawów, ${metrics.length} wierszy statystyk; ${detail}.`;
    await status(admin, "meta", true, message, info);
    return message;
  });
  await run("meta_pixel", on.meta_pixel, async () => {
    const health = await pixelHealth();
    await status(admin, "meta_pixel", health.ok, health.message, health.data);
    return health.message;
  });
  if (on.google_ads || on.ga4) {
    let token: string | null = null;
    const google = async () => token ??= await googleToken();
    await run("google_ads", on.google_ads, async () => {
      const { entities, metrics } = await syncGoogleAds(await google());
      await saveEntities(admin, "google_ads", entities);
      await saveMetrics(admin, metrics);
      const detail = await syncGoogleAdsDetail(admin, await google()).catch((e) => {
        console.error("ads: google detail", e);
        return e instanceof SourceError ? e.message : "reklamy: błąd";
      });
      const message = `${entities.length} kampanii, ${metrics.length} wierszy statystyk; ${detail}.`;
      await status(admin, "google_ads", true, message);
      return message;
    });
    await run("ga4", on.ga4, async () => {
      const metrics = await syncGa4(await google());
      await saveMetrics(admin, metrics);
      const message = `${metrics.length} wierszy ruchu na stronie (30 dni).`;
      await status(admin, "ga4", true, message);
      return message;
    });
  }
  return report;
}

async function load(admin: SupabaseClient) {
  const since = new Date(Date.now() - 31 * 864e5).toISOString().slice(0, 10);
  const [entities, metrics, settings] = await Promise.all([
    admin.from("ads_entities").select("*").order("name"),
    admin.from("ads_metrics").select("*").gte("day", since).order("day").limit(10000),
    admin.from("crm_settings").select("value").eq("key", "ads").maybeSingle(),
  ]);
  return {
    entities: (entities.data ?? []) as Entity[],
    metrics: ((metrics.data ?? []) as Metric[]).map((m) => ({
      ...m,
      spend: Number(m.spend),
      conversions: Number(m.conversions),
      revenue: Number(m.revenue),
    })),
    settings: cleanSettings(settings.data?.value),
  };
}

// The agent ----------------------------------------------------------------------------------

async function propose(admin: SupabaseClient, note: string | null) {
  const key = env("ANTHROPIC_API_KEY");
  if (!key) return { error: "no_key" as const };
  const today = new Date().toISOString().slice(0, 10);
  const { entities, metrics, settings } = await load(admin);
  const since = new Date(Date.now() - 30 * 864e5).toISOString();
  const [numbers, history, pixel] = await Promise.all([
    admin.rpc("crm_numbers"),
    admin.from("ads_actions").select("title, action, status, entity_name, created_at")
      .gte("created_at", since).order("created_at", { ascending: false }).limit(40),
    admin.from("ads_status").select("source, ok, message, updated_at"),
  ]);
  const business = { ...(numbers.data ?? {}) } as Record<string, unknown>;
  delete business.recent_users; // no e-mails to the model
  const growth = await dailyContext(admin);
  const context = {
    ...growth.context,
    limits: settings,
    connected: configured(),
    sources: pixel.data ?? [],
    ads: summarize(entities, metrics, today),
    business: {
      paying_families: business.paying_families,
      subs_monthly: business.subs_monthly,
      subs_yearly: business.subs_yearly,
      revenue_30d_gross: business.revenue_30d_gross,
      users_7d: business.users_7d,
    },
    past_actions: history.data ?? [],
  };

  const response = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: { "x-api-key": key, "anthropic-version": "2023-06-01", "content-type": "application/json" },
    body: JSON.stringify({
      model: MODEL,
      max_tokens: 5000,
      system: ADS_SYSTEM,
      messages: [{ role: "user", content: adsPrompt(context, note, today) }],
    }),
  });
  let text: string;
  try {
    if (!response.ok) await failWith("ads", response);
    text = answerText(await response.json());
  } catch (e) {
    return { error: "model" as const, reason: e instanceof ClaudeError ? e.reason : "model" };
  }
  let parsed;
  try {
    parsed = parseAdsAnswer(text, entities);
  } catch (e) {
    console.error("ads: answer", e, text.slice(0, 500));
    return { error: "answer" as const };
  }
  // Only what passes the limits now reaches Dawid; the rest is noted in the summary.
  const rejected: string[] = [];
  const rows = parsed.actions.flatMap((a) => {
    const problem = checkAction(a, entities, settings, false, growth.ads);
    if (problem) {
      rejected.push(`${a.title}: ${problem}`);
      return [];
    }
    return [{ ...a, status: "pending", source: "ai" }];
  });
  if (rows.length) {
    const { error } = await admin.from("ads_actions").insert(rows);
    if (error) throw new Error(`save actions: ${error.message}`);
  }
  const summary = parsed.summary +
    (rejected.length ? `\n\nOdrzucone przez limity:\n${rejected.map((r) => `- ${r}`).join("\n")}` : "");
  await status(admin, "agent", true, summary, { proposed: rows.length, at: new Date().toISOString() });
  return { summary, proposed: rows.length };
}

// Changes ------------------------------------------------------------------------------------

/** Applies one change after checking it against the limits once more; records the outcome. */
async function applyAction(admin: SupabaseClient, row: Record<string, unknown>, by: string | null) {
  const a = row as unknown as ProposedAction & { id: string };
  const decided = { decided_by: by, decided_at: new Date().toISOString() };
  if (a.action === "task") {
    const { data, error } = await admin.from("crm_items").insert({
      kind: "task",
      area: "marketing",
      title: a.title,
      body: [a.reason, a.expected && `Oczekiwany efekt: ${a.expected}`].filter(Boolean).join("\n\n"),
      status: "todo",
      priority: a.priority,
      owner: "Dawid",
      source: "ai",
      decision: "approved",
    }).select("id").single();
    if (error) throw new Error(`task: ${error.message}`);
    await admin.from("ads_actions").update({ status: "applied", result: { crm_item: data.id }, ...decided }).eq("id", a.id);
    return { ok: true, message: "Dodane jako zadanie na tablicy." };
  }

  const { entities, settings } = await load(admin);
  if (a.action === "pause_ad" || a.action === "add_negative") {
    const { data: ads } = await admin.from("ads_ads").select("*");
    const problem = checkAction(a, entities, settings, row.source === "dawid", ads ?? []);
    if (problem) {
      await admin.from("ads_actions").update({ status: "failed", result: { error: problem }, ...decided }).eq("id", a.id);
      return { ok: false, message: problem };
    }
    const ad = (ads ?? []).find((x) => x.platform === a.platform && x.ad_id === a.entity_id);
    try {
      await applyGrowthAction(a, ad);
    } catch (e) {
      const message = e instanceof SourceError ? e.message : "Platforma nie odpowiada.";
      if (!(e instanceof SourceError)) console.error("ads: apply growth", e);
      await admin.from("ads_actions").update({ status: "failed", result: { error: message }, ...decided }).eq("id", a.id);
      return { ok: false, message };
    }
    if (a.action === "pause_ad") {
      await admin.from("ads_ads").update({ status: "paused" }).eq("platform", a.platform).eq("ad_id", a.entity_id!);
    } else {
      await admin.from("ads_search_terms").update({ google_status: "excluded" }).eq("campaign_id", a.entity_id!).eq("term", a.params.term!);
    }
    const message = `Wprowadzone: ${describe({ ...a, entity_name: a.entity_name || ad?.name || "" })}.`;
    await admin.from("ads_actions").update({ status: "applied", result: { message }, ...decided }).eq("id", a.id);
    return { ok: true, message };
  }
  const problem = checkAction(a, entities, settings, row.source === "dawid");
  const entity = entities.find((e) => e.platform === a.platform && e.entity_id === a.entity_id);
  if (problem || !entity) {
    await admin.from("ads_actions").update({ status: "failed", result: { error: problem }, ...decided }).eq("id", a.id);
    return { ok: false, message: problem ?? "Nie ma takiej kampanii." };
  }
  const on = configured();
  try {
    if (a.platform === "meta") {
      if (!on.meta) throw new SourceError("Meta nie jest połączona.");
      await applyMeta(a);
    } else {
      if (!on.google_ads) throw new SourceError("Google Ads nie jest połączone.");
      await applyGoogleAds(a, entity, await googleToken());
    }
  } catch (e) {
    const message = e instanceof SourceError ? e.message : "Platforma nie odpowiada.";
    if (!(e instanceof SourceError)) console.error("ads: apply", e);
    await admin.from("ads_actions").update({ status: "failed", result: { error: message }, ...decided }).eq("id", a.id);
    return { ok: false, message };
  }
  const before = entity.daily_budget;
  await admin.from("ads_entities").update(
    a.action === "set_budget"
      ? { daily_budget: a.params.daily_budget }
      : { status: a.action === "pause" ? "paused" : "active" },
  ).eq("platform", a.platform).eq("entity_id", a.entity_id!);
  const message = `Wprowadzone: ${describe({ ...a, entity_name: entity.name }, before)}.`;
  await admin.from("ads_actions").update({ status: "applied", result: { before, message }, ...decided }).eq("id", a.id);
  return { ok: true, message };
}

// The handler --------------------------------------------------------------------------------

Deno.serve(withCors(async (req) => {
  if (req.method !== "POST") return json({ error: "method" }, 405);
  const admin = adminClient();
  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json({ error: "body" }, 400);
  }
  const action = String(body.action ?? "");

  // The daily cron proves itself with the secret kept in Vault.
  const cronSecret = req.headers.get("x-cron-secret");
  let userId: string | null = null;
  if (cronSecret) {
    const { data: ok } = await admin.rpc("ads_cron_ok", { p_secret: cronSecret });
    if (ok !== true || !["sync", "propose", "cycle", "research"].includes(action)) return json({ error: "unauthorized" }, 401);
  } else {
    const user = await requestUser(req, admin);
    if (!user) return json({ error: "unauthorized" }, 401);
    const { data: isAdmin } = await admin.from("admins").select("user_id").eq("user_id", user.id).maybeSingle();
    if (!isAdmin) return json({ error: "forbidden" }, 403);
    userId = user.id;
  }

  try {
    switch (action) {
      case "overview": {
        const { entities, metrics, settings } = await load(admin);
        const [actions, sources] = await Promise.all([
          admin.from("ads_actions").select("*").order("created_at", { ascending: false }).limit(150),
          admin.from("ads_status").select("*"),
        ]);
        return json({
          configured: configured(),
          sources: sources.data ?? [],
          settings,
          entities,
          metrics,
          summary: summarize(entities, metrics, new Date().toISOString().slice(0, 10)),
          actions: actions.data ?? [],
        });
      }
      case "sync":
        return json({ report: await sync(admin) });
      case "propose": {
        const note = typeof body.note === "string" && body.note.trim() ? body.note.trim().slice(0, 2000) : null;
        const result = await propose(admin, note);
        if ("error" in result) return json(result, result.error === "no_key" ? 412 : 502);
        return json(result);
      }
      case "cycle": {
        const report = await sync(admin);
        // Old proposals were made on old numbers.
        await admin.from("ads_actions").update({ status: "expired" }).eq("status", "pending")
          .lt("created_at", new Date(Date.now() - 7 * 864e5).toISOString());
        const { settings } = await load(admin);
        const agent = settings.enabled && configured().agent ? await propose(admin, null) : { skipped: true };
        return json({ report, agent });
      }
      case "decide": {
        const { data: row } = await admin.from("ads_actions").select("*").eq("id", String(body.id)).maybeSingle();
        if (!row || row.status !== "pending") return json({ error: "gone" }, 409);
        if (body.approve !== true) {
          await admin.from("ads_actions").update({ status: "rejected", decided_by: userId, decided_at: new Date().toISOString() })
            .eq("id", row.id);
          return json({ ok: true, message: "Odrzucone." });
        }
        // Dawid may lower or raise the proposed budget before approving.
        if (row.action === "set_budget" && typeof body.daily_budget === "number") {
          row.params = { daily_budget: Math.round(body.daily_budget * 100) / 100 };
          await admin.from("ads_actions").update({ params: row.params }).eq("id", row.id);
        }
        return json(await applyAction(admin, row, userId));
      }
      case "apply": {
        const { entities } = await load(admin);
        const entity = entities.find((e) => e.platform === body.platform && e.entity_id === body.entity_id);
        const kind = String(body.action_kind);
        if (!entity || !["set_budget", "pause", "enable"].includes(kind)) return json({ error: "body" }, 400);
        const manual: ProposedAction = {
          platform: entity.platform,
          entity_id: entity.entity_id,
          entity_name: entity.name,
          action: kind as ProposedAction["action"],
          params: kind === "set_budget" ? { daily_budget: Math.round(Number(body.daily_budget) * 100) / 100 } : {},
          title: "",
          reason: "Zmiana ręczna w Studio.",
          expected: "",
          priority: 2,
        };
        manual.title = describe(manual, entity.daily_budget);
        const { data: row, error } = await admin.from("ads_actions")
          .insert({ ...manual, status: "pending", source: "dawid" }).select("*").single();
        if (error) throw new Error(`manual: ${error.message}`);
        return json(await applyAction(admin, row, userId));
      }
      case "growth":
        return json(await growthOverview(admin));
      case "research": {
        const note = typeof body.note === "string" && body.note.trim() ? body.note.trim().slice(0, 2000) : null;
        const result = await weekly(admin, note);
        const agent = result.agent as { error?: string; reason?: string };
        if (agent.error) return json({ ...result, error: agent.error, reason: agent.reason }, agent.error === "no_key" ? 412 : 502);
        return json(result);
      }
      case "exclude": {
        // Dawid excludes a search term by hand (CRM → Słowa kluczowe).
        const term = String(body.term ?? "").trim().toLowerCase().slice(0, 80);
        const { data: campaign } = await admin.from("ads_entities").select("name")
          .eq("platform", "google_ads").eq("entity_id", String(body.campaign_id ?? "")).maybeSingle();
        const manual: ProposedAction = {
          platform: "google_ads",
          entity_id: String(body.campaign_id ?? ""),
          entity_name: campaign?.name ?? "",
          action: "add_negative",
          params: { term, match: body.match === "EXACT" ? "EXACT" : "PHRASE" },
          title: `Wykluczyć „${term}”`,
          reason: "Zmiana ręczna w Studio.",
          expected: "",
          priority: 2,
        };
        const { data: row, error } = await admin.from("ads_actions")
          .insert({ ...manual, status: "pending", source: "dawid" }).select("*").single();
        if (error) throw new Error(`exclude: ${error.message}`);
        return json(await applyAction(admin, row, userId));
      }
      case "creative": {
        // Approve (optionally edited, optionally straight into a Google ad group) or reject.
        const { data: row } = await admin.from("ads_creatives").select("*").eq("id", String(body.id)).maybeSingle();
        if (!row || row.status !== "draft") return json({ error: "gone" }, 409);
        const decided = { decided_at: new Date().toISOString() };
        if (body.approve !== true) {
          const feedback = typeof body.feedback === "string" ? body.feedback.trim().slice(0, 2000) : null;
          await admin.from("ads_creatives").update({ status: "rejected", feedback, ...decided }).eq("id", row.id);
          return json({ ok: true, message: "Odrzucone. Agent weźmie uwagę pod uwagę przy kolejnym badaniu." });
        }
        const edited = body.content && typeof body.content === "object"
          ? cleanCreative({ ...(body.content as Record<string, unknown>), platform: row.platform, format: row.format })
          : null;
        const content = edited?.content ?? row.content;
        const problems = edited?.problems ?? row.problems ?? [];
        if (row.platform === "google_ads") {
          const group = typeof body.group_id === "string" ? body.group_id : null;
          if (!group) {
            await admin.from("ads_creatives").update({ status: "approved", content, problems, ...decided }).eq("id", row.id);
            return json({ ok: true, message: "Zatwierdzone. Wybierz grupę reklam, by utworzyć ją w Google Ads." });
          }
          if ((content.headlines?.length ?? 0) < 3 || (content.descriptions?.length ?? 0) < 2) {
            return json({ ok: false, message: "Reklama Google potrzebuje co najmniej 3 nagłówków i 2 opisów." });
          }
          try {
            const resource = await createRsa(content, group);
            await admin.from("ads_creatives").update({ status: "live", content, problems, result: { resource, group_id: group }, ...decided })
              .eq("id", row.id);
            return json({ ok: true, message: "Reklama utworzona w Google Ads jako wstrzymana. Włącz ją w Google Ads albo w Studio, gdy będziecie gotowi." });
          } catch (e) {
            const message = e instanceof SourceError ? e.message : "Google Ads nie odpowiada.";
            if (!(e instanceof SourceError)) console.error("ads: rsa", e);
            return json({ ok: false, message });
          }
        }
        // Meta: pictures and video are made by people, so the copy and brief become a task.
        const brief = [
          `Tekst główny:\n${content.primary_text ?? ""}`,
          `Nagłówek: ${content.headline ?? ""}`,
          content.description ? `Opis: ${content.description}` : "",
          `Przycisk: ${content.cta ?? ""}`,
          `Link: ${content.final_url ?? "https://audiokiddo.pl/"}`,
          content.visual_brief ? `Grafika / kadr:\n${content.visual_brief}` : "",
          content.hook_script ? `Wideo (scenariusz):\n${content.hook_script}` : "",
          row.why ? `Dlaczego: ${row.why}` : "",
        ].filter(Boolean).join("\n\n");
        const { data: task, error } = await admin.from("crm_items").insert({
          kind: "task",
          area: "marketing",
          title: `Kreacja Meta: ${row.angle || "nowa reklama"}`.slice(0, 200),
          body: brief.slice(0, 8000),
          status: "todo",
          priority: 2,
          owner: "Dawid",
          source: "ai",
          decision: "approved",
        }).select("id").single();
        if (error) throw new Error(`creative task: ${error.message}`);
        await admin.from("ads_creatives").update({ status: "approved", content, problems, result: { crm_item: task.id }, ...decided })
          .eq("id", row.id);
        return json({ ok: true, message: "Zatwierdzone. Tekst i brief są w zadaniu na tablicy." });
      }
      case "creative_live": {
        // An approved Google creative placed in an ad group later.
        const { data: row } = await admin.from("ads_creatives").select("*").eq("id", String(body.id)).maybeSingle();
        if (!row || row.status !== "approved" || row.platform !== "google_ads") return json({ error: "gone" }, 409);
        try {
          const resource = await createRsa(row.content, String(body.group_id ?? ""));
          await admin.from("ads_creatives").update({ status: "live", result: { resource, group_id: body.group_id } }).eq("id", row.id);
          return json({ ok: true, message: "Reklama utworzona w Google Ads jako wstrzymana." });
        } catch (e) {
          return json({ ok: false, message: e instanceof SourceError ? e.message : "Google Ads nie odpowiada." });
        }
      }
      default:
        return json({ error: "action" }, 400);
    }
  } catch (e) {
    console.error("ads:", action, e);
    return json({ error: "server" }, 503);
  }
}));

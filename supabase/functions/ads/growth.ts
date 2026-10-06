// The part of the ads module that finds what works: single ads and their numbers, search terms,
// keyword ideas, competitors' ads (Meta Ad Library), the weekly research with new creatives,
// and the changes that come out of it (pausing one ad, a negative keyword, a new text ad).
import {
  type Ad,
  AD_LIBRARY_FIELDS,
  type AdMetric,
  cleanResearchSettings,
  competitorDigest,
  type CompetitorAd,
  creativeVerdicts,
  type Creative,
  GOOGLE_AD_QUERY,
  GOOGLE_GROUP_QUERY,
  GOOGLE_TERMS_QUERY,
  keywordIdeasBody,
  type KeywordIdea,
  parseAdLibrary,
  parseGoogleAdsAds,
  parseGoogleGroups,
  parseKeywordIdeas,
  parseMetaAdInsights,
  parseMetaAds,
  parseResearch,
  parseSearchTerms,
  relevantIdea,
  RESEARCH_SYSTEM,
  researchPrompt,
  type ResearchSettings,
  rsaOperation,
  type SearchTerm,
  upcomingMoments,
  wastedTerms,
} from "../_shared/ads_growth.ts";
import { cleanSettings, type ProposedAction } from "../_shared/ads.ts";
import { askClaude, ClaudeError } from "../_shared/claude.ts";
import type { SupabaseClient } from "npm:@supabase/supabase-js@2";
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

const today = () => new Date().toISOString().slice(0, 10);

async function note(admin: SupabaseClient, source: string, ok: boolean, message: string, data: Record<string, unknown> = {}) {
  await admin.from("ads_status").upsert({ source, ok, message: message.slice(0, 8000), data, updated_at: new Date().toISOString() });
}

async function upsertChunks(admin: SupabaseClient, table: string, rows: Record<string, unknown>[], onConflict?: string) {
  for (let i = 0; i < rows.length; i += 500) {
    const { error } = await admin.from(table).upsert(rows.slice(i, i + 500), onConflict ? { onConflict } : undefined);
    if (error) throw new Error(`${table}: ${error.message}`);
  }
}

/** Replaces one platform's ads: the ones gone from the platform disappear here too. */
async function saveAds(admin: SupabaseClient, platform: string, ads: Ad[], metrics: AdMetric[]) {
  const now = new Date().toISOString();
  await upsertChunks(admin, "ads_ads", ads.map((a) => ({ ...a, synced_at: now })));
  await admin.from("ads_ads").delete().eq("platform", platform).lt("synced_at", now);
  await upsertChunks(admin, "ads_ad_metrics", metrics as unknown as Record<string, unknown>[]);
}

// Daily: single ads, ad groups and search terms --------------------------------------------

export async function syncMetaAds(admin: SupabaseClient): Promise<string> {
  const act = metaAccount();
  const [ads, insights] = await Promise.all([
    metaPages(
      `${META}/${act}/ads?fields=id,name,status,adset_id,campaign_id,creative{body,title,thumbnail_url,video_id,object_story_spec}&limit=200`,
      "Meta reklamy",
    ),
    metaPages(
      `${META}/${act}/insights?level=ad&time_increment=1&date_preset=last_30d` +
        "&fields=ad_id,spend,impressions,clicks,inline_link_clicks,actions,action_values&limit=500",
      "Meta statystyki reklam",
      20,
    ),
  ]);
  const parsed = parseMetaAds(ads);
  const metrics = parseMetaAdInsights(insights);
  await saveAds(admin, "meta", parsed, metrics);
  return `${parsed.length} reklam`;
}

export async function syncGoogleAdsDetail(admin: SupabaseClient, token: string): Promise<string> {
  const [adsBatches, groupBatches, termBatches] = await Promise.all([
    googleSearch(token, GOOGLE_AD_QUERY, "Google Ads reklamy"),
    googleSearch(token, GOOGLE_GROUP_QUERY, "Google Ads grupy"),
    googleSearch(token, GOOGLE_TERMS_QUERY, "Google Ads wyszukiwane frazy"),
  ]);
  const { ads, metrics } = parseGoogleAdsAds(adsBatches);
  await saveAds(admin, "google_ads", ads, metrics);
  const now = new Date().toISOString();
  const groups = parseGoogleGroups(groupBatches);
  await upsertChunks(admin, "ads_groups", groups.map((g) => ({ ...g, synced_at: now })));
  await admin.from("ads_groups").delete().lt("synced_at", now);
  const terms = parseSearchTerms(termBatches).slice(0, 2000);
  await upsertChunks(admin, "ads_search_terms", terms.map((t) => ({ ...t, synced_at: now })));
  await admin.from("ads_search_terms").delete().lt("synced_at", now);
  return `${ads.length} reklam, ${terms.length} wyszukiwanych fraz`;
}

// What the agents see about creatives and terms ----------------------------------------------

export async function loadGrowth(admin: SupabaseClient) {
  const since = new Date(Date.now() - 31 * 864e5).toISOString().slice(0, 10);
  const [ads, metrics, terms, settings] = await Promise.all([
    admin.from("ads_ads").select("*"),
    admin.from("ads_ad_metrics").select("*").gte("day", since).limit(20000),
    admin.from("ads_search_terms").select("*").order("cost", { ascending: false }).limit(2000),
    admin.from("crm_settings").select("value").eq("key", "ads").maybeSingle(),
  ]);
  const num = (v: unknown) => Number(v ?? 0);
  const adRows = (ads.data ?? []) as Ad[];
  const metricRows = ((metrics.data ?? []) as AdMetric[]).map((m) => ({
    ...m,
    spend: num(m.spend),
    impressions: num(m.impressions),
    clicks: num(m.clicks),
    conversions: num(m.conversions),
    revenue: num(m.revenue),
  }));
  const termRows = ((terms.data ?? []) as SearchTerm[]).map((t) => ({
    ...t,
    impressions: num(t.impressions),
    clicks: num(t.clicks),
    cost: num(t.cost),
    conversions: num(t.conversions),
    revenue: num(t.revenue),
  }));
  const target = cleanSettings(settings.data?.value).target_cpa;
  return {
    ads: adRows,
    verdicts: creativeVerdicts(adRows, metricRows, today(), 14, target),
    terms: termRows,
    wasted: wastedTerms(termRows, target),
    target,
  };
}

/** The daily agent's extra context: creatives worth acting on, wasted terms, coming moments. */
export async function dailyContext(admin: SupabaseClient) {
  const g = await loadGrowth(admin);
  return {
    ads: g.ads,
    context: {
      creatives: g.verdicts.filter((v) => v.verdict === "przegrywa" || v.verdict === "zwyciezca" || v.verdict === "jedyna").slice(0, 20),
      wasted_terms: g.wasted.slice(0, 20).map((t) => ({ term: t.term, campaign_id: t.campaign_id, campaign: t.campaign_name, cost: t.cost, clicks: t.clicks })),
      moments: upcomingMoments(today(), 45),
    },
  };
}

// Weekly: competitors, keywords, research --------------------------------------------------

async function researchSettings(admin: SupabaseClient): Promise<ResearchSettings> {
  const { data } = await admin.from("crm_settings").select("value").eq("key", "ads_research").maybeSingle();
  return cleanResearchSettings(data?.value);
}

/** Competitors' ads that reached Poland in the last 90 days: by phrase and by page. */
export async function scanCompetitors(admin: SupabaseClient, settings: ResearchSettings): Promise<string> {
  const token = env("META_AD_LIBRARY_TOKEN") ?? env("META_ACCESS_TOKEN");
  if (!token) throw new SourceError("Biblioteka reklam: brak tokenu (META_AD_LIBRARY_TOKEN).");
  const min = new Date(Date.now() - 90 * 864e5).toISOString().slice(0, 10);
  const base = `${META}/ads_archive?ad_reached_countries=${encodeURIComponent('["PL"]')}&ad_type=ALL&ad_active_status=ALL` +
    `&ad_delivery_date_min=${min}&fields=${AD_LIBRARY_FIELDS}&limit=100`;
  const searches = [
    ...settings.search_terms.map((t) => ({ url: `${base}&search_terms=${encodeURIComponent(t)}`, by: t })),
    ...(settings.competitor_pages.length
      ? [{ url: `${base}&search_page_ids=${encodeURIComponent(JSON.stringify(settings.competitor_pages))}`, by: "strony konkurencji" }]
      : []),
  ];
  const now = new Date().toISOString();
  let total = 0;
  for (const s of searches) {
    const rows: unknown[] = [];
    let next: string | null = s.url;
    for (let i = 0; next && i < 3; i++) {
      const body: Record<string, unknown> = await call(next, { headers: { Authorization: `Bearer ${token}` } }, "Biblioteka reklam");
      rows.push(...((body.data as unknown[]) ?? []));
      next = ((body.paging as Record<string, unknown> | undefined)?.next as string | undefined) ?? null;
    }
    const ads = parseAdLibrary(rows);
    total += ads.length;
    // first_seen stays as it was: only new rows get it from the default.
    await upsertChunks(admin, "ads_competitor_ads", ads.map((a) => ({ ...a, found_by: s.by, last_seen: now })), "ad_archive_id");
  }
  // Older than half a year and not seen since: out.
  await admin.from("ads_competitor_ads").delete().lt("last_seen", new Date(Date.now() - 180 * 864e5).toISOString());
  return `${total} reklam konkurencji (${searches.length} wyszukiwań)`;
}

/** Keyword ideas from our seed words and from competitors' sites, plus fresh numbers for ours. */
export async function refreshKeywords(admin: SupabaseClient, settings: ResearchSettings): Promise<string> {
  const token = await googleToken();
  const ideasFor = async (seed: { keywords?: string[]; url?: string }) => {
    const body = await call(`${GOOGLE_ADS}/customers/${customer()}:generateKeywordIdeas`, {
      method: "POST",
      headers: adsHeaders(token),
      body: JSON.stringify(keywordIdeasBody(seed)),
    }, "Google słowa kluczowe");
    return parseKeywordIdeas(body);
  };
  const found = new Map<string, KeywordIdea & { seed: string }>();
  const add = (ideas: KeywordIdea[], seed: string) => {
    for (const idea of ideas) if (relevantIdea(idea.keyword) && !found.has(idea.keyword)) found.set(idea.keyword, { ...idea, seed });
  };
  if (settings.keyword_seeds.length) add(await ideasFor({ keywords: settings.keyword_seeds }), "nasze frazy");
  for (const site of settings.competitor_sites) {
    try {
      add(await ideasFor({ url: site }), site);
    } catch (e) {
      console.error("ads: keywords for", site, e);
    }
  }
  const { data: existing } = await admin.from("seo_keywords").select("keyword");
  const known = new Set((existing ?? []).map((k: { keyword: string }) => k.keyword));

  // Fresh numbers for the keywords already on the list.
  const ours = [...known].slice(0, 200);
  if (ours.length) {
    const body = await call(`${GOOGLE_ADS}/customers/${customer()}:generateKeywordHistoricalMetrics`, {
      method: "POST",
      headers: adsHeaders(token),
      body: JSON.stringify({
        keywords: ours,
        language: "languageConstants/1030",
        geoTargetConstants: ["geoTargetConstants/2616"],
        keywordPlanNetwork: "GOOGLE_SEARCH",
      }),
    }, "Google dane słów");
    const results = ((body.results as Record<string, unknown>[] | undefined) ?? [])
      .map((r) => ({ text: r.text, keywordIdeaMetrics: r.keywordMetrics }));
    const metrics = parseKeywordIdeas({ results }).filter((k) => known.has(k.keyword));
    const now = new Date().toISOString();
    await upsertChunks(admin, "seo_keywords", metrics.map((k) => ({
      keyword: k.keyword,
      monthly_searches: k.monthly_searches,
      competition: k.competition,
      cpc_low: k.cpc_low,
      cpc_high: k.cpc_high,
      trend: k.trend,
      updated_at: now,
    })), "keyword");
  }

  const fresh = [...found.values()]
    .filter((k) => !known.has(k.keyword))
    .sort((a, b) => (b.monthly_searches ?? 0) - (a.monthly_searches ?? 0))
    .slice(0, 120);
  if (fresh.length) {
    const { error } = await admin.from("seo_keywords").insert(fresh.map((k) => ({
      keyword: k.keyword,
      monthly_searches: k.monthly_searches,
      competition: k.competition,
      cpc_low: k.cpc_low,
      cpc_high: k.cpc_high,
      trend: k.trend,
      seed: k.seed.slice(0, 300),
      source: "google_ads",
    })));
    if (error) throw new Error(`seo_keywords: ${error.message}`);
  }
  return `${fresh.length} nowych fraz, ${ours.length} odświeżonych`;
}

/** The agent's weekly research: findings, creatives to approve, keywords, negatives, tasks. */
export async function research(admin: SupabaseClient, noteText: string | null) {
  if (!env("ANTHROPIC_API_KEY")) return { error: "no_key" as const };
  const day = today();
  const since = new Date(Date.now() - 30 * 864e5).toISOString();
  const [g, competitors, keywords, creatives, campaigns, numbers] = await Promise.all([
    loadGrowth(admin),
    admin.from("ads_competitor_ads").select("*").gte("last_seen", since).limit(2000),
    admin.from("seo_keywords").select("keyword, monthly_searches, competition, cpc_low, cpc_high, used_by, use_for")
      .order("monthly_searches", { ascending: false, nullsFirst: false }).limit(60),
    admin.from("ads_creatives").select("platform, format, angle, status, feedback, content, created_at")
      .order("created_at", { ascending: false }).limit(25),
    admin.from("ads_entities").select("platform, entity_id, name, status, kind").eq("kind", "campaign"),
    admin.rpc("crm_numbers"),
  ]);
  const verdictText = (id: string) => g.ads.find((a) => a.ad_id === id)?.content ?? {};
  const business = (numbers.data ?? {}) as Record<string, unknown>;
  const context = {
    competitors: competitorDigest((competitors.data ?? []) as CompetitorAd[], day),
    keywords: keywords.data ?? [],
    our_search_terms: g.terms.slice(0, 30).map((t) => ({ term: t.term, clicks: t.clicks, cost: t.cost, conversions: t.conversions })),
    wasted_terms: g.wasted.slice(0, 25).map((t) => ({ term: t.term, campaign_id: t.campaign_id, cost: t.cost })),
    our_creatives: g.verdicts
      .filter((v) => v.verdict !== "za_malo_danych")
      .slice(0, 15)
      .map((v) => ({ ...v, content: verdictText(v.ad_id) })),
    recent_creatives: (creatives.data ?? []).filter((c) => c.status !== "rejected"),
    rejected_creatives: (creatives.data ?? []).filter((c) => c.status === "rejected").map((c) => ({ angle: c.angle, feedback: c.feedback })),
    moments: upcomingMoments(day, 75),
    campaigns: campaigns.data ?? [],
    target_cpa: g.target,
    business: { paying_families: business.paying_families, revenue_30d_gross: business.revenue_30d_gross },
  };
  let answer: string;
  try {
    answer = await askClaude(RESEARCH_SYSTEM, researchPrompt(context, noteText, day), 9000);
  } catch (e) {
    console.error("ads: research model", e instanceof ClaudeError ? e.message : e);
    return { error: "model" as const, reason: e instanceof ClaudeError ? e.reason : "model" };
  }
  let parsed;
  try {
    parsed = parseResearch(
      answer,
      (campaigns.data ?? []).filter((c) => c.platform === "google_ads").map((c) => c.entity_id),
      g.wasted.map((t) => t.term),
    );
  } catch (e) {
    console.error("ads: research answer", e, answer.slice(0, 500));
    return { error: "answer" as const };
  }

  const { data: saved, error } = await admin.from("ads_research").insert({
    summary: parsed.summary,
    data: { keywords: parsed.keywords, competitors: context.competitors.length, moments: context.moments },
  }).select("id").single();
  if (error) throw new Error(`research: ${error.message}`);

  if (parsed.creatives.length) {
    await admin.from("ads_creatives").insert(parsed.creatives.map((c: Creative) => ({ ...c, research_id: saved.id, status: "draft", source: "ai" })));
  }
  if (parsed.keywords.length) {
    await admin.from("seo_keywords").upsert(
      parsed.keywords.map((k) => ({ keyword: k.keyword, source: "agent", use_for: k.use, note: k.why.slice(0, 500) })),
      { onConflict: "keyword", ignoreDuplicates: true },
    );
  }
  const names = new Map((campaigns.data ?? []).map((c) => [c.entity_id, c.name]));
  const actions = [
    ...parsed.negatives.map((x) => ({
      platform: "google_ads",
      entity_id: x.campaign_id,
      entity_name: names.get(x.campaign_id) ?? "",
      action: "add_negative",
      params: { term: x.term, match: "PHRASE" },
      title: `Wykluczyć „${x.term}”`,
      reason: x.why,
      expected: "Mniej kliknięć bez zakupu.",
      priority: 2,
      status: "pending",
      source: "ai",
    })),
    ...parsed.tasks.map((t) => ({
      platform: "site",
      entity_id: null,
      entity_name: "",
      action: "task",
      params: {},
      title: t.title,
      reason: t.reason,
      expected: "",
      priority: t.priority,
      status: "pending",
      source: "ai",
    })),
  ];
  if (actions.length) await admin.from("ads_actions").insert(actions);
  await note(admin, "research", true, parsed.summary, { creatives: parsed.creatives.length, at: new Date().toISOString() });
  return { summary: parsed.summary, creatives: parsed.creatives.length, actions: actions.length };
}

/** The whole weekly run; each part reports on its own, a failure does not stop the rest. */
export async function weekly(admin: SupabaseClient, noteText: string | null = null) {
  const settings = await researchSettings(admin);
  const on = configured();
  const report: Record<string, string> = {};
  const run = async (source: string, enabled: boolean, job: () => Promise<string>) => {
    if (!enabled) return;
    try {
      report[source] = await job();
      await note(admin, source, true, report[source]);
    } catch (e) {
      report[source] = e instanceof SourceError ? e.message : "błąd";
      if (!(e instanceof SourceError)) console.error(`ads: ${source}`, e);
      await note(admin, source, false, report[source]);
    }
  };
  await run("ad_library", !!(env("META_AD_LIBRARY_TOKEN") ?? env("META_ACCESS_TOKEN")), () => scanCompetitors(admin, settings));
  await run("keywords", on.google_ads, () => refreshKeywords(admin, settings));
  const agent = settings.enabled && on.agent ? await research(admin, noteText) : { skipped: true };
  return { report, agent };
}

// Changes from the growth part ---------------------------------------------------------------

export async function applyGrowthAction(a: ProposedAction, ad: Ad | undefined): Promise<void> {
  const on = configured();
  if (a.action === "pause_ad") {
    if (!ad) throw new SourceError("Nie ma takiej reklamy.");
    if (a.platform === "meta") {
      if (!on.meta) throw new SourceError("Meta nie jest połączona.");
      await call(`${META}/${a.entity_id}`, { method: "POST", headers: metaHeaders(), body: new URLSearchParams({ status: "PAUSED" }) }, "Meta reklama");
      return;
    }
    if (!on.google_ads) throw new SourceError("Google Ads nie jest połączone.");
    const id = customer();
    await call(`${GOOGLE_ADS}/customers/${id}/adGroupAds:mutate`, {
      method: "POST",
      headers: adsHeaders(await googleToken()),
      body: JSON.stringify({
        operations: [{ update: { resourceName: `customers/${id}/adGroupAds/${ad.group_id}~${ad.ad_id}`, status: "PAUSED" }, updateMask: "status" }],
      }),
    }, "Google Ads reklama");
    return;
  }
  if (a.action === "add_negative") {
    if (!on.google_ads) throw new SourceError("Google Ads nie jest połączone.");
    const id = customer();
    await call(`${GOOGLE_ADS}/customers/${id}/campaignCriteria:mutate`, {
      method: "POST",
      headers: adsHeaders(await googleToken()),
      body: JSON.stringify({
        operations: [{
          create: {
            campaign: `customers/${id}/campaigns/${a.entity_id}`,
            negative: true,
            keyword: { text: a.params.term, matchType: a.params.match ?? "PHRASE" },
          },
        }],
      }),
    }, "Google Ads wykluczenie");
  }
}

/** A Google text ad from an approved creative, created paused in [groupId]. */
export async function createRsa(content: Creative["content"], groupId: string): Promise<string> {
  if (!configured().google_ads) throw new SourceError("Google Ads nie jest połączone.");
  const body = await call(`${GOOGLE_ADS}/customers/${customer()}/adGroupAds:mutate`, {
    method: "POST",
    headers: adsHeaders(await googleToken()),
    body: JSON.stringify(rsaOperation(customer(), groupId, content)),
  }, "Google Ads nowa reklama");
  const results = (body.results as { resourceName?: string }[] | undefined) ?? [];
  return results[0]?.resourceName ?? "";
}

/** Everything the Kreacje / Konkurencja / Słowa kluczowe views show. */
export async function growthOverview(admin: SupabaseClient) {
  const since = new Date(Date.now() - 45 * 864e5).toISOString();
  const [g, creatives, research, competitors, keywords, groups, settings] = await Promise.all([
    loadGrowth(admin),
    admin.from("ads_creatives").select("*").order("created_at", { ascending: false }).limit(80),
    admin.from("ads_research").select("*").order("created_at", { ascending: false }).limit(6),
    admin.from("ads_competitor_ads").select("*").gte("last_seen", since).order("start_date", { ascending: true }).limit(1500),
    admin.from("seo_keywords").select("*").order("monthly_searches", { ascending: false, nullsFirst: false }).limit(400),
    admin.from("ads_groups").select("*").eq("status", "active").order("campaign_name"),
    researchSettings(admin),
  ]);
  const day = today();
  return {
    verdicts: g.verdicts,
    ads: g.ads,
    terms: g.terms.slice(0, 300),
    wasted: g.wasted,
    creatives: creatives.data ?? [],
    research: research.data ?? [],
    competitors: competitorDigest((competitors.data ?? []) as CompetitorAd[], day, 8),
    competitor_ads: (competitors.data ?? []).length,
    keywords: keywords.data ?? [],
    groups: groups.data ?? [],
    settings,
    moments: upcomingMoments(day, 90),
  };
}

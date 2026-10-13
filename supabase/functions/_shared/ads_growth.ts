// What makes the ads pay off, beyond budgets: how each creative does (with honest statistics),
// what people really typed before clicking, which words parents search for, what competitors
// run and for how long, and the moments of the Polish year worth preparing for. Then the
// agent's weekly research: insights and new creatives, every one waiting for approval.
// Nothing here talks to the network.

const n = (v: unknown) => {
  const x = typeof v === "number" ? v : Number(v ?? 0);
  return Number.isFinite(x) ? x : 0;
};
const money = (v: number) => Math.round(v * 100) / 100;
const text = (v: unknown, max = 300) => (typeof v === "string" ? v : v == null ? "" : String(v)).slice(0, max);
const strings = (v: unknown, max = 2000) =>
  Array.isArray(v) ? v.map((x) => text(x, max).trim()).filter((x) => x.length > 0) : [];

// Ads (creatives) and their numbers ----------------------------------------------------------

export type Ad = {
  platform: "meta" | "google_ads";
  ad_id: string;
  campaign_id: string | null;
  group_id: string | null;
  name: string;
  status: string;
  kind: string;
  content: Record<string, unknown>;
  preview_url: string | null;
};

export type AdMetric = {
  platform: "meta" | "google_ads";
  ad_id: string;
  day: string;
  spend: number;
  impressions: number;
  clicks: number;
  conversions: number;
  revenue: number;
};

const META_PURCHASE = ["omni_purchase", "purchase", "offsite_conversion.fb_pixel_purchase"];
function metaAction(list: unknown): number {
  if (!Array.isArray(list)) return 0;
  for (const type of META_PURCHASE) {
    const hit = list.find((a) => a?.action_type === type);
    if (hit) return n(hit.value);
  }
  return 0;
}

const status = (s: unknown) => {
  const v = text(s, 40).toUpperCase();
  return v === "ACTIVE" || v === "ENABLED" ? "active" : v === "PAUSED" ? "paused" : v.toLowerCase() || "unknown";
};

/** Meta ads (GET act_/ads with the creative's texts). */
export function parseMetaAds(rows: unknown[]): Ad[] {
  return rows.flatMap((raw) => {
    const r = raw as Record<string, unknown>;
    if (!r?.id) return [];
    const creative = (r.creative ?? {}) as Record<string, unknown>;
    const link = (((creative.object_story_spec ?? {}) as Record<string, unknown>).link_data ?? {}) as Record<string, unknown>;
    const s = status(r.status);
    if (s === "deleted" || s === "archived") return [];
    return [{
      platform: "meta" as const,
      ad_id: text(r.id, 80),
      campaign_id: text(r.campaign_id, 80) || null,
      group_id: text(r.adset_id, 80) || null,
      name: text(r.name),
      status: s,
      kind: creative.video_id || (link.child_attachments as unknown[] | undefined)?.length ? "video_or_carousel" : "image",
      content: {
        body: text(creative.body ?? link.message, 2000),
        title: text(creative.title ?? link.name, 300),
        description: text(link.description, 300),
      },
      preview_url: text(creative.thumbnail_url, 1000) || null,
    }];
  });
}

/** Meta insights at ad level, a row per day. */
export function parseMetaAdInsights(rows: unknown[]): AdMetric[] {
  return rows.flatMap((raw) => {
    const r = raw as Record<string, unknown>;
    if (!r?.ad_id || !r.date_start) return [];
    return [{
      platform: "meta" as const,
      ad_id: text(r.ad_id, 80),
      day: text(r.date_start, 10),
      spend: money(n(r.spend)),
      impressions: Math.round(n(r.impressions)),
      clicks: Math.round(n(r.inline_link_clicks ?? r.clicks)),
      conversions: metaAction(r.actions),
      revenue: money(metaAction(r.action_values)),
    }];
  });
}

/** Google Ads: ads with texts and daily numbers in one query. */
export const GOOGLE_AD_QUERY = `SELECT ad_group_ad.ad.id, ad_group_ad.ad.name, ad_group_ad.ad.type, ad_group_ad.status,
  ad_group_ad.ad.responsive_search_ad.headlines, ad_group_ad.ad.responsive_search_ad.descriptions,
  ad_group_ad.ad.final_urls, ad_group.id, campaign.id, segments.date, metrics.impressions, metrics.clicks,
  metrics.cost_micros, metrics.conversions, metrics.conversions_value
FROM ad_group_ad
WHERE segments.date DURING LAST_30_DAYS AND ad_group_ad.status != 'REMOVED'`;

/** Search ad groups, so a new text ad can be placed in one. */
export const GOOGLE_GROUP_QUERY = `SELECT ad_group.id, ad_group.name, ad_group.status, campaign.id, campaign.name
FROM ad_group
WHERE ad_group.status != 'REMOVED' AND campaign.status != 'REMOVED' AND campaign.advertising_channel_type = 'SEARCH'`;

/** What people typed before an ad showed, 30 days. */
export const GOOGLE_TERMS_QUERY = `SELECT search_term_view.search_term, search_term_view.status, campaign.id, campaign.name,
  ad_group.id, metrics.impressions, metrics.clicks, metrics.cost_micros, metrics.conversions, metrics.conversions_value
FROM search_term_view
WHERE segments.date DURING LAST_30_DAYS`;

type Row = Record<string, Record<string, unknown>>;
const rowsOf = (batches: unknown[]) =>
  batches.flatMap((b) => ((b as { results?: unknown[] })?.results ?? []) as Row[]);

export function parseGoogleAdsAds(batches: unknown[]): { ads: Ad[]; metrics: AdMetric[] } {
  const ads = new Map<string, Ad>();
  const metrics: AdMetric[] = [];
  for (const r of rowsOf(batches)) {
    const ad = (r.adGroupAd?.ad ?? {}) as Record<string, unknown>;
    const id = text(ad.id, 80);
    if (!id) continue;
    const rsa = (ad.responsiveSearchAd ?? {}) as Record<string, unknown>;
    const assets = (v: unknown) => Array.isArray(v) ? v.map((a) => text((a as { text?: string })?.text, 200)).filter(Boolean) : [];
    ads.set(id, {
      platform: "google_ads",
      ad_id: id,
      campaign_id: text(r.campaign?.id, 80) || null,
      group_id: text(r.adGroup?.id, 80) || null,
      name: text(ad.name) || assets(rsa.headlines)[0] || `Reklama ${id}`,
      status: status(r.adGroupAd?.status),
      kind: text(ad.type, 60).toLowerCase() || "unknown",
      content: { headlines: assets(rsa.headlines), descriptions: assets(rsa.descriptions), final_urls: ad.finalUrls ?? [] },
      preview_url: null,
    });
    if (r.segments?.date) {
      metrics.push({
        platform: "google_ads",
        ad_id: id,
        day: text(r.segments.date, 10),
        spend: money(n(r.metrics?.costMicros) / 1e6),
        impressions: Math.round(n(r.metrics?.impressions)),
        clicks: Math.round(n(r.metrics?.clicks)),
        conversions: money(n(r.metrics?.conversions)),
        revenue: money(n(r.metrics?.conversionsValue)),
      });
    }
  }
  return { ads: [...ads.values()], metrics };
}

export type AdGroup = { platform: "google_ads"; group_id: string; campaign_id: string; name: string; campaign_name: string; status: string };

export function parseGoogleGroups(batches: unknown[]): AdGroup[] {
  return rowsOf(batches).flatMap((r) => {
    const id = text(r.adGroup?.id, 80);
    if (!id) return [];
    return [{
      platform: "google_ads" as const,
      group_id: id,
      campaign_id: text(r.campaign?.id, 80),
      name: text(r.adGroup?.name),
      campaign_name: text(r.campaign?.name),
      status: status(r.adGroup?.status),
    }];
  });
}

export type SearchTerm = {
  term: string;
  campaign_id: string;
  campaign_name: string;
  google_status: string;
  impressions: number;
  clicks: number;
  cost: number;
  conversions: number;
  revenue: number;
};

/** One row per term and campaign (Google answers per ad group). */
export function parseSearchTerms(batches: unknown[]): SearchTerm[] {
  const out = new Map<string, SearchTerm>();
  for (const r of rowsOf(batches)) {
    const term = text(r.searchTermView?.searchTerm, 200).trim().toLowerCase();
    const campaign = text(r.campaign?.id, 80);
    if (!term || !campaign) continue;
    const key = `${campaign}|${term}`;
    const t = out.get(key) ?? {
      term,
      campaign_id: campaign,
      campaign_name: text(r.campaign?.name),
      google_status: text(r.searchTermView?.status, 40).toLowerCase() || "none",
      impressions: 0,
      clicks: 0,
      cost: 0,
      conversions: 0,
      revenue: 0,
    };
    t.impressions += Math.round(n(r.metrics?.impressions));
    t.clicks += Math.round(n(r.metrics?.clicks));
    t.cost = money(t.cost + n(r.metrics?.costMicros) / 1e6);
    t.conversions = money(t.conversions + n(r.metrics?.conversions));
    t.revenue = money(t.revenue + n(r.metrics?.conversionsValue));
    out.set(key, t);
  }
  return [...out.values()].sort((a, b) => b.cost - a.cost);
}

/**
 * Terms that cost money and sold nothing: candidates for negative keywords. A term is listed
 * when it spent at least [minCost] (or half the target purchase cost) with no conversion.
 */
export function wastedTerms(terms: SearchTerm[], targetCpa: number | null, minCost = 10): SearchTerm[] {
  const limit = Math.max(minCost, (targetCpa ?? 40) / 2);
  return terms.filter((t) => t.conversions === 0 && t.cost >= limit && t.google_status !== "excluded");
}

// Honest comparison of creatives -------------------------------------------------------------

/** Normal CDF (Abramowitz–Stegun), enough for decisions about ads. */
function phi(z: number): number {
  const t = 1 / (1 + 0.2316419 * Math.abs(z));
  const d = 0.3989423 * Math.exp(-z * z / 2);
  const p = d * t * (0.3193815 + t * (-0.3565638 + t * (1.781478 + t * (-1.821256 + t * 1.330274))));
  return z > 0 ? 1 - p : p;
}

/** The chance that rate A (a of n) is truly higher than rate B (b of m), Beta(1+x, 1+n-x) approximated. */
export function chanceBetter(a: number, nA: number, b: number, nB: number): number {
  const beta = (x: number, total: number) => {
    const al = x + 1, be = total - x + 1;
    const mean = al / (al + be);
    const variance = (al * be) / ((al + be) ** 2 * (al + be + 1));
    return { mean, variance };
  };
  const A = beta(a, nA), B = beta(b, nB);
  const sd = Math.sqrt(A.variance + B.variance);
  return sd === 0 ? 0.5 : phi((A.mean - B.mean) / sd);
}

export type Verdict = {
  ad_id: string;
  platform: "meta" | "google_ads";
  group_id: string | null;
  name: string;
  status: string;
  impressions: number;
  clicks: number;
  spend: number;
  conversions: number;
  ctr: number | null;
  cpa: number | null;
  /** The chance it has the best click rate in its group (other active ads). */
  chance_best: number | null;
  verdict: "za_malo_danych" | "zwyciezca" | "przegrywa" | "w_normie" | "jedyna";
  note: string;
};

/**
 * Per ad over [days]: numbers and a verdict against the other ads in the same ad set / ad group.
 * Winner: ≥95% chance its click rate is the best; losing: ≤5% and a pricier purchase or none.
 * Below 1000 impressions there is no verdict at all.
 */
export function creativeVerdicts(ads: Ad[], metrics: AdMetric[], today: string, days = 14, targetCpa: number | null = 40): Verdict[] {
  const since = new Date(Date.parse(`${today}T00:00:00Z`) - days * 864e5).toISOString().slice(0, 10);
  const totals = new Map<string, { spend: number; impressions: number; clicks: number; conversions: number }>();
  for (const m of metrics) {
    if (m.day < since) continue;
    const key = `${m.platform}|${m.ad_id}`;
    const t = totals.get(key) ?? { spend: 0, impressions: 0, clicks: 0, conversions: 0 };
    t.spend += m.spend;
    t.impressions += m.impressions;
    t.clicks += m.clicks;
    t.conversions += m.conversions;
    totals.set(key, t);
  }
  const rows = ads.map((ad) => {
    const t = totals.get(`${ad.platform}|${ad.ad_id}`) ?? { spend: 0, impressions: 0, clicks: 0, conversions: 0 };
    return { ad, ...t, spend: money(t.spend), conversions: money(t.conversions) };
  });
  return rows.map((r) => {
    const peers = rows.filter((p) =>
      p !== r && p.ad.platform === r.ad.platform && p.ad.group_id === r.ad.group_id && p.ad.status === "active" && p.impressions > 0
    );
    // Only peers with enough data take part in the comparison.
    const judged = peers.filter((p) => p.impressions >= 1000);
    const base = {
      ad_id: r.ad.ad_id,
      platform: r.ad.platform,
      group_id: r.ad.group_id,
      name: r.ad.name,
      status: r.ad.status,
      impressions: r.impressions,
      clicks: r.clicks,
      spend: r.spend,
      conversions: r.conversions,
      ctr: r.impressions > 0 ? Math.round((r.clicks / r.impressions) * 10000) / 100 : null,
      cpa: r.conversions > 0 ? money(r.spend / r.conversions) : null,
    };
    if (r.impressions < 1000) {
      return { ...base, chance_best: null, verdict: "za_malo_danych" as const, note: `${r.impressions} wyświetleń: za mało, by oceniać.` };
    }
    if (!peers.length) {
      return { ...base, chance_best: null, verdict: "jedyna" as const, note: "Jedyna aktywna reklama w grupie: dodaj wariant do porównania." };
    }
    if (!judged.length) {
      return { ...base, chance_best: null, verdict: "w_normie" as const, note: "Pozostałe reklamy w grupie mają jeszcze za mało wyświetleń." };
    }
    const chance = judged.reduce((p, o) => p * chanceBetter(r.clicks, r.impressions, o.clicks, o.impressions), 1);
    const rounded = Math.round(chance * 1000) / 1000;
    const pricey = base.cpa === null ? r.spend >= (targetCpa ?? 40) : targetCpa !== null && base.cpa > targetCpa * 1.5;
    if (chance >= 0.95) {
      return { ...base, chance_best: rounded, verdict: "zwyciezca" as const, note: `${Math.round(chance * 100)}% szans, że ma najlepszy CTR w grupie.` };
    }
    const chanceWorse = judged.every((o) => chanceBetter(o.clicks, o.impressions, r.clicks, r.impressions) >= 0.95);
    if (chanceWorse && pricey) {
      return { ...base, chance_best: rounded, verdict: "przegrywa" as const, note: "Wyraźnie słabszy CTR od pozostałych i drogi albo brak zakupu." };
    }
    return { ...base, chance_best: rounded, verdict: "w_normie" as const, note: "Jeszcze bez rozstrzygnięcia." };
  });
}

// Keyword ideas (Google Ads KeywordPlanIdeaService) -----------------------------------------

export type KeywordIdea = {
  keyword: string;
  monthly_searches: number | null;
  competition: string | null;
  cpc_low: number | null;
  cpc_high: number | null;
  trend: { month: string; searches: number }[];
};

const MONTHS: Record<string, string> = {
  JANUARY: "01", FEBRUARY: "02", MARCH: "03", APRIL: "04", MAY: "05", JUNE: "06",
  JULY: "07", AUGUST: "08", SEPTEMBER: "09", OCTOBER: "10", NOVEMBER: "11", DECEMBER: "12",
};

/** The request body: Polish, Poland, Google Search; seeds are words or a website. */
export function keywordIdeasBody(seed: { keywords?: string[]; url?: string }, pageToken?: string) {
  const base: Record<string, unknown> = {
    language: "languageConstants/1030",
    geoTargetConstants: ["geoTargetConstants/2616"],
    keywordPlanNetwork: "GOOGLE_SEARCH",
    includeAdultKeywords: false,
    pageSize: 300,
    ...(pageToken ? { pageToken } : {}),
  };
  const words = (seed.keywords ?? []).map((k) => k.trim()).filter(Boolean).slice(0, 20);
  if (seed.url && words.length) base.keywordAndUrlSeed = { url: seed.url, keywords: words };
  else if (seed.url) base.urlSeed = { url: seed.url };
  else base.keywordSeed = { keywords: words };
  return base;
}

export function parseKeywordIdeas(body: unknown): KeywordIdea[] {
  const results = ((body as { results?: unknown[] })?.results ?? []) as Record<string, unknown>[];
  return results.flatMap((r) => {
    const keyword = text(r.text, 120).trim().toLowerCase();
    if (keyword.length < 2) return [];
    const m = (r.keywordIdeaMetrics ?? {}) as Record<string, unknown>;
    const micros = (v: unknown) => v == null ? null : money(n(v) / 1e6);
    const trend = Array.isArray(m.monthlySearchVolumes)
      ? (m.monthlySearchVolumes as Record<string, unknown>[]).map((v) => ({
        month: `${n(v.year)}-${MONTHS[text(v.month, 20)] ?? "00"}`,
        searches: Math.round(n(v.monthlySearches)),
      })).slice(-12)
      : [];
    const competition = text(m.competition, 20).toUpperCase();
    return [{
      keyword,
      monthly_searches: m.avgMonthlySearches == null ? null : Math.round(n(m.avgMonthlySearches)),
      competition: ["LOW", "MEDIUM", "HIGH", "UNSPECIFIED", "UNKNOWN"].includes(competition) ? competition : null,
      cpc_low: micros(m.lowTopOfPageBidMicros),
      cpc_high: micros(m.highTopOfPageBidMicros),
      trend,
    }];
  });
}

/** Ideas that fit AudioKiddo: about children and listening, play, travel, sleep or speech. */
export function relevantIdea(keyword: string): boolean {
  const k = keyword.toLowerCase();
  const about = /(dzieck|dzieci|dziecię|przedszkol|maluch|latk|niemowl|rodzic|mam[aey]|bajk|kołysank|zagadk|logoped)/;
  const topic = /(zabaw|bajk|słuch|audio|bez ekranu|ekran|podróż|aut[aoy]|samoch|sen|snem|spani|wyciszen|mow[aęy]|logoped|zagadk|słow|wyobraź|nud|deszcz|kołysank|opowiad|histor|aplikacj)/;
  const off = /(darmo.*film|youtube|netflix|chomikuj|cda|torrent|pdf do druku za darmo|porno|sex)/;
  return about.test(k) && topic.test(k) && !off.test(k);
}

// Meta Ad Library (EU: every ad that reached Poland) -----------------------------------------

export type CompetitorAd = {
  ad_archive_id: string;
  page_id: string;
  page_name: string;
  bodies: string[];
  titles: string[];
  descriptions: string[];
  captions: string[];
  start_date: string | null;
  stop_date: string | null;
  platforms: string[];
  reach: number | null;
  snapshot_url: string | null;
  target_ages: string[];
};

export const AD_LIBRARY_FIELDS = [
  "id", "page_id", "page_name", "ad_creative_bodies", "ad_creative_link_titles", "ad_creative_link_descriptions",
  "ad_creative_link_captions", "ad_delivery_start_time", "ad_delivery_stop_time", "ad_snapshot_url",
  "publisher_platforms", "eu_total_reach", "target_ages",
].join(",");

export function parseAdLibrary(rows: unknown[]): CompetitorAd[] {
  return rows.flatMap((raw) => {
    const r = raw as Record<string, unknown>;
    if (!r?.id || !r.page_id) return [];
    const date = (v: unknown) => /^\d{4}-\d{2}-\d{2}/.test(text(v, 30)) ? text(v, 10) : null;
    return [{
      ad_archive_id: text(r.id, 80),
      page_id: text(r.page_id, 80),
      page_name: text(r.page_name),
      bodies: [...new Set(strings(r.ad_creative_bodies))].slice(0, 5),
      titles: [...new Set(strings(r.ad_creative_link_titles, 300))].slice(0, 5),
      descriptions: [...new Set(strings(r.ad_creative_link_descriptions, 300))].slice(0, 5),
      captions: [...new Set(strings(r.ad_creative_link_captions, 300))].slice(0, 5),
      start_date: date(r.ad_delivery_start_time),
      stop_date: date(r.ad_delivery_stop_time),
      platforms: strings(r.publisher_platforms, 40),
      reach: r.eu_total_reach == null ? null : Math.round(n(r.eu_total_reach)),
      snapshot_url: text(r.ad_snapshot_url, 1000) || null,
      target_ages: strings(r.target_ages, 20),
    }];
  });
}

/** Days an ad has been running: long runners are the ones that pay off for their owner. */
export function daysRunning(ad: { start_date: string | null; stop_date: string | null }, today: string): number {
  if (!ad.start_date) return 0;
  const end = ad.stop_date && ad.stop_date < today ? ad.stop_date : today;
  return Math.max(0, Math.round((Date.parse(`${end}T00:00:00Z`) - Date.parse(`${ad.start_date}T00:00:00Z`)) / 864e5));
}

/** Per advertiser: how many ads, the longest runners with their texts (for the agent). */
export function competitorDigest(ads: CompetitorAd[], today: string, perPage = 5) {
  const pages = new Map<string, CompetitorAd[]>();
  for (const ad of ads) pages.set(ad.page_id, [...(pages.get(ad.page_id) ?? []), ad]);
  return [...pages.values()]
    .map((list) => ({
      page: list[0].page_name,
      page_id: list[0].page_id,
      active_ads: list.filter((a) => !a.stop_date || a.stop_date >= today).length,
      longest: list
        .map((a) => ({ days: daysRunning(a, today), text: a.bodies[0]?.slice(0, 500) ?? "", title: a.titles[0] ?? "", reach: a.reach, platforms: a.platforms }))
        .sort((a, b) => b.days - a.days)
        .slice(0, perPage),
    }))
    .sort((a, b) => b.active_ads - a.active_ads)
    .slice(0, 15);
}

// The Polish year ------------------------------------------------------------------------------

/** Easter Sunday (Gregorian, anonymous algorithm). */
export function easter(year: number): string {
  const a = year % 19, b = Math.floor(year / 100), c = year % 100, d = Math.floor(b / 4), e = b % 4;
  const f = Math.floor((b + 8) / 25), g = Math.floor((b - f + 1) / 3), h = (19 * a + b - d - g + 15) % 30;
  const i = Math.floor(c / 4), k = c % 4, l = (32 + 2 * e + 2 * i - h - k) % 7, m = Math.floor((a + 11 * h + 22 * l) / 451);
  const month = Math.floor((h + l - 7 * m + 114) / 31), day = ((h + l - 7 * m + 114) % 31) + 1;
  return `${year}-${String(month).padStart(2, "0")}-${String(day).padStart(2, "0")}`;
}

export type Moment = { name: string; start: string; end: string; angle: string; days_to_start: number };

/** Moments within [ahead] days (or under way) with the angle that fits AudioKiddo. */
export function upcomingMoments(today: string, ahead = 60): Moment[] {
  const y = Number(today.slice(0, 4));
  const shift = (date: string, days: number) => new Date(Date.parse(`${date}T00:00:00Z`) + days * 864e5).toISOString().slice(0, 10);
  const list = [y, y + 1].flatMap((year) => {
    const e = easter(year);
    // Wakacje: from the last Friday of June.
    const june30 = new Date(Date.UTC(year, 5, 30));
    const lastFriday = shift(june30.toISOString().slice(0, 10), -((june30.getUTCDay() + 2) % 7));
    return [
      { name: "Ferie zimowe", start: `${year}-01-12`, end: `${year}-03-01`, angle: "ferie bez tabletu, wyjazdy w góry, długie trasy" },
      { name: "Wielkanoc: droga do dziadków", start: shift(e, -10), end: shift(e, 1), angle: "podróż do rodziny, zabawy w aucie, prezent od zajączka" },
      { name: "Majówka", start: `${year}-04-24`, end: `${year}-05-03`, angle: "długi weekend, wyjazdy, zabawy na trasę" },
      { name: "Dzień Matki", start: `${year}-05-12`, end: `${year}-05-26`, angle: "chwila dla mamy, rodzic odpoczywa, gdy dziecko się bawi" },
      { name: "Dzień Dziecka", start: `${year}-05-15`, end: `${year}-06-01`, angle: "prezent bez ekranu, pakiet w prezencie" },
      { name: "Wakacje", start: shift(lastFriday, -14), end: `${year}-08-31`, angle: "wakacyjne podróże, auto, samolot, offline" },
      { name: "Powrót do przedszkola i szkoły", start: `${year}-08-20`, end: `${year}-09-15`, angle: "wieczorny rytuał, wyciszenie po dniu, rutyna" },
      { name: "Wszystkich Świętych: wyjazdy", start: `${year}-10-22`, end: `${year}-11-02`, angle: "długie trasy do rodziny" },
      { name: "Mikołajki", start: `${year}-11-20`, end: `${year}-12-06`, angle: "prezent bez ekranu do skarpety" },
      { name: "Święta", start: `${year}-12-01`, end: `${year}-12-26`, angle: "prezent, wyjazdy do rodziny, przerwa świąteczna" },
    ];
  });
  const limit = shift(today, ahead);
  return list
    .filter((m) => m.end >= today && m.start <= limit)
    .map((m) => ({ ...m, days_to_start: Math.max(0, Math.round((Date.parse(`${m.start}T00:00:00Z`) - Date.parse(`${today}T00:00:00Z`)) / 864e5)) }))
    .sort((a, b) => a.start.localeCompare(b.start));
}

// Creatives the agent writes -------------------------------------------------------------------

export type Creative = {
  platform: "meta" | "google_ads";
  format: "rsa" | "meta_image" | "meta_video";
  angle: string;
  moment: string | null;
  content: {
    headlines?: string[];
    descriptions?: string[];
    path1?: string;
    path2?: string;
    final_url?: string;
    primary_text?: string;
    headline?: string;
    description?: string;
    cta?: string;
    visual_brief?: string;
    hook_script?: string;
  };
  why: string;
  problems: string[];
};

/** Google's limits for responsive search ads; Meta's recommended lengths. */
export const LIMITS = { headline: 30, headlines: [3, 15], description: 90, descriptions: [2, 4], path: 15, metaHeadline: 40, metaPrimary: 600 } as const;

const SITE = "https://audiokiddo.pl/";

/** One creative from the model, held to the platform limits; what does not fit is listed in problems. */
export function cleanCreative(raw: unknown): Creative | null {
  const r = (raw && typeof raw === "object" ? raw : {}) as Record<string, unknown>;
  const platform = r.platform === "google_ads" ? "google_ads" : r.platform === "meta" ? "meta" : null;
  if (!platform) return null;
  const problems: string[] = [];
  const angle = text(r.angle, 200).trim();
  const why = text(r.why, 2000).trim();
  if (platform === "google_ads") {
    const all = strings(r.headlines, 200);
    const headlines = [...new Set(all.filter((h) => h.length <= LIMITS.headline))].slice(0, LIMITS.headlines[1]);
    const longH = all.length - all.filter((h) => h.length <= LIMITS.headline).length;
    if (longH) problems.push(`${longH} nagłówków dłuższych niż ${LIMITS.headline} znaków pominięto.`);
    if (headlines.length < LIMITS.headlines[0]) problems.push(`Potrzeba co najmniej ${LIMITS.headlines[0]} nagłówków.`);
    const allD = strings(r.descriptions, 300);
    const descriptions = [...new Set(allD.filter((d) => d.length <= LIMITS.description))].slice(0, LIMITS.descriptions[1]);
    if (allD.length > descriptions.length) problems.push(`Opisy dłuższe niż ${LIMITS.description} znaków pominięto.`);
    if (descriptions.length < LIMITS.descriptions[0]) problems.push(`Potrzeba co najmniej ${LIMITS.descriptions[0]} opisów.`);
    const path = (v: unknown) => text(v, 40).replace(/[^a-z0-9ąćęłńóśźż-]/gi, "").slice(0, LIMITS.path);
    const url = text(r.final_url, 300);
    return {
      platform,
      format: "rsa",
      angle,
      moment: text(r.moment, 100) || null,
      content: {
        headlines,
        descriptions,
        path1: path(r.path1),
        path2: path(r.path2),
        final_url: url.startsWith(SITE) ? url : SITE,
      },
      why,
      problems,
    };
  }
  const headline = text(r.headline, 200).trim();
  if (headline.length > LIMITS.metaHeadline) problems.push(`Nagłówek ma ${headline.length} znaków (zalecane do ${LIMITS.metaHeadline}).`);
  const primary = text(r.primary_text, 2000).trim();
  if (primary.length > LIMITS.metaPrimary) problems.push("Tekst główny jest bardzo długi.");
  if (!primary) problems.push("Brak tekstu głównego.");
  return {
    platform,
    format: r.format === "meta_video" ? "meta_video" : "meta_image",
    angle,
    moment: text(r.moment, 100) || null,
    content: {
      primary_text: primary,
      headline,
      description: text(r.description, 200).trim(),
      cta: text(r.cta, 40).trim() || "Dowiedz się więcej",
      final_url: text(r.final_url, 300).startsWith(SITE) ? text(r.final_url, 300) : SITE,
      visual_brief: text(r.visual_brief, 3000).trim(),
      hook_script: text(r.hook_script, 3000).trim(),
    },
    why,
    problems,
  };
}

/** The body for adGroupAds:mutate: a responsive search ad, created paused. */
export function rsaOperation(customerId: string, groupId: string, c: Creative["content"]) {
  return {
    operations: [{
      create: {
        adGroup: `customers/${customerId}/adGroups/${groupId}`,
        status: "PAUSED",
        ad: {
          finalUrls: [c.final_url ?? SITE],
          responsiveSearchAd: {
            headlines: (c.headlines ?? []).map((t) => ({ text: t })),
            descriptions: (c.descriptions ?? []).map((t) => ({ text: t })),
            ...(c.path1 ? { path1: c.path1 } : {}),
            ...(c.path2 ? { path2: c.path2 } : {}),
          },
        },
      },
    }],
  };
}

// The weekly research --------------------------------------------------------------------------

export const RESEARCH_SYSTEM = `Jesteś strategiem reklam AudioKiddo i co tydzień przygotowujesz badanie dla Dawida i Neli. Piszesz po polsku, konkretnie, z liczbami.
AudioKiddo: polska aplikacja z audiozabawami bez ekranu dla dzieci 3–9 lat, tworzona przez parę: Nelę i Dawida (sami nagrywają). Dziecko słucha, odpowiada głosem i klaśnięciem, rusza się; rodzic odkłada telefon. Bez reklam w aplikacji, działa offline. Abonament 24,99 zł/mies. (7 dni za darmo) albo pakiety na audiokiddo.pl.
Reklamy kierujemy WYŁĄCZNIE do rodziców (nigdy do dzieci). Zasady treści:
- bez straszenia rodzica i bez zawstydzania („zły rodzic”, „uzależnione dziecko”);
- bez obietnic zdrowotnych i naukowych („poprawia IQ”, „leczy”), bez „najlepsza aplikacja” bez dowodu;
- bez nazw konkurencji w reklamach i bez kopiowania ich tekstów; uczymy się z ich kątów, piszemy swoje;
- konkret zamiast przymiotników: sytuacja (korek, poczekalnia, wieczór), czas (10 minut), efekt (dziecko odpowiada, rodzic pije kawę).
Długo emitowane reklamy konkurencji (30+ dni) zwykle się opłacają: wyciągnij z nich kąty, obietnice, oferty i formaty. Szukaj luk, których nikt nie zajął.
Odpowiadasz WYŁĄCZNIE jednym obiektem JSON, bez komentarzy i bez bloku kodu.`;

const RESEARCH_SHAPE = `{
"summary": "Markdown dla Dawida i Neli (maks. 25 linii): ## Konkurencja (kąty, oferty, formaty, co działa najdłużej), ## Luki dla nas, ## Słowa kluczowe (szanse: duży popyt, mała konkurencja), ## Nasze kreacje (zwycięzcy, przegrani, co testować), ## Okazje w kalendarzu",
"creatives": [
  {"platform": "google_ads", "angle": "kąt w 3–6 słowach", "moment": "nazwa okazji albo null", "headlines": ["do 30 znaków", "…(8–15 sztuk, różne kąty: korzyść, sytuacja, oferta, zaufanie)"], "descriptions": ["do 90 znaków", "…(3–4)"], "path1": "do 15 znaków", "path2": "do 15 znaków", "final_url": "https://audiokiddo.pl/…", "why": "na jakiej obserwacji to opierasz"},
  {"platform": "meta", "format": "meta_image|meta_video", "angle": "…", "moment": null, "primary_text": "2–5 krótkich zdań, pierwsze zdanie to haczyk", "headline": "do 40 znaków", "description": "krótko", "cta": "Dowiedz się więcej|Pobierz|Kup teraz", "final_url": "https://audiokiddo.pl/", "visual_brief": "co ma być na grafice / w kadrze, kolory marki, Szop’en", "hook_script": "dla wideo: pierwsze 3 sekundy i scenariusz do 20 s; dla grafiki pusty", "why": "…"}
],
"keywords": [{"keyword": "fraza", "use": "blog|ads|both", "why": "…"}],
"negatives": [{"term": "fraza do wykluczenia", "campaign_id": "id kampanii Google", "why": "…"}],
"tasks": [{"title": "co zrobić", "reason": "dlaczego", "priority": 1}]
}`;

export function researchPrompt(context: Record<string, unknown>, note: string | null, today: string): string {
  return `Dzisiaj: ${today}.
Dane (JSON): ${JSON.stringify(context)}

Zadanie: tygodniowe badanie reklam. Zaproponuj 2–4 kreacje Google (RSA) i 2–4 kreacje Meta, w tym co najmniej jedną na najbliższą okazję z kalendarza (jeśli jest) i jeden wariant zwycięskiej kreacji (jeśli jest). Nie powtarzaj kreacji odrzuconych (patrz rejected_creatives z uwagami). Słowa kluczowe: do 10 nowych fraz, których nie ma w keywords. Wykluczenia tylko z listy wasted_terms.${note ? `\nWskazówka Dawida: ${note}` : ""}

Format odpowiedzi: ${RESEARCH_SHAPE}`;
}

export type ResearchAnswer = {
  summary: string;
  creatives: Creative[];
  keywords: { keyword: string; use: string; why: string }[];
  negatives: { term: string; campaign_id: string; why: string }[];
  tasks: { title: string; reason: string; priority: 1 | 2 | 3 }[];
};

export function parseResearch(answer: string, campaignIds: string[], wasted: string[]): ResearchAnswer {
  const start = answer.indexOf("{");
  const end = answer.lastIndexOf("}");
  if (start < 0 || end <= start) throw new Error("no json");
  const raw = JSON.parse(answer.slice(start, end + 1)) as Record<string, unknown>;
  const list = (v: unknown) => (Array.isArray(v) ? v : []) as Record<string, unknown>[];
  const wastedSet = new Set(wasted.map((w) => w.toLowerCase()));
  return {
    summary: text(raw.summary, 12000),
    creatives: list(raw.creatives).map(cleanCreative).filter((c): c is Creative => c !== null).slice(0, 10),
    keywords: list(raw.keywords)
      .map((k) => ({ keyword: text(k.keyword, 120).trim().toLowerCase(), use: ["blog", "ads", "both"].includes(k.use as string) ? String(k.use) : "both", why: text(k.why, 500) }))
      .filter((k) => k.keyword.length >= 2)
      .slice(0, 15),
    // Only terms the numbers show as wasted, in campaigns that exist.
    negatives: list(raw.negatives)
      .map((x) => ({ term: text(x.term, 80).trim().toLowerCase(), campaign_id: text(x.campaign_id, 80), why: text(x.why, 500) }))
      .filter((x) => x.term && campaignIds.includes(x.campaign_id) && wastedSet.has(x.term))
      .slice(0, 15),
    tasks: list(raw.tasks)
      .map((t) => ({ title: text(t.title, 200).trim(), reason: text(t.reason, 2000), priority: ([1, 2, 3].includes(t.priority as number) ? t.priority : 2) as 1 | 2 | 3 }))
      .filter((t) => t.title)
      .slice(0, 6),
  };
}

/** The research settings (crm_settings.ads_research), with sensible defaults. */
export type ResearchSettings = {
  search_terms: string[];
  keyword_seeds: string[];
  competitor_sites: string[];
  /** Facebook page ids of competitors, scanned in full. */
  competitor_pages: string[];
  enabled: boolean;
};

export const DEFAULT_RESEARCH: ResearchSettings = {
  enabled: true,
  search_terms: ["bajki dla dzieci", "audiobooki dla dzieci", "słuchowiska dla dzieci", "zabawy dla dzieci", "aplikacja dla dzieci", "bez ekranu"],
  keyword_seeds: ["zabawy dla dzieci bez ekranu", "zabawy w aucie dla dzieci", "bajki do słuchania", "słuchowiska dla dzieci", "zabawy logopedyczne", "wyciszenie dziecka przed snem"],
  competitor_sites: [],
  competitor_pages: [],
};

export function cleanResearchSettings(raw: unknown): ResearchSettings {
  const r = (raw && typeof raw === "object" ? raw : {}) as Record<string, unknown>;
  const list = (v: unknown, fallback: string[], max: number) => {
    const s = strings(v, 200).slice(0, max);
    return Array.isArray(v) ? s : fallback;
  };
  return {
    enabled: typeof r.enabled === "boolean" ? r.enabled : true,
    search_terms: list(r.search_terms, DEFAULT_RESEARCH.search_terms, 12),
    keyword_seeds: list(r.keyword_seeds, DEFAULT_RESEARCH.keyword_seeds, 20),
    competitor_sites: list(r.competitor_sites, [], 10).filter((u) => /^https:\/\/[a-z0-9.-]+\.[a-z]{2,}/i.test(u)),
    competitor_pages: list(r.competitor_pages, [], 10).filter((id) => /^\d{5,20}$/.test(id)),
  };
}

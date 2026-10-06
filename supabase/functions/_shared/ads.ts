// The ads module of the CRM: what the platforms answer, turned into rows; the limits every
// change must pass; and what the ads agent is asked. Nothing here talks to the network.

export type AdPlatform = "meta" | "google_ads";
export type ActionKind = "set_budget" | "pause" | "enable" | "task" | "pause_ad" | "add_negative";

export type AdsSettings = {
  /** The daily run proposes changes (the sync runs anyway). */
  enabled: boolean;
  /** No campaign budget above this per day (account currency). */
  max_daily: number;
  /** At most this share up or down in one step (0.5 = ±50%). */
  max_change: number;
  /** What a purchase may cost, for the agent's judgement. */
  target_cpa: number | null;
};

export const DEFAULT_SETTINGS: AdsSettings = { enabled: true, max_daily: 150, max_change: 0.5, target_cpa: 40 };

export function cleanSettings(raw: unknown): AdsSettings {
  const r = (raw && typeof raw === "object" ? raw : {}) as Record<string, unknown>;
  const num = (v: unknown, min: number, max: number, fallback: number) =>
    typeof v === "number" && Number.isFinite(v) ? Math.min(max, Math.max(min, v)) : fallback;
  return {
    enabled: typeof r.enabled === "boolean" ? r.enabled : DEFAULT_SETTINGS.enabled,
    max_daily: num(r.max_daily, 5, 5000, DEFAULT_SETTINGS.max_daily),
    max_change: num(r.max_change, 0.05, 1, DEFAULT_SETTINGS.max_change),
    target_cpa: r.target_cpa === null ? null : num(r.target_cpa, 1, 10000, DEFAULT_SETTINGS.target_cpa!),
  };
}

export type Entity = {
  platform: AdPlatform;
  entity_id: string;
  kind: "campaign" | "adset";
  name: string;
  status: string;
  daily_budget: number | null;
  currency: string;
  parent_id: string | null;
  data: Record<string, unknown>;
};

export type Metric = {
  platform: AdPlatform | "ga4";
  entity_id: string;
  day: string;
  name: string;
  spend: number;
  impressions: number;
  clicks: number;
  conversions: number;
  revenue: number;
  data: Record<string, unknown>;
};

const n = (v: unknown) => {
  const x = typeof v === "number" ? v : Number(v ?? 0);
  return Number.isFinite(x) ? x : 0;
};
const money = (v: number) => Math.round(v * 100) / 100;
const text = (v: unknown, max = 300) => (typeof v === "string" ? v : v == null ? "" : String(v)).slice(0, max);

// Meta ---------------------------------------------------------------------------------------

/** Purchases first; the same purchase is reported under several names, so take one. */
const META_PURCHASE = ["omni_purchase", "purchase", "offsite_conversion.fb_pixel_purchase"];

function metaAction(list: unknown): number {
  if (!Array.isArray(list)) return 0;
  for (const type of META_PURCHASE) {
    const hit = list.find((a) => a?.action_type === type);
    if (hit) return n(hit.value);
  }
  return 0;
}

/** Insights at campaign level, one row per day (time_increment=1). */
export function parseMetaInsights(rows: unknown[]): Metric[] {
  return rows.flatMap((raw) => {
    const r = raw as Record<string, unknown>;
    if (!r?.campaign_id || !r.date_start) return [];
    return [{
      platform: "meta" as const,
      entity_id: text(r.campaign_id, 80),
      day: text(r.date_start, 10),
      name: text(r.campaign_name),
      spend: money(n(r.spend)),
      impressions: Math.round(n(r.impressions)),
      clicks: Math.round(n(r.inline_link_clicks ?? r.clicks)),
      conversions: metaAction(r.actions),
      revenue: money(metaAction(r.action_values)),
      data: {},
    }];
  });
}

const metaStatus = (s: unknown) => {
  const v = text(s, 40).toUpperCase();
  return v === "ACTIVE" ? "active" : v === "PAUSED" ? "paused" : v.toLowerCase() || "unknown";
};

/** Campaigns and ad sets; Meta budgets come in the currency's minor units (grosze). */
export function parseMetaEntities(campaigns: unknown[], adsets: unknown[], currency: string): Entity[] {
  const one = (raw: unknown, kind: "campaign" | "adset"): Entity | null => {
    const r = raw as Record<string, unknown>;
    if (!r?.id) return null;
    const budget = r.daily_budget == null || r.daily_budget === "" ? null : money(n(r.daily_budget) / 100);
    return {
      platform: "meta",
      entity_id: text(r.id, 80),
      kind,
      name: text(r.name),
      status: metaStatus(r.status),
      daily_budget: budget && budget > 0 ? budget : null,
      currency,
      parent_id: kind === "adset" ? text(r.campaign_id, 80) || null : null,
      data: { objective: r.objective ?? null, effective_status: r.effective_status ?? null },
    };
  };
  return [
    ...campaigns.map((c) => one(c, "campaign")),
    ...adsets.map((a) => one(a, "adset")),
  ].filter((e): e is Entity => e !== null && e.status !== "deleted" && e.status !== "archived");
}

// Google Ads ---------------------------------------------------------------------------------

/** The GAQL that feeds both the campaigns and their daily numbers. */
export const GOOGLE_ADS_QUERY = `SELECT campaign.id, campaign.name, campaign.status,
  campaign_budget.resource_name, campaign_budget.amount_micros, campaign_budget.explicitly_shared,
  customer.currency_code, segments.date, metrics.cost_micros, metrics.impressions, metrics.clicks,
  metrics.conversions, metrics.conversions_value
FROM campaign
WHERE segments.date DURING LAST_30_DAYS AND campaign.status != 'REMOVED'`;

/** searchStream answers with batches of results. */
export function parseGoogleAds(batches: unknown[]): { entities: Entity[]; metrics: Metric[] } {
  const entities = new Map<string, Entity>();
  const metrics: Metric[] = [];
  for (const batch of batches) {
    for (const raw of ((batch as { results?: unknown[] })?.results ?? [])) {
      const r = raw as Record<string, Record<string, unknown>>;
      const id = text(r.campaign?.id, 80);
      if (!id) continue;
      const status = text(r.campaign?.status, 40).toUpperCase();
      entities.set(id, {
        platform: "google_ads",
        entity_id: id,
        kind: "campaign",
        name: text(r.campaign?.name),
        status: status === "ENABLED" ? "active" : status === "PAUSED" ? "paused" : status.toLowerCase(),
        daily_budget: r.campaignBudget?.amountMicros == null ? null : money(n(r.campaignBudget.amountMicros) / 1e6),
        currency: text(r.customer?.currencyCode, 3) || "PLN",
        parent_id: null,
        data: {
          budget: r.campaignBudget?.resourceName ?? null,
          shared_budget: r.campaignBudget?.explicitlyShared === true,
        },
      });
      if (r.segments?.date) {
        metrics.push({
          platform: "google_ads",
          entity_id: id,
          day: text(r.segments.date, 10),
          name: text(r.campaign?.name),
          spend: money(n(r.metrics?.costMicros) / 1e6),
          impressions: Math.round(n(r.metrics?.impressions)),
          clicks: Math.round(n(r.metrics?.clicks)),
          conversions: money(n(r.metrics?.conversions)),
          revenue: money(n(r.metrics?.conversionsValue)),
          data: {},
        });
      }
    }
  }
  return { entities: [...entities.values()], metrics };
}

// Google Analytics 4 -------------------------------------------------------------------------

/** The GA4 Data API report: per day and source / medium. */
export const GA4_REPORT = {
  dateRanges: [{ startDate: "30daysAgo", endDate: "yesterday" }],
  dimensions: [{ name: "date" }, { name: "sessionSourceMedium" }],
  metrics: [
    { name: "sessions" },
    { name: "totalUsers" },
    { name: "keyEvents" },
    { name: "purchaseRevenue" },
    { name: "ecommercePurchases" },
  ],
  limit: 5000,
};

export function parseGa4(report: unknown): Metric[] {
  const rows = (report as { rows?: unknown[] })?.rows ?? [];
  return rows.flatMap((raw) => {
    const r = raw as { dimensionValues?: { value?: string }[]; metricValues?: { value?: string }[] };
    const [date, source] = (r.dimensionValues ?? []).map((d) => d.value ?? "");
    if (!date || date.length !== 8) return [];
    const [sessions, users, keyEvents, revenue, purchases] = (r.metricValues ?? []).map((m) => n(m.value));
    return [{
      platform: "ga4" as const,
      entity_id: text(source || "(direct) / (none)", 200),
      day: `${date.slice(0, 4)}-${date.slice(4, 6)}-${date.slice(6, 8)}`,
      name: text(source || "(direct) / (none)"),
      spend: 0,
      impressions: 0,
      clicks: Math.round(sessions ?? 0),
      conversions: money(purchases ?? 0),
      revenue: money(revenue ?? 0),
      data: { sessions: sessions ?? 0, users: users ?? 0, key_events: keyEvents ?? 0 },
    }];
  });
}

// The limits on every change ----------------------------------------------------------------

export type ProposedAction = {
  platform: AdPlatform | "ga4" | "site";
  entity_id: string | null;
  entity_name: string;
  action: ActionKind;
  params: { daily_budget?: number; term?: string; match?: "PHRASE" | "EXACT" };
  title: string;
  reason: string;
  expected: string;
  priority: 1 | 2 | 3;
};

/**
 * Whether [a] may be applied as it stands: a known campaign, a sensible budget within the
 * limits, a status change that changes something. Returns the reason in Polish when not.
 * Checked when the agent proposes and again right before applying; [manual] (a change made
 * by hand in Studio) skips the step limit but not the daily maximum.
 */
export function checkAction(
  a: ProposedAction,
  entities: Entity[],
  settings: AdsSettings,
  manual = false,
  ads: { platform: string; ad_id: string; status: string; group_id: string | null }[] = [],
): string | null {
  if (a.action === "task") return null;
  if (a.platform !== "meta" && a.platform !== "google_ads") return "Ta platforma pozwala tylko na zadania.";
  if (a.action === "pause_ad") {
    const ad = ads.find((x) => x.platform === a.platform && x.ad_id === a.entity_id);
    if (!ad) return "Nie ma takiej reklamy po ostatnim pobraniu danych.";
    if (ad.status !== "active") return "Ta reklama już nie jest aktywna.";
    // Never the last running ad of a group: the group would stop.
    const others = ads.filter((x) => x.platform === ad.platform && x.group_id === ad.group_id && x.ad_id !== ad.ad_id && x.status === "active");
    return others.length ? null : "To ostatnia aktywna reklama w grupie: najpierw dodaj nową.";
  }
  if (a.action === "add_negative") {
    if (a.platform !== "google_ads") return "Wykluczenia słów są tylko w Google Ads.";
    const term = a.params.term?.trim() ?? "";
    if (term.length < 2 || term.length > 80 || term.split(/\s+/).length > 10) return "Fraza do wykluczenia musi mieć 2–80 znaków.";
    if (!entities.some((x) => x.platform === "google_ads" && x.entity_id === a.entity_id && x.kind === "campaign")) {
      return "Nie ma takiej kampanii Google po ostatnim pobraniu danych.";
    }
    return null;
  }
  const e = entities.find((x) => x.platform === a.platform && x.entity_id === a.entity_id);
  if (!e) return "Nie ma takiej kampanii po ostatnim pobraniu danych.";
  switch (a.action) {
    case "pause":
      return e.status === "active" ? null : "Ta kampania już nie jest aktywna.";
    case "enable":
      return e.status === "paused" ? null : "Ta kampania nie jest wstrzymana.";
    case "set_budget": {
      const budget = a.params.daily_budget;
      if (e.daily_budget == null) return "Budżet tej kampanii ustawia się gdzie indziej (np. w zestawach reklam).";
      if (e.currency !== "PLN") return `Konto rozlicza się w ${e.currency}: zmień budżet ręcznie.`;
      if (e.data.shared_budget === true) return "Ten budżet jest wspólny dla kilku kampanii: zmień go ręcznie.";
      if (typeof budget !== "number" || !Number.isFinite(budget) || budget < 5) return "Budżet musi mieć co najmniej 5 zł dziennie.";
      if (budget > settings.max_daily) return `Limit to ${settings.max_daily} zł dziennie na kampanię (Ustawienia agenta).`;
      // A change Dawid makes by hand may jump further; the agent goes step by step.
      if (!manual && Math.abs(budget - e.daily_budget) / e.daily_budget > settings.max_change + 1e-9) {
        return `Jednorazowo najwyżej ±${Math.round(settings.max_change * 100)}% (teraz ${e.daily_budget} zł).`;
      }
      return budget === e.daily_budget ? "Budżet jest już taki." : null;
    }
  }
}

/** One proposal from the model, cleaned; null when it is not a usable action. */
export function cleanAction(raw: unknown, entities: Entity[]): ProposedAction | null {
  const r = (raw && typeof raw === "object" ? raw : {}) as Record<string, unknown>;
  const action = r.action as ActionKind;
  if (!["set_budget", "pause", "enable", "task", "pause_ad", "add_negative"].includes(action)) return null;
  const platform = (["meta", "google_ads", "ga4", "site"].includes(r.platform as string) ? r.platform : "site") as
    ProposedAction["platform"];
  const title = text(r.title, 200).trim();
  if (!title) return null;
  const entityId = r.entity_id == null ? null : text(r.entity_id, 80);
  const known = entities.find((e) => e.platform === platform && e.entity_id === entityId);
  const budget = Number(r.daily_budget ?? (r.params as Record<string, unknown> | undefined)?.daily_budget);
  const term = text(r.term ?? (r.params as Record<string, unknown> | undefined)?.term, 80).trim().toLowerCase();
  return {
    platform,
    entity_id: entityId,
    entity_name: known?.name ?? text(r.entity_name, 300),
    action,
    params: action === "set_budget" && Number.isFinite(budget)
      ? { daily_budget: money(budget) }
      : action === "add_negative"
      ? { term, match: r.match === "EXACT" ? "EXACT" : "PHRASE" }
      : {},
    title,
    reason: text(r.reason, 4000),
    expected: text(r.expected, 2000),
    priority: ([1, 2, 3].includes(r.priority as number) ? r.priority : 2) as 1 | 2 | 3,
  };
}

// What the agent sees and is asked ---------------------------------------------------------

type Totals = { spend: number; clicks: number; conversions: number; revenue: number; impressions: number };

function sum(rows: Metric[]): Totals {
  const t = { spend: 0, clicks: 0, conversions: 0, revenue: 0, impressions: 0 };
  for (const r of rows) {
    t.spend += r.spend;
    t.clicks += r.clicks;
    t.conversions += r.conversions;
    t.revenue += r.revenue;
    t.impressions += r.impressions;
  }
  return {
    spend: money(t.spend),
    clicks: t.clicks,
    conversions: money(t.conversions),
    revenue: money(t.revenue),
    impressions: t.impressions,
  };
}

const daysAgo = (today: string, days: number) =>
  new Date(Date.parse(`${today}T00:00:00Z`) - days * 864e5).toISOString().slice(0, 10);

/** Per campaign: the last 7 days, the 7 before, and 30 days, with CPA and ROAS. */
export function summarize(entities: Entity[], metrics: Metric[], today: string) {
  const week = daysAgo(today, 7), fortnight = daysAgo(today, 14);
  const card = (rows: Metric[]) => {
    const t = sum(rows);
    return {
      ...t,
      cpa: t.conversions > 0 ? money(t.spend / t.conversions) : null,
      roas: t.spend > 0 ? money(t.revenue / t.spend) : null,
      ctr: t.impressions > 0 ? Math.round((t.clicks / t.impressions) * 10000) / 100 : null,
    };
  };
  const campaigns = entities.map((e) => {
    // Numbers are per campaign; an ad set points to its campaign through campaign_id.
    const own = metrics.filter((m) => m.platform === e.platform && m.entity_id === e.entity_id);
    return {
      platform: e.platform,
      id: e.entity_id,
      kind: e.kind,
      name: e.name,
      status: e.status,
      daily_budget: e.daily_budget,
      campaign_id: e.parent_id,
      last_7: card(own.filter((m) => m.day >= week)),
      prev_7: card(own.filter((m) => m.day >= fortnight && m.day < week)),
      last_30: card(own),
    };
  });
  const ga4 = metrics.filter((m) => m.platform === "ga4" && m.day >= week);
  const sources = new Map<string, Metric[]>();
  for (const m of ga4) sources.set(m.entity_id, [...(sources.get(m.entity_id) ?? []), m]);
  return {
    campaigns,
    totals: {
      meta: card(metrics.filter((m) => m.platform === "meta" && m.day >= week)),
      google_ads: card(metrics.filter((m) => m.platform === "google_ads" && m.day >= week)),
    },
    site_sources_7d: [...sources.entries()]
      .map(([source, rows]) => ({
        source,
        sessions: rows.reduce((a, r) => a + n(r.data.sessions), 0),
        purchases: money(rows.reduce((a, r) => a + r.conversions, 0)),
        revenue: money(rows.reduce((a, r) => a + r.revenue, 0)),
      }))
      .sort((a, b) => b.sessions - a.sessions)
      .slice(0, 15),
  };
}

export const ADS_SYSTEM = `Jesteś specjalistą od kampanii płatnych w firmie AudioKiddo i pracujesz dla jej COO. Piszesz po polsku, konkretnie.
AudioKiddo: aplikacja z audiozabawami bez ekranu dla dzieci 3–9 lat; reklamy trafiają do RODZICÓW i prowadzą na audiokiddo.pl (sklep WooCommerce) albo do sklepów z aplikacją. Nigdy nie targetujemy dzieci.
Ceny: abonament 24,99 zł/mies. lub 239,88 zł/rok, pakiet 49,99 zł (Detektyw 69,99 zł). Mały budżet: liczy się każda złotówka.
Masz dane z Meta Ads, Google Ads i Google Analytics 4 oraz limity ustawione przez Dawida. Proponujesz zmiany, które Dawid zatwierdza; dopiero wtedy system je wprowadza.
Zasady:
- Zmieniaj budżet tylko kampaniom z budżetem (daily_budget nie jest null), maksymalnie o max_change w jednym kroku i nie powyżej max_daily.
- Nie oceniaj kampanii po 1–2 dniach ani przy mniej niż ok. 1000 wyświetleń; daj czas na naukę algorytmu (zwykle 7 dni).
- Wstrzymuj, gdy kampania wydała co najmniej 2× docelowy koszt zakupu bez zakupu albo jej CPA długo jest dużo powyżej celu.
- Zwiększaj budżet, gdy CPA jest poniżej celu i ROAS stabilny przez tydzień.
- Pojedyncze reklamy: "pause_ad" (entity_id = id reklamy) tylko dla reklam z werdyktem "przegrywa" w creatives; nigdy ostatniej aktywnej w grupie.
- Wykluczenia: "add_negative" (entity_id = id kampanii Google, term = fraza) tylko dla fraz z wasted_terms.
- Nowe kreacje, grupy odbiorców, Pixel i śledzenie: proponuj jako zadanie ("task"); kreacje pisze też cotygodniowe badanie.
- Zbliżające się okazje (moments): z wyprzedzeniem 2–3 tygodni zaproponuj przygotowanie kampanii (zadanie).
- Jeśli danych jest za mało, powiedz to i zaproponuj najwyżej zadania. Lepiej nic nie zmieniać niż zmieniać na ślepo.
Odpowiadasz WYŁĄCZNIE jednym obiektem JSON, bez komentarzy i bez bloku kodu.`;

const ADS_SHAPE = `{"summary": "Markdown dla Dawida: co działa, co nie, co proponujesz i dlaczego (maks. 12 linii)", "actions": [{"platform": "meta|google_ads|ga4|site", "entity_id": "id kampanii albo null", "action": "set_budget|pause|enable|task|pause_ad|add_negative", "daily_budget": 60, "term": "tylko przy add_negative", "title": "krótko, co zrobić", "reason": "dlaczego, z liczbami", "expected": "czego się spodziewamy i po czym poznamy", "priority": 1}]}`;

export function adsPrompt(context: Record<string, unknown>, note: string | null, today: string): string {
  return `Dzisiaj: ${today}.
Stan kampanii i sprzedaży (JSON): ${JSON.stringify(context)}

Zadanie: przejrzyj kampanie i ruch na stronie. Zaproponuj 0–6 działań (najważniejsze najpierw). "daily_budget" podawaj tylko przy "set_budget" (w zł dziennie). Nie powtarzaj propozycji, które czekają albo które Dawid niedawno odrzucił.${note ? `\nWskazówka Dawida: ${note}` : ""}

Format odpowiedzi: ${ADS_SHAPE}`;
}

/** The model's answer: a summary and the usable actions. */
export function parseAdsAnswer(answer: string, entities: Entity[]): { summary: string; actions: ProposedAction[] } {
  const start = answer.indexOf("{");
  const end = answer.lastIndexOf("}");
  if (start < 0 || end <= start) throw new Error("no json");
  const raw = JSON.parse(answer.slice(start, end + 1)) as Record<string, unknown>;
  const list = Array.isArray(raw.actions) ? raw.actions : [];
  return {
    summary: text(raw.summary, 8000),
    actions: list.map((a) => cleanAction(a, entities)).filter((a): a is ProposedAction => a !== null).slice(0, 8),
  };
}

/** One line describing an action, for the CRM task and the history. */
export function describe(a: Pick<ProposedAction, "action" | "entity_name" | "params">, current?: number | null): string {
  switch (a.action) {
    case "set_budget":
      return `Budżet „${a.entity_name}”: ${current ?? "?"} → ${a.params.daily_budget} zł dziennie`;
    case "pause":
      return `Wstrzymać „${a.entity_name}”`;
    case "enable":
      return `Wznowić „${a.entity_name}”`;
    case "pause_ad":
      return `Wstrzymać reklamę „${a.entity_name}”`;
    case "add_negative":
      return `Wykluczyć frazę „${a.params.term}” w „${a.entity_name}”`;
    case "task":
      return "Zadanie";
  }
}

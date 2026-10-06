import { assertEquals, assertThrows } from "jsr:@std/assert@1";
import {
  checkAction,
  cleanSettings,
  DEFAULT_SETTINGS,
  type Entity,
  parseAdsAnswer,
  parseGa4,
  parseGoogleAds,
  parseMetaEntities,
  parseMetaInsights,
  type ProposedAction,
  summarize,
} from "./ads.ts";

const campaign = (over: Partial<Entity> = {}): Entity => ({
  platform: "meta",
  entity_id: "c1",
  kind: "campaign",
  name: "Rodzice 3–6",
  status: "active",
  daily_budget: 40,
  currency: "PLN",
  parent_id: null,
  data: {},
  ...over,
});

const action = (over: Partial<ProposedAction> = {}): ProposedAction => ({
  platform: "meta",
  entity_id: "c1",
  entity_name: "Rodzice 3–6",
  action: "set_budget",
  params: { daily_budget: 60 },
  title: "Więcej na Rodziców",
  reason: "",
  expected: "",
  priority: 2,
  ...over,
});

Deno.test("Meta insights: one purchase counted once, budgets from grosze", () => {
  const [row] = parseMetaInsights([{
    campaign_id: "c1",
    campaign_name: "Rodzice",
    date_start: "2026-10-05",
    spend: "41.20",
    impressions: "3000",
    inline_link_clicks: "57",
    actions: [{ action_type: "offsite_conversion.fb_pixel_purchase", value: "2" }, { action_type: "purchase", value: "2" }],
    action_values: [{ action_type: "purchase", value: "99.98" }],
  }, { campaign_id: "x" }]);
  assertEquals([row.spend, row.clicks, row.conversions, row.revenue, row.day], [41.2, 57, 2, 99.98, "2026-10-05"]);

  const entities = parseMetaEntities(
    [{ id: "c1", name: "CBO", status: "ACTIVE", daily_budget: "4000" }, { id: "c2", name: "Stara", status: "ARCHIVED" }],
    [{ id: "s1", name: "Zestaw", status: "PAUSED", daily_budget: "", campaign_id: "c1" }],
    "PLN",
  );
  assertEquals(entities.map((e) => [e.entity_id, e.status, e.daily_budget, e.parent_id]), [
    ["c1", "active", 40, null],
    ["s1", "paused", null, "c1"],
  ]);
});

Deno.test("Google Ads rows give campaigns with budgets and daily numbers", () => {
  const { entities, metrics } = parseGoogleAds([{
    results: [{
      campaign: { id: "9", name: "Szukaj: audiobooki", status: "ENABLED" },
      campaignBudget: { resourceName: "customers/1/campaignBudgets/5", amountMicros: "25000000", explicitlyShared: false },
      customer: { currencyCode: "PLN" },
      segments: { date: "2026-10-05" },
      metrics: { costMicros: "12340000", impressions: "800", clicks: "40", conversions: 1.5, conversionsValue: 74.98 },
    }],
  }]);
  assertEquals(entities[0].daily_budget, 25);
  assertEquals(entities[0].data.budget, "customers/1/campaignBudgets/5");
  assertEquals([metrics[0].spend, metrics[0].conversions, metrics[0].revenue], [12.34, 1.5, 74.98]);
});

Deno.test("GA4 rows become sources per day", () => {
  const [row] = parseGa4({
    rows: [{
      dimensionValues: [{ value: "20261005" }, { value: "facebook / paid" }],
      metricValues: [{ value: "120" }, { value: "100" }, { value: "6" }, { value: "149.97" }, { value: "3" }],
    }],
  });
  assertEquals([row.day, row.entity_id, row.clicks, row.conversions, row.revenue, row.data.sessions], [
    "2026-10-05",
    "facebook / paid",
    120,
    3,
    149.97,
    120,
  ]);
});

Deno.test("every change passes the limits", () => {
  const all = [campaign(), campaign({ entity_id: "c2", status: "paused" }), campaign({ entity_id: "c3", daily_budget: null })];
  const s = DEFAULT_SETTINGS;
  assertEquals(checkAction(action(), all, s), null);
  assertEquals(checkAction(action({ params: { daily_budget: 61 } }), all, s)?.startsWith("Jednorazowo"), true);
  assertEquals(checkAction(action({ params: { daily_budget: 61 } }), all, s, true), null, "by hand it may jump");
  assertEquals(checkAction(action({ params: { daily_budget: 400 } }), all, s, true)?.startsWith("Limit"), true);
  assertEquals(checkAction(action({ params: { daily_budget: 3 } }), all, s, true)?.includes("5 zł"), true);
  assertEquals(checkAction(action({ entity_id: "c3" }), all, s)?.startsWith("Budżet tej kampanii"), true);
  assertEquals(checkAction(action({ entity_id: "nope" }), all, s)?.startsWith("Nie ma"), true);
  assertEquals(checkAction(action({ action: "pause", params: {} }), all, s), null);
  assertEquals(checkAction(action({ action: "pause", entity_id: "c2", params: {} }), all, s) !== null, true);
  assertEquals(checkAction(action({ action: "enable", entity_id: "c2", params: {} }), all, s), null);
  assertEquals(checkAction(action({ platform: "ga4", action: "pause" }), all, s) !== null, true);
  assertEquals(checkAction(action({ platform: "site", action: "task", entity_id: null }), all, s), null);
  const eur = [campaign({ currency: "EUR" })];
  assertEquals(checkAction(action(), eur, s)?.includes("EUR"), true);
  const shared = [campaign({ platform: "google_ads", data: { shared_budget: true } })];
  assertEquals(checkAction(action({ platform: "google_ads" }), shared, s)?.includes("wspólny"), true);
});

Deno.test("settings are clamped and default sensibly", () => {
  assertEquals(cleanSettings(null), DEFAULT_SETTINGS);
  const s = cleanSettings({ enabled: false, max_daily: 999999, max_change: 3, target_cpa: null });
  assertEquals([s.enabled, s.max_daily, s.max_change, s.target_cpa], [false, 5000, 1, null]);
});

Deno.test("the agent's answer: wrapped JSON, unknown actions dropped, names from the sync", () => {
  const parsed = parseAdsAnswer(
    'Proszę:\n```json\n{"summary": "Meta działa.", "actions": [' +
      '{"platform": "meta", "entity_id": "c1", "action": "set_budget", "daily_budget": "55.555", "title": "Więcej", "priority": 1},' +
      '{"platform": "meta", "entity_id": "c1", "action": "delete", "title": "x"},' +
      '{"platform": "site", "action": "task", "title": "Nowa rolka z trybem dziecka", "reason": "CTR spada"}' +
      "]}\n```",
    [campaign()],
  );
  assertEquals(parsed.summary, "Meta działa.");
  assertEquals(parsed.actions.length, 2);
  assertEquals(parsed.actions[0].params, { daily_budget: 55.56 });
  assertEquals(parsed.actions[0].entity_name, "Rodzice 3–6");
  assertEquals(parsed.actions[1].params, {});
  assertThrows(() => parseAdsAnswer("brak", []));
});

Deno.test("the summary compares this week with the last", () => {
  const day = (d: string, spend: number, conversions: number) => ({
    platform: "meta" as const,
    entity_id: "c1",
    day: d,
    name: "",
    spend,
    impressions: 1000,
    clicks: 10,
    conversions,
    revenue: conversions * 49.99,
    data: {},
  });
  const s = summarize([campaign()], [day("2026-10-05", 40, 2), day("2026-09-27", 30, 0)], "2026-10-06");
  const c = s.campaigns[0];
  assertEquals([c.last_7.spend, c.last_7.cpa, c.prev_7.spend, c.prev_7.cpa, c.last_30.spend], [40, 20, 30, null, 70]);
  assertEquals(s.totals.meta.roas, 2.5);
});

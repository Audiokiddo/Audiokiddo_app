import { assert, assertAlmostEquals, assertEquals } from "jsr:@std/assert@1";
import {
  type Ad,
  type AdMetric,
  chanceBetter,
  cleanCreative,
  cleanResearchSettings,
  competitorDigest,
  creativeVerdicts,
  daysRunning,
  easter,
  keywordIdeasBody,
  parseAdLibrary,
  parseGoogleAdsAds,
  parseKeywordIdeas,
  parseResearch,
  parseSearchTerms,
  relevantIdea,
  rsaOperation,
  upcomingMoments,
  wastedTerms,
} from "./ads_growth.ts";

Deno.test("chanceBetter: equal rates are a coin toss, clear differences are near certain", () => {
  assertAlmostEquals(chanceBetter(50, 1000, 50, 1000), 0.5, 0.01);
  assert(chanceBetter(80, 2000, 30, 2000) > 0.99);
  assert(chanceBetter(3, 100, 2, 100) < 0.8);
});

const ad = (id: string, group = "g1", status = "active"): Ad => ({
  platform: "meta",
  ad_id: id,
  campaign_id: "c1",
  group_id: group,
  name: id,
  status,
  kind: "image",
  content: {},
  preview_url: null,
});
const day = (id: string, impressions: number, clicks: number, spend = 50, conversions = 0): AdMetric => ({
  platform: "meta",
  ad_id: id,
  day: "2026-10-01",
  spend,
  impressions,
  clicks,
  conversions,
  revenue: 0,
});

Deno.test("creativeVerdicts: winner, loser, too little data, alone", () => {
  const ads = [ad("a"), ad("b"), ad("c"), ad("solo", "g2")];
  const metrics = [day("a", 5000, 150), day("b", 5000, 40, 90), day("c", 400, 10), day("solo", 3000, 30)];
  const v = Object.fromEntries(creativeVerdicts(ads, metrics, "2026-10-06").map((x) => [x.ad_id, x]));
  assertEquals(v.a.verdict, "zwyciezca");
  assertEquals(v.b.verdict, "przegrywa");
  assertEquals(v.c.verdict, "za_malo_danych");
  assertEquals(v.solo.verdict, "jedyna");
  assertEquals(v.a.ctr, 3);
});

Deno.test("creativeVerdicts: older days are left out", () => {
  const old = { ...day("a", 5000, 100), day: "2026-08-01" };
  assertEquals(creativeVerdicts([ad("a")], [old], "2026-10-06")[0].impressions, 0);
});

Deno.test("search terms add up per campaign; wasted ones are found", () => {
  const batch = {
    results: [
      { searchTermView: { searchTerm: "Bajki na YouTube", status: "NONE" }, campaign: { id: "1", name: "Szukaj" }, adGroup: { id: "9" }, metrics: { impressions: "100", clicks: "10", costMicros: "15000000", conversions: 0 } },
      { searchTermView: { searchTerm: "bajki na youtube", status: "NONE" }, campaign: { id: "1", name: "Szukaj" }, adGroup: { id: "8" }, metrics: { impressions: "50", clicks: "5", costMicros: "8000000", conversions: 0 } },
      { searchTermView: { searchTerm: "zabawy w aucie dla dzieci", status: "ADDED" }, campaign: { id: "1" }, adGroup: { id: "9" }, metrics: { impressions: "80", clicks: "8", costMicros: "30000000", conversions: 2 } },
    ],
  };
  const terms = parseSearchTerms([batch]);
  assertEquals(terms.length, 2);
  const yt = terms.find((t) => t.term === "bajki na youtube")!;
  assertEquals([yt.clicks, yt.cost], [15, 23]);
  assertEquals(wastedTerms(terms, 40).map((t) => t.term), ["bajki na youtube"]);
});

Deno.test("Google ads: texts and daily numbers", () => {
  const { ads, metrics } = parseGoogleAdsAds([{
    results: [{
      adGroupAd: { status: "ENABLED", ad: { id: "77", type: "RESPONSIVE_SEARCH_AD", responsiveSearchAd: { headlines: [{ text: "Zabawy bez ekranu" }], descriptions: [{ text: "Opis" }] } } },
      adGroup: { id: "9" },
      campaign: { id: "1" },
      segments: { date: "2026-10-01" },
      metrics: { impressions: "10", clicks: "1", costMicros: "2500000", conversions: 0 },
    }],
  }]);
  assertEquals(ads[0].name, "Zabawy bez ekranu");
  assertEquals(ads[0].status, "active");
  assertEquals(metrics[0].spend, 2.5);
});

Deno.test("keyword ideas: request for Poland in Polish, parsed metrics, relevance", () => {
  const body = keywordIdeasBody({ url: "https://example.pl", keywords: ["bajki"] });
  assertEquals(body.language, "languageConstants/1030");
  assertEquals((body.keywordAndUrlSeed as { url: string }).url, "https://example.pl");
  assertEquals(Object.keys(keywordIdeasBody({ keywords: ["a"] })).includes("keywordSeed"), true);
  const ideas = parseKeywordIdeas({
    results: [{
      text: "Zabawy w aucie dla dzieci",
      keywordIdeaMetrics: {
        avgMonthlySearches: "880",
        competition: "LOW",
        lowTopOfPageBidMicros: "450000",
        highTopOfPageBidMicros: "1900000",
        monthlySearchVolumes: [{ year: "2026", month: "JULY", monthlySearches: "2400" }],
      },
    }],
  });
  assertEquals(ideas[0], {
    keyword: "zabawy w aucie dla dzieci",
    monthly_searches: 880,
    competition: "LOW",
    cpc_low: 0.45,
    cpc_high: 1.9,
    trend: [{ month: "2026-07", searches: 2400 }],
  });
  assert(relevantIdea("zabawy w aucie dla dzieci"));
  assert(relevantIdea("bajki do słuchania dla dzieci"));
  assert(!relevantIdea("opony zimowe do auta"));
  assert(!relevantIdea("bajki dla dzieci youtube"));
});

Deno.test("Ad Library: parsed, running days, digest per advertiser", () => {
  const ads = parseAdLibrary([
    { id: "1", page_id: "p", page_name: "Bajkowo", ad_creative_bodies: ["Tekst A", "Tekst A"], ad_delivery_start_time: "2026-08-01", eu_total_reach: "12000" },
    { id: "2", page_id: "p", page_name: "Bajkowo", ad_creative_bodies: ["Tekst B"], ad_delivery_start_time: "2026-09-30", ad_delivery_stop_time: "2026-10-02" },
    { id: "3", page_name: "bez strony" },
  ]);
  assertEquals(ads.length, 2);
  assertEquals(ads[0].bodies, ["Tekst A"]);
  assertEquals(daysRunning(ads[0], "2026-10-06"), 66);
  assertEquals(daysRunning(ads[1], "2026-10-06"), 2);
  const digest = competitorDigest(ads, "2026-10-06");
  assertEquals(digest[0].active_ads, 1);
  assertEquals(digest[0].longest[0].days, 66);
});

Deno.test("the Polish year: Easter and what is coming", () => {
  assertEquals(easter(2026), "2026-04-05");
  assertEquals(easter(2027), "2027-03-28");
  const names = upcomingMoments("2026-10-06", 60).map((m) => m.name);
  assertEquals(names, ["Wszystkich Świętych: wyjazdy", "Mikołajki", "Święta"]);
  const summer = upcomingMoments("2026-06-01", 30).map((m) => m.name);
  assert(summer.includes("Wakacje"));
  assert(summer.includes("Dzień Dziecka"));
});

Deno.test("creatives: Google limits enforced, Meta kept with warnings, RSA body", () => {
  const g = cleanCreative({
    platform: "google_ads",
    angle: "auto",
    headlines: ["Zabawy do auta bez ekranu", "To jest nagłówek o wiele za długi na Google Ads", "7 dni za darmo", "7 dni za darmo"],
    descriptions: ["Dziecko słucha i odpowiada, a Ty prowadzisz spokojnie. Działa offline."],
    path1: "zabawy w aucie!",
    final_url: "https://evil.example/",
  })!;
  assertEquals(g.content.headlines, ["Zabawy do auta bez ekranu", "7 dni za darmo"]);
  assertEquals(g.content.final_url, "https://audiokiddo.pl/");
  assertEquals(g.content.path1, "zabawywaucie");
  assertEquals(g.problems.length, 3);
  const m = cleanCreative({ platform: "meta", primary_text: "Korek. Znowu.", headline: "Zabawy do auta bez ekranu" })!;
  assertEquals([m.format, m.problems.length, m.content.cta], ["meta_image", 0, "Dowiedz się więcej"]);
  assertEquals(cleanCreative({ platform: "tiktok" }), null);
  const op = rsaOperation("123", "9", g.content);
  assertEquals(op.operations[0].create.status, "PAUSED");
  assertEquals(op.operations[0].create.adGroup, "customers/123/adGroups/9");
});

Deno.test("research answer: negatives only from the wasted list and known campaigns", () => {
  const answer = JSON.stringify({
    summary: "## Konkurencja",
    creatives: [{ platform: "meta", primary_text: "x", headline: "y" }],
    keywords: [{ keyword: " Zabawy W Aucie ", use: "blog" }],
    negatives: [{ term: "bajki na youtube", campaign_id: "1" }, { term: "zabawy", campaign_id: "1" }, { term: "bajki na youtube", campaign_id: "2" }],
    tasks: [{ title: "Nagrać wideo", priority: 1 }],
  });
  const r = parseResearch(answer, ["1"], ["bajki na youtube"]);
  assertEquals(r.negatives.map((x) => x.term), ["bajki na youtube"]);
  assertEquals(r.keywords[0].keyword, "zabawy w aucie");
  assertEquals(r.creatives.length, 1);
  assertEquals(r.tasks[0].priority, 1);
});

Deno.test("research settings: defaults and only https competitor sites", () => {
  const s = cleanResearchSettings({ competitor_sites: ["https://bajki.pl", "javascript:alert(1)", "http://x.pl"] });
  assertEquals(s.competitor_sites, ["https://bajki.pl"]);
  assert(s.search_terms.length > 0);
});

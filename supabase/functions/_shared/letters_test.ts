import { assert, assertEquals } from "jsr:@std/assert@1";
import { digestMail, orderReminderMail } from "./digest.ts";
import { type CatalogItem, missedLetter, suggestions, talkPrompt, weeklyLetter } from "./letters.ts";

const catalog: CatalogItem[] = [
  { id: "sklep", title: "Magiczny sklep", pack_id: "wyobraznia", access: "free", skills: ["wyobraźnia"], duration_sec: 357, parent_description: "Magiczne przedmioty." },
  { id: "planeta", title: "Podróż na inną planetę", pack_id: "wyobraznia", access: "paid", skills: ["wyobraźnia"], duration_sec: 420 },
  { id: "synonimy", title: "Znajdź synonimy", pack_id: "slowa-i-wiedza", access: "paid", skills: ["słownictwo"], duration_sec: 300 },
  { id: "dzwiek", title: "Co to za dźwięk?", pack_id: "slowa-i-wiedza", access: "free", skills: ["słuchanie"], duration_sec: 480 },
  { id: "smietnik", title: "Gadający śmietnik", pack_id: "detektyw", access: "paid", skills: ["logiczne myślenie"] },
];
const base = { catalog, seed: 3, unsubscribeUrl: "https://example.supabase.co/functions/v1/mailer?u=abc" };

Deno.test("the weekly letter: a question per play, next plays the family can play, an idea, a tip", () => {
  const l = weeklyLetter({ ...base, week: ["sklep", "sklep"], ever: ["sklep"], scopes: ["pack:wyobraznia"] });
  assertEquals(l.subject, "Po „Magiczny sklep”: pytanie na kolację i plan na tydzień");
  assert(l.markdown.includes("**Magiczny sklep:** Wymyślcie razem inne zakończenie"));
  assert(l.markdown.includes("**Podróż na inną planetę** (7 min)"), "owned, untried, the same skill first");
  assert(!l.markdown.includes("Znajdź synonimy"), "not owned");
  assert(l.markdown.includes("## Bez ekranu") && l.markdown.includes("## Na marginesie"));
  assert(l.markdown.includes("[Nie chcę więcej listów](https://"));
});

Deno.test("a quiet week gets an encouraging letter, not empty numbers", () => {
  const l = weeklyLetter({ ...base, week: [], ever: [], scopes: [] });
  assert(l.markdown.includes("## Cisza w tym tygodniu"));
  assert(l.markdown.includes("Co to za dźwięk?") || l.markdown.includes("Magiczny sklep"), "a free play to start");
});

Deno.test("we miss you: one play to come back with", () => {
  const l = missedLetter({ ...base, week: [], ever: ["sklep", "dzwiek"], scopes: [] });
  assertEquals(l.subject, "Szop’en tęskni. Na powrót: „Magiczny sklep”");
  assertEquals(suggestions({ ...base, week: [], ever: [], scopes: ["all_content"] }, 5).length, 5);
  assertEquals(talkPrompt(catalog[4]), "Kto był winny i po czym to poznaliście? Niech dziecko wszystko wyjaśni. Ty udawaj, że nie wiesz.");
});

Deno.test("the morning digest leads with what is urgent", () => {
  const d = digestMail({
    date: "7.10.2026",
    alerts: [{ level: "critical", title: "Zakupy się nie kończą", detail: "Sprawdź." }],
    brief: "Dziś: premiera.",
    numbers: { paying_families: 12, mrr_gross: 250.5 },
    pending: 3,
    adsPending: 1,
    studioUrl: "https://audiokiddo.pl/studio/",
  });
  assertEquals(d.subject, "AudioKiddo 7.10.2026: 1 pilne, 4 do decyzji");
  assert(d.markdown.startsWith("## Do uwagi"));
  assert(d.markdown.includes("MRR brutto: **251 zł**"));
  assert(orderReminderMail(1234, ["pakiet Detektyw"]).markdown.includes("numer zamówienia **1234**"));
});

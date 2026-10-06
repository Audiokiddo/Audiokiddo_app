// Letters from Szop’en to parents who asked for them (Więcej → Listy od Szop’ena):
//   weekly  (Sunday)  what you played, a question to talk about each play, two plays for the
//                     coming week that fit what the child liked, one idea without a screen and
//                     one short tip for the parent;
//   missed  (after 14 days without a play) one play to come back with, no guilt.
// Nothing about the child is on the server (names and plans stay on the phone), so the letter
// speaks of "the child" and of the plays. Plain Markdown, turned into HTML by mail_html.ts.

export type CatalogItem = {
  id: string;
  title: string;
  pack_id?: string | null;
  kind?: string;
  access?: string;
  skills?: string[];
  parent_description?: string;
  duration_sec?: number;
};

export type LetterInput = {
  catalog: CatalogItem[];
  /** Plays started this week, newest first (ids, may repeat). */
  week: string[];
  /** Everything ever started on this account. */
  ever: string[];
  /** Access scopes: all_content, pack:<id>, item:<id>. */
  scopes: string[];
  /** Day of the year, so the rotating parts change every week. */
  seed: number;
  unsubscribeUrl: string;
};

export type Letter = { subject: string; preheader: string; markdown: string };

const GREETINGS = [
  "Szop’en melduje: tydzień zaliczony. Kawa wypita w połowie, jak zwykle.",
  "Dzień dobry z dyżuru. Przejrzałem Wasz tydzień i mam kilka podpowiedzi na kolejny.",
  "Niedziela. Ja odpoczywam w trybie czuwania, Wy dostajecie ściągawkę na nowy tydzień.",
  "Raport tygodniowy. Bez tabelek, obiecuję. Same rzeczy, które się przydadzą.",
  "Szop’en tu. Policzyłem zabawy, ale nie będę się chwalił liczbami. Mam za to pomysły.",
];

/** Things to do together with no screen and no preparation; rotated weekly. */
const NO_SCREEN = [
  "**Dźwiękowy spacer:** na spacerze każdy zbiera trzy dźwięki. W domu odgrywacie je, a reszta zgaduje.",
  "**Sklep z niczego:** łyżka, kapeć i pilot dostają nowe, magiczne zastosowanie. Kto sprzeda drożej?",
  "**Opowieść po zdaniu:** każdy dodaje jedno zdanie do historii. Zasada: musi pojawić się słowo „kalafior”.",
  "**Detektyw w kuchni:** schowaj jedną rzecz i daj trzy wskazówki. Potem zamiana ról.",
  "**Lustro:** jedno robi miny i ruchy, drugie je powtarza. Po minucie zamiana.",
  "**Zgadnij, co mam w ręce:** dziecko z zamkniętymi oczami zgaduje przedmiot dotykiem i opisuje go słowami.",
  "**Wywiad przy kolacji:** dziecko jest reporterem i zadaje trzy pytania każdemu przy stole.",
  "**Litera dnia:** do końca dnia szukacie rzeczy na wybraną literę. Wieczorem liczycie, kto znalazł więcej.",
  "**Pogoda w głosie:** mówcie zwykłe zdanie jak burza, jak słońce i jak mżawka. Śmiech gwarantowany.",
  "**Mapa skarbów:** narysujcie plan pokoju i zaznaczcie „skarb”. Drugie szuka według mapy.",
  "**Co by było, gdyby…:** gdyby koty umiały mówić? gdyby padał budyń? Każdy wymyśla jedną odpowiedź.",
  "**Cisza do dziesięciu:** zamknijcie oczy i liczcie dźwięki w pokoju. Kto usłyszał więcej?",
];

/** One short, practical thought for the parent; rotated weekly. */
const TIPS = [
  "Pytaj „co było najśmieszniejsze?” zamiast „jak było?”. Dzieci opowiadają wtedy dużo więcej.",
  "Nuda nie jest wrogiem. Dziecko, które się nudzi, zaczyna wymyślać. Daj jej 10 minut, zanim pomożesz.",
  "Chwal wysiłek („długo nad tym myślałeś”), nie wynik. To uczy, że warto próbować dalej.",
  "Powtarzanie tej samej zabawy to nie strata czasu: przy trzecim razie dziecko zaczyna ją współtworzyć.",
  "Krótko, ale codziennie działa lepiej niż długo raz w tygodniu. Nawet 5 minut się liczy.",
  "Gdy dziecko odpowiada źle, zapytaj „skąd to wiesz?”. Często tok myślenia jest ciekawszy niż odpowiedź.",
  "Przed snem lepiej słuchać niż patrzeć: ekran pobudza, głos uspokaja.",
  "Dzieci uczą się słów z rozmowy, nie z listy. Używaj trudniejszych słów i od razu je wyjaśniaj.",
];

/** A question that carries a play into family life (the same choice as the app's TalkCard). */
export function talkPrompt(item: CatalogItem): string {
  const skills = new Set(item.skills ?? []);
  if (item.kind === "song") return "Zaśpiewajcie refren razem w kąpieli albo w samochodzie. Kto głośniej?";
  if (item.kind === "interactive_game") return "Zadajcie sobie trzy pytania „prawda czy nie?” o Waszym dniu. Rodzic też odpowiada!";
  if (item.pack_id === "detektyw") return "Kto był winny i po czym to poznaliście? Niech dziecko wszystko wyjaśni. Ty udawaj, że nie wiesz.";
  if (skills.has("słownictwo")) return "Każdy mówi słowo na tę samą literę. Kto się zatnie, opowiada żart.";
  if (skills.has("logiczne myślenie")) return "Co tu nie pasuje: łyżka, widelec, kapeć? Wymyślajcie takie zagadki na zmianę.";
  if (skills.has("wyobraźnia") || skills.has("opowiadanie")) {
    return "Wymyślcie razem inne zakończenie tej historii. Im dziwniejsze, tym lepsze.";
  }
  return "Zamknijcie oczy na 10 sekund. Kto usłyszy więcej dźwięków w pokoju?";
}

export function canPlay(item: CatalogItem, scopes: string[]): boolean {
  return item.access === "free" || scopes.includes("all_content") ||
    (item.pack_id != null && scopes.includes(`pack:${item.pack_id}`)) || scopes.includes(`item:${item.id}`);
}

const minutes = (item: CatalogItem) => `${Math.max(1, Math.round((item.duration_sec ?? 300) / 60))} min`;

/** Plays the family has not tried yet and can play now, closest to what they liked first. */
export function suggestions(input: LetterInput, count: number): CatalogItem[] {
  const byId = new Map(input.catalog.map((i) => [i.id, i]));
  const liked = new Map<string, number>();
  for (const id of input.week) {
    for (const s of byId.get(id)?.skills ?? []) liked.set(s, (liked.get(s) ?? 0) + 1);
  }
  const tried = new Set(input.ever);
  return input.catalog
    .filter((i) => !tried.has(i.id) && canPlay(i, input.scopes) && i.kind !== "song")
    .map((i) => ({ i, score: (i.skills ?? []).reduce((a, s) => a + (liked.get(s) ?? 0), 0) }))
    .sort((a, b) => b.score - a.score || a.i.title.localeCompare(b.i.title, "pl"))
    .slice(0, count)
    .map((x) => x.i);
}

function footer(url: string): string {
  return `Ten list dostajesz, bo włączyłeś „Listy od Szop’ena” w aplikacji AudioKiddo. [Nie chcę więcej listów](${url})`;
}

export function weeklyLetter(input: LetterInput): Letter {
  const byId = new Map(input.catalog.map((i) => [i.id, i]));
  const played = [...new Set(input.week)].map((id) => byId.get(id)).filter((i): i is CatalogItem => !!i);
  const next = suggestions(input, 2);
  const greeting = GREETINGS[input.seed % GREETINGS.length];
  const idea = NO_SCREEN[input.seed % NO_SCREEN.length];
  const tip = TIPS[input.seed % TIPS.length];
  const lines: string[] = [greeting, ""];
  if (played.length) {
    lines.push("## Po zabawach z tego tygodnia", "");
    lines.push("Najwięcej zostaje w głowie, gdy o zabawie się porozmawia. Jedno pytanie do każdej:", "");
    for (const p of played.slice(0, 4)) lines.push(`- **${p.title}:** ${talkPrompt(p)}`);
  } else {
    lines.push("## Cisza w tym tygodniu", "");
    lines.push("Bywa. Czasem tydzień jest za krótki. Na start wystarczy jedna krótka zabawa, nawet w drodze do przedszkola.");
  }
  if (next.length) {
    lines.push("", "## Na nowy tydzień", "");
    for (const n of next) {
      lines.push(`- **${n.title}** (${minutes(n)})${n.parent_description ? `: ${n.parent_description}` : ""}`);
    }
    lines.push("", "Znajdziesz je w aplikacji w Bibliotece.");
  }
  lines.push("", "## Bez ekranu", "", idea);
  lines.push("", "## Na marginesie", "", tip);
  lines.push("", "Do zobaczenia w aplikacji,", "**Szop’en**", "", footer(input.unsubscribeUrl));
  const first = next[0]?.title;
  return {
    subject: played.length
      ? `Po „${played[0].title}”: pytanie na kolację i plan na tydzień`
      : "Szop’en ma 5-minutowy plan na ten tydzień",
    preheader: first ? `Na nowy tydzień: ${first}. Plus zabawa bez ekranu.` : "Zabawa bez ekranu i jedno pytanie przy kolacji.",
    markdown: lines.join("\n"),
  };
}

export function missedLetter(input: LetterInput): Letter {
  const byId = new Map(input.catalog.map((i) => [i.id, i]));
  const next = suggestions(input, 1)[0] ??
    [...new Set(input.ever)].map((id) => byId.get(id)).find((i) => i && canPlay(i, input.scopes));
  const lines = [
    "Szop’en tu. Od dwóch tygodni cisza w słuchawkach, więc sprawdzam, czy wszystko w porządku. Nie, nie obrażam się. Prawie.",
    "",
  ];
  if (next) {
    lines.push("## Na powrót", "", `**${next.title}** (${minutes(next)}). ${next.parent_description ?? ""}`.trim());
    lines.push("", "Włącz, połóż telefon i zrób sobie herbatę. Ja przypilnuję reszty.");
  }
  lines.push("", "## Albo zupełnie bez telefonu", "", NO_SCREEN[input.seed % NO_SCREEN.length]);
  lines.push("", "Czekam,", "**Szop’en**", "", footer(input.unsubscribeUrl));
  return {
    subject: next ? `Szop’en tęskni. Na powrót: „${next.title}”` : "Szop’en tęskni (trochę)",
    preheader: "Jedna krótka zabawa na powrót i pomysł bez ekranu.",
    markdown: lines.join("\n"),
  };
}

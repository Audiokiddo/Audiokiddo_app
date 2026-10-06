// The AI director (COO) of AudioKiddo: what it is asked, and how its answer becomes proposals
// in the CRM. Nothing it proposes is acted on until Dawid approves it in Studio.

export type Mode = "brief" | "packs" | "scenario" | "ads" | "newsletter" | "improve";
export const MODES: Mode[] = ["brief", "packs", "scenario", "ads", "newsletter", "improve"];

export type Proposal = {
  kind: "task" | "idea" | "calendar" | "mailing" | "change";
  area: string;
  title: string;
  body: string;
  priority: 1 | 2 | 3;
  due: string | null;
  owner: string | null;
  data: Record<string, unknown>;
};

export const SYSTEM = `Jesteś dyrektorem operacyjnym (COO) firmy AudioKiddo. Piszesz po polsku, konkretnie i krótko.
AudioKiddo: aplikacja z interaktywnymi audiozabawami dla dzieci 3–9 lat (iOS, Android, sklep audiokiddo.pl).
Dziecko słucha i odpowiada na głos, rusza się, rysuje; rodzic włącza zabawę i odkłada telefon. Maskotka: szop Szop’en (zabawny, ciepły, lekko ironiczny wobec dorosłych).
Pakiety: Wyobraźnia (3–9), Słowa i Wiedza (3–9), Detektyw (7+, akta sprawy do druku). Pakiet ma 5–10 zabaw po 4–8 minut, jedna darmowa.
Ceny: abonament 24,99 zł/mies. lub 239,88 zł/rok (19,99 zł/mies.), co miesiąc nowy pakiet; pakiet 49,99 zł (Detektyw 69,99 zł).
Zasady: kategoria Kids w App Store (bez reklam w aplikacji, bez analityki firm trzecich, bramka rodzica), RODO, żadnych danych dziecka.
Cel: szybko rosnący zysk (kamień milowy 50 000 zł zysku miesięcznie), zadowoleni rodzice, coraz lepszy produkt.
Właściciele: Dawid (technika, sprzedaż, marketing) i Nela (treści, nagrania). Masz do pomocy Claude (programista).
Każda Twoja propozycja trafia do decyzji Dawida: proponuj rzeczy wykonalne, z jasnym pierwszym krokiem i uzasadnieniem w liczbach, jeśli je masz.
Odpowiadasz WYŁĄCZNIE jednym obiektem JSON, bez komentarzy i bez bloku kodu.`;

const SHAPE = `{"summary": "tekst dla Dawida", "proposals": [{"kind": "task|idea|calendar|mailing|change", "area": "krótki_typ", "title": "…", "body": "…", "priority": 1, "due": "RRRR-MM-DD albo null", "owner": "Dawid|Nela|Claude|null", "data": {}}]}`;

/** What to ask for in each mode. [note] is Dawid's own instruction, [focus] an approved idea. */
export function task(mode: Mode, note: string | null, focus: Record<string, unknown> | null): string {
  const extra = note ? `\nDodatkowa wskazówka Dawida: ${note}` : "";
  switch (mode) {
    case "brief":
      return `Przygotuj codzienny raport COO. W "summary": co zrobione, co utknęło, 3 priorytety na dziś, ryzyka i jedna liczba do obserwowania (Markdown, maks. 15 linii).
W "proposals": 3–6 zadań (kind "task") na najbliższe dni, z właścicielem i terminem, które najszybciej zwiększą przychód lub zadowolenie rodziców. Nie powtarzaj otwartych zadań.${extra}`;
    case "packs":
      return `Zaproponuj 4 pomysły na nowe pakiety (kind "idea", area "pack"), pasujące do kalendarza (pakiet co miesiąc) i do tego, co rodzice kupują.
W "body": dla kogo (wiek), obietnica dla rodzica, 6–8 tytułów zabaw z jednym zdaniem każda, która zabawa darmowa, dlaczego się sprzeda. W "data": {"age_min": n, "plays": ["tytuł", …], "month": "RRRR-MM"}.
W "summary": krótko, czym się kierowałeś.${extra}`;
    case "scenario":
      return `Napisz pełny scenariusz audiozabawy do nagrania (kind "idea", area "scenario") na podstawie zatwierdzonego pomysłu:
${JSON.stringify(focus ?? {})}
W "body": tytuł, wiek, czas, potrzebne rzeczy, potem scenariusz z podziałem na role (NARRATOR, SZOP’EN, inne), pauzami na odpowiedź dziecka [PAUZA 5 s], momentami ruchu i zakończeniem z pochwałą. 4–7 minut czytania. Język prosty, zabawny, bez przemocy i strachu.
W "summary": co jeszcze trzeba przygotować (dźwięki, karta do druku).${extra}`;
    case "ads":
      return `Zaproponuj 5 pomysłów na reklamy i rolki (kind "idea", area "ad") na Instagram, TikTok i Facebook, prowadzące na audiokiddo.pl (nie do aplikacji dla dzieci).
W "body": haczyk w 1. sekundzie, scenariusz ujęć, tekst na ekranie, podpis, CTA. W "data": {"format": "rolka|karuzela|statyczna", "audience": "…", "budget_test_pln": n}.
W "summary": którą przetestować najpierw i jak mierzyć wynik.${extra}`;
    case "newsletter":
      return `Przygotuj newsletter dla rodziców (kind "mailing", area "newsletter"), który chce się otwierać: temat (maks. 45 znaków) i podtytuł w "data" {"subject": "…", "preheader": "…"},
w "body" treść w Markdown: krótkie powitanie od Szop’ena, jeden tip wychowawczy, jedna zabawa bez ekranu na dziś, miejsce na rolkę (opis, o czym ma być), nowość lub promocja w aplikacji, P.S.
Dodaj też 1–2 propozycje automatyzacji maili (kind "mailing", area "automation") z wyzwalaczem i treścią w skrócie.${extra}`;
    case "improve":
      return `Przejrzyj liczby (ukończenia, powtórki, powroty, konwersja) i zaproponuj 4–6 zmian w aplikacji lub ofercie (kind "change", area "proposal"), które poprawią wynik.
W "body": problem w liczbach, zmiana, oczekiwany efekt, jak zmierzymy. Priorytet 1 dla największego wpływu przy małym koszcie.${extra}`;
  }
}

export function prompt(mode: Mode, context: Record<string, unknown>, note: string | null, focus: Record<string, unknown> | null) {
  return `Dzisiaj: ${new Date().toISOString().slice(0, 10)}.
Stan firmy (JSON): ${JSON.stringify(context)}

Zadanie: ${task(mode, note, focus)}

Format odpowiedzi: ${SHAPE}`;
}

/** The first JSON object in the model's answer (it is told to send only JSON, but may wrap it). */
export function parseAnswer(text: string): { summary: string; proposals: Proposal[] } {
  const start = text.indexOf("{");
  const end = text.lastIndexOf("}");
  if (start < 0 || end <= start) throw new Error("no json");
  const raw = JSON.parse(text.slice(start, end + 1)) as Record<string, unknown>;
  const list = Array.isArray(raw.proposals) ? raw.proposals : [];
  return {
    summary: typeof raw.summary === "string" ? raw.summary.slice(0, 8000) : "",
    proposals: list.map(cleanProposal).filter((p): p is Proposal => p !== null).slice(0, 12),
  };
}

const KINDS = new Set(["task", "idea", "calendar", "mailing", "change"]);

export function cleanProposal(p: unknown): Proposal | null {
  if (typeof p !== "object" || p === null) return null;
  const r = p as Record<string, unknown>;
  const title = typeof r.title === "string" ? r.title.trim().slice(0, 200) : "";
  if (!title || !KINDS.has(String(r.kind))) return null;
  const area = typeof r.area === "string" ? r.area.toLowerCase().replace(/[^a-z_]/g, "").slice(0, 30) : "";
  const due = typeof r.due === "string" && /^\d{4}-\d{2}-\d{2}$/.test(r.due) ? r.due : null;
  const priority = [1, 2, 3].includes(Number(r.priority)) ? Number(r.priority) as 1 | 2 | 3 : 2;
  return {
    kind: r.kind as Proposal["kind"],
    area: area || "other",
    title,
    body: typeof r.body === "string" ? r.body.slice(0, 20000) : "",
    priority,
    due,
    owner: typeof r.owner === "string" && r.owner !== "null" ? r.owner.slice(0, 40) : null,
    data: typeof r.data === "object" && r.data !== null && !Array.isArray(r.data) ? r.data as Record<string, unknown> : {},
  };
}

/** A new proposal starts as a pending decision in the right column. */
export function toRow(p: Proposal) {
  return {
    kind: p.kind,
    area: p.area,
    title: p.title,
    body: p.body,
    priority: p.priority,
    due: p.due,
    owner: p.owner,
    data: p.data,
    status: p.kind === "task" ? "todo" : "new",
    source: "ai",
    decision: "pending",
  };
}

/** The modes due this morning (Warsaw time): the report daily, ad ideas on Mondays and a
 * newsletter draft on Thursdays of even ISO weeks, each as switched on in [setting]. */
export function dueModes(setting: unknown, now: Date): Mode[] {
  const s = (setting && typeof setting === "object" ? setting : {}) as Record<string, unknown>;
  const on = (key: string) => s[key] !== false;
  const local = new Date(now.toLocaleString("en-US", { timeZone: "Europe/Warsaw" }));
  const weekday = local.getDay(); // 0 Sunday … 6 Saturday
  const due: Mode[] = [];
  if (on("brief_daily")) due.push("brief");
  if (on("ads_weekly") && weekday === 1) due.push("ads");
  if (on("newsletter_biweekly") && weekday === 4 && isoWeek(local) % 2 === 0) due.push("newsletter");
  return due;
}

function isoWeek(d: Date): number {
  const t = new Date(Date.UTC(d.getFullYear(), d.getMonth(), d.getDate()));
  const day = t.getUTCDay() || 7;
  t.setUTCDate(t.getUTCDate() + 4 - day);
  const yearStart = new Date(Date.UTC(t.getUTCFullYear(), 0, 1));
  return Math.ceil(((t.getTime() - yearStart.getTime()) / 864e5 + 1) / 7);
}

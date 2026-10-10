// The factory's steps: what the agent is asked at each one, how its answer is read, and which
// step comes after an approval. Nothing here talks to the network.

export type Kind = "blog" | "pack";

export type Job = {
  id: string;
  kind: Kind;
  title: string;
  stage: string;
  step_index: number;
  status: "working" | "waiting" | "done" | "rejected" | "failed";
  data: Record<string, unknown>;
  output: Record<string, unknown>;
  feedback: string | null;
};

/** The order of steps; "script" repeats once for every play of the pack. */
export const STAGES: Record<Kind, string[]> = {
  blog: ["topic", "article", "publish", "done"],
  pack: ["idea", "script", "voice", "recording", "listing", "catalog", "done"],
};

export const STAGE_LABELS: Record<string, string> = {
  topic: "Temat",
  article: "Artykuł",
  publish: "Publikacja",
  idea: "Pomysł na pakiet",
  script: "Scenariusz zabawy",
  voice: "Próbne nagranie",
  recording: "Nagranie Neli",
  listing: "Opisy i okładka",
  catalog: "Do katalogu w Studio",
  done: "Gotowe",
};

/** Where an approval leads: the next play's script, or the next step. */
export function nextStage(job: Pick<Job, "kind" | "stage" | "step_index" | "data">): { stage: string; index: number } {
  if (job.kind === "pack" && job.stage === "script") {
    const plays = ((job.data.idea as { plays?: unknown[] } | undefined)?.plays ?? []).length;
    if (job.step_index + 1 < plays) return { stage: "script", index: job.step_index + 1 };
  }
  const order = STAGES[job.kind];
  const i = order.indexOf(job.stage);
  return { stage: order[Math.min(i + 1, order.length - 1)], index: 0 };
}

/** Steps where the system does the work itself (no model call): publishing, voice drafts,
 * waiting for Nela, inserting into Studio. */
export const MANUAL_OR_SYSTEM = new Set(["publish", "voice", "recording", "catalog", "done"]);

export const SYSTEM = `Pracujesz dla AudioKiddo: polskiej rodzinnej marki (Nela i Dawid) z interaktywnymi audiozabawami bez ekranu dla dzieci 3–9 lat. Dziecko słucha i odpowiada głosem, rusza się, wymyśla; rodzic odkłada telefon. Maskotka: szop Szop’en (ciepły dla dziecka, z humorem wobec dorosłych).
Piszesz po polsku, naturalnie, konkretnie, bez sztampy i bez zwrotów typu „w dzisiejszych czasach”, „odkryj”, „magiczny świat”. Nie wymyślasz badań, statystyk ani cytatów. Bez przemocy i straszenia.
Odpowiadasz WYŁĄCZNIE jednym obiektem JSON, bez komentarzy i bez bloku kodu.`;

const fb = (job: Job) => job.feedback ? `\n\nUWAGI DO POPRAWY od Dawida/Neli (uwzględnij je dokładnie):\n${job.feedback}` : "";

/** The prompt for the step the job is at. [context] carries keywords, existing posts, catalog. */
export function stagePrompt(job: Job, context: Record<string, unknown>): { prompt: string; maxTokens: number } {
  const d = job.data;
  switch (`${job.kind}:${job.stage}`) {
    case "blog:topic":
      return {
        maxTokens: 1500,
        prompt: `Zaproponuj temat artykułu na blog audiokiddo.pl${job.title ? ` wokół: „${job.title}”` : ""}.
Słowa kluczowe z liczbą wyszukiwań (wybierz jedno główne, najlepiej z dużą liczbą wyszukiwań i niską konkurencją, niewykorzystane): ${JSON.stringify(context.keywords ?? [])}
Istniejące artykuły (nie powtarzaj): ${JSON.stringify(context.posts ?? [])}
Artykuł ma odpowiadać na realne pytanie rodzica i naturalnie prowadzić do aplikacji lub przewodnika „Podróż bez ekranu”.
JSON: {"title": "tytuł do 60 znaków z frazą", "keyword": "fraza główna", "secondary": ["2–4 frazy poboczne"], "intent": "czego szuka rodzic", "outline": ["H2 …", "H2 …"], "faq": ["pytanie 1", "…"], "why": "dlaczego ten temat teraz (liczby z danych)"}${fb(job)}`,
      };
    case "blog:article": {
      const topic = d.topic ?? {};
      return {
        maxTokens: 9000,
        prompt: `Napisz artykuł na blog audiokiddo.pl według zatwierdzonego tematu: ${JSON.stringify(topic)}
Wymagania SEO i GEO (żeby Google i asystenci AI cytowali ten tekst):
- 1000–1500 słów, fraza główna w tytule, pierwszym akapicie i jednym nagłówku H2, naturalnie, bez upychania;
- zaraz po wstępie lista „Najważniejsze w skrócie” (3–5 konkretnych zdań-faktów, każde zrozumiałe samodzielnie);
- każdy H2 zaczyna się od bezpośredniej odpowiedzi w 1–2 zdaniach, potem rozwinięcie i przykłady;
- konkretne liczby praktyczne (wiek, minuty, liczba zabaw), żadnych zmyślonych badań;
- co najmniej jedna lista kroków albo zabaw;
- na końcu sekcja „Najczęstsze pytania” z 4–6 pytaniami (H3) i krótkimi odpowiedziami (p);
- 2–3 linki wewnętrzne: https://audiokiddo.pl/ (aplikacja), https://audiokiddo.pl/blog/ (blog), przewodnik do pobrania: https://audiokiddo.pl/#przewodnik;
- jedno subtelne wezwanie do działania (aplikacja albo przewodnik), bez nachalności;
- autor: Nela albo Dawid (pierwsza osoba liczby mnogiej „my” jako twórcy AudioKiddo); nie wymyślaj historii z ich życia ani dzieci, których nie podano w notatce.
content_html: tylko znaczniki h2, h3, p, ul, ol, li, strong, em, a (href https), blockquote. Bez h1 (tytuł jest osobno). Pierwszy element to <p> wstępu, potem <h2>Najważniejsze w skrócie</h2><ul>…</ul>.
JSON: {"title": "…", "slug": "male-litery-z-myslnikami", "meta_description": "140–155 znaków", "excerpt": "1–2 zdania", "content_html": "…", "faq": [{"q": "…", "a": "…"}], "category": "Zabawy | W podróży | Przed snem | Rozwój mowy | Ekran i rodzina", "tags": ["…"], "author": "Nela albo Dawid", "image_alt": "opis grafiki"}${fb(job)}`,
      };
    }
    case "pack:idea":
      return {
        maxTokens: 3000,
        prompt: `Zaprojektuj nowy pakiet audiozabaw${job.title ? `: „${job.title}”` : ""}.
Istniejące pakiety i zabawy (nie powtarzaj): ${JSON.stringify(context.catalog ?? {})}
Ranking zabaw z danych (co dzieci kończą i powtarzają): ${JSON.stringify(context.plays ?? [])}
Pakiet: 6–8 zabaw po 4–8 minut, jedna darmowa na zachętę, różne rodzaje (opowieść z wyborami, zagadki, ruch, słowa).
JSON: {"title": "…", "id": "slug", "age_min": 3, "age_max": 9, "promise": "obietnica dla rodzica w 1 zdaniu", "why": "dlaczego się sprzeda", "month": "RRRR-MM", "plays": [{"title": "…", "minutes": 6, "summary": "1 zdanie", "skills": ["…"], "free": false}]}${fb(job)}`,
      };
    case "pack:script": {
      const idea = d.idea as { title?: string; age_min?: number; plays?: { title: string; summary?: string; minutes?: number }[] } | undefined;
      const play = idea?.plays?.[job.step_index];
      return {
        maxTokens: 12000,
        prompt: `Napisz pełny scenariusz audiozabawy do nagrania. Pakiet: „${idea?.title}” (od ${idea?.age_min ?? 3} lat). Zabawa ${job.step_index + 1} z ${idea?.plays?.length}: ${JSON.stringify(play)}
Wcześniej zatwierdzone scenariusze w pakiecie (zachowaj spójność postaci i tonu, nie powtarzaj pomysłów): ${JSON.stringify(((d.scripts as { title: string }[] | undefined) ?? []).map((s) => s.title))}
Forma: role (NARRATOR, SZOP’EN, inne), pauzy na odpowiedź dziecka [PAUZA 5 s], momenty ruchu [RUCH], efekty dźwiękowe [DŹWIĘK: …], zakończenie z pochwałą. ${play?.minutes ?? 6} minut czytania. Język prosty, zabawny, dziecko jest bohaterem.
JSON: {"title": "…", "roles": ["NARRATOR", "…"], "text": "scenariusz: każda kwestia w nowej linii jako ROLA: tekst", "sounds": ["lista efektów"], "notes_for_nela": "jak to zagrać: tempo, emocje, trudne miejsca", "print_card": "opis karty do druku albo pusty tekst"}${fb(job)}`,
      };
    }
    case "pack:listing": {
      return {
        maxTokens: 6000,
        prompt: `Przygotuj opisy pakietu do aplikacji i sklepu oraz brief okładki. Pakiet: ${JSON.stringify(d.idea)}
Scenariusze (tytuły i treść w skrócie): ${JSON.stringify(((d.scripts as { title: string; text: string }[] | undefined) ?? []).map((s) => ({ title: s.title, start: s.text.slice(0, 400) })))}
JSON: {"pack": {"id": "slug", "title": "…", "subtitle": "…", "description": "2–3 zdania dla rodzica"}, "items": [{"id": "slug", "title": "…", "parent_description": "1–2 zdania: co dziecko robi i co rozwija", "age_min": 3, "age_max": 9, "duration_sec": 360, "skills": ["…"], "situations": ["podroz" | "w_domu" | "przed_snem" | "czekamy"], "requirements": [], "access": "free" | "paid"}], "shop_description": "opis do WooCommerce (Markdown, 120–200 słów)", "cover_brief": "brief okładki dla ilustratora / generatora: scena, postacie, kolory, styl jak dotychczasowe okładki, tytuł na okładce", "social": ["2 posty zapowiadające premierę"]}${fb(job)}`,
      };
    }
    default:
      throw new Error(`no prompt for ${job.kind}:${job.stage}`);
  }
}

/** The first JSON object in the model's answer. */
export function parseJson(text: string): Record<string, unknown> {
  const start = text.indexOf("{");
  const end = text.lastIndexOf("}");
  if (start < 0 || end <= start) throw new Error("no json");
  return JSON.parse(text.slice(start, end + 1));
}

const ALLOWED = new Set(["h2", "h3", "p", "ul", "ol", "li", "strong", "em", "a", "blockquote", "br"]);

/** Keeps only the allowed tags (and only https links); everything else is dropped as text. */
export function cleanHtml(html: string): string {
  return html
    .replace(/<\s*(script|style|iframe)[^>]*>[\s\S]*?<\s*\/\s*\1\s*>/gi, "")
    .replace(/<\s*(\/?)\s*([a-z0-9]+)([^>]*)>/gi, (_m, slash: string, tag: string, attrs: string) => {
      const t = tag.toLowerCase();
      if (!ALLOWED.has(t)) return "";
      if (t === "a" && !slash) {
        const href = /href\s*=\s*"(https:\/\/[^"]+)"/i.exec(attrs)?.[1];
        return href ? `<a href="${href}">` : "<a>";
      }
      return `<${slash}${t}>`;
    });
}

export function slugify(text: string): string {
  const map: Record<string, string> = { ą: "a", ć: "c", ę: "e", ł: "l", ń: "n", ó: "o", ś: "s", ź: "z", ż: "z" };
  return text.toLowerCase().replace(/[ąćęłńóśźż]/g, (c) => map[c]).replace(/[^a-z0-9]+/g, "-").replace(/^-|-$/g, "")
    .slice(0, 80);
}

/** The article as a WordPress post: our template, the FAQ kept in the content for the schema. */
export function wpPost(article: Record<string, unknown>, categoryId: number | null, status: string) {
  const faq = ((article.faq as { q: string; a: string }[] | undefined) ?? [])
    .filter((f) => f && typeof f.q === "string" && typeof f.a === "string")
    .map((f) => ({ q: f.q.trim(), a: f.a.trim() }));
  let html = cleanHtml(String(article.content_html ?? ""));
  if (faq.length && !/Najczęstsze pytania/i.test(html)) {
    html += `<h2>Najczęstsze pytania</h2>${faq.map((f) => `<h3>${escapeHtml(f.q)}</h3><p>${escapeHtml(f.a)}</p>`).join("")}`;
  }
  const author = String(article.author ?? "").toLowerCase();
  return {
    title: String(article.title ?? "").slice(0, 200),
    slug: slugify(String(article.slug ?? article.title ?? "")),
    excerpt: String(article.meta_description ?? article.excerpt ?? "").slice(0, 300),
    content: html,
    status,
    // Read by the audiokiddo-strona plugin: questions for the FAQ data, the author's box.
    meta: {
      ak_faq: JSON.stringify(faq),
      ak_author: author.includes("nela") && author.includes("dawid") ? "razem" : author.includes("nela") ? "nela" : author.includes("dawid") ? "dawid" : "razem",
      ak_image_alt: String(article.image_alt ?? "").slice(0, 200),
    },
    ...(categoryId ? { categories: [categoryId] } : {}),
  };
}

function escapeHtml(text: string): string {
  return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;");
}

/** Script text for a voice draft: role labels and stage directions out, pauses as silence marks. */
export function speakable(script: string): string {
  return script
    .split("\n")
    .map((l) => l.replace(/^[A-ZĄĆĘŁŃÓŚŹŻ’' ]{2,30}:\s*/, "").trim())
    .map((l) => l.replace(/\[PAUZA[^\]]*\]/gi, "…").replace(/\[(RUCH|DŹWIĘK)[^\]]*\]/gi, "").trim())
    .filter((l) => l.length > 0)
    .join("\n");
}

/** Splits text for text-to-speech at paragraph or sentence ends, at most [max] characters. */
export function chunks(text: string, max = 2400): string[] {
  const out: string[] = [];
  let current = "";
  for (const part of text.split(/(?<=[.!?…])\s+|\n+/)) {
    if ((current + " " + part).length > max && current) {
      out.push(current.trim());
      current = "";
    }
    current += " " + part;
  }
  if (current.trim()) out.push(current.trim());
  return out;
}

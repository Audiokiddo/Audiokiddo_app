// Store reviews in the CRM: fetched from the App Store and Google Play, a reply drafted by the
// agent, published only after Dawid approves it.

export type Review = {
  store: "app_store" | "google_play";
  review_id: string;
  rating: number;
  title: string;
  body: string;
  author: string;
  territory: string | null;
  app_version: string | null;
  created_at: string;
  reply: string | null;
};

/** App Store Connect customerReviews (with the included responses). */
export function parseAppleReviews(json: unknown): Review[] {
  const j = (json ?? {}) as { data?: Record<string, unknown>[]; included?: Record<string, unknown>[] };
  const responses = new Map<string, string>();
  for (const inc of j.included ?? []) {
    if (inc.type !== "customerReviewResponses") continue;
    const reviewId = ((inc.relationships as Record<string, { data?: { id?: string } }> | undefined)?.review?.data?.id);
    const body = (inc.attributes as Record<string, unknown> | undefined)?.responseBody;
    if (reviewId && typeof body === "string") responses.set(reviewId, body);
  }
  return (j.data ?? []).flatMap((d) => {
    const a = (d.attributes ?? {}) as Record<string, unknown>;
    if (typeof d.id !== "string") return [];
    return [{
      store: "app_store" as const,
      review_id: d.id,
      rating: Number(a.rating ?? 0),
      title: String(a.title ?? "").slice(0, 300),
      body: String(a.body ?? "").slice(0, 4000),
      author: String(a.reviewerNickname ?? "").slice(0, 100),
      territory: typeof a.territory === "string" ? a.territory : null,
      app_version: null,
      created_at: String(a.createdDate ?? new Date().toISOString()),
      reply: responses.get(d.id) ?? null,
    }];
  });
}

/** Google Play reviews.list (only reviews with text from the last week are returned). */
export function parseGoogleReviews(json: unknown): Review[] {
  const list = ((json ?? {}) as { reviews?: Record<string, unknown>[] }).reviews ?? [];
  return list.flatMap((r) => {
    const comments = (r.comments as Record<string, Record<string, unknown>>[] | undefined) ?? [];
    const user = comments.find((c) => c.userComment)?.userComment;
    const dev = comments.find((c) => c.developerComment)?.developerComment;
    if (typeof r.reviewId !== "string" || !user) return [];
    const seconds = Number((user.lastModified as Record<string, unknown> | undefined)?.seconds ?? 0);
    return [{
      store: "google_play" as const,
      review_id: r.reviewId,
      rating: Number(user.starRating ?? 0),
      title: "",
      body: String(user.text ?? "").trim().slice(0, 4000),
      author: String(r.authorName ?? "").slice(0, 100),
      territory: typeof user.reviewerLanguage === "string" ? user.reviewerLanguage : null,
      app_version: typeof user.appVersionName === "string" ? user.appVersionName : null,
      created_at: seconds ? new Date(seconds * 1000).toISOString() : new Date().toISOString(),
      reply: typeof dev?.text === "string" ? dev.text : null,
    }];
  });
}

export const REPLY_SYSTEM = `Odpowiadasz na opinie rodziców o aplikacji AudioKiddo (audiozabawy bez ekranu dla dzieci 3–9 lat) w imieniu zespołu: Dawida i Neli.
Zasady: po polsku (albo w języku opinii), ciepło i konkretnie, 2–4 zdania, bez szablonowych formułek. Podziękuj za coś konkretnego z opinii.
Przy problemie: przeproś bez tłumaczenia się, powiedz, co zrobić teraz (np. „Przywróć zakupy” w Więcej → Zarządzaj subskrypcją, aktualizacja aplikacji) i zaproś na kontakt@audiokiddo.pl. Nie obiecuj dat ani funkcji.
Nigdy nie podawaj cen spoza sklepu i nie kieruj do zakupu na stronie. Nie pisz o danych dziecka.
Podpis: „Dawid z AudioKiddo”. Maksymalnie 330 znaków razem z podpisem (limit Google Play to 350).
Odpowiadasz wyłącznie treścią odpowiedzi, bez cudzysłowów.`;

export function replyPrompt(r: Pick<Review, "rating" | "title" | "body" | "store">): string {
  return `Opinia (${r.store === "app_store" ? "App Store" : "Google Play"}, ${r.rating}/5)${r.title ? `, tytuł: „${r.title}”` : ""}:\n${r.body || "(bez treści, tylko ocena)"}`;
}

/** Trims a reply to the store's limit at a sentence or word boundary. */
export function fitReply(text: string, max = 350): string {
  const clean = text.trim().replace(/^["„]|["”]$/g, "").trim();
  if (clean.length <= max) return clean;
  const cut = clean.slice(0, max);
  const sentence = cut.lastIndexOf(". ");
  return (sentence > max * 0.6 ? cut.slice(0, sentence + 1) : cut.slice(0, cut.lastIndexOf(" "))).trim();
}

/** App Store Connect API token: ES256, valid 20 minutes. */
export async function appleToken(keyId: string, issuerId: string, pem: string, now = Date.now()): Promise<string> {
  const { b64url, pemToDer } = await import("./google_play.ts");
  const iat = Math.floor(now / 1000);
  const unsigned = `${b64url(JSON.stringify({ alg: "ES256", kid: keyId, typ: "JWT" }))}.${
    b64url(JSON.stringify({ iss: issuerId, iat, exp: iat + 1200, aud: "appstoreconnect-v1" }))
  }`;
  const key = await crypto.subtle.importKey("pkcs8", pemToDer(pem), { name: "ECDSA", namedCurve: "P-256" }, false, ["sign"]);
  const sig = new Uint8Array(await crypto.subtle.sign({ name: "ECDSA", hash: "SHA-256" }, key, new TextEncoder().encode(unsigned)));
  return `${unsigned}.${b64url(sig)}`;
}

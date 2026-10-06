// The ads platforms' doors, shared by the daily sync (index.ts) and the weekly research
// (growth.ts): secrets, one call with a short key-free error, Meta paging, Google sign-in.

export const env = (name: string) => Deno.env.get(name)?.trim() || null;
export const META = `https://graph.facebook.com/${env("META_API_VERSION") ?? "v23.0"}`;
export const GOOGLE_ADS = `https://googleads.googleapis.com/${env("GOOGLE_ADS_API_VERSION") ?? "v21"}`;

/** Which sources have their secrets set (never the values). */
export function configured() {
  const google = !!(env("GOOGLE_CLIENT_ID") && env("GOOGLE_CLIENT_SECRET") && env("GOOGLE_REFRESH_TOKEN"));
  return {
    meta: !!(env("META_ACCESS_TOKEN") && env("META_AD_ACCOUNT_ID")),
    meta_pixel: !!(env("META_ACCESS_TOKEN") && env("META_PIXEL_ID")),
    google_ads: google && !!(env("GOOGLE_ADS_DEVELOPER_TOKEN") && env("GOOGLE_ADS_CUSTOMER_ID")),
    ga4: google && !!env("GA4_PROPERTY_ID"),
    agent: !!env("ANTHROPIC_API_KEY"),
  };
}

export class SourceError extends Error {}

/** A platform call that throws a short, key-free message on failure. */
export async function call(url: string, init: RequestInit, label: string): Promise<Record<string, unknown>> {
  const response = await fetch(url, { ...init, signal: AbortSignal.timeout(30_000) });
  const body = await response.json().catch(() => ({})) as Record<string, unknown>;
  if (!response.ok) {
    const error = body.error as Record<string, unknown> | undefined;
    const message = typeof error?.message === "string" ? error.message : `HTTP ${response.status}`;
    console.error(`ads: ${label}`, response.status, JSON.stringify(body).slice(0, 800));
    throw new SourceError(`${label}: ${message.slice(0, 300)}`);
  }
  return body;
}

export const metaHeaders = () => ({ Authorization: `Bearer ${env("META_ACCESS_TOKEN")}` });
export const metaAccount = () => {
  const id = env("META_AD_ACCOUNT_ID")!.replace(/^act_/, "");
  return `act_${id}`;
};

export async function metaPages(url: string, label: string, pages = 10): Promise<unknown[]> {
  const rows: unknown[] = [];
  let next: string | null = url;
  for (let i = 0; next && i < pages; i++) {
    const body = await call(next, { headers: metaHeaders() }, label);
    rows.push(...((body.data as unknown[]) ?? []));
    next = ((body.paging as Record<string, unknown> | undefined)?.next as string | undefined) ?? null;
  }
  return rows;
}

export async function googleToken(): Promise<string> {
  const body = await call("https://oauth2.googleapis.com/token", {
    method: "POST",
    body: new URLSearchParams({
      client_id: env("GOOGLE_CLIENT_ID")!,
      client_secret: env("GOOGLE_CLIENT_SECRET")!,
      refresh_token: env("GOOGLE_REFRESH_TOKEN")!,
      grant_type: "refresh_token",
    }),
  }, "Google logowanie");
  return String(body.access_token);
}

export const customer = () => env("GOOGLE_ADS_CUSTOMER_ID")!.replace(/-/g, "");

export function adsHeaders(token: string): Record<string, string> {
  const headers: Record<string, string> = {
    Authorization: `Bearer ${token}`,
    "developer-token": env("GOOGLE_ADS_DEVELOPER_TOKEN")!,
    "content-type": "application/json",
  };
  const login = env("GOOGLE_ADS_LOGIN_CUSTOMER_ID");
  if (login) headers["login-customer-id"] = login.replace(/-/g, "");
  return headers;
}

/** A GAQL query through searchStream; the answer is a list of batches. */
export async function googleSearch(token: string, query: string, label: string): Promise<unknown[]> {
  const response = await fetch(`${GOOGLE_ADS}/customers/${customer()}/googleAds:searchStream`, {
    method: "POST",
    headers: adsHeaders(token),
    body: JSON.stringify({ query }),
    signal: AbortSignal.timeout(45_000),
  });
  const body = await response.json().catch(() => null);
  if (!response.ok) {
    console.error(`ads: ${label}`, response.status, JSON.stringify(body).slice(0, 800));
    const first = Array.isArray(body) ? body[0] : body;
    const message = first?.error?.message ?? `HTTP ${response.status}`;
    throw new SourceError(`${label}: ${String(message).slice(0, 300)}`);
  }
  return Array.isArray(body) ? body : [body];
}

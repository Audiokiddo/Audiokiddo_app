// Google Play Developer API (purchases) with a service account, and Pub/Sub push
// authentication for Real-time Developer Notifications.
//
// Secrets: GOOGLE_SERVICE_ACCOUNT_JSON (the key file's JSON, pasted by Dawid with
// `supabase secrets set`, never into chat), GOOGLE_PACKAGE_NAME (pl.audiokiddo.app).
import { createRemoteJWKSet, type JWTVerifyGetKey, jwtVerify } from "npm:jose@5.9.6";

export interface ServiceAccount {
  client_email: string;
  private_key: string;
  token_uri?: string;
}

type Fetch = typeof fetch;

export function b64url(bytes: Uint8Array | string): string {
  const raw = typeof bytes === "string" ? new TextEncoder().encode(bytes) : bytes;
  let s = "";
  for (const b of raw) s += String.fromCharCode(b);
  return btoa(s).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");
}

export function pemToDer(pem: string): ArrayBuffer {
  const b64 = pem.replace(/-----[^-]+-----/g, "").replace(/\s+/g, "");
  const binary = atob(b64);
  const out = new Uint8Array(new ArrayBuffer(binary.length));
  for (let i = 0; i < binary.length; i++) out[i] = binary.charCodeAt(i);
  return out.buffer;
}

/** Subset of purchases.subscriptionsv2 (SubscriptionPurchaseV2). */
export interface GoogleSubscriptionPurchase {
  subscriptionState: string;
  lineItems?: { productId: string; expiryTime?: string }[];
  linkedPurchaseToken?: string;
  acknowledgementState?: string;
  externalAccountIdentifiers?: { obfuscatedExternalAccountId?: string };
  testPurchase?: Record<string, never>;
}

/** Subset of purchases.products (ProductPurchase). */
export interface GoogleProductPurchase {
  purchaseState: number; // 0 purchased, 1 canceled, 2 pending
  acknowledgementState?: number;
  obfuscatedExternalAccountId?: string;
  productId?: string;
  orderId?: string;
}

export class GooglePlayError extends Error {
  constructor(message: string, readonly status: number) {
    super(message);
  }
}

export class GooglePlayClient {
  constructor(
    private readonly account: ServiceAccount,
    readonly packageName: string,
    private readonly fetchFn: Fetch = fetch,
  ) {}

  private token?: { value: string; expires: number };

  /** OAuth access token for the androidpublisher scope (cached until shortly before expiry). */
  async accessToken(now = Date.now()): Promise<string> {
    if (this.token && this.token.expires - 60_000 > now) return this.token.value;
    const iat = Math.floor(now / 1000);
    const aud = this.account.token_uri ?? "https://oauth2.googleapis.com/token";
    const unsigned = `${b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }))}.${b64url(
      JSON.stringify({
        iss: this.account.client_email,
        scope: "https://www.googleapis.com/auth/androidpublisher",
        aud,
        iat,
        exp: iat + 3600,
      }),
    )}`;
    const key = await crypto.subtle.importKey(
      "pkcs8",
      pemToDer(this.account.private_key),
      { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
      false,
      ["sign"],
    );
    const signature = new Uint8Array(
      await crypto.subtle.sign("RSASSA-PKCS1-v1_5", key, new TextEncoder().encode(unsigned)),
    );
    const res = await this.fetchFn(aud, {
      method: "POST",
      headers: { "content-type": "application/x-www-form-urlencoded" },
      body: new URLSearchParams({
        grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
        assertion: `${unsigned}.${b64url(signature)}`,
      }),
    });
    if (!res.ok) throw new GooglePlayError(`token ${res.status}`, res.status);
    const body = (await res.json()) as { access_token: string; expires_in: number };
    this.token = { value: body.access_token, expires: now + body.expires_in * 1000 };
    return body.access_token;
  }

  private async get<T>(path: string): Promise<T> {
    const res = await this.fetchFn(
      `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${
        encodeURIComponent(this.packageName)
      }/${path}`,
      { headers: { authorization: `Bearer ${await this.accessToken()}` } },
    );
    if (!res.ok) throw new GooglePlayError(`${path.split("/")[1]} ${res.status}`, res.status);
    return (await res.json()) as T;
  }

  /** Any call under the app (reviews, …): GET without [body], POST with it. */
  async call<T>(path: string, body?: unknown): Promise<T> {
    const res = await this.fetchFn(
      `https://androidpublisher.googleapis.com/androidpublisher/v3/applications/${
        encodeURIComponent(this.packageName)
      }/${path}`,
      {
        method: body === undefined ? "GET" : "POST",
        headers: { authorization: `Bearer ${await this.accessToken()}`, "content-type": "application/json" },
        body: body === undefined ? undefined : JSON.stringify(body),
      },
    );
    if (!res.ok) throw new GooglePlayError(`${path.split("?")[0]} ${res.status}`, res.status);
    return (await res.json()) as T;
  }

  subscription(purchaseToken: string): Promise<GoogleSubscriptionPurchase> {
    return this.get(`purchases/subscriptionsv2/tokens/${encodeURIComponent(purchaseToken)}`);
  }

  product(productId: string, purchaseToken: string): Promise<GoogleProductPurchase> {
    return this.get(
      `purchases/products/${encodeURIComponent(productId)}/tokens/${encodeURIComponent(purchaseToken)}`,
    );
  }
}

/** Client from the Edge Function secrets. */
export function googlePlayFromEnv(): GooglePlayClient {
  const json = Deno.env.get("GOOGLE_SERVICE_ACCOUNT_JSON");
  if (!json) throw new Error("missing secret GOOGLE_SERVICE_ACCOUNT_JSON");
  return new GooglePlayClient(JSON.parse(json), Deno.env.get("GOOGLE_PACKAGE_NAME") ?? "pl.audiokiddo.app");
}

const googleKeys = createRemoteJWKSet(new URL("https://www.googleapis.com/oauth2/v3/certs"));

/**
 * Pub/Sub push requests carry a Google-signed OIDC token. Accept it only for our push
 * subscription's audience and service account (GOOGLE_PUBSUB_AUDIENCE, GOOGLE_PUBSUB_EMAIL).
 */
export async function verifyPubSubToken(
  authorization: string | null,
  audience: string,
  email: string,
  keys: JWTVerifyGetKey = googleKeys,
): Promise<boolean> {
  const token = authorization?.replace(/^Bearer\s+/i, "");
  if (!token) return false;
  try {
    const { payload } = await jwtVerify(token, keys, {
      issuer: ["https://accounts.google.com", "accounts.google.com"],
      audience,
    });
    return payload.email === email && payload.email_verified === true;
  } catch {
    return false;
  }
}

/** Real-time Developer Notification inside a Pub/Sub push body. */
export interface DeveloperNotification {
  packageName: string;
  eventTimeMillis: string;
  subscriptionNotification?: { notificationType: number; purchaseToken: string; subscriptionId: string };
  oneTimeProductNotification?: { notificationType: number; purchaseToken: string; sku: string };
  voidedPurchaseNotification?: { purchaseToken: string; orderId: string; productType: number };
  testNotification?: { version: string };
}

export function parsePubSubPush(body: unknown): { messageId: string; notification: DeveloperNotification } | null {
  const message = (body as { message?: { data?: string; messageId?: string; message_id?: string } })?.message;
  if (!message?.data) return null;
  try {
    const notification = JSON.parse(atob(message.data)) as DeveloperNotification;
    return { messageId: message.messageId ?? message.message_id ?? "", notification };
  } catch {
    return null;
  }
}

// WooCommerce (audiokiddo.pl) → app entitlements (ARCHITECTURE §7a).

export type WooOrderStatus = "completed" | "refunded" | "cancelled";

export interface WooOrder {
  orderId: number;
  email: string;
  status: WooOrderStatus;
  /** 'woo:<product_id>' for each purchased product (mapped to scopes by store_products). */
  productRefs: string[];
  /** The buyer ticked "I want letters from AudioKiddo" at checkout (order meta
   * audiokiddo_newsletter; no leading underscore, or the REST API would hide it). */
  newsletter?: boolean;
  firstName?: string;
  productNames?: string[];
}

/** Normalised e-mail used to match shop buyers with app accounts. */
export function normalizeEmail(email: string): string {
  return email.trim().toLowerCase();
}

/**
 * WooCommerce signs webhook bodies: header `X-WC-Webhook-Signature` =
 * base64(HMAC-SHA256(raw body, webhook secret)). Constant-time comparison.
 */
export async function verifyWooSignature(rawBody: string, secret: string, signature: string | null): Promise<boolean> {
  if (!signature || !secret) return false;
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const mac = new Uint8Array(await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(rawBody)));
  const expected = btoa(String.fromCharCode(...mac));
  if (expected.length !== signature.length) return false;
  let diff = 0;
  for (let i = 0; i < expected.length; i++) diff |= expected.charCodeAt(i) ^ signature.charCodeAt(i);
  return diff === 0;
}

/**
 * WooCommerce checks a new webhook with an unsigned form body `webhook_id=<n>` and only
 * activates it after a 2xx answer. It carries no order data, so it is safe to accept.
 */
export function isWooPing(rawBody: string, signature: string | null): boolean {
  return !signature && /^webhook_id=\d+$/.test(rawBody.trim());
}

/** Only final order states matter; everything else (pending, on-hold, …) is ignored. */
export function parseWooOrder(payload: unknown): WooOrder | null {
  if (typeof payload !== "object" || payload === null) return null;
  const order = payload as Record<string, unknown>;
  const status = order.status;
  if (status !== "completed" && status !== "refunded" && status !== "cancelled") return null;
  const billing = order.billing as Record<string, unknown> | undefined;
  const email = typeof billing?.email === "string" ? normalizeEmail(billing.email) : "";
  const id = order.id;
  if (typeof id !== "number" || !email) return null;
  const items = Array.isArray(order.line_items) ? order.line_items : [];
  const productRefs = [
    ...new Set(
      items
        .map((i) => (i as Record<string, unknown>).product_id)
        .filter((p): p is number => typeof p === "number" && p > 0)
        .map((p) => `woo:${p}`),
    ),
  ];
  const meta = Array.isArray(order.meta_data) ? order.meta_data as Record<string, unknown>[] : [];
  const newsletter = meta.some((m) => m.key === "audiokiddo_newsletter" && (m.value === "yes" || m.value === "1"));
  const names = items.map((i) => (i as Record<string, unknown>).name).filter((n): n is string => typeof n === "string");
  return {
    orderId: id,
    email,
    status,
    productRefs,
    newsletter,
    firstName: typeof billing?.first_name === "string" ? billing.first_name.trim().slice(0, 60) : undefined,
    productNames: names.map((n) => n.slice(0, 120)),
  };
}

/** SHA-256 hex, used for store_events.payload_hash. */
export async function sha256Hex(text: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(text));
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

/**
 * GET on the shop's REST API with the read-only key. Some hosts drop the Authorization header
 * before PHP sees it; WooCommerce then accepts the same key as query parameters (HTTPS only).
 */
export async function wooGet(
  base: string,
  key: string,
  secret: string,
  path: string,
  params: Record<string, string> = {},
): Promise<Response> {
  const url = new URL(path, base);
  for (const [name, value] of Object.entries(params)) url.searchParams.set(name, value);
  const response = await fetch(url, { headers: { Authorization: `Basic ${btoa(`${key}:${secret}`)}` } });
  if (response.status !== 401) return response;
  const withKey = new URL(url);
  withKey.searchParams.set("consumer_key", key);
  withKey.searchParams.set("consumer_secret", secret);
  return await fetch(withKey);
}

/** The MailerLite subscriber for a buyer who agreed to letters: name, what they bought,
 * the buyers' group (its automation sends the after-purchase series). */
export function buyerSubscriber(order: WooOrder, groupId: string): Record<string, unknown> {
  return {
    email: order.email,
    fields: { name: order.firstName ?? "", last_purchase: (order.productNames ?? []).join(", ").slice(0, 250) },
    groups: [groupId],
    status: "active",
  };
}

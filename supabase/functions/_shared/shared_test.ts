import { assert, assertEquals } from "jsr:@std/assert@1";
import { isWooPing, normalizeEmail, parseWooOrder, sha256Hex, verifyWooSignature } from "./woo.ts";
import { appleStatus, googleOneTimeStatus, googleSubscriptionStatus } from "./store_status.ts";

async function sign(body: string, secret: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const mac = new Uint8Array(await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(body)));
  return btoa(String.fromCharCode(...mac));
}

Deno.test("woo signature: valid, tampered body, wrong secret, missing header", async () => {
  const body = '{"id":501,"status":"completed"}';
  const sig = await sign(body, "s3cret");
  assert(await verifyWooSignature(body, "s3cret", sig));
  assert(!(await verifyWooSignature(body + " ", "s3cret", sig)));
  assert(!(await verifyWooSignature(body, "other", sig)));
  assert(!(await verifyWooSignature(body, "s3cret", null)));
});

Deno.test("woo order parsing", () => {
  const order = parseWooOrder({
    id: 501,
    status: "completed",
    billing: { email: "  Rodzic@Example.com " },
    line_items: [{ product_id: 11 }, { product_id: 12 }, { product_id: 11 }, { product_id: 0 }],
  });
  assertEquals(order, {
    orderId: 501,
    email: "rodzic@example.com",
    status: "completed",
    productRefs: ["woo:11", "woo:12"],
    newsletter: false,
    productNames: [],
  });
  assertEquals(parseWooOrder({ id: 1, status: "processing", billing: { email: "a@b.pl" } }), null);
  assertEquals(parseWooOrder({ id: 1, status: "completed", billing: {} }), null);
  assertEquals(parseWooOrder("nonsense"), null);
  assertEquals(normalizeEmail(" A@B.PL "), "a@b.pl");
});

Deno.test("payload hash is stable", async () => {
  assertEquals(await sha256Hex("abc"), "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
});

const now = new Date("2026-10-01T12:00:00Z");
const day = 86_400_000;

Deno.test("apple: one-time, active, grace, billing retry, expired, refund, family revoke", () => {
  const tx = { originalTransactionId: "1", productId: "p" };
  assertEquals(appleStatus(tx, undefined, now).status, "active");
  assertEquals(appleStatus({ ...tx, expiresDate: now.getTime() + day }, undefined, now).status, "active");
  const lapsed = { ...tx, expiresDate: now.getTime() - day };
  assertEquals(appleStatus(lapsed, { gracePeriodExpiresDate: now.getTime() + day }, now).status, "grace");
  assertEquals(appleStatus(lapsed, { isInBillingRetryPeriod: true }, now).status, "billing_retry");
  assertEquals(appleStatus(lapsed, {}, now).status, "expired");
  assertEquals(appleStatus({ ...tx, revocationDate: now.getTime() }, undefined, now).status, "refunded");
  assertEquals(appleStatus({ ...tx, revocationDate: now.getTime() }, undefined, now, "REVOKE").status, "revoked");
});

Deno.test("google subscriptions: states and cancelled-but-paid", () => {
  const future = new Date(now.getTime() + day).toISOString();
  const past = new Date(now.getTime() - day).toISOString();
  const s = (state: string, expiry = future) =>
    googleSubscriptionStatus({ subscriptionState: state, lineItems: [{ productId: "p", expiryTime: expiry }] }, now)
      ?.status;
  assertEquals(s("SUBSCRIPTION_STATE_ACTIVE"), "active");
  assertEquals(s("SUBSCRIPTION_STATE_CANCELED"), "active");
  assertEquals(s("SUBSCRIPTION_STATE_CANCELED", past), "expired");
  assertEquals(s("SUBSCRIPTION_STATE_IN_GRACE_PERIOD"), "grace");
  assertEquals(s("SUBSCRIPTION_STATE_ON_HOLD"), "billing_retry");
  assertEquals(s("SUBSCRIPTION_STATE_EXPIRED"), "expired");
  assertEquals(s("SUBSCRIPTION_STATE_PENDING"), undefined);
});

Deno.test("google one-time purchases", () => {
  assertEquals(googleOneTimeStatus(0, false)?.status, "active");
  assertEquals(googleOneTimeStatus(1, false)?.status, "revoked");
  assertEquals(googleOneTimeStatus(2, false), null);
  assertEquals(googleOneTimeStatus(0, true)?.status, "refunded");
});

Deno.test("woo ping: unsigned creation check is accepted, anything else is not", () => {
  assertEquals(isWooPing("webhook_id=42", null), true);
  assertEquals(isWooPing("webhook_id=42", "abc"), false);
  assertEquals(isWooPing('{"id":1,"status":"completed"}', null), false);
  assertEquals(isWooPing("webhook_id=42&x=1", null), false);
});

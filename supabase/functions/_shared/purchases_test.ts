import { assertEquals, assertRejects } from "jsr:@std/assert@1";
import type { EntitlementStatus } from "./store_status.ts";
import type { GoogleProductPurchase, GoogleSubscriptionPurchase } from "./google_play.ts";
import {
  type EntitlementStore,
  handleAppleNotification,
  handleGoogleNotification,
  PurchaseRejected,
  type Source,
  UnknownProductError,
  verifyApplePurchase,
  verifyGooglePurchase,
} from "./purchases.ts";
import { chain, sign } from "./test_chain.ts";

const PARENT = "11111111-1111-4111-8111-111111111111";
const OTHER = "22222222-2222-4222-8222-222222222222";
const KNOWN = new Set([
  "ios:pl.audiokiddo.sub.yearly",
  "ios:pl.audiokiddo.pack.wyobraznia",
  "android:pl.audiokiddo.sub.monthly",
  "android:pl.audiokiddo.pack.detektyw",
]);

interface Row {
  userId: string;
  source: Source;
  productRef: string;
  txId: string;
  status: EntitlementStatus;
  validUntil: Date | null;
}

class FakeStore implements EntitlementStore {
  rows = new Map<string, Row>();
  events = new Set<string>();

  ownerOf(source: Source, txId: string) {
    return Promise.resolve(this.rows.get(`${source}:${txId}`)?.userId ?? null);
  }
  upsert(e: Row) {
    if (!KNOWN.has(e.productRef)) return Promise.reject(new UnknownProductError(e.productRef));
    this.rows.set(`${e.source}:${e.txId}`, { ...e });
    return Promise.resolve();
  }
  setStatus(source: Source, txId: string, status: EntitlementStatus) {
    const row = this.rows.get(`${source}:${txId}`);
    if (row) row.status = status;
    return Promise.resolve();
  }
  recordEvent(id: string) {
    const fresh = !this.events.has(id);
    this.events.add(id);
    return Promise.resolve(fresh);
  }
}

const now = new Date("2026-09-28T12:00:00Z");
const day = 86_400_000;

async function apple() {
  const c = await chain();
  const signTx = (tx: Record<string, unknown>) =>
    sign({ bundleId: "pl.audiokiddo.app", environment: "Sandbox", signedDate: now.getTime() - day, ...tx }, c.x5c, c.leafKey);
  return { c, signTx, jws: { roots: [c.rootB64] } };
}

Deno.test("apple purchase: verified yearly subscription is granted to the caller", async () => {
  const { signTx, jws } = await apple();
  const store = new FakeStore();
  const tx = await signTx({
    transactionId: "t1",
    originalTransactionId: "o1",
    productId: "pl.audiokiddo.sub.yearly",
    expiresDate: now.getTime() + 300 * day,
  });
  const out = await verifyApplePurchase({ store, bundleId: "pl.audiokiddo.app", jws, now }, PARENT, tx);
  assertEquals(out.status, "active");
  assertEquals(store.rows.get("app_store:o1")?.userId, PARENT);
});

Deno.test("apple purchase: another app's bundle, unknown product and bad signature are rejected", async () => {
  const { signTx, jws } = await apple();
  const store = new FakeStore();
  const ctx = { store, bundleId: "pl.audiokiddo.app", jws, now };
  const other = await signTx({ originalTransactionId: "o2", productId: "pl.audiokiddo.sub.yearly", bundleId: "com.other" });
  await assertRejects(() => verifyApplePurchase(ctx, PARENT, other), PurchaseRejected, "bundle");
  const unknown = await signTx({ originalTransactionId: "o3", productId: "pl.audiokiddo.free.money" });
  await assertRejects(() => verifyApplePurchase(ctx, PARENT, unknown), PurchaseRejected, "product");
  await assertRejects(() => verifyApplePurchase(ctx, PARENT, "a.b.c"), PurchaseRejected, "signature");
  assertEquals(store.rows.size, 0);
});

Deno.test("apple purchase: restore on another account moves the purchase there", async () => {
  const { signTx, jws } = await apple();
  const store = new FakeStore();
  const ctx = { store, bundleId: "pl.audiokiddo.app", jws, now };
  const tx = await signTx({ originalTransactionId: "o4", productId: "pl.audiokiddo.pack.wyobraznia" });
  await verifyApplePurchase(ctx, PARENT, tx);
  await verifyApplePurchase(ctx, OTHER, tx);
  assertEquals(store.rows.get("app_store:o4")?.userId, OTHER);
  assertEquals(store.rows.get("app_store:o4")?.status, "active");
});

Deno.test("apple notification: refund revokes, redelivery is a duplicate, unknown purchase is ignored", async () => {
  const { c, signTx, jws } = await apple();
  const store = new FakeStore();
  const ctx = { store, bundleId: "pl.audiokiddo.app", jws, now };
  await verifyApplePurchase(ctx, PARENT, await signTx({ originalTransactionId: "o5", productId: "pl.audiokiddo.sub.yearly", expiresDate: now.getTime() + day }));

  const refundTx = await signTx({
    originalTransactionId: "o5",
    productId: "pl.audiokiddo.sub.yearly",
    expiresDate: now.getTime() + day,
    revocationDate: now.getTime() - 1000,
  });
  const note = await sign(
    { notificationType: "REFUND", notificationUUID: "n1", signedDate: now.getTime() - 1000, data: { bundleId: "pl.audiokiddo.app", signedTransactionInfo: refundTx } },
    c.x5c,
    c.leafKey,
  );
  assertEquals(await handleAppleNotification(ctx, note, "h1"), "updated");
  assertEquals(store.rows.get("app_store:o5")?.status, "refunded");
  assertEquals(await handleAppleNotification(ctx, note, "h1"), "duplicate");

  const stranger = await sign(
    {
      notificationType: "DID_RENEW",
      notificationUUID: "n2",
      signedDate: now.getTime() - 1000,
      data: { signedTransactionInfo: await signTx({ originalTransactionId: "never-seen", productId: "pl.audiokiddo.sub.yearly" }) },
    },
    c.x5c,
    c.leafKey,
  );
  assertEquals(await handleAppleNotification(ctx, stranger, "h2"), "ignored");
});

Deno.test("apple notification: grace period keeps access after the renewal failed", async () => {
  const { c, signTx, jws } = await apple();
  const store = new FakeStore();
  const ctx = { store, bundleId: "pl.audiokiddo.app", jws, now };
  const expired = { originalTransactionId: "o6", productId: "pl.audiokiddo.sub.yearly", expiresDate: now.getTime() - day };
  await verifyApplePurchase(ctx, PARENT, await signTx(expired));
  const renewal = await sign({ gracePeriodExpiresDate: now.getTime() + 5 * day, signedDate: now.getTime() - 1000 }, c.x5c, c.leafKey);
  const note = await sign(
    { notificationType: "DID_FAIL_TO_RENEW", subtype: "GRACE_PERIOD", notificationUUID: "n3", signedDate: now.getTime() - 1000, data: { signedTransactionInfo: await signTx(expired), signedRenewalInfo: renewal } },
    c.x5c,
    c.leafKey,
  );
  await handleAppleNotification(ctx, note, "h3");
  assertEquals(store.rows.get("app_store:o6")?.status, "grace");
});

// ---------------------------------------------------------------- Google

class FakePlay {
  packageName = "pl.audiokiddo.app";
  subs = new Map<string, GoogleSubscriptionPurchase>();
  products = new Map<string, GoogleProductPurchase>();
  subscription(token: string) {
    const s = this.subs.get(token);
    return s ? Promise.resolve(s) : Promise.reject(new Error("404"));
  }
  product(_productId: string, token: string) {
    const p = this.products.get(token);
    return p ? Promise.resolve(p) : Promise.reject(new Error("404"));
  }
}

const SUBS = new Set(["pl.audiokiddo.sub.monthly", "pl.audiokiddo.sub.yearly"]);

Deno.test("google purchase: subscription and one-time pack; pending grants nothing", async () => {
  const store = new FakeStore();
  const play = new FakePlay();
  const ctx = { store, play, subscriptionIds: SUBS, now };
  play.subs.set("s1", {
    subscriptionState: "SUBSCRIPTION_STATE_ACTIVE",
    lineItems: [{ productId: "pl.audiokiddo.sub.monthly", expiryTime: new Date(now.getTime() + 30 * day).toISOString() }],
  });
  assertEquals((await verifyGooglePurchase(ctx, PARENT, "pl.audiokiddo.sub.monthly", "s1")).status, "active");
  play.products.set("p1", { purchaseState: 0 });
  assertEquals((await verifyGooglePurchase(ctx, PARENT, "pl.audiokiddo.pack.detektyw", "p1")).status, "active");
  play.products.set("p2", { purchaseState: 2 });
  assertEquals((await verifyGooglePurchase(ctx, PARENT, "pl.audiokiddo.pack.detektyw", "p2")).status, "pending");
  assertEquals(store.rows.has("google_play:p2"), false);
});

Deno.test("google notifications: renewal, upgrade replaces the old token, voided purchase is refunded", async () => {
  const store = new FakeStore();
  const play = new FakePlay();
  const ctx = { store, play, subscriptionIds: SUBS, now };
  play.products.set("p1", { purchaseState: 0 });
  await verifyGooglePurchase(ctx, PARENT, "pl.audiokiddo.pack.detektyw", "p1");
  play.subs.set("old", { subscriptionState: "SUBSCRIPTION_STATE_ACTIVE", lineItems: [{ productId: "pl.audiokiddo.sub.monthly" }] });
  await verifyGooglePurchase(ctx, PARENT, "pl.audiokiddo.sub.monthly", "old");

  // The new token arrives by notification; the account comes from obfuscatedExternalAccountId.
  play.subs.set("new", {
    subscriptionState: "SUBSCRIPTION_STATE_ACTIVE",
    linkedPurchaseToken: "old",
    lineItems: [{ productId: "pl.audiokiddo.sub.monthly", expiryTime: new Date(now.getTime() + day).toISOString() }],
    externalAccountIdentifiers: { obfuscatedExternalAccountId: PARENT },
  });
  const base = { packageName: "pl.audiokiddo.app", eventTimeMillis: "0" };
  assertEquals(
    await handleGoogleNotification(ctx, "m1", { ...base, subscriptionNotification: { notificationType: 2, purchaseToken: "new", subscriptionId: "pl.audiokiddo.sub.monthly" } }, "h"),
    "updated",
  );
  assertEquals(store.rows.get("google_play:old")?.status, "expired");
  assertEquals(store.rows.get("google_play:new")?.userId, PARENT);

  assertEquals(
    await handleGoogleNotification(ctx, "m2", { ...base, voidedPurchaseNotification: { purchaseToken: "p1", orderId: "GPA.1", productType: 2 } }, "h2"),
    "updated",
  );
  assertEquals(store.rows.get("google_play:p1")?.status, "refunded");
  assertEquals(
    await handleGoogleNotification(ctx, "m3", { ...base, packageName: "com.other" }, "h3"),
    "ignored",
  );
  assertEquals(await handleGoogleNotification(ctx, "m4", { ...base, testNotification: { version: "1.0" } }, "h4"), "ignored");
});

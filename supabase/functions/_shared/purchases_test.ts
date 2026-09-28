import { assertEquals, assertRejects } from "jsr:@std/assert@1";
import type { GoogleProductPurchase, GoogleSubscriptionPurchase } from "./google_play.ts";
import {
  type EntitlementStore,
  type Grant,
  handleAppleNotification,
  handleGoogleNotification,
  PurchaseRejected,
  type Source,
  type StoreChange,
  UnknownProductError,
  verifyApplePurchase,
  verifyGooglePurchase,
} from "./purchases.ts";
import { chain, sign } from "./test_chain.ts";

const PARENT = "11111111-1111-4111-8111-111111111111";
const OTHER = "22222222-2222-4222-8222-222222222222";
const GUEST = "33333333-3333-4333-8333-333333333333";
const KNOWN = new Set([
  "ios:pl.audiokiddo.sub.yearly",
  "ios:pl.audiokiddo.pack.wyobraznia",
  "android:pl.audiokiddo.sub.monthly",
  "android:pl.audiokiddo.pack.detektyw",
]);

/** Postgres rules in memory: newer signing time wins, events are atomic and deduplicated. */
class FakeStore implements EntitlementStore {
  rows = new Map<string, Grant>();
  events = new Set<string>();
  anonymous = new Set<string>([GUEST]);

  ownerOf(source: Source, txId: string) {
    return Promise.resolve(this.rows.get(`${source}:${txId}`)?.userId ?? null);
  }
  isAnonymous(userId: string) {
    return Promise.resolve(this.anonymous.has(userId));
  }
  upsert(e: Grant) {
    if (!KNOWN.has(e.productRef)) return Promise.reject(new UnknownProductError(e.productRef));
    const key = `${e.source}:${e.txId}`;
    const before = this.rows.get(key);
    if (!before || e.signedAt >= before.signedAt) this.rows.set(key, { ...e });
    return Promise.resolve();
  }
  async applyEvent(eventId: string, _hash: string, change: StoreChange) {
    if (this.events.has(eventId)) return "duplicate" as const;
    const before = this.rows.get(`${change.source}:${change.txId}`);
    if (change.kind === "grant" && !KNOWN.has(change.productRef)) throw new UnknownProductError(change.productRef);
    this.events.add(eventId);
    if (before && change.signedAt < before.signedAt) return "stale" as const;
    if (change.kind === "grant") {
      await this.upsert(change);
    } else if (before) {
      before.status = change.status;
      before.signedAt = change.signedAt;
    }
    return "updated" as const;
  }
}

const now = new Date("2026-09-28T12:00:00Z");
const day = 86_400_000;
const PROD = new Set(["Production"]);

async function apple(environments: ReadonlySet<string> = PROD) {
  const c = await chain();
  const signTx = (tx: Record<string, unknown>) =>
    sign(
      { bundleId: "pl.audiokiddo.app", environment: "Production", signedDate: now.getTime() - day, ...tx },
      c.x5c,
      c.leafKey,
    );
  const store = new FakeStore();
  return { c, signTx, store, ctx: { store, bundleId: "pl.audiokiddo.app", environments, jws: { roots: [c.rootB64] }, now } };
}

Deno.test("apple purchase: verified yearly subscription is granted to the caller", async () => {
  const { signTx, store, ctx } = await apple();
  const tx = await signTx({
    transactionId: "t1",
    originalTransactionId: "o1",
    productId: "pl.audiokiddo.sub.yearly",
    expiresDate: now.getTime() + 300 * day,
  });
  const out = await verifyApplePurchase(ctx, PARENT, tx);
  assertEquals(out.status, "active");
  assertEquals(store.rows.get("app_store:o1")?.userId, PARENT);
});

Deno.test("apple purchase: another app's bundle, unknown product and bad signature are rejected", async () => {
  const { signTx, store, ctx } = await apple();
  const other = await signTx({ originalTransactionId: "o2", productId: "pl.audiokiddo.sub.yearly", bundleId: "com.other" });
  await assertRejects(() => verifyApplePurchase(ctx, PARENT, other), PurchaseRejected, "bundle");
  const unknown = await signTx({ originalTransactionId: "o3", productId: "pl.audiokiddo.free.money" });
  await assertRejects(() => verifyApplePurchase(ctx, PARENT, unknown), PurchaseRejected, "product");
  await assertRejects(() => verifyApplePurchase(ctx, PARENT, "a.b.c"), PurchaseRejected, "signature");
  assertEquals(store.rows.size, 0);
});

Deno.test("apple purchase: a guest's purchase moves to the parent's account after sign-in", async () => {
  const { signTx, store, ctx } = await apple();
  const tx = await signTx({ originalTransactionId: "o4", productId: "pl.audiokiddo.pack.wyobraznia", appAccountToken: GUEST });
  await verifyApplePurchase(ctx, GUEST, tx);
  await verifyApplePurchase(ctx, PARENT, tx);
  assertEquals(store.rows.get("app_store:o4")?.userId, PARENT);
});

Deno.test("apple purchase: the account Apple names may reclaim its purchase", async () => {
  const { signTx, store, ctx } = await apple();
  const tx = await signTx({ originalTransactionId: "o7", productId: "pl.audiokiddo.pack.wyobraznia", appAccountToken: PARENT });
  await verifyApplePurchase(ctx, OTHER, tx); // first seen on another account (e.g. restored there)
  await verifyApplePurchase(ctx, PARENT, tx);
  assertEquals(store.rows.get("app_store:o7")?.userId, PARENT);
});

// ---------------------------------------------------------------- audit regressions (RAPORT P1)

Deno.test("audit P1-1: an old valid transaction does not reactivate a refunded purchase", async () => {
  const { c, signTx, store, ctx } = await apple();
  const old = await signTx({ originalTransactionId: "r1", productId: "pl.audiokiddo.pack.wyobraznia", signedDate: now.getTime() - 3 * day });
  await verifyApplePurchase(ctx, PARENT, old);
  const revoked = await signTx({
    originalTransactionId: "r1",
    productId: "pl.audiokiddo.pack.wyobraznia",
    revocationDate: now.getTime() - day,
    signedDate: now.getTime() - day,
  });
  const refund = await sign(
    { notificationType: "REFUND", notificationUUID: "refund-1", signedDate: now.getTime() - day, data: { bundleId: "pl.audiokiddo.app", signedTransactionInfo: revoked } },
    c.x5c,
    c.leafKey,
  );
  assertEquals(await handleAppleNotification(ctx, refund, "h"), "updated");
  assertEquals(store.rows.get("app_store:r1")?.status, "refunded");
  await verifyApplePurchase(ctx, PARENT, old);
  assertEquals(store.rows.get("app_store:r1")?.status, "refunded", "the replayed old document loses");
});

Deno.test("audit P1-2: Sandbox grants nothing unless configured", async () => {
  const prod = await apple();
  const sandboxTx = await prod.signTx({ originalTransactionId: "s1", productId: "pl.audiokiddo.pack.wyobraznia", environment: "Sandbox" });
  await assertRejects(() => verifyApplePurchase(prod.ctx, PARENT, sandboxTx), PurchaseRejected, "environment");
  assertEquals(prod.store.rows.size, 0);

  const review = await apple(new Set(["Production", "Sandbox"]));
  const tx = await review.signTx({ originalTransactionId: "s2", productId: "pl.audiokiddo.pack.wyobraznia", environment: "Sandbox" });
  assertEquals((await verifyApplePurchase(review.ctx, PARENT, tx)).status, "active");
});

Deno.test("audit P1-3: a replayed old notification changes nothing", async () => {
  const { c, signTx, store, ctx } = await apple();
  await verifyApplePurchase(ctx, PARENT, await signTx({ originalTransactionId: "d1", productId: "pl.audiokiddo.sub.yearly", expiresDate: now.getTime() + day }));
  const renew = await sign(
    {
      notificationType: "DID_RENEW",
      notificationUUID: "old-event",
      signedDate: now.getTime() - day / 2,
      data: { signedTransactionInfo: await signTx({ originalTransactionId: "d1", productId: "pl.audiokiddo.sub.yearly", expiresDate: now.getTime() + day, signedDate: now.getTime() - day / 2 }) },
    },
    c.x5c,
    c.leafKey,
  );
  await handleAppleNotification(ctx, renew, "h");
  // A refund arrives later (newer signing time).
  await store.applyEvent("apple:refund", "h2", { kind: "status", source: "app_store", txId: "d1", status: "refunded", signedAt: now });
  assertEquals(await handleAppleNotification(ctx, renew, "h"), "duplicate");
  assertEquals(store.rows.get("app_store:d1")?.status, "refunded");
});

Deno.test("audit P1-4: another account cannot take over a purchase held by a parent", async () => {
  const { signTx, store, ctx } = await apple();
  const tx = await signTx({ originalTransactionId: "a1", productId: "pl.audiokiddo.pack.wyobraznia", appAccountToken: PARENT });
  await verifyApplePurchase(ctx, PARENT, tx);
  await assertRejects(() => verifyApplePurchase(ctx, OTHER, tx), PurchaseRejected, "account");
  assertEquals(store.rows.get("app_store:a1")?.userId, PARENT);
});

// ---------------------------------------------------------------- notifications

Deno.test("apple notification: refund revokes, redelivery is a duplicate, unknown purchase is ignored", async () => {
  const { c, signTx, store, ctx } = await apple();
  await verifyApplePurchase(ctx, PARENT, await signTx({ originalTransactionId: "o5", productId: "pl.audiokiddo.sub.yearly", expiresDate: now.getTime() + day }));
  const refundTx = await signTx({
    originalTransactionId: "o5",
    productId: "pl.audiokiddo.sub.yearly",
    expiresDate: now.getTime() + day,
    revocationDate: now.getTime() - 1000,
    signedDate: now.getTime() - 1000,
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
  const { c, signTx, store, ctx } = await apple();
  const expired = { originalTransactionId: "o6", productId: "pl.audiokiddo.sub.yearly", expiresDate: now.getTime() - day };
  await verifyApplePurchase(ctx, PARENT, await signTx(expired));
  const renewal = await sign({ gracePeriodExpiresDate: now.getTime() + 5 * day, signedDate: now.getTime() - 1000 }, c.x5c, c.leafKey);
  const note = await sign(
    {
      notificationType: "DID_FAIL_TO_RENEW",
      subtype: "GRACE_PERIOD",
      notificationUUID: "n3",
      signedDate: now.getTime() - 1000,
      data: { signedTransactionInfo: await signTx({ ...expired, signedDate: now.getTime() - 1000 }), signedRenewalInfo: renewal },
    },
    c.x5c,
    c.leafKey,
  );
  await handleAppleNotification(ctx, note, "h3");
  assertEquals(store.rows.get("app_store:o6")?.status, "grace");
});

Deno.test("apple notification: Sandbox events are ignored in production", async () => {
  const { c, signTx, ctx } = await apple();
  const note = await sign(
    {
      notificationType: "DID_RENEW",
      notificationUUID: "n4",
      signedDate: now.getTime(),
      data: { environment: "Sandbox", signedTransactionInfo: await signTx({ originalTransactionId: "x", productId: "pl.audiokiddo.sub.yearly", environment: "Sandbox" }) },
    },
    c.x5c,
    c.leafKey,
  );
  assertEquals(await handleAppleNotification(ctx, note, "h4"), "ignored");
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

Deno.test("google purchase: a token held by a parent cannot be taken by another account", async () => {
  const store = new FakeStore();
  const play = new FakePlay();
  const ctx = { store, play, subscriptionIds: SUBS, now };
  play.products.set("p9", { purchaseState: 0, obfuscatedExternalAccountId: PARENT });
  await verifyGooglePurchase(ctx, PARENT, "pl.audiokiddo.pack.detektyw", "p9");
  await assertRejects(() => verifyGooglePurchase(ctx, OTHER, "pl.audiokiddo.pack.detektyw", "p9"), PurchaseRejected, "account");
});

Deno.test("google notifications: renewal, upgrade replaces the old token, voided purchase is refunded", async () => {
  const store = new FakeStore();
  const play = new FakePlay();
  const earlier = { store, play, subscriptionIds: SUBS, now: new Date(now.getTime() - day) };
  const ctx = { store, play, subscriptionIds: SUBS, now };
  play.products.set("p1", { purchaseState: 0 });
  await verifyGooglePurchase(earlier, PARENT, "pl.audiokiddo.pack.detektyw", "p1");
  play.subs.set("old", { subscriptionState: "SUBSCRIPTION_STATE_ACTIVE", lineItems: [{ productId: "pl.audiokiddo.sub.monthly" }] });
  await verifyGooglePurchase(earlier, PARENT, "pl.audiokiddo.sub.monthly", "old");

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
  assertEquals(await handleGoogleNotification(ctx, "m2", { ...base, voidedPurchaseNotification: { purchaseToken: "p1", orderId: "GPA.1", productType: 2 } }, "h2"), "duplicate");
  assertEquals(await handleGoogleNotification(ctx, "m3", { ...base, packageName: "com.other" }, "h3"), "ignored");
  assertEquals(await handleGoogleNotification(ctx, "m4", { ...base, testNotification: { version: "1.0" } }, "h4"), "ignored");
});

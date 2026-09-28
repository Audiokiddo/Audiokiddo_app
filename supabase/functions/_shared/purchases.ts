// Store purchases → entitlements (ARCHITECTURE §7). Used by verify-purchase (the app sends a
// fresh purchase or a restore) and store-notifications (Apple and Google tell us about
// renewals, refunds, grace periods). The database sits behind EntitlementStore, so the rules
// are tested without Postgres.
import type { SupabaseClient } from "npm:@supabase/supabase-js@2";
import {
  type AppleJwsOptions,
  type AppleNotificationPayload,
  type AppleTransactionPayload,
  verifyAppleJws,
} from "./apple_jws.ts";
import type { DeveloperNotification, GooglePlayClient } from "./google_play.ts";
import {
  type AppleRenewalInfo,
  appleProductRef,
  appleStatus,
  type EntitlementStatus,
  googleOneTimeStatus,
  googleProductRef,
  googleSubscriptionStatus,
} from "./store_status.ts";

export type Source = "app_store" | "google_play";

export interface EntitlementStore {
  /** The account that already holds this store purchase, if any. */
  ownerOf(source: Source, txId: string): Promise<string | null>;
  /** Grants/updates every scope of the product; throws UnknownProductError. */
  upsert(e: {
    userId: string;
    source: Source;
    productRef: string;
    txId: string;
    status: EntitlementStatus;
    validUntil: Date | null;
  }): Promise<void>;
  /** Sets the status of every scope of one purchase (refunds, replaced subscriptions). */
  setStatus(source: Source, txId: string, status: EntitlementStatus): Promise<void>;
  /** false when the event was seen before. */
  recordEvent(eventId: string, source: Source, payloadHash: string): Promise<boolean>;
}

export class UnknownProductError extends Error {}

export class PurchaseRejected extends Error {
  constructor(readonly code: "signature" | "bundle" | "product" | "not_found" | "account") {
    super(code);
  }
}

export interface Outcome {
  status: EntitlementStatus | "pending";
  validUntil: Date | null;
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

async function grant(
  store: EntitlementStore,
  e: Parameters<EntitlementStore["upsert"]>[0],
): Promise<void> {
  try {
    await store.upsert(e);
  } catch (error) {
    if (error instanceof UnknownProductError) throw new PurchaseRejected("product");
    throw error;
  }
}

// ---------------------------------------------------------------- App Store

export interface AppleContext {
  store: EntitlementStore;
  bundleId: string;
  jws?: AppleJwsOptions;
  now?: Date;
}

/** A transaction JWS from the app (StoreKit 2 jwsRepresentation), for the signed-in user. */
export async function verifyApplePurchase(ctx: AppleContext, userId: string, signedTransaction: string): Promise<Outcome> {
  let tx: AppleTransactionPayload;
  try {
    tx = await verifyAppleJws<AppleTransactionPayload>(signedTransaction, ctx.jws);
  } catch {
    throw new PurchaseRejected("signature");
  }
  if (tx.bundleId !== ctx.bundleId) throw new PurchaseRejected("bundle");
  const derived = appleStatus(tx, undefined, ctx.now ?? new Date());
  // A restore on another AudioKiddo account moves the purchase there (ARCHITECTURE §7.5).
  await grant(ctx.store, {
    userId,
    source: "app_store",
    productRef: appleProductRef(tx.productId),
    txId: tx.originalTransactionId,
    status: derived.status,
    validUntil: derived.validUntil,
  });
  return derived;
}

/** App Store Server Notification V2 body: { signedPayload }. Returns what was done. */
export async function handleAppleNotification(
  ctx: AppleContext,
  signedPayload: string,
  payloadHash: string,
): Promise<"updated" | "duplicate" | "ignored"> {
  const note = await verifyAppleJws<AppleNotificationPayload>(signedPayload, ctx.jws);
  if (note.data?.bundleId && note.data.bundleId !== ctx.bundleId) return "ignored";
  const signedTx = note.data?.signedTransactionInfo;
  if (!signedTx) return "ignored"; // TEST, CONSUMPTION_REQUEST, summaries
  const tx = await verifyAppleJws<AppleTransactionPayload>(signedTx, ctx.jws);
  const renewal = note.data?.signedRenewalInfo
    ? await verifyAppleJws<AppleRenewalInfo>(note.data.signedRenewalInfo, ctx.jws)
    : undefined;
  const owner = (await ctx.store.ownerOf("app_store", tx.originalTransactionId)) ??
    (tx.appAccountToken && UUID.test(tx.appAccountToken) ? tx.appAccountToken : null);
  // Not seen yet: the app's verify-purchase call will create it with the right account.
  if (!owner) return "ignored";
  const derived = appleStatus(tx, renewal, ctx.now ?? new Date(), note.notificationType);
  await grant(ctx.store, {
    userId: owner,
    source: "app_store",
    productRef: appleProductRef(tx.productId),
    txId: tx.originalTransactionId,
    status: derived.status,
    validUntil: derived.validUntil,
  });
  // Recorded after the update, so a failed update is retried by Apple.
  return (await ctx.store.recordEvent(`apple:${note.notificationUUID}`, "app_store", payloadHash))
    ? "updated"
    : "duplicate";
}

// ---------------------------------------------------------------- Google Play

export interface GoogleContext {
  store: EntitlementStore;
  play: Pick<GooglePlayClient, "subscription" | "product" | "packageName">;
  subscriptionIds: ReadonlySet<string>;
  now?: Date;
}

async function applyGoogleSubscription(
  ctx: GoogleContext,
  token: string,
  userId: string | null,
): Promise<Outcome | null> {
  const sub = await ctx.play.subscription(token);
  const owner = userId ?? (await ctx.store.ownerOf("google_play", token)) ??
    (sub.externalAccountIdentifiers?.obfuscatedExternalAccountId ?? null);
  const productId = sub.lineItems?.[0]?.productId;
  const derived = googleSubscriptionStatus(sub, ctx.now ?? new Date());
  if (!owner || !productId) return null;
  if (!derived) return { status: "pending", validUntil: null };
  // An upgrade/downgrade replaces the old purchase token.
  if (sub.linkedPurchaseToken) await ctx.store.setStatus("google_play", sub.linkedPurchaseToken, "expired");
  await grant(ctx.store, {
    userId: owner,
    source: "google_play",
    productRef: googleProductRef(productId),
    txId: token,
    status: derived.status,
    validUntil: derived.validUntil,
  });
  return derived;
}

async function applyGoogleProduct(
  ctx: GoogleContext,
  productId: string,
  token: string,
  userId: string | null,
): Promise<Outcome | null> {
  const purchase = await ctx.play.product(productId, token);
  const owner = userId ?? (await ctx.store.ownerOf("google_play", token)) ?? purchase.obfuscatedExternalAccountId ?? null;
  const derived = googleOneTimeStatus(purchase.purchaseState, false);
  if (!owner) return null;
  if (!derived) return { status: "pending", validUntil: null };
  await grant(ctx.store, {
    userId: owner,
    source: "google_play",
    productRef: googleProductRef(productId),
    txId: token,
    status: derived.status,
    validUntil: derived.validUntil,
  });
  return derived;
}

/** A purchase token from the app, for the signed-in user. */
export async function verifyGooglePurchase(
  ctx: GoogleContext,
  userId: string,
  productId: string,
  purchaseToken: string,
): Promise<Outcome> {
  const outcome = ctx.subscriptionIds.has(productId)
    ? await applyGoogleSubscription(ctx, purchaseToken, userId)
    : await applyGoogleProduct(ctx, productId, purchaseToken, userId);
  if (!outcome) throw new PurchaseRejected("not_found");
  return outcome;
}

/** Real-time Developer Notification (already authenticated and decoded). */
export async function handleGoogleNotification(
  ctx: GoogleContext,
  messageId: string,
  n: DeveloperNotification,
  payloadHash: string,
): Promise<"updated" | "duplicate" | "ignored"> {
  if (n.packageName !== ctx.play.packageName) return "ignored";
  let changed = false;
  if (n.subscriptionNotification) {
    changed = (await applyGoogleSubscription(ctx, n.subscriptionNotification.purchaseToken, null)) !== null;
  } else if (n.oneTimeProductNotification) {
    const { sku, purchaseToken } = n.oneTimeProductNotification;
    changed = (await applyGoogleProduct(ctx, sku, purchaseToken, null)) !== null;
  } else if (n.voidedPurchaseNotification) {
    await ctx.store.setStatus("google_play", n.voidedPurchaseNotification.purchaseToken, "refunded");
    changed = true;
  }
  if (!changed) return "ignored";
  return (await ctx.store.recordEvent(`google:${messageId}`, "google_play", payloadHash)) ? "updated" : "duplicate";
}

// ---------------------------------------------------------------- Postgres

export class SupabaseEntitlementStore implements EntitlementStore {
  constructor(private readonly db: SupabaseClient) {}

  async ownerOf(source: Source, txId: string): Promise<string | null> {
    const { data, error } = await this.db
      .from("entitlements")
      .select("user_id")
      .eq("source", source)
      .eq("store_original_tx_id", txId)
      .limit(1)
      .maybeSingle();
    if (error) throw error;
    return (data?.user_id as string | undefined) ?? null;
  }

  async upsert(e: Parameters<EntitlementStore["upsert"]>[0]): Promise<void> {
    const { error } = await this.db.rpc("upsert_entitlement", {
      p_user_id: e.userId,
      p_source: e.source,
      p_product_ref: e.productRef,
      p_tx_id: e.txId,
      p_status: e.status,
      p_valid_until: e.validUntil?.toISOString() ?? null,
    });
    if (error?.code === "P0002") throw new UnknownProductError(e.productRef);
    if (error) throw error;
  }

  async setStatus(source: Source, txId: string, status: EntitlementStatus): Promise<void> {
    const { error } = await this.db
      .from("entitlements")
      .update({ status, updated_at: new Date().toISOString() })
      .eq("source", source)
      .eq("store_original_tx_id", txId);
    if (error) throw error;
  }

  async recordEvent(eventId: string, source: Source, payloadHash: string): Promise<boolean> {
    const { data, error } = await this.db.rpc("record_store_event", {
      p_event_id: eventId,
      p_source: source,
      p_payload_hash: payloadHash,
    });
    if (error) throw error;
    return data === true;
  }
}

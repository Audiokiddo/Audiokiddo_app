// Store purchases → entitlements (ARCHITECTURE §7). Used by verify-purchase (the app sends a
// fresh purchase or a restore) and store-notifications (Apple and Google tell us about
// renewals, refunds, grace periods). The database sits behind EntitlementStore, so the rules
// are tested without Postgres.
//
// Rules added after the audit of 2026-09-28 (docs/audyt-2026-09-28/RAPORT.md):
// - every change carries the time the store signed its document; older never beats newer,
//   so an old valid transaction cannot undo a refund (P1-1);
// - Apple environments are explicit: Sandbox counts only where it is configured (P1-2);
// - a store event is recorded and applied in one database transaction (P1-3);
// - a purchase stays with its account; it moves only from an anonymous holder, or to the
//   account the store itself names (appAccountToken / obfuscatedAccountId) (P1-4).
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

export interface Grant {
  userId: string;
  source: Source;
  productRef: string;
  txId: string;
  status: EntitlementStatus;
  validUntil: Date | null;
  /** When the store signed (or we fetched) the document this state comes from. */
  signedAt: Date;
}

/** A store event: either a full grant or a status change of an existing purchase. */
export type StoreChange =
  | ({ kind: "grant" } & Grant)
  | { kind: "status"; source: Source; txId: string; status: EntitlementStatus; signedAt: Date };

export interface EntitlementStore {
  /** The account that already holds this store purchase, if any. */
  ownerOf(source: Source, txId: string): Promise<string | null>;
  /** Anonymous purchase holders (no parent account yet) may hand purchases over. */
  isAnonymous(userId: string): Promise<boolean>;
  /** Grants/updates every scope of the product unless newer state exists; throws UnknownProductError. */
  upsert(e: Grant): Promise<void>;
  /** Records the event and applies the change atomically. */
  applyEvent(
    eventId: string,
    payloadHash: string,
    change: StoreChange,
  ): Promise<"updated" | "duplicate" | "stale">;
}

export class UnknownProductError extends Error {}

export class PurchaseRejected extends Error {
  constructor(readonly code: "signature" | "bundle" | "environment" | "product" | "not_found" | "account") {
    super(code);
  }
}

export interface Outcome {
  status: EntitlementStatus | "pending";
  validUntil: Date | null;
}

const UUID = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

async function grant(store: EntitlementStore, e: Grant): Promise<void> {
  try {
    await store.upsert(e);
  } catch (error) {
    if (error instanceof UnknownProductError) throw new PurchaseRejected("product");
    throw error;
  }
}

/**
 * Who may hold a purchase the caller presents. First verification: the caller. Afterwards
 * the purchase stays with its account, except when the store itself names the caller
 * ([storeAccount]) or when the current holder is anonymous (reinstall, or the parent signed
 * in after buying as a guest).
 */
async function ownerFor(
  store: EntitlementStore,
  source: Source,
  txId: string,
  caller: string,
  storeAccount?: string,
): Promise<string> {
  const current = await store.ownerOf(source, txId);
  if (current === null || current === caller) return caller;
  if (storeAccount && storeAccount === caller) return caller;
  if (await store.isAnonymous(current)) return caller;
  throw new PurchaseRejected("account");
}

// ---------------------------------------------------------------- App Store

export interface AppleContext {
  store: EntitlementStore;
  bundleId: string;
  /** Apple environments that grant access, e.g. {"Production"} or {"Production", "Sandbox"}. */
  environments: ReadonlySet<string>;
  jws?: AppleJwsOptions;
  now?: Date;
}

/** APPLE_ENVIRONMENTS, comma separated; Production only unless configured otherwise. */
export function appleEnvironmentsFrom(value: string | undefined): Set<string> {
  const list = (value ?? "Production").split(",").map((s) => s.trim()).filter(Boolean);
  return new Set(list.length ? list : ["Production"]);
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
  if (!ctx.environments.has(tx.environment)) throw new PurchaseRejected("environment");
  const now = ctx.now ?? new Date();
  const token = tx.appAccountToken && UUID.test(tx.appAccountToken) ? tx.appAccountToken.toLowerCase() : undefined;
  const owner = await ownerFor(ctx.store, "app_store", tx.originalTransactionId, userId, token);
  const derived = appleStatus(tx, undefined, now);
  await grant(ctx.store, {
    userId: owner,
    source: "app_store",
    productRef: appleProductRef(tx.productId),
    txId: tx.originalTransactionId,
    status: derived.status,
    validUntil: derived.validUntil,
    // A replayed old document carries its old signing time and loses to anything newer.
    signedAt: new Date(tx.signedDate ?? now.getTime()),
  });
  return derived;
}

/** App Store Server Notification V2 body: { signedPayload }. Returns what was done. */
export async function handleAppleNotification(
  ctx: AppleContext,
  signedPayload: string,
  payloadHash: string,
): Promise<"updated" | "duplicate" | "stale" | "ignored"> {
  const note = await verifyAppleJws<AppleNotificationPayload>(signedPayload, ctx.jws);
  if (note.data?.bundleId && note.data.bundleId !== ctx.bundleId) return "ignored";
  if (note.data?.environment && !ctx.environments.has(note.data.environment)) return "ignored";
  const signedTx = note.data?.signedTransactionInfo;
  if (!signedTx) return "ignored"; // TEST, CONSUMPTION_REQUEST, summaries
  const tx = await verifyAppleJws<AppleTransactionPayload>(signedTx, ctx.jws);
  if (!ctx.environments.has(tx.environment)) return "ignored";
  const renewal = note.data?.signedRenewalInfo
    ? await verifyAppleJws<AppleRenewalInfo>(note.data.signedRenewalInfo, ctx.jws)
    : undefined;
  const owner = (await ctx.store.ownerOf("app_store", tx.originalTransactionId)) ??
    (tx.appAccountToken && UUID.test(tx.appAccountToken) ? tx.appAccountToken.toLowerCase() : null);
  // Not seen yet: the app's verify-purchase call will create it with the right account.
  if (!owner) return "ignored";
  const now = ctx.now ?? new Date();
  const derived = appleStatus(tx, renewal, now, note.notificationType);
  try {
    return await ctx.store.applyEvent(`apple:${note.notificationUUID}`, payloadHash, {
      kind: "grant",
      userId: owner,
      source: "app_store",
      productRef: appleProductRef(tx.productId),
      txId: tx.originalTransactionId,
      status: derived.status,
      validUntil: derived.validUntil,
      signedAt: new Date(note.signedDate ?? tx.signedDate ?? now.getTime()),
    });
  } catch (error) {
    if (error instanceof UnknownProductError) return "ignored";
    throw error;
  }
}

// ---------------------------------------------------------------- Google Play

export interface GoogleContext {
  store: EntitlementStore;
  play: Pick<GooglePlayClient, "subscription" | "product" | "packageName">;
  subscriptionIds: ReadonlySet<string>;
  now?: Date;
}

// Google answers with the live state, so its documents are as new as the moment we fetch.

/** A purchase token from the app, for the signed-in user. */
export async function verifyGooglePurchase(
  ctx: GoogleContext,
  userId: string,
  productId: string,
  purchaseToken: string,
): Promise<Outcome> {
  const now = ctx.now ?? new Date();
  if (ctx.subscriptionIds.has(productId)) {
    const sub = await ctx.play.subscription(purchaseToken);
    const lineProduct = sub.lineItems?.[0]?.productId;
    if (!lineProduct) throw new PurchaseRejected("not_found");
    const derived = googleSubscriptionStatus(sub, now);
    if (!derived) return { status: "pending", validUntil: null };
    const owner = await ownerFor(
      ctx.store,
      "google_play",
      purchaseToken,
      userId,
      sub.externalAccountIdentifiers?.obfuscatedExternalAccountId,
    );
    if (sub.linkedPurchaseToken) {
      await ctx.store.applyEvent(`google:linked:${purchaseToken}`, "linked", {
        kind: "status",
        source: "google_play",
        txId: sub.linkedPurchaseToken,
        status: "expired",
        signedAt: now,
      });
    }
    await grant(ctx.store, {
      userId: owner,
      source: "google_play",
      productRef: googleProductRef(lineProduct),
      txId: purchaseToken,
      status: derived.status,
      validUntil: derived.validUntil,
      signedAt: now,
    });
    return derived;
  }
  const purchase = await ctx.play.product(productId, purchaseToken);
  const derived = googleOneTimeStatus(purchase.purchaseState, false);
  if (!derived) return { status: "pending", validUntil: null };
  const owner = await ownerFor(ctx.store, "google_play", purchaseToken, userId, purchase.obfuscatedExternalAccountId);
  await grant(ctx.store, {
    userId: owner,
    source: "google_play",
    productRef: googleProductRef(productId),
    txId: purchaseToken,
    status: derived.status,
    validUntil: derived.validUntil,
    signedAt: now,
  });
  return derived;
}

/** Real-time Developer Notification (already authenticated and decoded). */
export async function handleGoogleNotification(
  ctx: GoogleContext,
  messageId: string,
  n: DeveloperNotification,
  payloadHash: string,
): Promise<"updated" | "duplicate" | "stale" | "ignored"> {
  if (n.packageName !== ctx.play.packageName) return "ignored";
  const now = ctx.now ?? new Date();
  const eventId = `google:${messageId}`;
  let change: StoreChange | null = null;

  if (n.subscriptionNotification) {
    const token = n.subscriptionNotification.purchaseToken;
    const sub = await ctx.play.subscription(token);
    const productId = sub.lineItems?.[0]?.productId;
    const derived = googleSubscriptionStatus(sub, now);
    const owner = (await ctx.store.ownerOf("google_play", token)) ??
      sub.externalAccountIdentifiers?.obfuscatedExternalAccountId ?? null;
    if (!owner || !productId || !derived) return "ignored";
    if (sub.linkedPurchaseToken) {
      await ctx.store.applyEvent(`${eventId}:linked`, payloadHash, {
        kind: "status",
        source: "google_play",
        txId: sub.linkedPurchaseToken,
        status: "expired",
        signedAt: now,
      });
    }
    change = {
      kind: "grant",
      userId: owner,
      source: "google_play",
      productRef: googleProductRef(productId),
      txId: token,
      status: derived.status,
      validUntil: derived.validUntil,
      signedAt: now,
    };
  } else if (n.oneTimeProductNotification) {
    const { sku, purchaseToken } = n.oneTimeProductNotification;
    const purchase = await ctx.play.product(sku, purchaseToken);
    const derived = googleOneTimeStatus(purchase.purchaseState, false);
    const owner = (await ctx.store.ownerOf("google_play", purchaseToken)) ?? purchase.obfuscatedExternalAccountId ?? null;
    if (!owner || !derived) return "ignored";
    change = {
      kind: "grant",
      userId: owner,
      source: "google_play",
      productRef: googleProductRef(sku),
      txId: purchaseToken,
      status: derived.status,
      validUntil: derived.validUntil,
      signedAt: now,
    };
  } else if (n.voidedPurchaseNotification) {
    change = {
      kind: "status",
      source: "google_play",
      txId: n.voidedPurchaseNotification.purchaseToken,
      status: "refunded",
      signedAt: now,
    };
  }
  if (!change) return "ignored";
  try {
    return await ctx.store.applyEvent(eventId, payloadHash, change);
  } catch (error) {
    if (error instanceof UnknownProductError) return "ignored";
    throw error;
  }
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

  async isAnonymous(userId: string): Promise<boolean> {
    const { data, error } = await this.db.rpc("is_anonymous_user", { p_user_id: userId });
    if (error) throw error;
    return data === true;
  }

  async upsert(e: Grant): Promise<void> {
    const { error } = await this.db.rpc("upsert_entitlement", {
      p_user_id: e.userId,
      p_source: e.source,
      p_product_ref: e.productRef,
      p_tx_id: e.txId,
      p_status: e.status,
      p_valid_until: e.validUntil?.toISOString() ?? null,
      p_signed_at: e.signedAt.toISOString(),
    });
    if (error?.code === "P0002") throw new UnknownProductError(e.productRef);
    if (error) throw error;
  }

  async applyEvent(eventId: string, payloadHash: string, change: StoreChange): Promise<"updated" | "duplicate" | "stale"> {
    const { data, error } = await this.db.rpc("apply_store_event", {
      p_event_id: eventId,
      p_source: change.source,
      p_payload_hash: payloadHash,
      p_tx_id: change.txId,
      p_status: change.status,
      p_signed_at: change.signedAt.toISOString(),
      ...(change.kind === "grant"
        ? {
          p_user_id: change.userId,
          p_product_ref: change.productRef,
          p_valid_until: change.validUntil?.toISOString() ?? null,
        }
        : {}),
    });
    if (error?.code === "P0002" && change.kind === "grant") throw new UnknownProductError(change.productRef);
    if (error) throw error;
    return data as "updated" | "duplicate" | "stale";
  }
}

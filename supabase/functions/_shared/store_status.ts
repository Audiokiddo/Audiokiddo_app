// Store purchase state → entitlement status (ARCHITECTURE §7).
//
// The status is always derived from the authoritative purchase record (decoded App Store
// transaction + renewal info, Google Play Developer API response), never from the
// notification type alone. Field names follow Apple's App Store Server API and Google's
// purchases.subscriptionsv2 / purchases.products resources.
// TODO(Etap 3, with store accounts): verify against sandbox payloads.

export type EntitlementStatus = "active" | "grace" | "billing_retry" | "expired" | "revoked" | "refunded";

export interface Derived {
  status: EntitlementStatus;
  validUntil: Date | null;
}

/** Subset of Apple's JWSTransactionDecodedPayload. Dates are milliseconds since epoch. */
export interface AppleTransaction {
  originalTransactionId: string;
  productId: string;
  expiresDate?: number;
  revocationDate?: number;
  appAccountToken?: string;
}

/** Subset of Apple's JWSRenewalInfoDecodedPayload. */
export interface AppleRenewalInfo {
  gracePeriodExpiresDate?: number;
  isInBillingRetryPeriod?: boolean;
}

export function appleStatus(
  tx: AppleTransaction,
  renewal: AppleRenewalInfo | undefined,
  now: Date,
  notificationType?: string,
): Derived {
  if (tx.revocationDate) {
    // REVOKE = removed from Family Sharing; any other revocation is a refund.
    return { status: notificationType === "REVOKE" ? "revoked" : "refunded", validUntil: null };
  }
  if (tx.expiresDate === undefined) return { status: "active", validUntil: null }; // one-time purchase
  const expires = new Date(tx.expiresDate);
  if (expires > now) return { status: "active", validUntil: expires };
  if (renewal?.gracePeriodExpiresDate && new Date(renewal.gracePeriodExpiresDate) > now) {
    return { status: "grace", validUntil: new Date(renewal.gracePeriodExpiresDate) };
  }
  if (renewal?.isInBillingRetryPeriod) return { status: "billing_retry", validUntil: expires };
  return { status: "expired", validUntil: expires };
}

/** Subset of Google's SubscriptionPurchaseV2. */
export interface GoogleSubscription {
  subscriptionState: string;
  lineItems?: { productId: string; expiryTime?: string }[];
}

/** null = no entitlement yet (pending purchase). */
export function googleSubscriptionStatus(sub: GoogleSubscription, now: Date): Derived | null {
  const expiries = (sub.lineItems ?? [])
    .map((l) => (l.expiryTime ? new Date(l.expiryTime) : null))
    .filter((d): d is Date => d !== null);
  const validUntil = expiries.length ? new Date(Math.max(...expiries.map((d) => d.getTime()))) : null;
  switch (sub.subscriptionState) {
    case "SUBSCRIPTION_STATE_ACTIVE":
      return { status: "active", validUntil };
    case "SUBSCRIPTION_STATE_CANCELED":
      // Auto-renew switched off: access continues until the paid period ends.
      return { status: validUntil && validUntil > now ? "active" : "expired", validUntil };
    case "SUBSCRIPTION_STATE_IN_GRACE_PERIOD":
      return { status: "grace", validUntil };
    case "SUBSCRIPTION_STATE_ON_HOLD":
      return { status: "billing_retry", validUntil };
    case "SUBSCRIPTION_STATE_PAUSED":
    case "SUBSCRIPTION_STATE_EXPIRED":
      return { status: "expired", validUntil };
    default:
      return null; // PENDING, PENDING_PURCHASE_CANCELED, unknown
  }
}

/** Google purchases.products: purchaseState 0 = purchased, 1 = canceled, 2 = pending. */
export function googleOneTimeStatus(purchaseState: number, voided: boolean): Derived | null {
  if (voided) return { status: "refunded", validUntil: null };
  if (purchaseState === 0) return { status: "active", validUntil: null };
  if (purchaseState === 1) return { status: "revoked", validUntil: null };
  return null;
}

/** store_products keys for store purchases. */
export const appleProductRef = (productId: string) => `ios:${productId}`;
export const googleProductRef = (productId: string) => `android:${productId}`;

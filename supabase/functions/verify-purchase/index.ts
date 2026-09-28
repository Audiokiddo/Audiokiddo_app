// The app sends a fresh or restored store purchase; we verify it with the store and record
// the entitlement. Only then does the app acknowledge the purchase (ARCHITECTURE §7.3).
// Body: { platform: "ios", signedTransaction } | { platform: "android", productId, purchaseToken }
// Secrets: APPLE_BUNDLE_ID, APPLE_ENVIRONMENTS ("Production" by default; add "Sandbox" for
// TestFlight and App Review), GOOGLE_SERVICE_ACCOUNT_JSON, GOOGLE_PACKAGE_NAME (+ Supabase ones).
import { adminClient, json, requestUser } from "../_shared/supabase.ts";
import { googlePlayFromEnv } from "../_shared/google_play.ts";
import {
  appleEnvironmentsFrom,
  PurchaseRejected,
  SupabaseEntitlementStore,
  verifyApplePurchase,
  verifyGooglePurchase,
} from "../_shared/purchases.ts";

const SUBSCRIPTIONS = new Set(["pl.audiokiddo.sub.monthly", "pl.audiokiddo.sub.yearly"]);

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method" }, 405);
  const admin = adminClient();
  // Signed in or anonymous (created by the app before the purchase); never without a user.
  const user = await requestUser(req, admin);
  if (!user) return json({ error: "auth" }, 401);

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json({ error: "body" }, 400);
  }
  const store = new SupabaseEntitlementStore(admin);
  try {
    if (body.platform === "ios" && typeof body.signedTransaction === "string") {
      const outcome = await verifyApplePurchase(
        {
          store,
          bundleId: Deno.env.get("APPLE_BUNDLE_ID") ?? "pl.audiokiddo.app",
          environments: appleEnvironmentsFrom(Deno.env.get("APPLE_ENVIRONMENTS")),
        },
        user.id,
        body.signedTransaction,
      );
      return json({ ok: true, ...outcome });
    }
    if (body.platform === "android" && typeof body.productId === "string" && typeof body.purchaseToken === "string") {
      const outcome = await verifyGooglePurchase(
        { store, play: googlePlayFromEnv(), subscriptionIds: SUBSCRIPTIONS },
        user.id,
        body.productId,
        body.purchaseToken,
      );
      return json({ ok: true, ...outcome });
    }
    return json({ error: "body" }, 400);
  } catch (error) {
    if (error instanceof PurchaseRejected) return json({ error: error.code }, 422);
    // Store or database hiccup: the app keeps the purchase unacknowledged and retries.
    console.error("verify-purchase:", error);
    return json({ error: "retry" }, 503);
  }
});

// The app sends a fresh or restored store purchase; we verify it with the store and record
// the entitlement. Only then does the app acknowledge the purchase (ARCHITECTURE §7.3).
// Body: { platform: "ios", signedTransaction } | { platform: "android", productId, purchaseToken }
// Secrets: APPLE_BUNDLE_ID, APPLE_ENVIRONMENTS ("Production" by default; add "Sandbox" for
// TestFlight and App Review), GOOGLE_SERVICE_ACCOUNT_JSON, GOOGLE_PACKAGE_NAME (+ Supabase ones).
// Every outcome is logged as one JSON line (Supabase → Edge Functions → verify-purchase → Logs),
// without the transaction or token themselves.
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

type Stage = "setup" | "auth" | "body" | "verify";

function log(level: "info" | "warn" | "error", fields: Record<string, unknown>) {
  const line = JSON.stringify({ fn: "verify-purchase", level, ...fields });
  if (level === "error") console.error(line);
  else if (level === "warn") console.warn(line);
  else console.log(line);
}

function describe(error: unknown): Record<string, unknown> {
  if (error instanceof Error) {
    return { error: error.name, message: error.message.slice(0, 300), status: (error as { status?: number }).status };
  }
  return { error: "unknown", message: String(error).slice(0, 300) };
}

Deno.serve(async (req) => {
  const requestId = crypto.randomUUID().slice(0, 8);
  const started = Date.now();
  let stage: Stage = "setup";
  const ctx: Record<string, unknown> = { requestId };
  try {
    if (req.method !== "POST") return json({ error: "method" }, 405);
    const admin = adminClient();

    stage = "auth";
    // Signed in or anonymous (created by the app before the purchase); never without a user.
    const user = await requestUser(req, admin);
    if (!user) {
      log("warn", { ...ctx, stage, outcome: "auth", hasBearer: req.headers.has("Authorization") });
      return json({ error: "auth" }, 401);
    }
    ctx.user = user.id;
    ctx.anonymous = user.is_anonymous ?? null;

    stage = "body";
    let body: Record<string, unknown>;
    try {
      body = await req.json();
    } catch {
      log("warn", { ...ctx, stage, outcome: "body", reason: "not json" });
      return json({ error: "body" }, 400);
    }
    ctx.platform = body.platform;
    ctx.product = typeof body.productId === "string" ? body.productId : undefined;

    stage = "verify";
    const store = new SupabaseEntitlementStore(admin);
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
      log("info", { ...ctx, stage, outcome: "ok", ms: Date.now() - started, ...outcome });
      return json({ ok: true, ...outcome });
    }
    if (body.platform === "android" && typeof body.productId === "string" && typeof body.purchaseToken === "string") {
      const outcome = await verifyGooglePurchase(
        { store, play: googlePlayFromEnv(), subscriptionIds: SUBSCRIPTIONS },
        user.id,
        body.productId,
        body.purchaseToken,
      );
      log("info", { ...ctx, stage, outcome: "ok", ms: Date.now() - started, ...outcome });
      return json({ ok: true, ...outcome });
    }
    log("warn", { ...ctx, stage: "body", outcome: "body", reason: "missing fields", keys: Object.keys(body) });
    return json({ error: "body" }, 400);
  } catch (error) {
    if (error instanceof PurchaseRejected) {
      // The store says this purchase is not valid for us (wrong bundle, sandbox in production,
      // unknown product, someone else's account…): the app shows the error and does not retry.
      log("warn", { ...ctx, stage, outcome: "rejected", code: error.code, ms: Date.now() - started });
      return json({ error: error.code }, 422);
    }
    // Missing secret, store or database hiccup: the app keeps the purchase unacknowledged and retries.
    log("error", { ...ctx, stage, outcome: "retry", ms: Date.now() - started, ...describe(error) });
    return json({ error: "retry" }, 503);
  }
});

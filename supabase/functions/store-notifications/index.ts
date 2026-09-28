// Store notifications: App Store Server Notifications V2 at …/store-notifications/apple and
// Google Real-time Developer Notifications (Pub/Sub push) at …/store-notifications/google.
// Every event is verified (Apple: signed JWS chain to Apple's root; Google: OIDC token of our
// push subscription), applied from the store's own record, and recorded for idempotency.
// Secrets: APPLE_BUNDLE_ID, APPLE_ENVIRONMENTS ("Production" by default; add "Sandbox" for
// TestFlight and App Review), GOOGLE_SERVICE_ACCOUNT_JSON, GOOGLE_PACKAGE_NAME,
// GOOGLE_PUBSUB_AUDIENCE, GOOGLE_PUBSUB_EMAIL (+ Supabase ones).
import { adminClient, env, json } from "../_shared/supabase.ts";
import { sha256Hex } from "../_shared/woo.ts";
import { googlePlayFromEnv, parsePubSubPush, verifyPubSubToken } from "../_shared/google_play.ts";
import { appleEnvironmentsFrom, handleAppleNotification, handleGoogleNotification, SupabaseEntitlementStore } from "../_shared/purchases.ts";
import { AppleJwsError } from "../_shared/apple_jws.ts";

const SUBSCRIPTIONS = new Set(["pl.audiokiddo.sub.monthly", "pl.audiokiddo.sub.yearly"]);

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method" }, 405);
  const path = new URL(req.url).pathname;
  const raw = await req.text();
  const hash = await sha256Hex(raw);
  const store = new SupabaseEntitlementStore(adminClient());

  try {
    if (path.endsWith("/apple")) {
      const signedPayload = (JSON.parse(raw) as { signedPayload?: string }).signedPayload;
      if (!signedPayload) return json({ error: "body" }, 400);
      const result = await handleAppleNotification(
        {
          store,
          bundleId: Deno.env.get("APPLE_BUNDLE_ID") ?? "pl.audiokiddo.app",
          environments: appleEnvironmentsFrom(Deno.env.get("APPLE_ENVIRONMENTS")),
        },
        signedPayload,
        hash,
      );
      return json({ ok: true, result });
    }
    if (path.endsWith("/google")) {
      const trusted = await verifyPubSubToken(
        req.headers.get("authorization"),
        env("GOOGLE_PUBSUB_AUDIENCE"),
        env("GOOGLE_PUBSUB_EMAIL"),
      );
      if (!trusted) return json({ error: "auth" }, 401);
      const push = parsePubSubPush(JSON.parse(raw));
      if (!push) return json({ ok: true, result: "ignored" }); // ack, nothing to do
      const result = await handleGoogleNotification(
        { store, play: googlePlayFromEnv(), subscriptionIds: SUBSCRIPTIONS },
        push.messageId,
        push.notification,
        hash,
      );
      return json({ ok: true, result });
    }
    return json({ error: "path" }, 404);
  } catch (error) {
    if (error instanceof AppleJwsError) {
      console.warn("store-notifications: rejected Apple payload:", error.message);
      return json({ error: "signature" }, 401);
    }
    // Apple and Pub/Sub retry on errors.
    console.error("store-notifications:", error);
    return json({ error: "retry" }, 500);
  }
});

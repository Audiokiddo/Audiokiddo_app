// WooCommerce webhook (topic `order.updated`) from audiokiddo.pl.
// Secrets: WOO_WEBHOOK_SECRET, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY.
import { isWooPing, parseWooOrder, sha256Hex, verifyWooSignature } from "../_shared/woo.ts";
import { adminClient, env, json } from "../_shared/supabase.ts";

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method" }, 405);
  const raw = await req.text();
  const signature = req.headers.get("x-wc-webhook-signature");
  if (isWooPing(raw, signature)) return json({ ok: true, ignored: "ping" });
  if (!signature) {
    console.warn("woo-webhook: missing signature header");
    return json({ error: "signature" }, 401);
  }
  if (!(await verifyWooSignature(raw, env("WOO_WEBHOOK_SECRET"), signature))) {
    console.warn("woo-webhook: signature mismatch (WOO_WEBHOOK_SECRET differs from the shop's webhook secret)");
    return json({ error: "signature" }, 401);
  }

  let payload: unknown;
  try {
    payload = JSON.parse(raw);
  } catch {
    return json({ ok: true, ignored: "not json" });
  }
  const order = parseWooOrder(payload);
  if (!order) return json({ ok: true, ignored: "status" });

  const admin = adminClient();
  const hash = await sha256Hex(raw);
  const delivery = req.headers.get("x-wc-webhook-delivery-id") ?? hash;
  const { data: isNew, error: eventError } = await admin.rpc("record_store_event", {
    p_event_id: `woo:${delivery}`,
    p_source: "woocommerce",
    p_payload_hash: hash,
  });
  if (eventError) return json({ error: "event" }, 500); // WooCommerce retries
  if (!isNew) return json({ ok: true, duplicate: true });

  const rows = order.productRefs.map((product_ref) => ({
    woo_order_id: order.orderId,
    product_ref,
    email_normalized: order.email,
    order_status: order.status,
  }));
  if (rows.length) {
    const { error } = await admin.from("web_purchases_pending").upsert(rows);
    if (error) return json({ error: "store" }, 500);
  }

  // Buyer already has an app account with this confirmed e-mail: apply now (grant or revoke).
  const { data: userId } = await admin.rpc("user_id_for_email", { p_email: order.email });
  if (userId) {
    const { error } = await admin.rpc("claim_web_purchases", { p_user_id: userId, p_email: order.email });
    if (error) return json({ error: "claim" }, 500);
  }
  return json({ ok: true });
});

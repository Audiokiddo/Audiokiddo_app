// WooCommerce webhook (topic `order.updated`) from audiokiddo.pl.
// Secrets: WOO_WEBHOOK_SECRET, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY; for the buyers'
// newsletter (only with the checkout consent): MAILERLITE_API_KEY, MAILERLITE_BUYERS_GROUP.
import { buyerSubscriber, isWooPing, parseWooOrder, sha256Hex, verifyWooSignature, type WooOrder } from "../_shared/woo.ts";
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

  // One database transaction: the event mark, the order rows and (when the buyer already has
  // an account) the entitlements. A failure rolls everything back, so WooCommerce's retry
  // is processed again instead of being ignored as a duplicate (audit P1-5).
  const hash = await sha256Hex(raw);
  const delivery = req.headers.get("x-wc-webhook-delivery-id") ?? hash;
  const { data: result, error } = await adminClient().rpc("apply_woo_order", {
    p_event_id: `woo:${delivery}`,
    p_payload_hash: hash,
    p_order_id: order.orderId,
    p_email: order.email,
    p_status: order.status,
    p_product_refs: order.productRefs,
  });
  if (error) {
    console.error("woo-webhook: apply_woo_order failed:", error.message);
    return json({ error: "store" }, 500); // WooCommerce retries
  }
  await addBuyerToNewsletter(order);
  return json({ ok: true, result });
});

/** A completed order whose buyer ticked the newsletter consent joins the buyers' group in
 * MailerLite. Never fails the webhook: the order matters more than the letter. */
async function addBuyerToNewsletter(order: WooOrder) {
  const key = Deno.env.get("MAILERLITE_API_KEY");
  const group = Deno.env.get("MAILERLITE_BUYERS_GROUP");
  if (order.status !== "completed" || !order.newsletter || !key || !group) return;
  try {
    const r = await fetch("https://connect.mailerlite.com/api/subscribers", {
      method: "POST",
      headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json", Accept: "application/json" },
      body: JSON.stringify(buyerSubscriber(order, group)),
      signal: AbortSignal.timeout(10_000),
    });
    if (!r.ok) console.error("woo-webhook: mailerlite", r.status, (await r.text()).slice(0, 300));
  } catch (e) {
    console.error("woo-webhook: mailerlite", e);
  }
}

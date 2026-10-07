// WooCommerce webhook (topic `order.updated`) from audiokiddo.pl.
// Secrets: WOO_WEBHOOK_SECRET, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY; for gift products also
// WOO_URL, WOO_WRITE_KEY, WOO_WRITE_SECRET (a read/write REST key) and GIFT_CODE_SECRET.
import { giftCode, giftNote } from "../_shared/gifts.ts";
import { hashCode } from "../_shared/codes.ts";
import { isWooPing, parseWooOrder, sha256Hex, verifyWooSignature, wooAddCustomerNote, type WooOrder } from "../_shared/woo.ts";
import { adminClient, env, json } from "../_shared/supabase.ts";

/**
 * Gift lines of a paid order get a code e-mailed to the buyer (as a customer note); a refund
 * or cancellation ends them. False when a note could not be sent (WooCommerce then retries).
 */
async function handleGifts(order: WooOrder): Promise<boolean> {
  const admin = adminClient();
  if (order.status !== "completed") {
    const { error } = await admin.rpc("revoke_gift_codes", { p_order_id: order.orderId });
    if (error) console.error("woo-webhook: revoke_gift_codes failed:", error.message);
    return !error;
  }
  const { data: gifts } = await admin.from("gift_products").select("product_ref, label").in("product_ref", order.productRefs);
  let ok = true;
  for (const gift of gifts ?? []) {
    const secret = Deno.env.get("GIFT_CODE_SECRET") ?? env("WOO_WEBHOOK_SECRET");
    const code = await giftCode(secret, order.orderId, gift.product_ref);
    const { data: state, error } = await admin.rpc("issue_gift_code", {
      p_order_id: order.orderId,
      p_product_ref: gift.product_ref,
      p_code_hash: await hashCode(code),
    });
    if (error) {
      console.error("woo-webhook: issue_gift_code failed:", error.message);
      ok = false;
      continue;
    }
    if (state !== "send") continue;
    const key = Deno.env.get("WOO_WRITE_KEY"), keySecret = Deno.env.get("WOO_WRITE_SECRET");
    if (!key || !keySecret) {
      console.error("woo-webhook: gift code issued but WOO_WRITE_KEY / WOO_WRITE_SECRET are not set");
      ok = false;
      continue;
    }
    if (await wooAddCustomerNote(env("WOO_URL"), key, keySecret, order.orderId, giftNote(code, gift.label))) {
      await admin.rpc("mark_gift_note_sent", { p_order_id: order.orderId, p_product_ref: gift.product_ref });
    } else {
      console.error(`woo-webhook: gift note for order ${order.orderId} not accepted by the shop`);
      ok = false;
    }
  }
  return ok;
}

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
  // After the order itself: a retry finds it applied and only finishes the gifts.
  if (!(await handleGifts(order))) return json({ error: "gift" }, 500);
  return json({ ok: true, result });
});

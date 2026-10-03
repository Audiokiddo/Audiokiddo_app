// Adds the packs of one shop order to the signed-in account, for buyers whose shop e-mail is not
// the one they use in the app (or who bought as a guest): the order number plus the billing
// e-mail of that order prove it is theirs. Auth: the signed-in user, anonymous included.
// Body: { order, email }. Answer: { status } = ok | taken | not_paid | nothing | not_found |
// rate_limited | format. A wrong pair always answers not_found (nothing about orders leaks).
// Secrets: WOO_URL, WOO_CONSUMER_KEY, WOO_CONSUMER_SECRET (read-only).
import { normalizeEmail, parseWooOrder, wooGet } from "../_shared/woo.ts";
import { adminClient, env, json, requestUser } from "../_shared/supabase.ts";

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method" }, 405);
  const admin = adminClient();
  const user = await requestUser(req, admin);
  if (!user) return json({ error: "unauthorized" }, 401);
  let body: { order?: unknown; email?: unknown };
  try {
    body = await req.json();
  } catch {
    return json({ error: "body" }, 400);
  }
  const orderId = Number(String(body.order ?? "").replace(/^#/, "").trim());
  const email = typeof body.email === "string" ? normalizeEmail(body.email) : "";
  if (!Number.isInteger(orderId) || orderId < 1 || orderId > 2_000_000_000 || !/^[^@\s]{1,64}@[^@\s]+\.[^@\s]{2,}$/.test(email) || email.length > 254) {
    return json({ status: "format" });
  }

  const { data: limited } = await admin.rpc("claim_rate_limited", { p_user_id: user.id });
  if (limited === true) return json({ status: "rate_limited" });

  const response = await wooGet(env("WOO_URL"), env("WOO_CONSUMER_KEY"), env("WOO_CONSUMER_SECRET"), `/wp-json/wc/v3/orders/${orderId}`);
  if (response.status === 404) {
    await admin.rpc("note_claim_failure", { p_user_id: user.id, p_kind: "order" });
    return json({ status: "not_found" });
  }
  if (!response.ok) {
    console.warn(`claim-order: shop answered ${response.status}`);
    return json({ error: "shop" }, 502);
  }
  const order = (await response.json()) as Record<string, unknown>;
  const billing = order.billing as Record<string, unknown> | undefined;
  if (typeof billing?.email !== "string" || normalizeEmail(billing.email) !== email) {
    await admin.rpc("note_claim_failure", { p_user_id: user.id, p_kind: "order" });
    return json({ status: "not_found" });
  }
  const status = String(order.status);
  const parsed = parseWooOrder(order);
  if (!parsed) return json({ status: "not_paid" }); // processing, on hold, pending…
  const { data, error } = await admin.rpc("claim_order", {
    p_user_id: user.id,
    p_order_id: orderId,
    p_email: email,
    p_status: status,
    p_product_refs: parsed.productRefs,
  });
  if (error) {
    console.error("claim-order:", error.message);
    return json({ error: "retry" }, 503);
  }
  return json({ status: data });
});

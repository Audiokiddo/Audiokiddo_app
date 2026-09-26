// Called by the app after the parent signs in with the e-mail used on audiokiddo.pl.
// Fetches that e-mail's shop orders (read-only REST key) and grants them (ARCHITECTURE §7a).
// Secrets: WOO_URL, WOO_CONSUMER_KEY, WOO_CONSUMER_SECRET, SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY.
import { normalizeEmail, parseWooOrder } from "../_shared/woo.ts";
import { adminClient, env, json, requestUser } from "../_shared/supabase.ts";

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method" }, 405);
  const admin = adminClient();
  const user = await requestUser(req, admin);
  if (!user?.email || !user.email_confirmed_at) return json({ error: "unauthorized" }, 401);
  const email = normalizeEmail(user.email);

  const url = new URL("/wp-json/wc/v3/orders", env("WOO_URL"));
  url.searchParams.set("search", email);
  url.searchParams.set("status", "completed,refunded,cancelled");
  url.searchParams.set("per_page", "100");
  const auth = btoa(`${env("WOO_CONSUMER_KEY")}:${env("WOO_CONSUMER_SECRET")}`);
  const response = await fetch(url, { headers: { Authorization: `Basic ${auth}` } });
  if (!response.ok) return json({ error: "shop" }, 502);

  const orders = ((await response.json()) as unknown[])
    .map(parseWooOrder)
    // `search` also matches names and notes; only the billing e-mail counts.
    .filter((o) => o !== null && o.email === email);
  const rows = orders.flatMap((o) =>
    o!.productRefs.map((product_ref) => ({
      woo_order_id: o!.orderId,
      product_ref,
      email_normalized: email,
      order_status: o!.status,
    }))
  );
  if (rows.length) {
    const { error } = await admin.from("web_purchases_pending").upsert(rows);
    if (error) return json({ error: "store" }, 500);
  }
  const { data: claimed, error } = await admin.rpc("claim_web_purchases", { p_user_id: user.id, p_email: email });
  if (error) return json({ error: "claim" }, 500);
  return json({ ok: true, claimed });
});

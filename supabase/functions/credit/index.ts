// Referral credit (30 zł per friend, see migration 20261021000001): what the parent has and what
// it can buy, and spending it. Auth: the signed-in user. Body: { action: "offers" } →
// { balance, offers: [{ scope, title, price }] }, or { action: "spend", scope } →
// { status: ok | insufficient | unknown | owned, balance, scopes? }. Prices in grosze.
import { adminClient, json, requestUser } from "../_shared/supabase.ts";

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method" }, 405);
  const admin = adminClient();
  const user = await requestUser(req, admin);
  if (!user) return json({ error: "unauthorized" }, 401);
  let body: { action?: unknown; scope?: unknown };
  try {
    body = await req.json();
  } catch {
    return json({ error: "body" }, 400);
  }
  if (body.action === "offers") {
    const { data, error } = await admin.rpc("credit_offers", { p_user: user.id });
    if (error) {
      console.error("credit (offers):", error.message);
      return json({ error: "retry" }, 503);
    }
    return json(data);
  }
  if (body.action === "spend" && typeof body.scope === "string" && body.scope.length <= 64) {
    const { data, error } = await admin.rpc("spend_credit", { p_user: user.id, p_scope: body.scope });
    if (error) {
      console.error("credit (spend):", error.message);
      return json({ error: "retry" }, 503);
    }
    return json(data);
  }
  return json({ error: "body" }, 400);
});

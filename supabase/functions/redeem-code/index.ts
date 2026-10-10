// A parent types an access code (gift, tester, promotion) in the app; it adds that code's packs to
// the parent's account. Auth: the signed-in user, anonymous accounts included (a guest account
// may hold access until the parent signs in). Body: { code }. Answer: { status, scopes } with
// status ok | already | invalid | expired | used_up | rate_limited | format. Referral codes
// (POLEC-…) give 14 days of everything (redeem_referral).
import { hashCode, normalizeCode, normalizeReferralCode } from "../_shared/codes.ts";
import { adminClient, json, requestUser } from "../_shared/supabase.ts";

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method" }, 405);
  const admin = adminClient();
  const user = await requestUser(req, admin);
  if (!user) return json({ error: "unauthorized" }, 401);
  let raw: unknown;
  try {
    raw = (await req.json()).code;
  } catch {
    return json({ error: "body" }, 400);
  }
  const text = typeof raw === "string" && raw.length <= 64 ? raw : "";
  // A friend's referral code ("POLEC-…") goes through the same box in the app.
  const referral = normalizeReferralCode(text);
  if (referral) {
    const { data, error } = await admin.rpc("redeem_referral", { p_user_id: user.id, p_code: referral });
    if (error) {
      console.error("redeem-code (referral):", error.message);
      return json({ error: "retry" }, 503);
    }
    return json(data);
  }
  const code = normalizeCode(text);
  if (!code) return json({ status: "format", scopes: [] });
  const { data, error } = await admin.rpc("redeem_access_code", { p_user_id: user.id, p_code_hash: await hashCode(code) });
  if (error) {
    console.error("redeem-code:", error.message);
    return json({ error: "retry" }, 503);
  }
  return json(data);
});

// A parent types an access code (gift, tester, promotion) in the app; it adds that code's packs to
// the parent's account. Auth: the signed-in user, anonymous accounts included (a guest account
// may hold access until the parent signs in). Body: { code }. Answer: { status, scopes } with
// status ok | already | invalid | expired | used_up | rate_limited | format.
import { hashCode, normalizeCode } from "../_shared/codes.ts";
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
  const code = typeof raw === "string" && raw.length <= 64 ? normalizeCode(raw) : null;
  if (!code) return json({ status: "format", scopes: [] });
  const { data, error } = await admin.rpc("redeem_access_code", { p_user_id: user.id, p_code_hash: await hashCode(code) });
  if (error) {
    console.error("redeem-code:", error.message);
    return json({ error: "retry" }, 503);
  }
  return json(data);
});

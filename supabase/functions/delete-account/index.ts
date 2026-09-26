// Deletes the signed-in parent's account and, by cascade, their entitlements and account row
// (Apple 5.1.1(v), Google account deletion). Store subscriptions are NOT cancelled here —
// the app tells the parent to cancel in App Store / Google Play (ARCHITECTURE §7).
// Secrets: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY.
import { adminClient, json, requestUser } from "../_shared/supabase.ts";

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method" }, 405);
  const admin = adminClient();
  const user = await requestUser(req, admin);
  if (!user) return json({ error: "unauthorized" }, 401);
  const { error } = await admin.auth.admin.deleteUser(user.id);
  if (error) return json({ error: "delete" }, 500);
  return json({ ok: true });
});

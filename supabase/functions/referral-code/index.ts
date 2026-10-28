// The signed-in parent's referral code and how many friends used it. Auth: the signed-in user
// (guest accounts included). Answer: { code: "POLEC-7K3M9Q", friends, rewards }.
import { formatReferralCode, generateReferralCode } from "../_shared/codes.ts";
import { adminClient, json, requestUser } from "../_shared/supabase.ts";

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method" }, 405);
  const admin = adminClient();
  const user = await requestUser(req, admin);
  if (!user) return json({ error: "unauthorized" }, 401);
  // A fresh code clashes with another parent's almost never; try a few.
  for (let attempt = 0; attempt < 5; attempt++) {
    const { data, error } = await admin.rpc("referral_code_for", {
      p_user_id: user.id,
      p_candidate: generateReferralCode(),
    });
    if (error) {
      console.error("referral-code:", error.message);
      return json({ error: "retry" }, 503);
    }
    if (data) return json({ ...data, code: formatReferralCode(data.code) });
  }
  return json({ error: "retry" }, 503);
});

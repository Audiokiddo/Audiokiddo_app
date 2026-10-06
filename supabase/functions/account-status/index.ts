// Sign-in, step one: is there a parent account with this e-mail? Body: { email }.
// Answer: { exists: true|false }, or 429 after too many lookups from one caller.
// No sign-in needed (the parent is not signed in yet); the caller is identified by IP.
import { adminClient, json } from "../_shared/supabase.ts";

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method" }, 405);
  let email = "";
  try {
    email = String((await req.json())?.email ?? "").trim();
  } catch {
    return json({ error: "body" }, 400);
  }
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email) || email.length > 254) return json({ error: "email" }, 400);
  const caller = (req.headers.get("x-forwarded-for") ?? "unknown").split(",")[0].trim();
  const { data, error } = await adminClient().rpc("account_exists", { p_email: email, p_caller: caller });
  if (error) {
    console.error("account-status:", error.message);
    return json({ error: "retry" }, 503);
  }
  if (data === null) return json({ error: "rate_limited" }, 429);
  return json({ exists: data === true });
});

// A short-lived link to one catalog file (audiozabawa, game segment, PDF), after checking that
// the caller may have it: free files for anyone, paid ones with a live entitlement
// (content_files + can_download). Audit 2026-09-28, P1-6.
// Body: { path }. Secrets: DOWNLOAD_SIGNING_KEY, FILES_BASE_URL (+ Supabase ones).
import { adminClient, env, json, requestUser } from "../_shared/supabase.ts";
import { isSafePath, signedFileUrl } from "../_shared/signed_url.ts";

// Long enough to stream a whole play and seek in it (a player re-reads the link while it plays).
const TTL_SECONDS = 4 * 60 * 60;

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method" }, 405);
  let path: unknown;
  try {
    path = (await req.json()).path;
  } catch {
    return json({ error: "body" }, 400);
  }
  if (typeof path !== "string" || !isSafePath(path)) return json({ error: "path" }, 400);

  const admin = adminClient();
  const user = await requestUser(req, admin); // free files need no account
  const { data: allowed, error } = await admin.rpc("can_download", { p_user_id: user?.id ?? null, p_path: path });
  if (error) {
    console.error("download-url:", error.message);
    return json({ error: "retry" }, 503);
  }
  if (allowed !== true) return json({ error: "forbidden" }, 403);

  const expiresAt = Math.floor(Date.now() / 1000) + TTL_SECONDS;
  const url = await signedFileUrl(env("FILES_BASE_URL"), path, env("DOWNLOAD_SIGNING_KEY"), expiresAt);
  return json({ url, expiresAt });
});

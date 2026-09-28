// Short-lived download links for files on the LH.pl hosting (tool/lhpl/get.php checks them).
// Signature: hex HMAC-SHA256 of "<path>\n<expires>" with DOWNLOAD_SIGNING_KEY, the same key
// that sits in config.php on the server. Links are useless after they expire.

async function hmacHex(key: string, message: string): Promise<string> {
  const k = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(key),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const mac = new Uint8Array(await crypto.subtle.sign("HMAC", k, new TextEncoder().encode(message)));
  return [...mac].map((b) => b.toString(16).padStart(2, "0")).join("");
}

export async function signedFileUrl(
  baseUrl: string,
  path: string,
  key: string,
  expiresAt: number, // unix seconds
): Promise<string> {
  const sig = await hmacHex(key, `${path}\n${expiresAt}`);
  const url = new URL(`${baseUrl.replace(/\/+$/, "")}/get.php`);
  url.searchParams.set("p", path);
  url.searchParams.set("e", String(expiresAt));
  url.searchParams.set("s", sig);
  return url.toString();
}

/** Only catalog-style paths: letters, digits, dash, underscore, dots in names, slashes between. */
export function isSafePath(path: string): boolean {
  return /^[a-z0-9_-]+(\/[a-z0-9_.-]+)+$/i.test(path) && !path.includes("..");
}

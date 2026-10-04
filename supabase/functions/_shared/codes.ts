// Access codes: "AK-7K3M-9QXD". Typed by a parent in the app, so the alphabet leaves out the
// look-alikes (0 O 1 I) and the dashes and case do not matter. Only the SHA-256 of the
// normalised code is stored (access_codes.code_hash), like a password.

export const CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"; // 32 symbols, 5 bits each
export const CODE_LENGTH = 8; // 40 bits, plus the 10 000 guess limit per account and hour

/** "ak 7k3m-9qxd" → "AK7K3M9QXD"; null when the text cannot be a code. */
export function normalizeCode(input: string): string | null {
  const text = input.toUpperCase().replace(/[\s\-_.]/g, "");
  const body = text.startsWith("AK") && text.length === CODE_LENGTH + 2 ? text.slice(2) : text;
  if (body.length !== CODE_LENGTH) return null;
  for (const c of body) if (!CODE_ALPHABET.includes(c)) return null;
  return `AK${body}`;
}

/** "AK7K3M9QXD" → "AK-7K3M-9QXD". */
export function formatCode(normalized: string): string {
  return `AK-${normalized.slice(2, 6)}-${normalized.slice(6)}`;
}

export function generateCode(random: (n: number) => Uint8Array = (n) => crypto.getRandomValues(new Uint8Array(n))): string {
  const bytes = random(CODE_LENGTH);
  let body = "";
  for (const b of bytes) body += CODE_ALPHABET[b % CODE_ALPHABET.length]; // 256 % 32 == 0: no bias
  return `AK${body}`;
}

export async function hashCode(normalized: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(normalized));
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

// Referral codes: "POLEC-7K3M9Q", one per parent, shared with friends. Stored as they are
// (they give a friend a trial, not paid access), so the parent can always see their own.
export const REFERRAL_PREFIX = "POLEC";
export const REFERRAL_LENGTH = 6;

/** "polec 7k3m-9q" → "POLEC7K3M9Q"; null when the text is not a referral code. */
export function normalizeReferralCode(input: string): string | null {
  const text = input.toUpperCase().replace(/[\s\-_.]/g, "");
  if (!text.startsWith(REFERRAL_PREFIX)) return null;
  const body = text.slice(REFERRAL_PREFIX.length);
  if (body.length !== REFERRAL_LENGTH) return null;
  for (const c of body) if (!CODE_ALPHABET.includes(c)) return null;
  return `${REFERRAL_PREFIX}${body}`;
}

/** "POLEC7K3M9Q" → "POLEC-7K3M9Q". */
export function formatReferralCode(normalized: string): string {
  return `${REFERRAL_PREFIX}-${normalized.slice(REFERRAL_PREFIX.length)}`;
}

export function generateReferralCode(
  random: (n: number) => Uint8Array = (n) => crypto.getRandomValues(new Uint8Array(n)),
): string {
  let body = "";
  for (const b of random(REFERRAL_LENGTH)) body += CODE_ALPHABET[b % CODE_ALPHABET.length];
  return `${REFERRAL_PREFIX}${body}`;
}

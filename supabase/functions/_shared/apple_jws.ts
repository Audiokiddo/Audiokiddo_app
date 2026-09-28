// App Store signed data (JWS): transactions, renewal info and Server Notifications V2.
//
// Apple signs with ES256 and puts the chain in the header (x5c: leaf, intermediate, root).
// We trust it only when the root is exactly Apple Root CA - G3, each certificate is signed
// by the next and valid at the time Apple signed the data, the leaf and intermediate carry
// Apple's App Store OIDs, and the leaf's key verifies the signature.
import * as x509 from "npm:@peculiar/x509@1.12.3";
import { APPLE_ROOT_CA_G3 } from "./apple_root.ts";

x509.cryptoProvider.set(crypto);

const LEAF_OID = "1.2.840.113635.100.6.11.1"; // App Store receipt signing
const INTERMEDIATE_OID = "1.2.840.113635.100.6.2.1"; // Apple Worldwide Developer Relations

export class AppleJwsError extends Error {}

export interface AppleJwsOptions {
  /** Trusted roots, DER in base64. Apple's G3 root by default; tests pass their own. */
  roots?: string[];
  /** Apple's App Store OIDs on leaf and intermediate (off only for test chains). */
  requireAppleOids?: boolean;
  /** Fallback time for the validity check when the payload has no signedDate. */
  now?: Date;
}

function b64Decode(b64: string): Uint8Array<ArrayBuffer> {
  const binary = atob(b64);
  const bytes = new Uint8Array(new ArrayBuffer(binary.length));
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return bytes;
}

function b64urlDecode(part: string): Uint8Array<ArrayBuffer> {
  return b64Decode(part.replace(/-/g, "+").replace(/_/g, "/") + "===".slice((part.length + 3) % 4));
}

function sameBytes(a: Uint8Array, b: Uint8Array): boolean {
  return a.length === b.length && a.every((v, i) => v === b[i]);
}

/** Verifies an App Store JWS and returns its decoded payload. Throws AppleJwsError. */
export async function verifyAppleJws<T = Record<string, unknown>>(
  jws: string,
  options: AppleJwsOptions = {},
): Promise<T> {
  const parts = jws.split(".");
  if (parts.length !== 3) throw new AppleJwsError("not a JWS");
  let header: { alg?: string; x5c?: string[] };
  let payload: T & { signedDate?: number };
  try {
    header = JSON.parse(new TextDecoder().decode(b64urlDecode(parts[0])));
    payload = JSON.parse(new TextDecoder().decode(b64urlDecode(parts[1])));
  } catch {
    throw new AppleJwsError("malformed JWS");
  }
  if (header.alg !== "ES256") throw new AppleJwsError("unexpected algorithm");
  if (!Array.isArray(header.x5c) || header.x5c.length !== 3) throw new AppleJwsError("missing certificate chain");

  const [leaf, intermediate, root] = header.x5c.map((c) => new x509.X509Certificate(b64Decode(c)));
  const trusted = (options.roots ?? [APPLE_ROOT_CA_G3]).map(b64Decode);
  if (!trusted.some((t) => sameBytes(new Uint8Array(root.rawData), t))) {
    throw new AppleJwsError("untrusted root");
  }
  if (options.requireAppleOids ?? true) {
    if (!leaf.getExtension(LEAF_OID) || !intermediate.getExtension(INTERMEDIATE_OID)) {
      throw new AppleJwsError("not an App Store certificate");
    }
  }
  // Apple: check validity when the data was signed, so older transactions stay verifiable.
  const date = payload.signedDate ? new Date(payload.signedDate) : (options.now ?? new Date());
  if (!(await intermediate.verify({ publicKey: root.publicKey, date }))) {
    throw new AppleJwsError("intermediate not signed by root");
  }
  if (!(await leaf.verify({ publicKey: intermediate.publicKey, date }))) {
    throw new AppleJwsError("leaf not signed by intermediate");
  }

  const key = await leaf.publicKey.export({ name: "ECDSA", namedCurve: "P-256" }, ["verify"]);
  const valid = await crypto.subtle.verify(
    { name: "ECDSA", hash: "SHA-256" },
    key,
    b64urlDecode(parts[2]),
    new TextEncoder().encode(`${parts[0]}.${parts[1]}`),
  );
  if (!valid) throw new AppleJwsError("bad signature");
  return payload;
}

/** Subset of JWSTransactionDecodedPayload we rely on. */
export interface AppleTransactionPayload {
  transactionId: string;
  originalTransactionId: string;
  bundleId: string;
  productId: string;
  environment: "Sandbox" | "Production" | string;
  expiresDate?: number;
  revocationDate?: number;
  appAccountToken?: string;
  signedDate?: number;
}

/** Subset of ResponseBodyV2DecodedPayload (App Store Server Notifications V2). */
export interface AppleNotificationPayload {
  notificationType: string;
  subtype?: string;
  notificationUUID: string;
  data?: {
    bundleId?: string;
    environment?: string;
    signedTransactionInfo?: string;
    signedRenewalInfo?: string;
  };
  signedDate?: number;
}

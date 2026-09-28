// Test-only: an Apple-shaped certificate chain (same OIDs, local keys) and JWS signing.
import * as x509 from "npm:@peculiar/x509@1.12.3";

x509.cryptoProvider.set(crypto);

const alg = { name: "ECDSA", namedCurve: "P-256", hash: "SHA-256" };
const oid = (id: string) => new x509.Extension(id, false, new Uint8Array([0x05, 0x00]));
const notBefore = new Date("2025-01-01T00:00:00Z");
const notAfter = new Date("2035-01-01T00:00:00Z");

/** A root → intermediate → leaf chain shaped like Apple's (same OIDs, test keys). */
export async function chain(appleOids = true) {
  const keys = () => crypto.subtle.generateKey(alg, true, ["sign", "verify"]) as Promise<CryptoKeyPair>;
  const [rootKeys, midKeys, leafKeys] = await Promise.all([keys(), keys(), keys()]);
  const root = await x509.X509CertificateGenerator.createSelfSigned({
    serialNumber: "01",
    name: "CN=Test Root",
    notBefore,
    notAfter,
    signingAlgorithm: alg,
    keys: rootKeys,
    extensions: [new x509.BasicConstraintsExtension(true, undefined, true)],
  });
  const mid = await x509.X509CertificateGenerator.create({
    serialNumber: "02",
    subject: "CN=Test WWDR",
    issuer: root.subject,
    notBefore,
    notAfter,
    signingAlgorithm: alg,
    publicKey: midKeys.publicKey,
    signingKey: rootKeys.privateKey,
    extensions: [new x509.BasicConstraintsExtension(true, 0, true), ...(appleOids ? [oid("1.2.840.113635.100.6.2.1")] : [])],
  });
  const leaf = await x509.X509CertificateGenerator.create({
    serialNumber: "03",
    subject: "CN=Test App Store",
    issuer: mid.subject,
    notBefore,
    notAfter,
    signingAlgorithm: alg,
    publicKey: leafKeys.publicKey,
    signingKey: midKeys.privateKey,
    extensions: appleOids ? [oid("1.2.840.113635.100.6.11.1")] : [],
  });
  const b64 = (c: x509.X509Certificate) => btoa(String.fromCharCode(...new Uint8Array(c.rawData)));
  return { x5c: [b64(leaf), b64(mid), b64(root)], rootB64: b64(root), leafKey: leafKeys.privateKey };
}

export const enc = (o: unknown) =>
  btoa(JSON.stringify(o)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "");

export async function sign(payload: unknown, x5c: string[], key: CryptoKey): Promise<string> {
  const head = `${enc({ alg: "ES256", x5c })}.${enc(payload)}`;
  const sig = new Uint8Array(await crypto.subtle.sign(alg, key, new TextEncoder().encode(head)));
  return `${head}.${btoa(String.fromCharCode(...sig)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/, "")}`;
}


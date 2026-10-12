import { assertEquals, assertNotEquals } from "jsr:@std/assert@1";
import {
  CODE_ALPHABET,
  formatCode,
  formatReferralCode,
  generateCode,
  generateReferralCode,
  hashCode,
  normalizeCode,
  normalizeReferralCode,
} from "./codes.ts";

Deno.test("codes are read the way people type them", () => {
  const expected = "AK7K3M9QXD";
  for (const text of ["AK-7K3M-9QXD", "ak 7k3m 9qxd", " 7K3M-9QXD ", "AK7K3M9QXD", "ak_7k3m.9qxd"]) {
    assertEquals(normalizeCode(text), expected, text);
  }
  assertEquals(formatCode(expected), "AK-7K3M-9QXD");
});

Deno.test("text that cannot be a code is refused before the server is asked", () => {
  for (const text of ["", "AK-7K3M", "AK-7K3M-9QXD-1", "AK-0K3M-9QXD", "AK-7K3M-9QXI", "ŁĄKA-7K3M-9QXD", "<script>"]) {
    assertEquals(normalizeCode(text), null, text);
  }
});

Deno.test("generated codes use the alphabet, normalise to themselves and differ", () => {
  const seen = new Set<string>();
  for (let i = 0; i < 200; i++) {
    const code = generateCode();
    assertEquals(normalizeCode(code), code);
    assertEquals(code.length, 10);
    for (const c of code.slice(2)) assertEquals(CODE_ALPHABET.includes(c), true);
    seen.add(code);
  }
  assertEquals(seen.size, 200);
});

Deno.test("the hash is the SHA-256 of the normalised code (pinned against openssl)", async () => {
  // printf 'AK7K3M9QXD' | openssl dgst -sha256
  assertEquals(await hashCode("AK7K3M9QXD"), "fc9bce72581853d85f4048b48f1d9ef46a00a941174263c59b6e7645188fc53f");
  assertNotEquals(await hashCode("AK7K3M9QXD"), await hashCode("AK7K3M9QXE"));
});

Deno.test("referral codes are read the way people type them and refused otherwise", () => {
  for (const text of ["POLEC-7K3M9Q", "polec 7k3m9q", "POLEC7K3M9Q", " polec_7k3m-9q "]) {
    assertEquals(normalizeReferralCode(text), "POLEC7K3M9Q", text);
  }
  for (const text of ["", "POLEC-7K3M", "POLEC-7K3M9Q1", "POLEC-0K3M9Q", "AK-7K3M-9QXD", "PROMO-7K3M9Q"]) {
    assertEquals(normalizeReferralCode(text), null, text);
  }
  assertEquals(formatReferralCode("POLEC7K3M9Q"), "POLEC-7K3M9Q");
  const code = generateReferralCode();
  assertEquals(normalizeReferralCode(code), code);
});

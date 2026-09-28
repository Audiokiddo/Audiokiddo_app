import { assertEquals, assertRejects } from "jsr:@std/assert@1";
import { AppleJwsError, verifyAppleJws } from "./apple_jws.ts";
import { chain, enc, sign } from "./test_chain.ts";


const tx = {
  transactionId: "2000000001",
  originalTransactionId: "2000000000",
  bundleId: "pl.audiokiddo.app",
  productId: "pl.audiokiddo.sub.yearly",
  environment: "Sandbox",
  signedDate: Date.parse("2026-09-28T10:00:00Z"),
};

Deno.test("apple jws: valid chain and signature decode the payload", async () => {
  const c = await chain();
  const payload = await verifyAppleJws(await sign(tx, c.x5c, c.leafKey), { roots: [c.rootB64] });
  assertEquals(payload, tx);
});

Deno.test("apple jws: someone else's root is rejected (default is Apple's G3)", async () => {
  const c = await chain();
  await assertRejects(async () => verifyAppleJws(await sign(tx, c.x5c, c.leafKey)), AppleJwsError, "untrusted root");
});

Deno.test("apple jws: tampered payload fails the signature", async () => {
  const c = await chain();
  const [h, , s] = (await sign(tx, c.x5c, c.leafKey)).split(".");
  const forged = `${h}.${enc({ ...tx, productId: "pl.audiokiddo.everything" })}.${s}`;
  await assertRejects(() => verifyAppleJws(forged, { roots: [c.rootB64] }), AppleJwsError, "bad signature");
});

Deno.test("apple jws: chain without App Store OIDs is rejected", async () => {
  const c = await chain(false);
  await assertRejects(
    async () => verifyAppleJws(await sign(tx, c.x5c, c.leafKey), { roots: [c.rootB64] }),
    AppleJwsError,
    "not an App Store certificate",
  );
});

Deno.test("apple jws: signed outside the certificates' validity is rejected", async () => {
  const c = await chain();
  const old = { ...tx, signedDate: Date.parse("2020-01-01T00:00:00Z") };
  await assertRejects(async () => verifyAppleJws(await sign(old, c.x5c, c.leafKey), { roots: [c.rootB64] }), AppleJwsError);
});

Deno.test("apple jws: a leaf signed by a stranger is rejected", async () => {
  const a = await chain();
  const b = await chain();
  const mixed = [b.x5c[0], a.x5c[1], a.x5c[2]];
  await assertRejects(
    async () => verifyAppleJws(await sign(tx, mixed, b.leafKey), { roots: [a.rootB64] }),
    AppleJwsError,
    "leaf not signed by intermediate",
  );
});

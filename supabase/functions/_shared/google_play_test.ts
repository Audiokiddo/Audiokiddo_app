import { assert, assertEquals } from "jsr:@std/assert@1";
import { createLocalJWKSet, exportJWK, exportPKCS8, generateKeyPair, jwtVerify, SignJWT } from "npm:jose@5.9.6";
import { GooglePlayClient, parsePubSubPush, verifyPubSubToken } from "./google_play.ts";

Deno.test("google: service-account token request is a signed JWT for androidpublisher, cached", async () => {
  const { publicKey, privateKey } = await generateKeyPair("RS256", { extractable: true });
  const calls: { url: string; body: string }[] = [];
  const fakeFetch = (async (url: string | URL | Request, init?: RequestInit) => {
    calls.push({ url: String(url), body: String(init?.body ?? "") });
    return new Response(JSON.stringify({ access_token: "ya29.test", expires_in: 3600 }));
  }) as typeof fetch;
  const client = new GooglePlayClient(
    { client_email: "verifier@audiokiddo.iam.gserviceaccount.com", private_key: await exportPKCS8(privateKey) },
    "pl.audiokiddo.app",
    fakeFetch,
  );
  assertEquals(await client.accessToken(), "ya29.test");
  assertEquals(await client.accessToken(), "ya29.test");
  assertEquals(calls.length, 1, "token is cached");
  const assertion = new URLSearchParams(calls[0].body).get("assertion")!;
  const { payload } = await jwtVerify(assertion, publicKey, { audience: "https://oauth2.googleapis.com/token" });
  assertEquals(payload.iss, "verifier@audiokiddo.iam.gserviceaccount.com");
  assertEquals(payload.scope, "https://www.googleapis.com/auth/androidpublisher");
});

Deno.test("google: Pub/Sub push token must match audience and service account", async () => {
  const { publicKey, privateKey } = await generateKeyPair("RS256");
  const jwk = { ...(await exportJWK(publicKey)), kid: "k1", alg: "RS256" };
  const keys = createLocalJWKSet({ keys: [jwk] });
  const token = (email: string, aud: string) =>
    new SignJWT({ email, email_verified: true })
      .setProtectedHeader({ alg: "RS256", kid: "k1" })
      .setIssuer("https://accounts.google.com")
      .setAudience(aud)
      .setIssuedAt()
      .setExpirationTime("5m")
      .sign(privateKey);
  const aud = "https://example.supabase.co/functions/v1/store-notifications/google";
  const email = "rtdn@audiokiddo.iam.gserviceaccount.com";
  assert(await verifyPubSubToken(`Bearer ${await token(email, aud)}`, aud, email, keys));
  assert(!(await verifyPubSubToken(`Bearer ${await token("someone@else.com", aud)}`, aud, email, keys)));
  assert(!(await verifyPubSubToken(`Bearer ${await token(email, "https://other")}`, aud, email, keys)));
  assert(!(await verifyPubSubToken(null, aud, email, keys)));
});

Deno.test("google: Pub/Sub push body decodes the developer notification", () => {
  const n = { packageName: "pl.audiokiddo.app", eventTimeMillis: "1", testNotification: { version: "1.0" } };
  const push = parsePubSubPush({ message: { data: btoa(JSON.stringify(n)), messageId: "42" } });
  assertEquals(push?.messageId, "42");
  assertEquals(push?.notification.testNotification?.version, "1.0");
  assertEquals(parsePubSubPush({}), null);
});

import { assert, assertEquals } from "jsr:@std/assert@1";
import { appleToken, fitReply, parseAppleReviews, parseGoogleReviews } from "./reviews.ts";

Deno.test("reviews from both stores, with replies already given", () => {
  const apple = parseAppleReviews({
    data: [{ id: "a1", type: "customerReviews", attributes: { rating: 5, title: "Super", body: "Córka uwielbia", reviewerNickname: "Mama", territory: "POL", createdDate: "2026-10-01T10:00:00Z" } }],
    included: [{ type: "customerReviewResponses", attributes: { responseBody: "Dziękujemy!" }, relationships: { review: { data: { id: "a1" } } } }],
  });
  assertEquals([apple[0].rating, apple[0].reply], [5, "Dziękujemy!"]);
  const google = parseGoogleReviews({
    reviews: [{ reviewId: "g1", authorName: "Tata", comments: [{ userComment: { text: " Nie działa mikrofon ", starRating: 2, lastModified: { seconds: 1790000000 }, appVersionName: "0.2.0" } }] }],
  });
  assertEquals([google[0].body, google[0].rating, google[0].reply, google[0].app_version], ["Nie działa mikrofon", 2, null, "0.2.0"]);
});

Deno.test("replies fit Google's 350 characters at a sentence", () => {
  const long = "Dziękujemy za opinię. ".repeat(30);
  const r = fitReply(`„${long}”`);
  assert(r.length <= 350 && r.endsWith("."), r);
});

Deno.test("the App Store token is an ES256 JWT", async () => {
  const pair = await crypto.subtle.generateKey({ name: "ECDSA", namedCurve: "P-256" }, true, ["sign", "verify"]);
  const pkcs8 = new Uint8Array(await crypto.subtle.exportKey("pkcs8", pair.privateKey));
  const pem = `-----BEGIN PRIVATE KEY-----\n${btoa(String.fromCharCode(...pkcs8))}\n-----END PRIVATE KEY-----`;
  const token = await appleToken("KEY123", "issuer", pem, Date.UTC(2026, 9, 7));
  const [h, p, s] = token.split(".");
  const dec = (x: string) => JSON.parse(atob(x.replace(/-/g, "+").replace(/_/g, "/")));
  assertEquals(dec(h), { alg: "ES256", kid: "KEY123", typ: "JWT" });
  assertEquals(dec(p).aud, "appstoreconnect-v1");
  const sig = Uint8Array.from(atob(s.replace(/-/g, "+").replace(/_/g, "/") + "==".slice(0, (4 - s.length % 4) % 4)), (c) => c.charCodeAt(0));
  assert(await crypto.subtle.verify({ name: "ECDSA", hash: "SHA-256" }, pair.publicKey, sig, new TextEncoder().encode(`${h}.${p}`)));
});

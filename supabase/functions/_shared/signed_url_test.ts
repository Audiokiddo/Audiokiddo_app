import { assert, assertEquals } from "jsr:@std/assert@1";
import { isSafePath, signedFileUrl } from "./signed_url.ts";

Deno.test("signed url: stable HMAC over path and expiry, matching get.php", async () => {
  const url = new URL(await signedFileUrl("https://pliki.example.pl/", "audio/wyobraznia/mikstura.m4a", "k3y", 1790000000));
  assertEquals(url.origin + url.pathname, "https://pliki.example.pl/get.php");
  assertEquals(url.searchParams.get("p"), "audio/wyobraznia/mikstura.m4a");
  assertEquals(url.searchParams.get("e"), "1790000000");
  // printf 'audio/wyobraznia/mikstura.m4a\n1790000000' | openssl dgst -sha256 -hmac k3y
  assertEquals(url.searchParams.get("s"), "88b9fa733f92c119b3747c9a2c5daacabda9112ac1dcf129761e3559ea66b10a");
  const other = new URL(await signedFileUrl("https://pliki.example.pl", "audio/wyobraznia/mikstura.m4a", "k3y", 1790000001));
  assert(other.searchParams.get("s") !== url.searchParams.get("s"));
});

Deno.test("signed url: only catalog paths are accepted", () => {
  assert(isSafePath("audio/detektyw/tajemnicze-znaki.m4a"));
  assert(isSafePath("games/zgadnij-dzwiek/intro.m4a"));
  assert(!isSafePath("../etc/passwd"));
  assert(!isSafePath("/audio/x.m4a"));
  assert(!isSafePath("audio/../../config.php"));
  assert(!isSafePath("audio/a b.m4a"));
});

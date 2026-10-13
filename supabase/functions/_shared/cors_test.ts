import { assertEquals } from "jsr:@std/assert@1";
import { allowedOrigin, withCors } from "./cors.ts";

Deno.test("only our site and localhost may call from a browser", () => {
  assertEquals(allowedOrigin("https://audiokiddo.pl"), "https://audiokiddo.pl");
  assertEquals(allowedOrigin("https://www.audiokiddo.pl"), "https://www.audiokiddo.pl");
  assertEquals(allowedOrigin("http://localhost:5173"), "http://localhost:5173");
  assertEquals(allowedOrigin("https://audiokiddo.pl.evil.com"), null);
  assertEquals(allowedOrigin(null), null);
});

Deno.test("preflight is answered, responses carry the origin", async () => {
  const handler = withCors(() => Promise.resolve(new Response("ok")));
  const pre = await handler(new Request("https://x/f", { method: "OPTIONS", headers: { Origin: "https://audiokiddo.pl" } }));
  assertEquals(pre.status, 204);
  assertEquals(pre.headers.get("Access-Control-Allow-Origin"), "https://audiokiddo.pl");
  const post = await handler(new Request("https://x/f", { method: "POST", headers: { Origin: "http://localhost:8080" } }));
  assertEquals(post.headers.get("Access-Control-Allow-Origin"), "http://localhost:8080");
  const evil = await handler(new Request("https://x/f", { method: "OPTIONS", headers: { Origin: "https://evil.com" } }));
  assertEquals(evil.status, 403);
});

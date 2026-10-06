import { assertEquals } from "jsr:@std/assert@1";
import { wooGet } from "./woo.ts";

Deno.test("wooGet sends the key as Basic auth and retries with query keys when the host drops the header", async () => {
  const calls: string[] = [];
  const original = globalThis.fetch;
  globalThis.fetch = ((input: Request | URL | string, init?: RequestInit) => {
    const url = new URL(String(input));
    calls.push(`${url.pathname}?${url.searchParams.toString()}|${(init?.headers as Record<string, string> | undefined)?.Authorization ?? "-"}`);
    return Promise.resolve(new Response("{}", { status: url.searchParams.has("consumer_key") ? 200 : 401 }));
  }) as typeof fetch;
  try {
    const response = await wooGet("https://shop.example", "ck_1", "cs_1", "/wp-json/wc/v3/orders/7", { per_page: "1" });
    assertEquals(response.status, 200);
    assertEquals(calls.length, 2);
    assertEquals(calls[0], `/wp-json/wc/v3/orders/7?per_page=1|Basic ${btoa("ck_1:cs_1")}`);
    assertEquals(calls[1].startsWith("/wp-json/wc/v3/orders/7?per_page=1&consumer_key=ck_1&consumer_secret=cs_1|"), true);
  } finally {
    globalThis.fetch = original;
  }
});

Deno.test("a buyer who ticked the consent goes to the buyers' group with what they bought", async () => {
  const { parseWooOrder, buyerSubscriber } = await import("./woo.ts");
  const order = parseWooOrder({
    id: 77,
    status: "completed",
    billing: { email: " Mama@Example.com ", first_name: "Ola" },
    line_items: [{ product_id: 12, name: "Pakiet Detektyw" }],
    meta_data: [{ key: "audiokiddo_newsletter", value: "yes" }],
  })!;
  if (!order.newsletter) throw new Error("consent");
  const s = buyerSubscriber(order, "g1");
  if (JSON.stringify(s) !== JSON.stringify({
    email: "mama@example.com",
    fields: { name: "Ola", last_purchase: "Pakiet Detektyw" },
    groups: ["g1"],
    status: "active",
  })) throw new Error(JSON.stringify(s));
  const without = parseWooOrder({ id: 78, status: "completed", billing: { email: "a@b.pl" }, line_items: [] })!;
  if (without.newsletter) throw new Error("no consent, no letters");
});

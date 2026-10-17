import { assertEquals } from "jsr:@std/assert@1";

// Capture the Edge Function entrypoint without opening a server or reaching a real backend.
let handler: (req: Request) => Promise<Response>;
const originalServe = Deno.serve;
try {
  Deno.serve = ((fn: typeof handler) => {
    handler = fn;
    return {};
  }) as typeof Deno.serve;
  await import("../claim-order/index.ts");
} finally {
  Deno.serve = originalServe;
}

for (const [name, rpcStatus, rpcBody, expectedStatus, expectedBody] of [
  ["limiter failure", 500, { message: "database unavailable" }, 503, { error: "retry" }],
  ["missing limiter result", 200, null, 503, { error: "retry" }],
  ["limit reached", 200, true, 200, { status: "rate_limited" }],
] as const) {
  Deno.test(`claim-order: ${name} never queries the shop`, async () => {
    const oldFetch = globalThis.fetch;
    const keys = ["SUPABASE_URL", "SUPABASE_SERVICE_ROLE_KEY"];
    const saved = keys.map((key) => Deno.env.get(key));
    const calls: string[] = [];
    Deno.env.set(keys[0], "https://backend.example.test");
    Deno.env.set(keys[1], "test-service-key");
    globalThis.fetch = ((input: RequestInfo | URL) => {
      const url = input instanceof Request ? input.url : String(input);
      calls.push(url);
      if (url.endsWith("/auth/v1/user")) {
        return Promise.resolve(Response.json({ id: "test-parent", aud: "authenticated" }));
      }
      if (url.endsWith("/rest/v1/rpc/claim_rate_limited")) {
        return Promise.resolve(Response.json(rpcBody, { status: rpcStatus }));
      }
      throw new Error(`Unexpected request: ${url}`);
    }) as typeof fetch;
    try {
      const response = await handler(new Request("https://edge.example.test/claim-order", {
        method: "POST",
        headers: { authorization: "Bearer test-token", "content-type": "application/json" },
        body: JSON.stringify({ order: 123, email: "parent@example.test" }),
      }));
      assertEquals(response.status, expectedStatus);
      assertEquals(await response.json(), expectedBody);
      assertEquals(calls.length, 2);
    } finally {
      globalThis.fetch = oldFetch;
      keys.forEach((key, index) => {
        if (saved[index] === undefined) Deno.env.delete(key);
        else Deno.env.set(key, saved[index]!);
      });
    }
  });
}

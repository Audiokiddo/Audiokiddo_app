import { assertEquals, assertThrows } from "jsr:@std/assert@1";
import { answerText, ClaudeError, claudeReason } from "./claude.ts";

Deno.test("Claude failures become advice: key, credit, model, busy", () => {
  assertEquals(claudeReason(401, '{"type":"error","error":{"type":"authentication_error"}}'), "key");
  assertEquals(claudeReason(400, '{"error":{"message":"Your credit balance is too low to access the Anthropic API."}}'), "credit");
  assertEquals(claudeReason(404, '{"error":{"type":"not_found_error","message":"model: x"}}'), "model_missing");
  assertEquals(claudeReason(529, '{"error":{"type":"overloaded_error"}}'), "busy");
  assertEquals(claudeReason(500, "oops"), "model");
});

Deno.test("an answer cut at the token limit is reported, not parsed", () => {
  const e = assertThrows(() => answerText({ stop_reason: "max_tokens", content: [{ type: "text", text: "{" }] }), ClaudeError);
  assertEquals(e.reason, "too_long");
  assertEquals(answerText({ stop_reason: "end_turn", content: [{ type: "text", text: "ok" }] }), "ok");
});

import { askClaude, geminiReason, geminiText, providers } from "./claude.ts";

Deno.test("providers: Claude first unless AI_PROVIDER says Gemini; only those with a key", () => {
  const env = (vars: Record<string, string>) => (k: string) => vars[k];
  assertEquals(providers(env({ ANTHROPIC_API_KEY: "a", GEMINI_API_KEY: "g" })), ["claude", "gemini"]);
  assertEquals(providers(env({ ANTHROPIC_API_KEY: "a", GEMINI_API_KEY: "g", AI_PROVIDER: "gemini" })), ["gemini", "claude"]);
  assertEquals(providers(env({ GEMINI_API_KEY: "g" })), ["gemini"]);
  assertEquals(providers(env({})), []);
});

Deno.test("Gemini failures and answers", () => {
  assertEquals(geminiReason(400, '{"error":{"status":"INVALID_ARGUMENT","details":[{"reason":"API_KEY_INVALID"}]}}'), "key");
  assertEquals(geminiReason(429, '{"error":{"status":"RESOURCE_EXHAUSTED"}}'), "quota");
  assertEquals(geminiReason(404, "{}"), "model_missing");
  assertEquals(
    geminiText({ candidates: [{ finishReason: "STOP", content: { parts: [{ text: "thinking", thought: true }, { text: '{"a":1}' }] } }] }),
    '{"a":1}',
  );
  const e = assertThrows(() => geminiText({ candidates: [{ finishReason: "MAX_TOKENS" }] }), ClaudeError);
  assertEquals(e.reason, "too_long");
});

Deno.test("a wrong Claude key falls through to Gemini", async () => {
  Deno.env.set("ANTHROPIC_API_KEY", "bad");
  Deno.env.set("GEMINI_API_KEY", "good");
  const real = globalThis.fetch;
  const asked: string[] = [];
  globalThis.fetch = ((input: string | URL | Request) => {
    const url = String(input);
    asked.push(url.includes("anthropic") ? "claude" : "gemini");
    return Promise.resolve(
      url.includes("anthropic")
        ? new Response('{"type":"error","error":{"type":"authentication_error"}}', { status: 401 })
        : new Response(JSON.stringify({ candidates: [{ finishReason: "STOP", content: { parts: [{ text: '{"ok":true}' }] } }] })),
    );
  }) as typeof fetch;
  try {
    assertEquals(await askClaude("s", "p", 100), '{"ok":true}');
    assertEquals(asked, ["claude", "gemini"]);
  } finally {
    globalThis.fetch = real;
    Deno.env.delete("ANTHROPIC_API_KEY");
    Deno.env.delete("GEMINI_API_KEY");
  }
});

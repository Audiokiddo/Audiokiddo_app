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

// One call to Claude (Anthropic API) for the agents. Secret: ANTHROPIC_API_KEY; model from
// COO_MODEL or the default.

/** Why a call to Claude failed, in a word Studio turns into advice. */
export type ClaudeReason = "key" | "credit" | "model_missing" | "busy" | "too_long" | "model";

export class ClaudeError extends Error {
  constructor(message: string, readonly reason: ClaudeReason = "model") {
    super(message);
  }
}

/** Reads Anthropic's error answer (status and body) into a reason. Never includes the key. */
export function claudeReason(status: number, body: string): ClaudeReason {
  const text = body.toLowerCase();
  if (status === 401 || status === 403 || text.includes("authentication_error") || text.includes("x-api-key")) return "key";
  if (text.includes("credit balance") || text.includes("billing")) return "credit";
  if (status === 404 || text.includes("not_found_error")) return "model_missing";
  if (status === 429 || status === 529 || text.includes("overloaded")) return "busy";
  return "model";
}

/** Raises the matching [ClaudeError] for a failed response (and logs it for the function logs). */
export async function failWith(tag: string, response: Response): Promise<never> {
  const body = await response.text();
  console.error(`${tag}: model`, response.status, body.slice(0, 500));
  throw new ClaudeError(`model ${response.status}`, claudeReason(response.status, body));
}

/** The text of an answer; an answer cut at the token limit is reported, not parsed half-way. */
export function answerText(answer: { content?: { type: string; text?: string }[]; stop_reason?: string }): string {
  if (answer.stop_reason === "max_tokens") throw new ClaudeError("max_tokens", "too_long");
  return (answer.content ?? []).filter((c) => c.type === "text").map((c) => c.text ?? "").join("");
}

export async function askClaude(system: string, prompt: string, maxTokens: number): Promise<string> {
  const key = Deno.env.get("ANTHROPIC_API_KEY");
  if (!key) throw new ClaudeError("no_key");
  const response = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: { "x-api-key": key, "anthropic-version": "2023-06-01", "content-type": "application/json" },
    body: JSON.stringify({
      model: Deno.env.get("COO_MODEL") ?? "claude-sonnet-5-5",
      max_tokens: maxTokens,
      system,
      messages: [{ role: "user", content: prompt }],
    }),
  });
  if (!response.ok) await failWith("claude", response);
  return answerText(await response.json());
}

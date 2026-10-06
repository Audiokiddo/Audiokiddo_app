// One call to Claude (Anthropic API) for the agents. Secret: ANTHROPIC_API_KEY; model from
// COO_MODEL or the default.

export class ClaudeError extends Error {}

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
  if (!response.ok) {
    console.error("claude:", response.status, (await response.text()).slice(0, 500));
    throw new ClaudeError(`model ${response.status}`);
  }
  const answer = await response.json() as { content?: { type: string; text?: string }[] };
  return (answer.content ?? []).filter((c) => c.type === "text").map((c) => c.text ?? "").join("");
}

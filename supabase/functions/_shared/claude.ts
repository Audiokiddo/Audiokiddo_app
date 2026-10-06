// One call to the AI for the agents (COO, ads, factory, reviews). Two providers:
//   Claude (Anthropic API): ANTHROPIC_API_KEY, model COO_MODEL or the default;
//   Gemini (Google AI Studio, has a free tier): GEMINI_API_KEY, model GEMINI_MODEL or the default.
// AI_PROVIDER = claude | gemini puts one first. Otherwise Claude goes first and Gemini steps in
// when Claude's key is missing, wrong, out of credit or busy.

/** Why a call failed, in a word Studio turns into advice. */
export type ClaudeReason = "no_key" | "key" | "credit" | "quota" | "model_missing" | "busy" | "too_long" | "model";

export class ClaudeError extends Error {
  /** [detail]: the provider's own short message (never the key), shown in Studio. */
  constructor(message: string, readonly reason: ClaudeReason = "model", readonly detail = "") {
    super(message);
  }
}

/** The provider's error message from its JSON answer, short. */
export function providerMessage(body: string): string {
  try {
    const parsed = JSON.parse(body) as { error?: { message?: string } };
    return (parsed.error?.message ?? "").slice(0, 300);
  } catch {
    return body.slice(0, 200);
  }
}

const pause = (ms: number) => new Promise((r) => setTimeout(r, ms));

type Provider = "claude" | "gemini";

/** The providers with a key, in the order to try. */
export function providers(env: (k: string) => string | undefined = (k) => Deno.env.get(k)): Provider[] {
  const have = (["claude", "gemini"] as Provider[]).filter((p) =>
    p === "claude" ? !!env("ANTHROPIC_API_KEY") : !!env("GEMINI_API_KEY")
  );
  const first = env("AI_PROVIDER")?.toLowerCase();
  return first === "gemini" ? [...have.filter((p) => p === "gemini"), ...have.filter((p) => p !== "gemini")] : have;
}

/** Whether any AI is configured (the agents wait otherwise). */
export function hasAi(): boolean {
  return providers().length > 0;
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

/** The same for Google's Gemini API. */
export function geminiReason(status: number, body: string): ClaudeReason {
  const text = body.toLowerCase();
  if (text.includes("api_key_invalid") || text.includes("api key not valid") || status === 401 || status === 403) return "key";
  if (status === 429 || text.includes("resource_exhausted") || text.includes("quota")) return "quota";
  if (status === 404) return "model_missing";
  if (status === 503 || text.includes("overloaded") || text.includes("unavailable")) return "busy";
  return "model";
}

/** Raises the matching [ClaudeError] for a failed Claude response (and logs it). */
export async function failWith(tag: string, response: Response): Promise<never> {
  const body = await response.text();
  console.error(`${tag}: model`, response.status, body.slice(0, 500));
  throw new ClaudeError(`model ${response.status}`, claudeReason(response.status, body), providerMessage(body));
}

/** The text of a Claude answer; an answer cut at the token limit is reported, not parsed half-way. */
export function answerText(answer: { content?: { type: string; text?: string }[]; stop_reason?: string }): string {
  if (answer.stop_reason === "max_tokens") throw new ClaudeError("max_tokens", "too_long");
  return (answer.content ?? []).filter((c) => c.type === "text").map((c) => c.text ?? "").join("");
}

/** The text of a Gemini answer, the same way. */
export function geminiText(answer: {
  candidates?: { finishReason?: string; content?: { parts?: { text?: string; thought?: boolean }[] } }[];
}): string {
  const first = answer.candidates?.[0];
  if (first?.finishReason === "MAX_TOKENS") throw new ClaudeError("max_tokens", "too_long");
  return (first?.content?.parts ?? []).filter((p) => !p.thought).map((p) => p.text ?? "").join("");
}

async function claude(system: string, prompt: string, maxTokens: number, model?: string): Promise<string> {
  const response = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "x-api-key": Deno.env.get("ANTHROPIC_API_KEY")!,
      "anthropic-version": "2023-06-01",
      "content-type": "application/json",
    },
    body: JSON.stringify({
      model: model ?? Deno.env.get("COO_MODEL") ?? "claude-sonnet-5-5",
      max_tokens: maxTokens,
      system,
      messages: [{ role: "user", content: prompt }],
    }),
  });
  if (!response.ok) await failWith("claude", response);
  return answerText(await response.json());
}

async function gemini(system: string, prompt: string, maxTokens: number, json: boolean): Promise<string> {
  // The function has about 150 s in all, so every try fits in what is left of 110 s. The chosen
  // model first, then the lighter one when it is busy; thinking off, so the answer comes quickly.
  const deadline = Date.now() + 110_000;
  const models = [...new Set([Deno.env.get("GEMINI_MODEL") ?? "gemini-flash-latest", "gemini-flash-lite-latest"])];
  let last: ClaudeError | null = null;
  let thinkingOff = true;
  for (const model of models) {
    for (const wait of [0, 3000]) {
      if (wait) await pause(wait);
      const left = deadline - Date.now();
      if (left < 15_000) throw last ?? new ClaudeError("gemini timeout", "busy");
      let response: Response;
      try {
        response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent`, {
          method: "POST",
          signal: AbortSignal.timeout(left),
          headers: { "x-goog-api-key": Deno.env.get("GEMINI_API_KEY")!, "content-type": "application/json" },
          body: JSON.stringify({
            systemInstruction: { parts: [{ text: system }] },
            contents: [{ role: "user", parts: [{ text: prompt }] }],
            generationConfig: {
              maxOutputTokens: maxTokens + 2000,
              ...(json ? { responseMimeType: "application/json" } : {}),
              ...(thinkingOff ? { thinkingConfig: { thinkingBudget: 0 } } : {}),
            },
          }),
        });
      } catch (e) {
        console.error("gemini: no answer in time", model, e);
        last = new ClaudeError("gemini timeout", "busy", "Gemini nie odpowiedział w czasie.");
        continue;
      }
      const started = deadline - left;
      if (response.ok) {
        console.log("gemini:", model, "answered in", Date.now() - started, "ms");
        return geminiText(await response.json());
      }
      const body = await response.text();
      console.error("gemini:", model, response.status, body.slice(0, 500));
      // A model that cannot switch thinking off says so: ask again without the setting.
      if (response.status === 400 && thinkingOff && body.toLowerCase().includes("thinking")) {
        thinkingOff = false;
        continue;
      }
      last = new ClaudeError(`gemini ${response.status}`, geminiReason(response.status, body), providerMessage(body));
      if (last.reason !== "busy" && last.reason !== "model_missing") throw last;
      if (last.reason === "model_missing") break;
    }
  }
  throw last!;
}

/** Reasons that mean "try the other provider" rather than "this request is wrong". */
const SWITCH: ClaudeReason[] = ["key", "credit", "quota", "model_missing", "busy"];

/**
 * Asks the configured AI. [json]: the answer must be one JSON object (Gemini is told so too).
 * Throws [ClaudeError] with the reason of the last provider tried ("no_key" when none is set).
 */
export async function askClaude(
  system: string,
  prompt: string,
  maxTokens: number,
  options: { json?: boolean; model?: string } = {},
): Promise<string> {
  const list = providers();
  if (!list.length) throw new ClaudeError("no_key", "no_key");
  let last: ClaudeError | null = null;
  for (const provider of list) {
    try {
      return provider === "claude"
        ? await claude(system, prompt, maxTokens, options.model)
        : await gemini(system, prompt, maxTokens, options.json ?? true);
    } catch (e) {
      if (!(e instanceof ClaudeError)) throw e;
      last = e;
      if (!SWITCH.includes(e.reason)) break;
    }
  }
  throw last!;
}

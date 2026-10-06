import { assertEquals, assertThrows } from "jsr:@std/assert@1";
import { cleanProposal, dueModes, parseAnswer, prompt, toRow } from "./coo.ts";

Deno.test("the answer becomes clean proposals, wrapped or not", () => {
  const answer = 'Oto plan:\n```json\n{"summary": "Dziś: abonament.", "proposals": [' +
    '{"kind": "task", "area": "Marketing!", "title": " Rolka o trybie dziecka ", "priority": 1, "due": "2026-10-10", "owner": "Nela"},' +
    '{"kind": "hack", "title": "x"}, {"kind": "idea", "title": ""}, {"kind": "idea", "area": "pack", "title": "Kosmos", "due": "jutro", "data": {"age_min": 4}}' +
    "]}\n```";
  const parsed = parseAnswer(answer);
  assertEquals(parsed.summary, "Dziś: abonament.");
  assertEquals(parsed.proposals.length, 2);
  assertEquals(parsed.proposals[0].title, "Rolka o trybie dziecka");
  assertEquals(parsed.proposals[0].area, "marketing");
  assertEquals(parsed.proposals[1].due, null);
  assertEquals(parsed.proposals[1].data, { age_min: 4 });
  assertThrows(() => parseAnswer("nie wiem"));
});

Deno.test("every proposal waits for Dawid's decision", () => {
  const task = toRow(cleanProposal({ kind: "task", title: "A" })!);
  assertEquals([task.decision, task.status, task.source, task.priority], ["pending", "todo", "ai", 2]);
  assertEquals(toRow(cleanProposal({ kind: "idea", title: "B" })!).status, "new");
});

Deno.test("the prompt carries the business state and the approved idea", () => {
  const text = prompt("scenario", { numbers: { paying_families: 3 } }, "krócej", { title: "Kosmos" });
  for (const part of ['"paying_families":3', "Kosmos", "krócej", "proposals"]) {
    if (!text.includes(part)) throw new Error(`missing ${part}`);
  }
});

Deno.test("the morning rhythm: report daily, ads on Monday, newsletter every other Thursday", () => {
  // 2026-10-05 is a Monday; 2026-10-08 a Thursday of ISO week 41 (odd), 2026-10-15 of week 42.
  assertEquals(dueModes(null, new Date("2026-10-05T05:00:00Z")), ["brief", "ads"]);
  assertEquals(dueModes(null, new Date("2026-10-08T05:00:00Z")), ["brief"]);
  assertEquals(dueModes(null, new Date("2026-10-15T05:00:00Z")), ["brief", "newsletter"]);
  assertEquals(dueModes({ brief_daily: false, ads_weekly: false }, new Date("2026-10-05T05:00:00Z")), []);
});

Deno.test("proposals keep only real dates and storable text", async () => {
  const { cleanProposal, toRow } = await import("./coo.ts");
  const bad = cleanProposal({ kind: "task", title: "Zadanie", due: "2026-02-30", body: "a\u0000b" })!;
  assertEquals(bad.due, null);
  assertEquals(toRow(bad).body, "ab");
  assertEquals(cleanProposal({ kind: "task", title: "Zadanie", due: "2026-03-01" })!.due, "2026-03-01");
});

Deno.test("areas: known ones stay, common synonyms map, the rest is 'other'", async () => {
  const { cleanProposal } = await import("./coo.ts");
  assertEquals(cleanProposal({ kind: "task", title: "a", area: "marketing" })!.area, "marketing");
  assertEquals(cleanProposal({ kind: "task", title: "a", area: "dev" })!.area, "feature");
  assertEquals(cleanProposal({ kind: "task", title: "a", area: "kosmos" })!.area, "other");
});

Deno.test("each proposal can carry a prompt for an AI chat and the suggested tool", async () => {
  const { cleanProposal } = await import("./coo.ts");
  const p = cleanProposal({
    kind: "task",
    title: "Opisy do sklepu",
    data: { prompt: "  Napisz opis…  ", ai: "ChatGPT", ai_why: "grafiki" },
  })!;
  assertEquals(p.data, { prompt: "Napisz opis…", ai: "chatgpt", ai_why: "grafiki" });
  assertEquals(cleanProposal({ kind: "task", title: "a", data: { ai: "copilot", prompt: 5 } })!.data, {});
});

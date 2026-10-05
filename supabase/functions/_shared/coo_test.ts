import { assertEquals, assertThrows } from "jsr:@std/assert@1";
import { cleanProposal, parseAnswer, prompt, toRow } from "./coo.ts";

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

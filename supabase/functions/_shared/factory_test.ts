import { assert, assertEquals } from "jsr:@std/assert@1";
import { chunks, cleanHtml, nextStage, slugify, speakable, stagePrompt, wpPost } from "./factory.ts";

Deno.test("steps follow each other; a script per play", () => {
  const idea = { plays: [{ title: "A" }, { title: "B" }] };
  assertEquals(nextStage({ kind: "blog", stage: "topic", step_index: 0, data: {} }), { stage: "article", index: 0 });
  assertEquals(nextStage({ kind: "blog", stage: "publish", step_index: 0, data: {} }), { stage: "done", index: 0 });
  assertEquals(nextStage({ kind: "pack", stage: "idea", step_index: 0, data: { idea } }), { stage: "script", index: 0 });
  assertEquals(nextStage({ kind: "pack", stage: "script", step_index: 0, data: { idea } }), { stage: "script", index: 1 });
  assertEquals(nextStage({ kind: "pack", stage: "script", step_index: 1, data: { idea } }), { stage: "voice", index: 0 });
});

Deno.test("the article prompt carries the topic and the remarks", () => {
  const { prompt } = stagePrompt({
    id: "1", kind: "blog", title: "", stage: "article", step_index: 0, status: "working",
    data: { topic: { keyword: "zabawy w aucie" } }, output: {}, feedback: "krócej",
  }, {});
  assert(prompt.includes("zabawy w aucie") && prompt.includes("UWAGI DO POPRAWY") && prompt.includes("krócej"));
});

Deno.test("article HTML: only safe tags, https links, the FAQ kept for the schema", () => {
  assertEquals(
    cleanHtml('<p onclick="x">Hej <script>alert(1)</script><a href="http://zly.pl">a</a><a href="https://audiokiddo.pl/">b</a></p><img src=x>'),
    '<p>Hej <a>a</a><a href="https://audiokiddo.pl/">b</a></p>',
  );
  const post = wpPost({ title: "Zabawy w aucie", slug: "Zabawy w Aucie!", content_html: "<p>x</p>", faq: [{ q: "Ile?", a: "Pięć." }], meta_description: "Opis" }, 7, "publish");
  assertEquals([post.slug, post.excerpt, post.template], ["zabawy-w-aucie", "Opis", "audiokiddo-wpis.php"]);
  assert(post.content.includes("<h2>Najczęstsze pytania</h2><h3>Ile?</h3><p>Pięć.</p>"));
  assertEquals(slugify("Żółć gęślą jaźń"), "zolc-gesla-jazn");
});

Deno.test("a script becomes speakable text in pieces for the voice", () => {
  const s = speakable("NARRATOR: Dzień dobry! [PAUZA 5 s]\nSZOP’EN: Klaśnij! [RUCH: klaskanie]\n[DŹWIĘK: dzwonek]");
  assertEquals(s, "Dzień dobry! …\nKlaśnij!");
  const parts = chunks("Zdanie. ".repeat(800), 2400);
  assert(parts.every((p) => p.length <= 2400) && parts.length > 1);
});

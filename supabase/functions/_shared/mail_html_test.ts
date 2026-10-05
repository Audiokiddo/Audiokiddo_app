import { assert, assertStringIncludes } from "jsr:@std/assert@1";
import { markdownToEmail } from "./mail_html.ts";

Deno.test("markdown newsletter becomes safe e-mail html with an unsubscribe link", () => {
  const html = markdownToEmail("## Cześć!\nTo **ważne**: [zabawa](https://audiokiddo.pl)\n- jeden\n- dwa\n<script>x</script>", "Nowa zabawa");
  assertStringIncludes(html, "<h2");
  assertStringIncludes(html, "<strong>ważne</strong>");
  assertStringIncludes(html, 'href="https://audiokiddo.pl"');
  assertStringIncludes(html, "<li>jeden</li><li>dwa</li>");
  assertStringIncludes(html, "{$unsubscribe}");
  assert(!html.includes("<script>"), "escaped");
});

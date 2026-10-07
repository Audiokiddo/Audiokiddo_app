import { assert, assertEquals, assertNotEquals } from "jsr:@std/assert@1";
import { giftCode, giftNote } from "./gifts.ts";
import { normalizeCode } from "./codes.ts";

Deno.test("a gift code is the same for a retry and different per order line", async () => {
  const a = await giftCode("s3cret", 1201, "woo:55");
  assertEquals(a, await giftCode("s3cret", 1201, "woo:55"));
  assertNotEquals(a, await giftCode("s3cret", 1202, "woo:55"));
  assertNotEquals(a, await giftCode("s3cret", 1201, "woo:56"));
  assertNotEquals(a, await giftCode("other", 1201, "woo:55"));
  assertEquals(normalizeCode(a), a, "a valid access code");
});

Deno.test("the note tells the buyer the code and how to use it", async () => {
  const note = giftNote(await giftCode("s", 1, "woo:1"), "Zestaw 3 pakietów");
  assert(note.includes("Kod prezentowy: AK-"));
  assert(note.includes("Mam kod"));
  assert(note.includes("Zestaw 3 pakietów"));
});

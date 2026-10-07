// Gift codes for gift products bought on audiokiddo.pl. The code comes from a server secret
// and the order line, so a webhook retry gives the same code (and the same note), and only
// its hash is ever stored.
import { formatCode, generateCode } from "./codes.ts";

export async function giftCode(secret: string, orderId: number, productRef: string): Promise<string> {
  const key = await crypto.subtle.importKey(
    "raw",
    new TextEncoder().encode(secret),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const mac = new Uint8Array(await crypto.subtle.sign("HMAC", key, new TextEncoder().encode(`gift:${orderId}:${productRef}`)));
  return generateCode((n) => mac.slice(0, n));
}

/** The customer note WooCommerce e-mails to the buyer. */
export function giftNote(code: string, label: string): string {
  return [
    `Dziękujemy za prezent${label ? `: ${label}` : ""}!`,
    "",
    `Kod prezentowy: ${formatCode(code)}`,
    "",
    "Jak go użyć: w aplikacji AudioKiddo wejdź w Sklep → „Masz już dostęp z audiokiddo.pl?” → „Mam kod” i wpisz kod.",
    "Kod działa na jednym koncie i nie ma daty ważności do wpisania.",
    "Kartkę z kodem do wydruku znajdziesz na audiokiddo.pl/prezent.",
  ].join("\n");
}

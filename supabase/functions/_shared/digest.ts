// Dawid's morning e-mail: what needs attention, the agent's report, the numbers that matter,
// and how much waits in Studio. Plain Markdown (mail_html.ts makes the HTML).

export type DigestInput = {
  date: string;
  alerts: { level: string; title: string; detail: string }[];
  brief: string | null;
  numbers: Record<string, unknown>;
  pending: number;
  adsPending: number;
  studioUrl: string;
};

const icon: Record<string, string> = { critical: "🔴", warning: "🟠", info: "🔵" };
const zl = (v: unknown) => (typeof v === "number" ? `${Math.round(v)} zł` : "–");

export function digestMail(d: DigestInput): { subject: string; preheader: string; markdown: string } {
  const critical = d.alerts.filter((a) => a.level === "critical").length;
  const lines: string[] = [];
  if (d.alerts.length) {
    lines.push("## Do uwagi", "");
    for (const a of d.alerts) lines.push(`- ${icon[a.level] ?? "•"} **${a.title}.** ${a.detail}`);
  } else {
    lines.push("## Do uwagi", "", "Nic. Strażnik nie widzi problemów.");
  }
  lines.push(
    "",
    "## Liczby",
    "",
    `- Płacące rodziny: **${d.numbers.paying_families ?? "–"}**`,
    `- MRR brutto: **${zl(d.numbers.mrr_gross)}**, zysk w tym miesiącu (szac.): **${zl(d.numbers.profit_month_estimate)}**`,
    `- Nowe konta w 7 dni: **${d.numbers.users_7d ?? "–"}**`,
    `- Przychód 30 dni: **${zl(d.numbers.revenue_30d_gross)}**`,
  );
  if (d.brief) lines.push("", "## Raport COO", "", d.brief);
  const waiting = d.pending + d.adsPending;
  lines.push(
    "",
    "## Czeka na Ciebie",
    "",
    waiting
      ? `${d.pending} propozycji w „Decyzje”${d.adsPending ? ` i ${d.adsPending} w „Kampanie”` : ""}. [Otwórz Studio](${d.studioUrl})`
      : `Nic nie czeka. [Otwórz Studio](${d.studioUrl})`,
  );
  return {
    subject: `AudioKiddo ${d.date}: ${
      critical ? `${critical} pilne, ` : d.alerts.length ? `${d.alerts.length} do uwagi, ` : ""
    }${waiting} do decyzji`,
    preheader: d.alerts[0]?.title ?? "Spokojny dzień. Raport i liczby w środku.",
    markdown: lines.join("\n"),
  };
}

/** For a buyer who has not opened a shop order in the app. */
export function orderReminderMail(order: number, products: string[]): { subject: string; preheader: string; markdown: string } {
  return {
    subject: `Twoje zabawy z zamówienia ${order} czekają w aplikacji`,
    preheader: "Dwa sposoby, każdy zajmuje minutę.",
    markdown: [
      "Dzień dobry!",
      "",
      `Dziękujemy za zakup na audiokiddo.pl (zamówienie ${order}${products.length ? `: ${products.join(", ")}` : ""}). Te same zabawy możesz mieć w aplikacji AudioKiddo, z pobieraniem na wyjazd, trybem dziecka i planem zabaw.`,
      "",
      "## Jak je odebrać",
      "",
      "- **Najprościej:** zaloguj się w aplikacji tym samym adresem e-mail, którego użyłeś w sklepie. Zakupy pojawią się same.",
      `- **Inny adres w aplikacji?** Wejdź w Sklep → „Odbierz dostęp” i wpisz numer zamówienia **${order}** oraz e-mail ze sklepu.`,
      "",
      "Aplikację pobierzesz za darmo z App Store i Google Play (szukaj: AudioKiddo).",
      "",
      "Coś nie działa? Odpisz na ten mail albo napisz na kontakt@audiokiddo.pl.",
      "",
      "Pozdrawiamy,",
      "**Dawid i Nela z AudioKiddo**",
    ].join("\n"),
  };
}

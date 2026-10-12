// E-mail through our own mailbox at LH.pl (no-reply@audiokiddo.pl, SMTP over TLS on 465;
// Supabase blocks 25 and 587). For the morning digest to Dawid, letters to parents who asked
// for them and reminders about shop orders.
// Secrets: SMTP_HOST, SMTP_PORT (465), SMTP_USER, SMTP_PASS, MAIL_FROM ("AudioKiddo <…>").
import { SMTPClient } from "https://deno.land/x/denomailer@1.6.0/mod.ts";

export type Mail = { to: string; subject: string; html: string; text: string; unsubscribe?: string };

export function smtpConfigured(): boolean {
  return ["SMTP_HOST", "SMTP_USER", "SMTP_PASS"].every((k) => !!Deno.env.get(k));
}

/** Sends [mails] over one connection, a little apart (small mailboxes have hourly limits).
 * Returns how many went out; one failure does not stop the rest. */
export async function sendMails(mails: Mail[], pauseMs = 400): Promise<{ sent: number; failed: number }> {
  if (!mails.length) return { sent: 0, failed: 0 };
  const client = new SMTPClient({
    connection: {
      hostname: Deno.env.get("SMTP_HOST")!,
      port: Number(Deno.env.get("SMTP_PORT") ?? 465),
      tls: true,
      auth: { username: Deno.env.get("SMTP_USER")!, password: Deno.env.get("SMTP_PASS")! },
    },
  });
  const from = Deno.env.get("MAIL_FROM") ?? `AudioKiddo <${Deno.env.get("SMTP_USER")}>`;
  let sent = 0, failed = 0;
  try {
    for (const m of mails) {
      try {
        await client.send({
          from,
          to: m.to,
          subject: m.subject,
          content: m.text,
          html: m.html,
          headers: m.unsubscribe
            ? { "List-Unsubscribe": `<${m.unsubscribe}>`, "List-Unsubscribe-Post": "List-Unsubscribe=One-Click" }
            : undefined,
        });
        sent++;
      } catch (e) {
        failed++;
        console.error("smtp: send", e instanceof Error ? e.message : e);
      }
      if (pauseMs) await new Promise((r) => setTimeout(r, pauseMs));
    }
  } finally {
    try {
      await client.close();
    } catch {
      // Already closed.
    }
  }
  return { sent, failed };
}

/** Markdown as plain text for the text part of the mail. */
export function markdownToText(markdown: string): string {
  return markdown
    .replace(/^#{1,3} /gm, "")
    .replace(/\*\*(.+?)\*\*/g, "$1")
    .replace(/\[([^\]]+)\]\((https:\/\/[^)\s]+)\)/g, "$1: $2");
}

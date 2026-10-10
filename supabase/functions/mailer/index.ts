// E-mail from our own mailbox (SMTP at LH.pl, _shared/smtp.ts).
//   cron  { action: "digest" }   Dawid's morning e-mail: alerts, the agent's report, numbers
//   cron  { action: "letters" }  parents' letters: weekly on Sundays, "we miss you" every day
//   admin { action: "digest" }   the same digest now (a test)
//   admin { action: "letter_preview" }  a sample weekly letter to the admin's own address
//   admin { action: "order_reminder", order: n }  how to open a shop order in the app
//   GET/POST ?u=<token>          a parent stops the letters (link and one-click header)
// Secrets: SMTP_HOST, SMTP_PORT, SMTP_USER, SMTP_PASS, MAIL_FROM, REPORT_TO (Dawid's address).
import { withCors } from "../_shared/cors.ts";
import { digestMail, orderReminderMail } from "../_shared/digest.ts";
import { type CatalogItem, type Letter, missedLetter, weeklyLetter } from "../_shared/letters.ts";
import { markdownToEmail } from "../_shared/mail_html.ts";
import { type Mail, markdownToText, sendMails, smtpConfigured } from "../_shared/smtp.ts";
import { adminClient, json, requestUser } from "../_shared/supabase.ts";
import type { SupabaseClient } from "npm:@supabase/supabase-js@2";

const BASE = `${Deno.env.get("SUPABASE_URL")}/functions/v1/mailer`;
const STUDIO = "https://audiokiddo.pl/studio/";

const mail = (to: string, l: Letter | ReturnType<typeof digestMail>, unsubscribe?: string): Mail => ({
  to,
  subject: l.subject,
  html: markdownToEmail(l.markdown, l.preheader),
  text: markdownToText(l.markdown),
  unsubscribe,
});

function page(title: string, text: string): Response {
  return new Response(
    `<!doctype html><html lang="pl"><meta charset="utf-8"><meta name="viewport" content="width=device-width">` +
      `<title>${title}</title><body style="font-family:Arial,sans-serif;background:#FFF8E7;color:#211C35;padding:40px;text-align:center">` +
      `<h1>${title}</h1><p>${text}</p></body></html>`,
    { headers: { "content-type": "text/html; charset=utf-8" } },
  );
}

Deno.serve(async (req) => {
  const admin = adminClient();
  const url = new URL(req.url);

  // Unsubscribe: a link in the letter (GET) or the mail app's one-click button (POST).
  const token = url.searchParams.get("u");
  if (token) {
    if (!/^[0-9a-f-]{36}$/.test(token)) return page("Nieprawidłowy link", "Napisz do nas: kontakt@audiokiddo.pl.");
    await admin.from("parent_letters").update({ weekly: false, missed: false, updated_at: new Date().toISOString() })
      .eq("token", token);
    return page("Wypisano", "Nie wyślemy więcej listów od Szop’ena. Włączysz je znowu w aplikacji: Więcej → Listy od Szop’ena.");
  }
  return await withCors(handle)(req);

  async function handle(req: Request): Promise<Response> {
    if (req.method !== "POST") return json({ error: "method" }, 405);
    let body: Record<string, unknown>;
    try {
      body = await req.json();
    } catch {
      return json({ error: "body" }, 400);
    }
    if (!smtpConfigured()) return json({ error: "no_smtp" }, 412);

    const cronSecret = req.headers.get("x-cron-secret");
    if (cronSecret) {
      const { data: ok } = await admin.rpc("ads_cron_ok", { p_secret: cronSecret });
      if (ok !== true) return json({ error: "unauthorized" }, 401);
      if (body.action === "digest") return json(await digest(admin));
      if (body.action === "letters") return json(await letters(admin, new Date()));
      return json({ error: "action" }, 400);
    }

    const user = await requestUser(req, admin);
    if (!user) return json({ error: "unauthorized" }, 401);
    const { data: isAdmin } = await admin.from("admins").select("user_id").eq("user_id", user.id).maybeSingle();
    if (!isAdmin) return json({ error: "forbidden" }, 403);
    switch (body.action) {
      case "digest":
        return json(await digest(admin));
      case "letter_preview": {
        const catalog = await catalogItems(admin);
        const l = weeklyLetter({
          catalog,
          week: catalog.slice(0, 2).map((i) => i.id),
          ever: catalog.slice(0, 2).map((i) => i.id),
          scopes: [],
          seed: dayOfYear(new Date()),
          unsubscribeUrl: `${BASE}?u=00000000-0000-0000-0000-000000000000`,
        });
        return json(await sendMails([mail(user.email!, l)]));
      }
      case "order_reminder": {
        const order = Number(body.order);
        if (!Number.isInteger(order) || order <= 0) return json({ error: "order" }, 400);
        const { data: rows } = await admin.from("web_purchases_pending").select("email_normalized, product_ref")
          .eq("woo_order_id", order).is("claimed_by", null);
        if (!rows?.length) return json({ error: "order" }, 404);
        const { data: names } = await admin.from("store_products").select("product_ref, scopes")
          .in("product_ref", rows.map((r) => r.product_ref));
        const products = (names ?? []).flatMap((n) => (n.scopes as string[]).map(scopeName));
        return json(await sendMails([mail(rows[0].email_normalized, orderReminderMail(order, [...new Set(products)]))]));
      }
      default:
        return json({ error: "action" }, 400);
    }
  }
});

function scopeName(scope: string): string {
  if (scope === "all_content") return "abonament";
  if (scope.startsWith("pack:")) {
    return `pakiet ${({ wyobraznia: "Wyobraźnia", "slowa-i-wiedza": "Słowa i Wiedza", detektyw: "Detektyw" } as Record<string, string>)[scope.slice(5)] ?? scope.slice(5)}`;
  }
  return scope.replace(/^item:/, "zabawa ");
}

const dayOfYear = (d: Date) => Math.floor((d.getTime() - Date.UTC(d.getUTCFullYear(), 0, 1)) / 864e5);

async function catalogItems(admin: SupabaseClient): Promise<CatalogItem[]> {
  const { data } = await admin.rpc("published_catalog");
  return ((data as { manifest?: { items?: CatalogItem[] } } | null)?.manifest?.items ?? []);
}

async function digest(admin: SupabaseClient) {
  const to = Deno.env.get("REPORT_TO");
  if (!to) return { error: "no_report_to" };
  await admin.rpc("crm_watch");
  const today = new Date().toISOString().slice(0, 10);
  const [alerts, brief, numbers, pending, ads] = await Promise.all([
    admin.from("crm_alerts").select("level, title, detail").is("resolved_at", null).order("first_seen"),
    admin.from("crm_items").select("body").eq("kind", "briefing").eq("area", "brief")
      .gte("created_at", `${today}T00:00:00Z`).order("created_at", { ascending: false }).limit(1).maybeSingle(),
    admin.rpc("crm_numbers"),
    admin.from("crm_items").select("id", { count: "exact", head: true }).eq("decision", "pending"),
    admin.from("ads_actions").select("id", { count: "exact", head: true }).eq("status", "pending"),
  ]);
  const order = { critical: 0, warning: 1, info: 2 } as Record<string, number>;
  const d = digestMail({
    date: new Date().toLocaleDateString("pl-PL"),
    alerts: (alerts.data ?? []).sort((a, b) => (order[a.level] ?? 3) - (order[b.level] ?? 3)),
    brief: brief.data?.body ?? null,
    numbers: (numbers.data ?? {}) as Record<string, unknown>,
    pending: pending.count ?? 0,
    adsPending: ads.count ?? 0,
    studioUrl: STUDIO,
  });
  return await sendMails([mail(to, d)], 0);
}

async function letters(admin: SupabaseClient, now: Date) {
  const catalog = await catalogItems(admin);
  if (!catalog.length) return { error: "no_catalog" };
  const sunday = new Date(now.toLocaleString("en-US", { timeZone: "Europe/Warsaw" })).getDay() === 0;
  const result: Record<string, unknown> = {};
  for (const kind of sunday ? ["weekly", "missed"] as const : ["missed"] as const) {
    const { data: due, error } = await admin.rpc("letters_due", { p_kind: kind });
    if (error) {
      result[kind] = { error: error.message };
      continue;
    }
    const rows = (due ?? []) as { user_id: string; email: string; token: string; week: string[]; ever: string[]; scopes: string[] }[];
    const mails = rows.map((r) => {
      const input = {
        catalog,
        week: r.week,
        ever: r.ever,
        scopes: r.scopes,
        seed: dayOfYear(now),
        unsubscribeUrl: `${BASE}?u=${r.token}`,
      };
      return mail(r.email, kind === "weekly" ? weeklyLetter(input) : missedLetter(input), input.unsubscribeUrl);
    });
    const sent = await sendMails(mails);
    if (rows.length) {
      await admin.from("parent_letters")
        .update(kind === "weekly" ? { last_weekly_at: now.toISOString() } : { last_missed_at: now.toISOString() })
        .in("user_id", rows.map((r) => r.user_id));
    }
    result[kind] = { due: rows.length, ...sent };
  }
  return result;
}

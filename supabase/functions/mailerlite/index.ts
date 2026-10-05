// MailerLite for the CRM in Studio. Admins only. Body: { action, ... }
//   overview                          → subscribers, groups, recent campaigns, automations
//   draft { item_id, group_id? }      → a draft campaign from an approved newsletter item
//                                       (sent by Dawid himself in MailerLite)
// Secrets: MAILERLITE_API_KEY, MAILERLITE_FROM (verified sender), MAILERLITE_FROM_NAME.
import { withCors } from "../_shared/cors.ts";
import { markdownToEmail } from "../_shared/mail_html.ts";
import { adminClient, json, requestUser } from "../_shared/supabase.ts";

const API = "https://connect.mailerlite.com/api";

Deno.serve(withCors(async (req) => {
  if (req.method !== "POST") return json({ error: "method" }, 405);
  const admin = adminClient();
  const user = await requestUser(req, admin);
  if (!user) return json({ error: "unauthorized" }, 401);
  const { data: isAdmin } = await admin.from("admins").select("user_id").eq("user_id", user.id).maybeSingle();
  if (!isAdmin) return json({ error: "forbidden" }, 403);
  const key = Deno.env.get("MAILERLITE_API_KEY");
  if (!key) return json({ error: "no_key" }, 412);

  const ml = async (path: string, init?: RequestInit) => {
    const r = await fetch(`${API}${path}`, {
      ...init,
      headers: { Authorization: `Bearer ${key}`, "Content-Type": "application/json", Accept: "application/json" },
    });
    if (!r.ok) throw new Error(`${path} ${r.status} ${await r.text()}`);
    return await r.json() as Record<string, unknown>;
  };

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json({ error: "body" }, 400);
  }

  try {
    switch (body.action) {
      case "overview": {
        const [subs, groups, campaigns, automations] = await Promise.all([
          ml("/subscribers?limit=1"),
          ml("/groups?limit=25"),
          ml("/campaigns?filter[status]=sent&limit=10"),
          ml("/automations?limit=25"),
        ]);
        const list = (r: Record<string, unknown>) => (r.data as Record<string, unknown>[] | undefined) ?? [];
        return json({
          subscribers: (subs.meta as Record<string, unknown> | undefined)?.total ?? null,
          groups: list(groups).map((g) => ({
            id: g.id,
            name: g.name,
            active: g.active_count,
            open_rate: (g.open_rate as Record<string, unknown> | undefined)?.string ?? null,
          })),
          campaigns: list(campaigns).map((c) => {
            const stats = (c.stats as Record<string, unknown> | undefined) ?? {};
            return {
              name: c.name,
              subject: ((c.emails as Record<string, unknown>[] | undefined)?.[0]?.subject) ?? null,
              sent: stats.sent ?? null,
              open_rate: (stats.open_rate as Record<string, unknown> | undefined)?.string ?? null,
              click_rate: (stats.click_rate as Record<string, unknown> | undefined)?.string ?? null,
              finished_at: c.finished_at ?? null,
            };
          }),
          automations: list(automations).map((a) => ({
            name: a.name,
            enabled: a.enabled,
            completed: (a.stats as Record<string, unknown> | undefined)?.completed_subscribers_count ?? null,
          })),
        });
      }
      case "draft": {
        if (typeof body.item_id !== "string") return json({ error: "item" }, 400);
        const { data: item } = await admin.from("crm_items").select("*").eq("id", body.item_id).maybeSingle();
        if (!item || item.kind !== "mailing" || item.decision === "rejected") return json({ error: "item" }, 400);
        const from = Deno.env.get("MAILERLITE_FROM");
        if (!from) return json({ error: "no_from" }, 412);
        const subject = String(item.data?.subject ?? item.title).slice(0, 150);
        const campaign = await ml("/campaigns", {
          method: "POST",
          body: JSON.stringify({
            name: `AudioKiddo: ${item.title}`.slice(0, 255),
            type: "regular",
            emails: [{
              subject,
              from_name: Deno.env.get("MAILERLITE_FROM_NAME") ?? "Szop’en z AudioKiddo",
              from,
              content: markdownToEmail(item.body, String(item.data?.preheader ?? "")),
            }],
            ...(typeof body.group_id === "string" ? { groups: [body.group_id] } : {}),
          }),
        });
        const id = (campaign.data as Record<string, unknown> | undefined)?.id ?? null;
        await admin.from("crm_items").update({
          status: "doing",
          data: { ...(item.data ?? {}), mailerlite_campaign_id: id },
        }).eq("id", item.id);
        return json({ campaign_id: id });
      }
      default:
        return json({ error: "action" }, 400);
    }
  } catch (e) {
    console.error("mailerlite:", e);
    return json({ error: "mailerlite" }, 502);
  }
}));

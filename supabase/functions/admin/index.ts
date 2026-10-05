// Studio (the content and sales panel) talks to the server through this function. Only accounts
// listed in public.admins may use it. Body: { action, ... }.
//   stats { days }                      → numbers for the dashboard
//   catalog                             → the published catalog { version, manifest }
//   publish { manifest, note }          → a new catalog version for the app, files registered
//   promotions                          → every promotion, newest first
//   promotion_save { promotion }        → add or change one (id present = change)
//   promotion_delete { id }
import { adminClient, json, requestUser } from "../_shared/supabase.ts";

const ID = /^[a-z0-9-]+$/;

async function sha256Hex(text: string): Promise<string> {
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(text));
  return [...new Uint8Array(digest)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

/** The checks the server can make cheaply; Studio validates fully with the app's own code. */
function manifestProblem(m: unknown): string | null {
  if (typeof m !== "object" || m === null) return "manifest";
  const { packs, items } = m as Record<string, unknown>;
  if (!Array.isArray(packs) || !Array.isArray(items) || items.length === 0) return "packs/items";
  for (const item of items as Record<string, unknown>[]) {
    if (typeof item?.id !== "string" || !ID.test(item.id)) return `item id ${String(item?.id)}`;
    for (const list of [item.audio, item.pdf]) {
      if (list !== undefined && !Array.isArray(list)) return `files of ${item.id}`;
      for (const a of (list as Record<string, unknown>[] | undefined) ?? []) {
        if (typeof a?.path !== "string" || a.path.startsWith("/") || a.path.includes("..")) return `path in ${item.id}`;
      }
    }
  }
  return null;
}

Deno.serve(async (req) => {
  if (req.method !== "POST") return json({ error: "method" }, 405);
  const admin = adminClient();
  const user = await requestUser(req, admin);
  if (!user) return json({ error: "unauthorized" }, 401);
  const { data: isAdmin } = await admin.from("admins").select("user_id").eq("user_id", user.id).maybeSingle();
  if (!isAdmin) return json({ error: "forbidden" }, 403);

  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json({ error: "body" }, 400);
  }
  const fail = (message: string) => {
    console.error(`admin ${String(body.action)}:`, message);
    return json({ error: "retry" }, 503);
  };

  switch (body.action) {
    case "stats": {
      const days = Math.min(Math.max(Number(body.days) || 30, 1), 365);
      const { data, error } = await admin.rpc("admin_stats", { p_days: days });
      return error ? fail(error.message) : json(data);
    }
    case "catalog": {
      const { data, error } = await admin.rpc("published_catalog");
      return error ? fail(error.message) : json(data ?? {});
    }
    case "publish": {
      const problem = manifestProblem(body.manifest);
      if (problem) return json({ error: "invalid", problem }, 400);
      const raw = JSON.stringify(body.manifest);
      const { data, error } = await admin.rpc("publish_catalog", {
        p_manifest: body.manifest,
        p_sha256: await sha256Hex(raw),
        p_note: typeof body.note === "string" ? body.note.slice(0, 200) : null,
        p_by: user.id,
      });
      return error ? fail(error.message) : json({ version: data });
    }
    case "promotions": {
      const { data, error } = await admin.from("promotions").select("*").order("starts_at", { ascending: false });
      return error ? fail(error.message) : json(data);
    }
    case "promotion_save": {
      const p = body.promotion as Record<string, unknown> | undefined;
      if (!p) return json({ error: "body" }, 400);
      const row = {
        ...(typeof p.id === "string" ? { id: p.id } : {}),
        title: p.title,
        body: p.body ?? "",
        badge: p.badge || null,
        target: p.target || null,
        starts_at: p.starts_at,
        ends_at: p.ends_at,
        active: p.active !== false,
      };
      const { data, error } = await admin.from("promotions").upsert(row).select().single();
      return error ? json({ error: "invalid", problem: error.message }, 400) : json(data);
    }
    case "promotion_delete": {
      if (typeof body.id !== "string") return json({ error: "body" }, 400);
      const { error } = await admin.from("promotions").delete().eq("id", body.id);
      return error ? fail(error.message) : json({ ok: true });
    }
    default:
      return json({ error: "action" }, 400);
  }
});

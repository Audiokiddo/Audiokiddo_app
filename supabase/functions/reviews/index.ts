// Store reviews (CRM → Opinie). Body: { action, … }
//   cycle                       the daily cron: fetch new reviews, draft replies to unanswered ones
//   sync                        admins: fetch now
//   draft { store, review_id }  admins: a new draft from the agent
//   publish { store, review_id, text }  admins: the approved reply goes to the store
//   skip { store, review_id }   admins: no reply needed
// Secrets: App Store: ASC_KEY_ID, ASC_ISSUER_ID, ASC_PRIVATE_KEY (the .p8 text), ASC_APP_ID;
// Google Play: GOOGLE_SERVICE_ACCOUNT_JSON (as for purchases); agent: ANTHROPIC_API_KEY or GEMINI_API_KEY.
import { askClaude } from "../_shared/claude.ts";
import { withCors } from "../_shared/cors.ts";
import { googlePlayFromEnv } from "../_shared/google_play.ts";
import {
  appleToken,
  fitReply,
  parseAppleReviews,
  parseGoogleReviews,
  REPLY_SYSTEM,
  replyPrompt,
  type Review,
} from "../_shared/reviews.ts";
import { adminClient, json, requestUser } from "../_shared/supabase.ts";
import type { SupabaseClient } from "npm:@supabase/supabase-js@2";

const env = (k: string) => Deno.env.get(k)?.trim() || null;
const ASC = "https://api.appstoreconnect.apple.com/v1";

const appleReady = () => !!(env("ASC_KEY_ID") && env("ASC_ISSUER_ID") && env("ASC_PRIVATE_KEY") && env("ASC_APP_ID"));
const googleReady = () => !!env("GOOGLE_SERVICE_ACCOUNT_JSON");

async function apple(path: string, init?: RequestInit) {
  const token = await appleToken(env("ASC_KEY_ID")!, env("ASC_ISSUER_ID")!, env("ASC_PRIVATE_KEY")!);
  const r = await fetch(`${ASC}${path}`, {
    ...init,
    headers: { Authorization: `Bearer ${token}`, "content-type": "application/json" },
    signal: AbortSignal.timeout(30_000),
  });
  if (!r.ok) throw new Error(`App Store ${r.status}: ${(await r.text()).slice(0, 300)}`);
  return r.status === 204 ? {} : await r.json();
}

async function sync(admin: SupabaseClient) {
  const found: Review[] = [];
  const report: Record<string, string> = {};
  if (appleReady()) {
    try {
      found.push(...parseAppleReviews(
        await apple(`/apps/${env("ASC_APP_ID")}/customerReviews?sort=-createdDate&limit=100&include=response`),
      ));
      report.app_store = "ok";
    } catch (e) {
      report.app_store = String(e).slice(0, 300);
    }
  }
  if (googleReady()) {
    try {
      found.push(...parseGoogleReviews(await googlePlayFromEnv().call("reviews?maxResults=100")));
      report.google_play = "ok";
    } catch (e) {
      report.google_play = String(e).slice(0, 300);
    }
  }
  for (const r of found) {
    const { data: known } = await admin.from("store_reviews").select("status").eq("store", r.store)
      .eq("review_id", r.review_id).maybeSingle();
    await admin.from("store_reviews").upsert({
      ...r,
      // Answered elsewhere (in the store's own panel) counts as published.
      status: r.reply ? "published" : known?.status ?? "new",
      synced_at: new Date().toISOString(),
    });
  }
  return { found: found.length, ...report };
}

async function draft(admin: SupabaseClient, r: Pick<Review, "store" | "review_id" | "rating" | "title" | "body">) {
  let text: string;
  try {
    text = fitReply(await askClaude(REPLY_SYSTEM, replyPrompt(r), 400, { json: false }));
  } catch {
    return null;
  }
  if (!text) return null;
  await admin.from("store_reviews").update({ draft: text, status: "draft" }).eq("store", r.store).eq("review_id", r.review_id);
  return text;
}

async function publish(admin: SupabaseClient, store: string, reviewId: string, text: string) {
  const reply = fitReply(text);
  try {
    if (store === "app_store") {
      await apple("/customerReviewResponses", {
        method: "POST",
        body: JSON.stringify({
          data: {
            type: "customerReviewResponses",
            attributes: { responseBody: reply },
            relationships: { review: { data: { type: "customerReviews", id: reviewId } } },
          },
        }),
      });
    } else {
      await googlePlayFromEnv().call(`reviews/${encodeURIComponent(reviewId)}:reply`, { replyText: reply });
    }
  } catch (e) {
    await admin.from("store_reviews").update({ status: "failed", error: String(e).slice(0, 500) })
      .eq("store", store).eq("review_id", reviewId);
    return { ok: false, message: "Sklep nie przyjął odpowiedzi. Spróbuj za chwilę." };
  }
  await admin.from("store_reviews").update({ reply, draft: null, status: "published", error: null })
    .eq("store", store).eq("review_id", reviewId);
  return { ok: true, message: "Odpowiedź opublikowana." };
}

Deno.serve(withCors(async (req) => {
  if (req.method !== "POST") return json({ error: "method" }, 405);
  const admin = adminClient();
  let body: Record<string, unknown>;
  try {
    body = await req.json();
  } catch {
    return json({ error: "body" }, 400);
  }
  const cronSecret = req.headers.get("x-cron-secret");
  if (cronSecret) {
    const { data: ok } = await admin.rpc("ads_cron_ok", { p_secret: cronSecret });
    if (ok !== true || body.action !== "cycle") return json({ error: "unauthorized" }, 401);
    const synced = await sync(admin);
    const { data: fresh } = await admin.from("store_reviews").select("store, review_id, rating, title, body")
      .eq("status", "new").order("created_at", { ascending: false }).limit(20);
    let drafted = 0;
    for (const r of fresh ?? []) if (await draft(admin, r)) drafted++;
    return json({ ...synced, drafted });
  }
  const user = await requestUser(req, admin);
  if (!user) return json({ error: "unauthorized" }, 401);
  const { data: isAdmin } = await admin.from("admins").select("user_id").eq("user_id", user.id).maybeSingle();
  if (!isAdmin) return json({ error: "forbidden" }, 403);

  const store = String(body.store ?? "");
  const reviewId = String(body.review_id ?? "");
  switch (body.action) {
    case "sync":
      if (!appleReady() && !googleReady()) return json({ error: "no_key" }, 412);
      return json(await sync(admin));
    case "draft": {
      const { data: r } = await admin.from("store_reviews").select("store, review_id, rating, title, body")
        .eq("store", store).eq("review_id", reviewId).maybeSingle();
      if (!r) return json({ error: "review" }, 404);
      const text = await draft(admin, r);
      return text ? json({ draft: text }) : json({ error: "model" }, 502);
    }
    case "publish": {
      const text = String(body.text ?? "").trim();
      if (!text) return json({ error: "body" }, 400);
      return json(await publish(admin, store, reviewId, text));
    }
    case "skip":
      await admin.from("store_reviews").update({ status: "skipped" }).eq("store", store).eq("review_id", reviewId);
      return json({ ok: true });
    default:
      return json({ error: "action" }, 400);
  }
}));

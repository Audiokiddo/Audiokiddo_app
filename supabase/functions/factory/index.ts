// The factory (Studio → Fabryka): blog articles and new packs, step by step. The agent works
// on a step, then waits; only an approval starts the next step. Body: { action, … }
//   create { kind: "blog" | "pack", title?, note? }   a new job (the agent starts the first step)
//   propose_topics { count? }   blog topics from the keywords (also every Monday by cron)
//   approve { id, output? }     accept the step (with Dawid's edits) and start the next one
//   revise { id, feedback }     the agent redoes the step with the remarks
//   reject { id }               stop the job
//   audio_url { path }          a signed link to listen to a voice draft
// Secrets: ANTHROPIC_API_KEY; blog: WP_URL, WP_USER, WP_APP_PASSWORD (an application password
// of a WordPress user who may publish); voice drafts: ELEVENLABS_API_KEY (ELEVENLABS_VOICE,
// ELEVENLABS_MODEL optional).
import { askClaude, ClaudeError } from "../_shared/claude.ts";
import { withCors } from "../_shared/cors.ts";
import {
  chunks,
  type Job,
  MANUAL_OR_SYSTEM,
  nextStage,
  parseJson,
  speakable,
  stagePrompt,
  SYSTEM,
  wpPost,
} from "../_shared/factory.ts";
import { adminClient, json, requestUser } from "../_shared/supabase.ts";
import type { SupabaseClient } from "npm:@supabase/supabase-js@2";

const env = (k: string) => Deno.env.get(k)?.trim() || null;
declare const EdgeRuntime: { waitUntil(p: Promise<unknown>): void } | undefined;

/** Runs [work] after the answer is sent (the agent can take a minute). */
function background(work: Promise<unknown>) {
  if (typeof EdgeRuntime !== "undefined") EdgeRuntime.waitUntil(work);
}

async function update(admin: SupabaseClient, id: string, values: Record<string, unknown>) {
  const { error } = await admin.from("factory_jobs").update(values).eq("id", id);
  if (error) throw new Error(`factory update: ${error.message}`);
}

async function context(admin: SupabaseClient, job: Job): Promise<Record<string, unknown>> {
  if (job.kind === "blog") {
    const [keywords, posts] = await Promise.all([
      admin.from("seo_keywords").select("keyword, monthly_searches, competition").is("used_by", null)
        .order("monthly_searches", { ascending: false, nullsFirst: false }).limit(60),
      admin.from("factory_jobs").select("title").eq("kind", "blog").neq("status", "rejected").neq("id", job.id).limit(100),
    ]);
    return { keywords: keywords.data ?? [], posts: (posts.data ?? []).map((p) => p.title) };
  }
  const [catalog, plays] = await Promise.all([admin.rpc("published_catalog"), admin.rpc("plays_ranking", { p_days: 90 })]);
  const manifest = (catalog.data as { manifest?: { packs?: { title?: string }[]; items?: { title?: string }[] } })?.manifest;
  return {
    catalog: { packs: (manifest?.packs ?? []).map((p) => p.title), plays: (manifest?.items ?? []).map((i) => i.title) },
    plays: plays.data ?? [],
  };
}

/** The work of the step the job is at; ends waiting for a decision (or failed). */
async function process(admin: SupabaseClient, job: Job): Promise<void> {
  try {
    let output: Record<string, unknown>;
    if (job.stage === "publish") {
      // Published is the end: nothing more to approve.
      const wp = await publish(admin, job);
      await update(admin, job.id, { data: { ...job.data, wp }, stage: "done", status: "done", output: {}, error: null });
      return;
    } else if (job.stage === "voice") {
      output = await voice(admin, job);
    } else if (job.stage === "recording") {
      const scripts = (job.data.scripts as { title: string }[] | undefined) ?? [];
      output = {
        checklist: scripts.map((s, i) => `${i + 1}. ${s.title}: nagranie, efekty, kontrola głośności`),
        note: "Nela nagrywa zatwierdzone scenariusze. Gdy pliki są gotowe, kliknij „Nagrane”.",
      };
    } else if (job.stage === "catalog") {
      output = { note: "Kliknij „Dodaj do katalogu w Studio”: pakiet i zabawy trafią do Treści jako szkic." };
    } else if (job.stage === "done") {
      await update(admin, job.id, { status: "done", output: {} });
      return;
    } else {
      const { prompt, maxTokens } = stagePrompt(job, await context(admin, job));
      output = parseJson(await askClaude(SYSTEM, prompt, maxTokens));
    }
    const title = job.title || String(output.title ?? "");
    await update(admin, job.id, { status: "waiting", output, title, error: null });
  } catch (e) {
    console.error("factory:", job.id, job.stage, e);
    await update(admin, job.id, {
      status: "failed",
      error: e instanceof ClaudeError ? "Agent nie odpowiedział. Spróbuj „Popraw” za chwilę." : String(e).slice(0, 500),
    });
  }
}

async function publish(admin: SupabaseClient, job: Job): Promise<Record<string, unknown>> {
  const url = env("WP_URL"), user = env("WP_USER"), pass = env("WP_APP_PASSWORD");
  if (!url || !user || !pass) throw new Error("Brak WP_URL, WP_USER, WP_APP_PASSWORD w sekretach.");
  const auth = `Basic ${btoa(`${user}:${pass}`)}`;
  const wp = async (path: string, init?: RequestInit) => {
    const r = await fetch(`${url.replace(/\/$/, "")}/wp-json/wp/v2${path}`, {
      ...init,
      headers: { Authorization: auth, "content-type": "application/json" },
    });
    if (!r.ok) throw new Error(`WordPress ${r.status}: ${(await r.text()).slice(0, 300)}`);
    return await r.json();
  };
  const article = job.data.article as Record<string, unknown>;
  const name = String(article.category ?? "Zabawy");
  const found = await wp(`/categories?search=${encodeURIComponent(name)}`) as { id: number; name: string }[];
  const category = found.find((c) => c.name.toLowerCase() === name.toLowerCase())?.id ??
    (await wp("/categories", { method: "POST", body: JSON.stringify({ name }) }) as { id: number }).id;
  const { data: setting } = await admin.from("crm_settings").select("value").eq("key", "blog").maybeSingle();
  const status = (setting?.value as { publish_status?: string } | undefined)?.publish_status === "draft" ? "draft" : "publish";
  const post = await wp("/posts", { method: "POST", body: JSON.stringify(wpPost(article, category, status)) }) as {
    id: number;
    link: string;
  };
  const keyword = (job.data.topic as { keyword?: string } | undefined)?.keyword;
  if (keyword) await admin.from("seo_keywords").update({ used_by: job.id }).eq("keyword", keyword);
  return { wp_id: post.id, url: post.link, status };
}

async function voice(admin: SupabaseClient, job: Job): Promise<Record<string, unknown>> {
  const key = env("ELEVENLABS_API_KEY");
  if (!key) throw new Error("Brak ELEVENLABS_API_KEY w sekretach (próbne nagrania).");
  const voiceId = env("ELEVENLABS_VOICE") ?? "PCOFCZ4Ict9D0opt85il"; // Nela
  const limit = Number(env("ELEVENLABS_DRAFT_LIMIT") ?? 20000);
  const scripts = (job.data.scripts as { title: string; text: string }[] | undefined) ?? [];
  const files: { title: string; path: string; chars: number }[] = [];
  let spent = 0;
  for (const [i, s] of scripts.entries()) {
    const text = speakable(s.text);
    if (spent + text.length > limit) break; // a draft is a draft: cost has a ceiling
    const parts: Uint8Array[] = [];
    for (const piece of chunks(text)) {
      const r = await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${voiceId}?output_format=mp3_44100_128`, {
        method: "POST",
        headers: { "xi-api-key": key, "content-type": "application/json" },
        body: JSON.stringify({
          text: piece,
          model_id: env("ELEVENLABS_MODEL") ?? "eleven_v4",
          language_code: "pl",
          voice_settings: { stability: 0.5, similarity_boost: 0.8 },
        }),
      });
      if (!r.ok) throw new Error(`ElevenLabs ${r.status}: ${(await r.text()).slice(0, 200)}`);
      parts.push(new Uint8Array(await r.arrayBuffer()));
    }
    spent += text.length;
    // MP3 frames can simply follow each other.
    const all = new Uint8Array(parts.reduce((a, p) => a + p.length, 0));
    let at = 0;
    for (const p of parts) {
      all.set(p, at);
      at += p.length;
    }
    const path = `${job.id}/${i + 1}.mp3`;
    const { error } = await admin.storage.from("drafts").upload(path, all, { contentType: "audio/mpeg", upsert: true });
    if (error) throw new Error(`storage: ${error.message}`);
    files.push({ title: s.title, path, chars: text.length });
  }
  return { files, chars: spent, skipped: scripts.length - files.length };
}

/** What an approved step adds to the job's data. */
function keep(job: Job, output: Record<string, unknown>): Record<string, unknown> {
  const data = { ...job.data };
  switch (job.stage) {
    case "topic":
      data.topic = output;
      break;
    case "article":
      data.article = output;
      break;
    case "publish":
      data.wp = output;
      break;
    case "idea":
      data.idea = output;
      break;
    case "script": {
      const scripts = [...((data.scripts as unknown[]) ?? [])];
      scripts[job.step_index] = output;
      data.scripts = scripts;
      break;
    }
    case "voice":
      data.voice = output;
      break;
    case "recording":
      data.recording = { done: true, at: new Date().toISOString() };
      break;
    case "listing":
      data.listing = output;
      break;
    case "catalog":
      data.catalog = { done: true, at: new Date().toISOString() };
      break;
  }
  return data;
}

async function load(admin: SupabaseClient, id: string): Promise<Job | null> {
  const { data } = await admin.from("factory_jobs").select("*").eq("id", id).maybeSingle();
  return data as Job | null;
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
    const { data: setting } = await admin.from("crm_settings").select("value").eq("key", "blog").maybeSingle();
    const count = Number((setting?.value as { weekly_topics?: number } | undefined)?.weekly_topics ?? 0);
    const jobs = [];
    for (let i = 0; i < Math.min(count, 5); i++) jobs.push(await createJob(admin, "blog", "", null));
    return json({ created: jobs.length });
  }

  const user = await requestUser(req, admin);
  if (!user) return json({ error: "unauthorized" }, 401);
  const { data: isAdmin } = await admin.from("admins").select("user_id").eq("user_id", user.id).maybeSingle();
  if (!isAdmin) return json({ error: "forbidden" }, 403);
  if (!env("ANTHROPIC_API_KEY") && ["create", "propose_topics", "revise"].includes(String(body.action))) {
    return json({ error: "no_key" }, 412);
  }

  switch (body.action) {
    case "create": {
      const kind = body.kind === "pack" ? "pack" : "blog";
      const job = await createJob(admin, kind, String(body.title ?? "").slice(0, 200), body.note ? String(body.note) : null);
      return json({ id: job.id });
    }
    case "propose_topics": {
      const count = Math.min(Math.max(Number(body.count ?? 3), 1), 5);
      for (let i = 0; i < count; i++) await createJob(admin, "blog", "", null);
      return json({ created: count });
    }
    case "approve": {
      const job = await load(admin, String(body.id));
      if (!job || job.status !== "waiting") return json({ error: "state" }, 409);
      const output = body.output && typeof body.output === "object" ? body.output as Record<string, unknown> : job.output;
      await admin.from("factory_steps").insert({
        job_id: job.id, stage: job.stage, step_index: job.step_index, decision: "approved", output,
      });
      const data = keep(job, output);
      const next = nextStage({ ...job, data });
      const advanced: Job = { ...job, data, stage: next.stage, step_index: next.index, output: {}, feedback: null };
      await update(admin, job.id, {
        data, stage: next.stage, step_index: next.index, output: {}, feedback: null,
        status: next.stage === "done" ? "done" : "working",
      });
      if (next.stage !== "done") background(process(admin, advanced));
      return json({ ok: true, stage: next.stage });
    }
    case "revise": {
      const job = await load(admin, String(body.id));
      const feedback = String(body.feedback ?? "").trim().slice(0, 4000);
      if (!job || !["waiting", "failed"].includes(job.status)) return json({ error: "state" }, 409);
      if (MANUAL_OR_SYSTEM.has(job.stage) && job.stage !== "publish" && job.stage !== "voice") {
        return json({ error: "manual" }, 400);
      }
      await admin.from("factory_steps").insert({
        job_id: job.id, stage: job.stage, step_index: job.step_index, decision: "revise", feedback, output: job.output,
      });
      await update(admin, job.id, { status: "working", feedback: feedback || null, error: null });
      background(process(admin, { ...job, feedback: feedback || null }));
      return json({ ok: true });
    }
    case "reject": {
      const job = await load(admin, String(body.id));
      if (!job) return json({ error: "state" }, 404);
      await admin.from("factory_steps").insert({
        job_id: job.id, stage: job.stage, step_index: job.step_index, decision: "rejected", output: job.output,
      });
      await update(admin, job.id, { status: "rejected" });
      return json({ ok: true });
    }
    case "audio_url": {
      const { data, error } = await admin.storage.from("drafts").createSignedUrl(String(body.path), 3600);
      if (error) return json({ error: "path" }, 404);
      return json({ url: data.signedUrl });
    }
    default:
      return json({ error: "action" }, 400);
  }
}));

async function createJob(admin: SupabaseClient, kind: "blog" | "pack", title: string, note: string | null): Promise<Job> {
  const stage = kind === "blog" ? "topic" : "idea";
  const { data, error } = await admin.from("factory_jobs")
    .insert({ kind, title, stage, status: "working", feedback: note }).select("*").single();
  if (error) throw new Error(`factory create: ${error.message}`);
  background(process(admin, data as Job));
  return data as Job;
}

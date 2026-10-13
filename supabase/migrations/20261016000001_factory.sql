-- The factory (Studio → Fabryka): work the agent does in steps, each approved by Dawid or
-- Nela before the agent starts the next one.
--   blog: topic → article → published on audiokiddo.pl
--   pack: idea → script for each play → voice drafts (ElevenLabs) → Nela records →
--         descriptions and cover brief → into Studio's catalog
create table public.factory_jobs (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('blog', 'pack')),
  title text not null default '' check (length(title) <= 300),
  -- The step it is at (topic, article, publish, idea, script, voice, recording, listing, done).
  stage text not null check (stage ~ '^[a-z_]{2,20}$'),
  -- For steps that repeat (one script per play): which one.
  step_index integer not null default 0,
  -- working: the agent is on it; waiting: for a decision; done; rejected; failed.
  status text not null default 'working' check (status in ('working', 'waiting', 'done', 'rejected', 'failed')),
  -- Everything approved so far, by step.
  data jsonb not null default '{}' check (octet_length(data::text) <= 500000),
  -- What the agent made at the current step, waiting for a decision (editable before approving).
  output jsonb not null default '{}' check (octet_length(output::text) <= 300000),
  feedback text check (feedback is null or length(feedback) <= 4000),
  error text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index factory_jobs_status_idx on public.factory_jobs (status, updated_at desc);
create trigger factory_jobs_touch before update on public.factory_jobs
  for each row execute function public.crm_touch();

-- Every decision, for the history (and so the agent learns what gets approved).
create table public.factory_steps (
  id bigint generated always as identity primary key,
  job_id uuid not null references public.factory_jobs (id) on delete cascade,
  stage text not null,
  step_index integer not null default 0,
  decision text not null check (decision in ('approved', 'revise', 'rejected')),
  feedback text,
  output jsonb not null default '{}' check (octet_length(output::text) <= 300000),
  decided_at timestamptz not null default now()
);
create index factory_steps_job_idx on public.factory_steps (job_id, decided_at);

alter table public.factory_jobs enable row level security;
alter table public.factory_steps enable row level security;
create policy "admins read factory jobs" on public.factory_jobs for select to authenticated using (public.is_admin());
create policy "admins read factory steps" on public.factory_steps for select to authenticated using (public.is_admin());
grant select on public.factory_jobs, public.factory_steps to authenticated;

-- Voice drafts (ElevenLabs) for listening in Studio: a private bucket, read through signed links.
insert into storage.buckets (id, name, public) values ('drafts', 'drafts', false)
on conflict (id) do nothing;

-- The blog topics the agent may draw from: keywords with search volume (from the ads module's
-- keyword research, or added by hand).
insert into public.crm_settings (key, value) values
  ('blog', '{"weekly_topics": 3, "publish_status": "publish"}')
on conflict (key) do nothing;

-- Keywords for the blog and the ads: search volume and competition (Google Ads keyword ideas,
-- or added by hand), so articles and campaigns go where parents actually search.
create table public.seo_keywords (
  keyword text primary key check (length(keyword) between 2 and 120),
  monthly_searches integer,
  competition text check (competition is null or competition in ('LOW', 'MEDIUM', 'HIGH', 'UNSPECIFIED', 'UNKNOWN')),
  cpc_low numeric(10, 2),
  cpc_high numeric(10, 2),
  source text not null default 'manual' check (source in ('google_ads', 'manual', 'agent')),
  -- An article already covers it (blog job id), so topics do not repeat.
  used_by uuid references public.factory_jobs (id) on delete set null,
  updated_at timestamptz not null default now()
);
alter table public.seo_keywords enable row level security;
create policy "admins manage keywords" on public.seo_keywords for all to authenticated
  using (public.is_admin()) with check (public.is_admin());
grant select, insert, update, delete on public.seo_keywords to authenticated;

-- A start: what parents type when looking for this (volumes come with the first sync).
insert into public.seo_keywords (keyword, source) values
  ('zabawy dla dzieci bez ekranu', 'manual'), ('zabawy do samochodu dla dzieci', 'manual'),
  ('zabawy w aucie dla dzieci', 'manual'), ('co robić z dzieckiem w podróży', 'manual'),
  ('zabawy przed snem dla dzieci', 'manual'), ('słuchowiska dla dzieci', 'manual'),
  ('audiobooki dla dzieci', 'manual'), ('bajki do słuchania dla dzieci', 'manual'),
  ('zabawy logopedyczne dla 3 latka', 'manual'), ('zabawy rozwijające wyobraźnię', 'manual'),
  ('zagadki dla dzieci 7 lat', 'manual'), ('jak ograniczyć dziecku telefon', 'manual'),
  ('zabawy słowne dla dzieci', 'manual'), ('co robić z dzieckiem w deszczowy dzień', 'manual'),
  ('wyciszenie dziecka przed snem', 'manual'), ('zabawy dla przedszkolaka w domu', 'manual')
on conflict (keyword) do nothing;

-- The ranking of plays for the agents (service role): the same as CRM → Analiza shows.
create or replace function public.plays_ranking(p_days integer default 30)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  v_since timestamptz := now() - make_interval(days => least(greatest(coalesce(p_days, 30), 1), 365));
begin
  return coalesce((
    with items as (
      select i ->> 'id' id, i ->> 'title' title, i ->> 'pack_id' pack_id, i ->> 'access' access,
             (i ->> 'duration_sec')::int duration_sec
      from jsonb_array_elements(coalesce(public.published_catalog() -> 'manifest' -> 'items', '[]'::jsonb)) i
    ),
    stats as (
      select a.item_id,
             count(*) filter (where a.event = 'play_start') starts,
             count(*) filter (where a.event = 'play_complete') completes,
             count(*) filter (where a.event = 'play_start' and a.props ->> 'replay' = 'true') replays,
             count(*) filter (where a.event = 'play_start' and a.props ->> 'next' = 'true') next_plays,
             count(distinct coalesce(a.user_id::text, a.install_id::text)) filter (where a.event = 'play_start') families
      from public.app_events a
      where a.created_at > v_since and a.item_id is not null and a.event in ('play_start', 'play_complete')
      group by a.item_id
    )
    select jsonb_agg(jsonb_build_object(
      'id', coalesce(i.id, s.item_id),
      'title', coalesce(i.title, s.item_id),
      'pack_id', i.pack_id,
      'free', i.access = 'free',
      'duration_sec', i.duration_sec,
      'starts', coalesce(s.starts, 0),
      'completes', coalesce(s.completes, 0),
      'completion', case when coalesce(s.starts, 0) > 0
                         then round(least(s.completes, s.starts)::numeric / s.starts * 100) end,
      'replays', coalesce(s.replays, 0),
      'next_plays', coalesce(s.next_plays, 0),
      'families', coalesce(s.families, 0)
    ) order by coalesce(s.starts, 0) desc, coalesce(i.title, s.item_id))
    from items i full join stats s on s.item_id = i.id
  ), '[]'::jsonb);
end;
$$;
revoke all on function public.plays_ranking(integer) from public, anon, authenticated;

create or replace function public.crm_plays(p_days integer default 30)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  return public.plays_ranking(p_days);
end;
$$;

-- Mondays 5:15 UTC: new blog topics wait in the factory (crm_settings.blog.weekly_topics).
do $do$
begin
  if exists (select 1 from pg_available_extensions where name = 'pg_cron') then
    create extension if not exists pg_cron;
    create extension if not exists pg_net;
    perform cron.schedule('factory-blog-topics', '15 5 * * 1', $job$
      select net.http_post(
        url := 'https://ypdxofcwewwdyoelamgy.supabase.co/functions/v1/factory',
        headers := jsonb_build_object('content-type', 'application/json',
          'x-cron-secret', (select decrypted_secret from vault.decrypted_secrets where name = 'ads_cron_secret')),
        body := '{"action": "cycle"}'::jsonb, timeout_milliseconds := 60000)
    $job$);
  end if;
end;
$do$;

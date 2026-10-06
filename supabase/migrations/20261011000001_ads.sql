-- Ads in Studio (CRM → Kampanie): Meta Ads, Meta Pixel, Google Ads and Google Analytics 4.
-- The `ads` Edge Function syncs campaigns and daily numbers here, the ads agent proposes
-- changes (budgets, pausing, tasks), and nothing is changed on a platform before an admin
-- approves it in Studio. Everything is written by the function (service role); admins read.

-- Campaigns and ad sets as they are now on the platforms (the ones a budget can be set on).
create table public.ads_entities (
  platform text not null check (platform in ('meta', 'google_ads')),
  entity_id text not null check (length(entity_id) between 1 and 80),
  kind text not null check (kind in ('campaign', 'adset')),
  name text not null default '' check (length(name) <= 300),
  -- active, paused, or the platform's own word for anything else (archived, removed, …).
  status text not null default 'active' check (length(status) <= 40),
  -- The daily budget in the account currency (null when it is set elsewhere, e.g. on ad sets).
  daily_budget numeric(12, 2),
  currency text not null default 'PLN' check (currency ~ '^[A-Z]{3}$'),
  parent_id text,
  data jsonb not null default '{}' check (octet_length(data::text) <= 20000),
  synced_at timestamptz not null default now(),
  primary key (platform, entity_id)
);

-- Numbers per day: campaigns (Meta, Google Ads) and traffic sources (GA4).
create table public.ads_metrics (
  platform text not null check (platform in ('meta', 'google_ads', 'ga4')),
  entity_id text not null check (length(entity_id) between 1 and 200),
  day date not null,
  name text not null default '' check (length(name) <= 300),
  spend numeric(12, 2) not null default 0,
  impressions bigint not null default 0,
  clicks bigint not null default 0,
  -- Purchases (Meta, Google Ads conversions, GA4 key events) and their value.
  conversions numeric(12, 2) not null default 0,
  revenue numeric(12, 2) not null default 0,
  -- GA4: sessions and users; anything else worth keeping.
  data jsonb not null default '{}' check (octet_length(data::text) <= 5000),
  primary key (platform, entity_id, day)
);
create index ads_metrics_day_idx on public.ads_metrics (day desc);

-- What the agent (or an admin) proposes, and what happened to it.
create table public.ads_actions (
  id uuid primary key default gen_random_uuid(),
  platform text not null check (platform in ('meta', 'google_ads', 'ga4', 'site')),
  entity_id text,
  entity_name text not null default '',
  -- set_budget: params.daily_budget; pause / enable: no params; task: becomes a CRM task.
  action text not null check (action in ('set_budget', 'pause', 'enable', 'task')),
  params jsonb not null default '{}' check (octet_length(params::text) <= 5000),
  title text not null check (length(title) between 1 and 200),
  reason text not null default '' check (length(reason) <= 4000),
  expected text not null default '' check (length(expected) <= 2000),
  priority smallint not null default 2 check (priority between 1 and 3),
  status text not null default 'pending'
    check (status in ('pending', 'rejected', 'applied', 'failed', 'expired')),
  result jsonb not null default '{}' check (octet_length(result::text) <= 10000),
  source text not null default 'ai' check (source in ('ai', 'dawid')),
  decided_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  decided_at timestamptz
);
create index ads_actions_status_idx on public.ads_actions (status, created_at desc);

-- The last sync or agent run per source: is it connected, did it work, what did it say.
create table public.ads_status (
  source text primary key check (source in ('meta', 'meta_pixel', 'google_ads', 'ga4', 'agent')),
  ok boolean not null,
  message text not null default '' check (length(message) <= 8000),
  data jsonb not null default '{}' check (octet_length(data::text) <= 20000),
  updated_at timestamptz not null default now()
);

alter table public.ads_entities enable row level security;
alter table public.ads_metrics enable row level security;
alter table public.ads_actions enable row level security;
alter table public.ads_status enable row level security;
create policy "admins read ads entities" on public.ads_entities for select to authenticated using (public.is_admin());
create policy "admins read ads metrics" on public.ads_metrics for select to authenticated using (public.is_admin());
create policy "admins read ads actions" on public.ads_actions for select to authenticated using (public.is_admin());
create policy "admins read ads status" on public.ads_status for select to authenticated using (public.is_admin());
grant select on public.ads_entities, public.ads_metrics, public.ads_actions, public.ads_status to authenticated;

-- The agent's limits, editable in Studio. enabled: the daily run proposes changes;
-- max_daily: no budget above this per campaign; max_change: at most ±50% per step.
insert into public.crm_settings (key, value) values
  ('ads', '{"enabled": true, "max_daily": 150, "max_change": 0.5, "target_cpa": 40}')
on conflict (key) do nothing;

-- The daily run: pg_cron calls the function with a secret kept in Vault, so no key is
-- typed anywhere. The function asks the database whether the secret matches.
do $$
begin
  if not exists (select 1 from vault.secrets where name = 'ads_cron_secret') then
    perform vault.create_secret(
      replace(gen_random_uuid()::text || gen_random_uuid()::text, '-', ''),
      'ads_cron_secret',
      'AudioKiddo Studio: the daily ads sync and agent run'
    );
  end if;
end;
$$;

create or replace function public.ads_cron_ok(p_secret text)
returns boolean language sql stable security definer set search_path = public, vault as $$
  select coalesce(length(p_secret) >= 32 and exists (
    select 1 from vault.decrypted_secrets where name = 'ads_cron_secret' and decrypted_secret = p_secret
  ), false)
$$;
revoke all on function public.ads_cron_ok(text) from public, anon, authenticated;

-- 5:00 UTC: 7:00 in Polish summer time, 6:00 in winter. Rescheduling by name replaces the job.
-- (Only where pg_cron exists: always on Supabase, not in the local test database.)
do $do$
begin
  if exists (select 1 from pg_available_extensions where name = 'pg_cron') then
    create extension if not exists pg_cron;
    create extension if not exists pg_net;
    perform cron.schedule(
      'ads-daily-cycle',
      '0 5 * * *',
      $job$
      select net.http_post(
        url := 'https://ypdxofcwewwdyoelamgy.supabase.co/functions/v1/ads',
        headers := jsonb_build_object(
          'content-type', 'application/json',
          'x-cron-secret', (select decrypted_secret from vault.decrypted_secrets where name = 'ads_cron_secret')
        ),
        body := '{"action": "cycle"}'::jsonb,
        timeout_milliseconds := 150000
      )
      $job$
    );
  end if;
end;
$do$;

-- Ads that pay off (Studio → Kampanie → Kreacje, Konkurencja, Słowa kluczowe):
-- each ad's numbers with an honest verdict, what people typed before clicking, the words parents
-- search for, competitors' ads from the Meta Ad Library (every week), the agent's weekly
-- research and the creatives it writes. Nothing goes live before an admin approves it.

-- Single ads (creatives) as they are now on the platforms.
create table public.ads_ads (
  platform text not null check (platform in ('meta', 'google_ads')),
  ad_id text not null check (length(ad_id) between 1 and 80),
  campaign_id text,
  -- The ad set (Meta) or ad group (Google) it belongs to: creatives are compared within it.
  group_id text,
  name text not null default '' check (length(name) <= 300),
  status text not null default 'active' check (length(status) <= 40),
  kind text not null default '' check (length(kind) <= 60),
  content jsonb not null default '{}' check (octet_length(content::text) <= 20000),
  preview_url text check (preview_url is null or length(preview_url) <= 1000),
  synced_at timestamptz not null default now(),
  primary key (platform, ad_id)
);

create table public.ads_ad_metrics (
  platform text not null check (platform in ('meta', 'google_ads')),
  ad_id text not null,
  day date not null,
  spend numeric(12, 2) not null default 0,
  impressions bigint not null default 0,
  clicks bigint not null default 0,
  conversions numeric(12, 2) not null default 0,
  revenue numeric(12, 2) not null default 0,
  primary key (platform, ad_id, day)
);
create index ads_ad_metrics_day_idx on public.ads_ad_metrics (day desc);

-- Google search ad groups, for placing a new text ad.
create table public.ads_groups (
  platform text not null default 'google_ads' check (platform = 'google_ads'),
  group_id text not null,
  campaign_id text not null,
  name text not null default '',
  campaign_name text not null default '',
  status text not null default 'active',
  synced_at timestamptz not null default now(),
  primary key (platform, group_id)
);

-- What people typed before our Google ad showed (30 days, replaced on every sync).
create table public.ads_search_terms (
  term text not null check (length(term) between 1 and 200),
  campaign_id text not null,
  campaign_name text not null default '',
  -- Google's own: added, excluded, none…
  google_status text not null default 'none',
  impressions bigint not null default 0,
  clicks bigint not null default 0,
  cost numeric(12, 2) not null default 0,
  conversions numeric(12, 2) not null default 0,
  revenue numeric(12, 2) not null default 0,
  synced_at timestamptz not null default now(),
  primary key (campaign_id, term)
);

-- Competitors' ads that reached Poland (Meta Ad Library), kept between scans.
create table public.ads_competitor_ads (
  ad_archive_id text primary key check (length(ad_archive_id) between 1 and 80),
  page_id text not null,
  page_name text not null default '' check (length(page_name) <= 300),
  -- Which search found it (a phrase or a page id from the settings).
  found_by text not null default '' check (length(found_by) <= 200),
  bodies text[] not null default '{}',
  titles text[] not null default '{}',
  descriptions text[] not null default '{}',
  captions text[] not null default '{}',
  start_date date,
  stop_date date,
  platforms text[] not null default '{}',
  reach bigint,
  snapshot_url text,
  target_ages text[] not null default '{}',
  first_seen timestamptz not null default now(),
  last_seen timestamptz not null default now()
);
create index ads_competitor_ads_page_idx on public.ads_competitor_ads (page_id, start_date);

-- The weekly research: the agent's findings for Dawid and Nela.
create table public.ads_research (
  id uuid primary key default gen_random_uuid(),
  summary text not null default '' check (length(summary) <= 12000),
  data jsonb not null default '{}' check (octet_length(data::text) <= 100000),
  created_at timestamptz not null default now()
);

-- Creatives: written by the agent (or by hand), edited and approved in Studio. An approved
-- Google text ad is created paused in the chosen ad group; a Meta one becomes a task with the
-- copy and the brief (pictures and video are made by people).
create table public.ads_creatives (
  id uuid primary key default gen_random_uuid(),
  platform text not null check (platform in ('meta', 'google_ads')),
  format text not null check (format in ('rsa', 'meta_image', 'meta_video')),
  angle text not null default '' check (length(angle) <= 200),
  moment text check (moment is null or length(moment) <= 100),
  content jsonb not null default '{}' check (octet_length(content::text) <= 20000),
  why text not null default '' check (length(why) <= 2000),
  problems text[] not null default '{}',
  -- draft: waits; approved: copy accepted (Meta: a task); live: exists on the platform (paused
  -- until someone turns it on); rejected; retired.
  status text not null default 'draft' check (status in ('draft', 'approved', 'live', 'rejected', 'retired')),
  source text not null default 'ai' check (source in ('ai', 'dawid')),
  research_id uuid references public.ads_research (id) on delete set null,
  feedback text check (feedback is null or length(feedback) <= 2000),
  result jsonb not null default '{}' check (octet_length(result::text) <= 5000),
  created_at timestamptz not null default now(),
  decided_at timestamptz
);
create index ads_creatives_status_idx on public.ads_creatives (status, created_at desc);

-- Keywords: the trend over 12 months and what found them (a seed word or a competitor's site).
alter table public.seo_keywords
  add column trend jsonb not null default '[]' check (octet_length(trend::text) <= 5000),
  add column seed text check (seed is null or length(seed) <= 300),
  add column use_for text not null default 'both' check (use_for in ('blog', 'ads', 'both')),
  add column note text check (note is null or length(note) <= 500);

-- Two more kinds of change: pausing one ad, and a negative keyword in a Google campaign.
alter table public.ads_actions drop constraint ads_actions_action_check;
alter table public.ads_actions add constraint ads_actions_action_check
  check (action in ('set_budget', 'pause', 'enable', 'task', 'pause_ad', 'add_negative'));
alter table public.ads_status drop constraint ads_status_source_check;
alter table public.ads_status add constraint ads_status_source_check
  check (source in ('meta', 'meta_pixel', 'google_ads', 'ga4', 'agent', 'ad_library', 'keywords', 'research'));

alter table public.ads_ads enable row level security;
alter table public.ads_ad_metrics enable row level security;
alter table public.ads_groups enable row level security;
alter table public.ads_search_terms enable row level security;
alter table public.ads_competitor_ads enable row level security;
alter table public.ads_research enable row level security;
alter table public.ads_creatives enable row level security;
create policy "admins read ads" on public.ads_ads for select to authenticated using (public.is_admin());
create policy "admins read ad metrics" on public.ads_ad_metrics for select to authenticated using (public.is_admin());
create policy "admins read ad groups" on public.ads_groups for select to authenticated using (public.is_admin());
create policy "admins read search terms" on public.ads_search_terms for select to authenticated using (public.is_admin());
create policy "admins read competitor ads" on public.ads_competitor_ads for select to authenticated using (public.is_admin());
create policy "admins read research" on public.ads_research for select to authenticated using (public.is_admin());
create policy "admins read creatives" on public.ads_creatives for select to authenticated using (public.is_admin());
grant select on public.ads_ads, public.ads_ad_metrics, public.ads_groups, public.ads_search_terms,
  public.ads_competitor_ads, public.ads_research, public.ads_creatives to authenticated;

-- What the research looks at, editable in Studio.
insert into public.crm_settings (key, value) values
  ('ads_research', '{"enabled": true, "search_terms": ["bajki dla dzieci", "audiobooki dla dzieci", "słuchowiska dla dzieci", "zabawy dla dzieci", "aplikacja dla dzieci", "bez ekranu"], "keyword_seeds": ["zabawy dla dzieci bez ekranu", "zabawy w aucie dla dzieci", "bajki do słuchania", "słuchowiska dla dzieci", "zabawy logopedyczne", "wyciszenie dziecka przed snem"], "competitor_sites": [], "competitor_pages": []}')
on conflict (key) do nothing;

-- Mondays 5:30 UTC: competitors, keywords and the agent's research with new creatives.
do $do$
begin
  if exists (select 1 from pg_available_extensions where name = 'pg_cron') then
    create extension if not exists pg_cron;
    create extension if not exists pg_net;
    perform cron.schedule('ads-weekly-research', '30 5 * * 1', $job$
      select net.http_post(
        url := 'https://ypdxofcwewwdyoelamgy.supabase.co/functions/v1/ads',
        headers := jsonb_build_object('content-type', 'application/json',
          'x-cron-secret', (select decrypted_secret from vault.decrypted_secrets where name = 'ads_cron_secret')),
        body := '{"action": "research"}'::jsonb, timeout_milliseconds := 150000)
    $job$);
  end if;
end;
$do$;

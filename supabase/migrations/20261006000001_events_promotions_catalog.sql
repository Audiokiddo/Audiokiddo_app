-- First-party statistics, server promotions and the catalog published from Studio.
-- No third-party tools (Kids Category): events go only to our own database, without any
-- data about the child (no names, ages, recordings or answers).

-- 1. App events: what parents do, counted per install (a random id made on the phone).
create table public.app_events (
  id bigint generated always as identity primary key,
  install_id uuid not null,
  user_id uuid references auth.users (id) on delete set null,
  event text not null check (event in (
    'first_open', 'app_open', 'onboarding_done',
    'play_start', 'play_complete',
    'paywall_view', 'purchase_start', 'purchase_done',
    'referral_open', 'referral_share', 'promo_view', 'promo_tap',
    'download_pack', 'reminder_on', 'news_alerts_on'
  )),
  item_id text check (item_id is null or item_id ~ '^[a-z0-9._-]{1,80}$'),
  props jsonb not null default '{}' check (octet_length(props::text) <= 1000),
  app_version text check (app_version is null or length(app_version) <= 20),
  platform text check (platform is null or platform in ('ios', 'android', 'web')),
  created_at timestamptz not null default now()
);
create index app_events_time_idx on public.app_events (created_at desc);
create index app_events_event_idx on public.app_events (event, created_at desc);
alter table public.app_events enable row level security;

-- The app may only add events; nobody but the service role (admin function) reads them.
-- A signed-in parent can only send their own user id (or none).
create policy "app adds events" on public.app_events for insert to anon, authenticated
  with check (user_id is null or user_id = auth.uid());
grant insert on public.app_events to anon, authenticated;

-- 2. Promotions shown in the app (Mikołajki, Dzień Dziecka…): real start and end dates.
-- Prices themselves change in App Store Connect, Play Console and the shop; this is the message.
create table public.promotions (
  id uuid primary key default gen_random_uuid(),
  title text not null check (length(title) between 3 and 60),
  body text not null default '' check (length(body) <= 200),
  badge text check (badge is null or length(badge) <= 20),
  -- What the promotion is about: a pack id, 'subscription', 'bundle' or null (general).
  target text check (target is null or target ~ '^[a-z0-9-]{1,40}$'),
  starts_at timestamptz not null,
  ends_at timestamptz not null,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  check (ends_at > starts_at)
);
alter table public.promotions enable row level security;
create policy "everyone reads running promotions" on public.promotions for select to anon, authenticated
  using (active and now() between starts_at and ends_at);
grant select on public.promotions to anon, authenticated;

-- 3. The published catalog for the app: the manifest the pointer shows, readable by everyone
-- (it holds only titles, descriptions and file paths; paid files stay behind download-url).
create or replace function public.published_catalog()
returns jsonb language sql stable security definer set search_path = public as $$
  select jsonb_build_object('version', v.version, 'manifest', v.manifest, 'sha256', v.manifest_sha256)
  from public.catalog_pointer p join public.catalog_versions v on v.version = p.version
$$;
revoke all on function public.published_catalog() from public;
grant execute on function public.published_catalog() to anon, authenticated;

-- Publishing (admin function, service role): a new immutable version, the pointer moves to it,
-- and every file of the manifest is registered for download-url with its item, pack and
-- whether it is free (free plays and previews).
create or replace function public.publish_catalog(p_manifest jsonb, p_sha256 text, p_note text, p_by uuid)
returns integer language plpgsql security definer set search_path = public as $$
declare
  v_version integer;
  v_item jsonb;
  v_free boolean;
  v_asset jsonb;
begin
  insert into public.catalog_versions (manifest, manifest_sha256, note, created_by)
  values (p_manifest, p_sha256, p_note, p_by) returning version into v_version;
  insert into public.catalog_pointer (singleton, version) values (true, v_version)
  on conflict (singleton) do update set version = excluded.version;
  for v_item in select * from jsonb_array_elements(coalesce(p_manifest -> 'items', '[]')) loop
    v_free := coalesce(v_item ->> 'access', '') = 'free';
    for v_asset in
      select * from jsonb_array_elements(coalesce(v_item -> 'audio', '[]'))
      union all select * from jsonb_array_elements(coalesce(v_item -> 'pdf', '[]'))
    loop
      insert into public.content_files (path, item_id, pack_id, free)
      values (v_asset ->> 'path', v_item ->> 'id', v_item ->> 'pack_id', v_free)
      on conflict (path) do update set item_id = excluded.item_id, pack_id = excluded.pack_id, free = excluded.free;
    end loop;
    if v_item ? 'preview' then
      insert into public.content_files (path, item_id, pack_id, free)
      values (v_item -> 'preview' ->> 'path', v_item ->> 'id', v_item ->> 'pack_id', true)
      on conflict (path) do update set free = true;
    end if;
  end loop;
  return v_version;
end;
$$;
revoke all on function public.publish_catalog(jsonb, text, text, uuid) from public, anon, authenticated;

-- Numbers for the Studio dashboard (admin function, service role), last [p_days] days.
create or replace function public.admin_stats(p_days integer)
returns jsonb language sql stable security definer set search_path = public as $$
  with since as (select now() - make_interval(days => p_days) as t)
  select jsonb_build_object(
    'events', coalesce((
      select jsonb_object_agg(event, jsonb_build_object('count', n, 'installs', i))
      from (select event, count(*) n, count(distinct install_id) i from public.app_events, since
            where created_at > since.t group by event) e), '{}'),
    'purchases', coalesce((
      select jsonb_agg(jsonb_build_object('product', product_ref, 'source', source, 'count', n) order by n desc)
      from (select product_ref, source::text, count(distinct store_original_tx_id) n from public.entitlements, since
            where source <> 'manual' and updated_at > since.t group by product_ref, source) p), '[]'),
    'paying_families', (select count(distinct user_id) from public.entitlements
                        where source <> 'manual' and status in ('active', 'grace')
                          and (valid_until is null or valid_until > now())),
    'active_subscriptions', (select count(distinct user_id) from public.entitlements
                             where scope = 'all_content' and source <> 'manual' and status in ('active', 'grace')
                               and (valid_until is null or valid_until > now())),
    'referrals', jsonb_build_object(
      'redeemed', (select count(*) from public.referral_redemptions, since where redeemed_at > since.t),
      'rewarded', (select count(*) from public.referral_redemptions, since where rewarded_at > since.t)),
    'daily', coalesce((
      select jsonb_agg(jsonb_build_object('day', d, 'installs', i, 'plays', p) order by d)
      from (select date_trunc('day', created_at)::date d,
                   count(distinct install_id) filter (where event = 'app_open' or event = 'first_open') i,
                   count(*) filter (where event = 'play_start') p
            from public.app_events, since where created_at > since.t group by 1) x), '[]')
  )
$$;
revoke all on function public.admin_stats(integer) from public, anon, authenticated;

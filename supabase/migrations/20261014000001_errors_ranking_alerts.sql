-- Quality in the CRM: our own error log (the Kids Category allows no Crashlytics or Sentry),
-- a ranking of plays, and a watchdog that checks the business every hour and raises alerts
-- (payments, errors, purchases that do not finish, fewer families, the free plan's limits).

-- 1. Errors from the app. The app strips e-mails and numbers before sending; nothing about
-- the child. Kept for 90 days.
create table public.app_errors (
  id bigint generated always as identity primary key,
  install_id uuid not null,
  user_id uuid references auth.users (id) on delete set null,
  kind text not null check (kind in ('flutter', 'async', 'platform')),
  error_type text not null check (length(error_type) between 1 and 120),
  message text not null default '' check (length(message) <= 1000),
  stack text not null default '' check (length(stack) <= 4000),
  -- Same error, same place in our code: one group in the CRM.
  fingerprint text not null check (fingerprint ~ '^[0-9a-f]{8,16}$'),
  app_version text check (app_version is null or length(app_version) <= 20),
  platform text check (platform is null or platform in ('ios', 'android', 'web')),
  os_version text check (os_version is null or length(os_version) <= 80),
  created_at timestamptz not null default now()
);
create index app_errors_time_idx on public.app_errors (created_at desc);
create index app_errors_fingerprint_idx on public.app_errors (fingerprint, created_at desc);
alter table public.app_errors enable row level security;
create policy "app adds errors" on public.app_errors for insert to anon, authenticated
  with check (user_id is null or user_id = auth.uid());
grant insert on public.app_errors to anon, authenticated;

-- A broken phone in a loop must not fill the database: at most 100 errors a day per install.
create or replace function public.app_errors_limit() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if (select count(*) from public.app_errors
      where install_id = new.install_id and created_at > now() - interval '1 day') >= 100 then
    return null;
  end if;
  return new;
end;
$$;
create trigger app_errors_limit before insert on public.app_errors
  for each row execute function public.app_errors_limit();

-- Errors grouped for the CRM: how often, on how many phones, since and until when.
create or replace function public.crm_errors(p_days integer default 7)
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  return coalesce((
    select jsonb_agg(g order by (g ->> 'count')::int desc)
    from (
      select jsonb_build_object(
        'fingerprint', e.fingerprint,
        'error_type', (array_agg(e.error_type order by e.created_at desc))[1],
        'message', (array_agg(e.message order by e.created_at desc))[1],
        'stack', (array_agg(e.stack order by e.created_at desc))[1],
        'count', count(*),
        'installs', count(distinct e.install_id),
        'first_seen', min(e.created_at),
        'last_seen', max(e.created_at),
        'versions', (select jsonb_agg(distinct v) from unnest(array_agg(e.app_version)) v where v is not null),
        'platforms', (select jsonb_agg(distinct p) from unnest(array_agg(e.platform)) p where p is not null)
      ) g
      from public.app_errors e
      where e.created_at > now() - make_interval(days => least(greatest(coalesce(p_days, 7), 1), 90))
      group by e.fingerprint
      limit 200
    ) groups
  ), '[]'::jsonb);
end;
$$;
revoke all on function public.crm_errors(integer) from public, anon;
grant execute on function public.crm_errors(integer) to authenticated;

-- 2. Every play of the published catalog: started, finished, replayed, played next, on how
-- many phones. Plays nobody started are listed too (they may need a better place).
create or replace function public.crm_plays(p_days integer default 30)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  v_since timestamptz := now() - make_interval(days => least(greatest(coalesce(p_days, 30), 1), 365));
begin
  if not public.is_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
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
revoke all on function public.crm_plays(integer) from public, anon;
grant execute on function public.crm_plays(integer) to authenticated;

-- 3. The watchdog: one row per open alert, updated every hour, closed when it passes.
create table public.crm_alerts (
  id uuid primary key default gen_random_uuid(),
  code text not null check (code ~ '^[a-z_:0-9]{1,80}$'),
  level text not null check (level in ('critical', 'warning', 'info')),
  title text not null check (length(title) <= 200),
  detail text not null default '' check (length(detail) <= 2000),
  first_seen timestamptz not null default now(),
  last_seen timestamptz not null default now(),
  acknowledged_at timestamptz,
  resolved_at timestamptz
);
create unique index crm_alerts_open_idx on public.crm_alerts (code) where resolved_at is null;
alter table public.crm_alerts enable row level security;
create policy "admins read alerts" on public.crm_alerts for select to authenticated using (public.is_admin());
grant select on public.crm_alerts to authenticated;

create or replace function public.crm_watch()
returns integer language plpgsql security definer set search_path = public, auth as $$
declare
  v jsonb := '[]'::jsonb;
  n bigint;
  m bigint;
  a record;
begin
  -- Payments the stores could not take: the family may lose access soon.
  select count(distinct user_id) into n from public.entitlements
  where status in ('billing_retry', 'grace') and scope = 'all_content';
  if n > 0 then
    v := v || jsonb_build_object('code', 'payments', 'level', 'warning',
      'title', n || ' rodzin ma problem z płatnością',
      'detail', 'Sklep ponawia płatność. Rodzic zobaczy prośbę w App Store / Google Play; w CRM → Użytkownicy sprawdzisz konto.');
  end if;

  -- Subscriptions that ended this week.
  select count(distinct user_id) into n from public.entitlements
  where scope = 'all_content' and source <> 'manual'
    and status in ('expired', 'revoked', 'refunded') and updated_at > now() - interval '7 days';
  if n > 0 then
    v := v || jsonb_build_object('code', 'churn', 'level', 'info',
      'title', n || ' abonamentów zakończyło się w 7 dni',
      'detail', 'Warto zapytać o powód (mail) i rozważyć ofertę powrotu.');
  end if;

  -- Purchases that start but do not finish (store, verification or network trouble).
  select count(*) filter (where event = 'purchase_start'), count(*) filter (where event = 'purchase_done')
  into n, m from public.app_events where created_at > now() - interval '7 days';
  if n >= 5 and m::numeric / n < 0.3 then
    v := v || jsonb_build_object('code', 'purchases_failing', 'level', 'critical',
      'title', 'Zakupy się nie kończą: ' || m || ' z ' || n || ' w 7 dni',
      'detail', 'Sprawdź funkcję verify-purchase (Supabase → Edge Functions → Logs) i produkty w sklepach.');
  end if;

  -- Errors: many more than usual, or a new one on several phones.
  select count(*) into n from public.app_errors where created_at > now() - interval '1 day';
  select count(*) into m from public.app_errors
  where created_at > now() - interval '8 days' and created_at <= now() - interval '1 day';
  if n >= 5 and n > 3 * greatest(m / 7.0, 1) then
    v := v || jsonb_build_object('code', 'errors_spike', 'level', 'critical',
      'title', n || ' błędów aplikacji w 24 h (zwykle ok. ' || round(m / 7.0) || ')',
      'detail', 'CRM → Błędy: najczęstszy błąd i wersja aplikacji.');
  end if;
  for a in
    select fingerprint, (array_agg(error_type))[1] error_type, count(distinct install_id) installs
    from public.app_errors
    group by fingerprint
    having min(created_at) > now() - interval '1 day' and count(distinct install_id) >= 3
  loop
    v := v || jsonb_build_object('code', 'new_error:' || a.fingerprint, 'level', 'warning',
      'title', 'Nowy błąd na ' || a.installs || ' telefonach: ' || a.error_type,
      'detail', 'Pojawił się w ostatniej dobie. CRM → Błędy.');
  end loop;

  -- Fewer families than the week before.
  select count(distinct coalesce(user_id::text, install_id::text)) into n from public.app_events
  where created_at > now() - interval '7 days' and event in ('app_open', 'play_start');
  select count(distinct coalesce(user_id::text, install_id::text)) into m from public.app_events
  where created_at > now() - interval '14 days' and created_at <= now() - interval '7 days'
    and event in ('app_open', 'play_start');
  if m >= 10 and n < m * 0.7 then
    v := v || jsonb_build_object('code', 'active_drop', 'level', 'warning',
      'title', 'Aktywnych rodzin mniej o ' || round((1 - n::numeric / m) * 100) || '% (' || n || ' zamiast ' || m || ')',
      'detail', 'Sprawdź błędy, ostatnią wersję i przypomnienia. Może brakuje nowości?');
  end if;

  -- Nothing at all from the apps for a day, while people use them.
  if (select count(*) from auth.users where not is_anonymous) >= 20
     and not exists (select 1 from public.app_events where created_at > now() - interval '1 day') then
    v := v || jsonb_build_object('code', 'no_events', 'level', 'critical',
      'title', 'Od doby żadnych zdarzeń z aplikacji',
      'detail', 'Aplikacja może nie łączyć się z serwerem. Sprawdź Supabase (czy projekt nie jest uśpiony) i ostatnią wersję.');
  end if;

  -- Shop orders whose buyers have not opened them in the app.
  select count(distinct woo_order_id) into n from public.web_purchases_pending
  where order_status = 'completed' and claimed_by is null and created_at < now() - interval '3 days';
  if n > 0 then
    v := v || jsonb_build_object('code', 'web_unclaimed', 'level', 'info',
      'title', n || ' zamówień z audiokiddo.pl czeka na odebranie w aplikacji',
      'detail', 'Kupujący nie zalogowali się tym adresem. Warto wysłać przypomnienie z instrukcją.');
  end if;

  -- The free plan holds 500 MB.
  if pg_database_size(current_database()) > 400 * 1024 * 1024 then
    v := v || jsonb_build_object('code', 'db_size', 'level', 'warning',
      'title', 'Baza ma ' || pg_size_pretty(pg_database_size(current_database())) || ' (plan Free: 500 MB)',
      'detail', 'Czas na plan Pro albo porządki w starych zdarzeniach.');
  end if;

  -- Ad sources that stopped working.
  for a in select source, message from public.ads_status where not ok and source <> 'agent' loop
    v := v || jsonb_build_object('code', 'ads:' || a.source, 'level', 'warning',
      'title', 'Kampanie: ' || a.source || ' nie działa',
      'detail', left(a.message, 500));
  end loop;

  -- Decisions waiting too long.
  select count(*) into n from public.crm_items where decision = 'pending' and created_at < now() - interval '3 days';
  if n > 0 then
    v := v || jsonb_build_object('code', 'decisions', 'level', 'info',
      'title', n || ' propozycji czeka na decyzję dłużej niż 3 dni',
      'detail', 'CRM → Decyzje.');
  end if;

  -- Open, refresh or close.
  for a in select * from jsonb_to_recordset(v) as x(code text, level text, title text, detail text) loop
    update public.crm_alerts set level = a.level, title = a.title, detail = a.detail, last_seen = now()
    where code = a.code and resolved_at is null;
    if not found then
      insert into public.crm_alerts (code, level, title, detail) values (a.code, a.level, a.title, a.detail);
    end if;
  end loop;
  update public.crm_alerts set resolved_at = now()
  where resolved_at is null and code not in (select x ->> 'code' from jsonb_array_elements(v) x);

  delete from public.app_errors where created_at < now() - interval '90 days';
  delete from public.crm_alerts where resolved_at < now() - interval '90 days';
  return jsonb_array_length(v);
end;
$$;
revoke all on function public.crm_watch() from public, anon, authenticated;

-- What Studio shows: checked right now, open alerts first by level.
create or replace function public.crm_alerts_now()
returns jsonb language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  perform public.crm_watch();
  return coalesce((
    select jsonb_agg(to_jsonb(a) order by
      case a.level when 'critical' then 0 when 'warning' then 1 else 2 end, a.first_seen desc)
    from public.crm_alerts a where a.resolved_at is null), '[]'::jsonb);
end;
$$;
revoke all on function public.crm_alerts_now() from public, anon;
grant execute on function public.crm_alerts_now() to authenticated;

create or replace function public.crm_ack(p_id uuid)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  update public.crm_alerts set acknowledged_at = now() where id = p_id;
end;
$$;
revoke all on function public.crm_ack(uuid) from public, anon;
grant execute on function public.crm_ack(uuid) to authenticated;

-- Every hour, in the database itself (no function call, no key).
do $do$
begin
  if exists (select 1 from pg_available_extensions where name = 'pg_cron') then
    create extension if not exists pg_cron;
    perform cron.schedule('crm-watch-hourly', '7 * * * *', 'select public.crm_watch()');
  end if;
end;
$do$;

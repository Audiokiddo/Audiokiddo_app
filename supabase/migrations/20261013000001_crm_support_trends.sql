-- CRM, part two: customer support (find an account, see its purchases and activity, give or
-- take back access by hand), weekly trends for the dashboard, and the agent's own rhythm
-- (a morning report, ad ideas on Mondays, a newsletter draft every other Thursday), whose
-- proposals still wait in "Decyzje".

-- 1. A customer by e-mail: the account, every purchase and 30 days of activity. Admins only.
create or replace function public.crm_customer(p_email text)
returns jsonb language plpgsql stable security definer set search_path = public, auth as $$
declare
  u record;
begin
  if not public.is_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  select id, email, created_at, last_sign_in_at into u
  from auth.users
  where lower(email) = lower(trim(p_email)) and deleted_at is null
  order by created_at desc
  limit 1;
  if u.id is null then
    return null;
  end if;
  return jsonb_build_object(
    'id', u.id,
    'email', u.email,
    'created_at', u.created_at,
    'last_sign_in_at', u.last_sign_in_at,
    'entitlements', coalesce((
      select jsonb_agg(jsonb_build_object(
        'scope', e.scope, 'status', e.status, 'source', e.source, 'valid_until', e.valid_until,
        'product_ref', e.product_ref, 'updated_at', e.updated_at) order by e.updated_at desc)
      from public.entitlements e where e.user_id = u.id), '[]'::jsonb),
    'activity', (
      select jsonb_build_object(
        'opens', count(*) filter (where a.event = 'app_open'),
        'plays', count(*) filter (where a.event = 'play_start'),
        'completed', count(*) filter (where a.event = 'play_complete'),
        'paywall_views', count(*) filter (where a.event = 'paywall_view'),
        'last_seen', max(a.created_at),
        'platform', (array_agg(a.platform order by a.created_at desc) filter (where a.platform is not null))[1],
        'app_version', (array_agg(a.app_version order by a.created_at desc) filter (where a.app_version is not null))[1])
      from public.app_events a
      where a.user_id = u.id and a.created_at > now() - interval '30 days')
  );
end;
$$;
revoke all on function public.crm_customer(text) from public, anon;
grant execute on function public.crm_customer(text) to authenticated;

-- 2. Access given by hand (a gift, a complaint, a tester): a "manual" entitlement, which the
-- revenue figures leave out. Every change is noted in the CRM history.
create or replace function public.crm_grant(p_user uuid, p_scope text, p_days integer, p_note text)
returns void language plpgsql security definer set search_path = public, auth as $$
declare
  v_email text;
begin
  if not public.is_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  if p_scope !~ '^(all_content|pack:[a-z0-9-]+)$' then
    raise exception 'scope' using errcode = '22023';
  end if;
  if p_days is null or p_days not between 1 and 3660 then
    raise exception 'days' using errcode = '22023';
  end if;
  select email into v_email from auth.users where id = p_user;
  if v_email is null then
    raise exception 'user' using errcode = '22023';
  end if;
  insert into public.entitlements (user_id, source, scope, status, valid_until, product_ref, store_original_tx_id)
  values (p_user, 'manual', p_scope, 'active', now() + make_interval(days => p_days), 'crm', 'manual:crm:' || p_user)
  on conflict (source, store_original_tx_id, scope)
    do update set status = 'active', valid_until = excluded.valid_until, updated_at = now();
  insert into public.crm_items (kind, area, title, body, status, source)
  values ('change', 'support', left('Dostęp ręczny: ' || p_scope || ' na ' || p_days || ' dni', 200),
          left('Konto: ' || v_email || coalesce(E'\n' || nullif(trim(p_note), ''), ''), 2000), 'done', 'dawid');
end;
$$;
revoke all on function public.crm_grant(uuid, text, integer, text) from public, anon;
grant execute on function public.crm_grant(uuid, text, integer, text) to authenticated;

create or replace function public.crm_revoke(p_user uuid, p_scope text)
returns void language plpgsql security definer set search_path = public, auth as $$
begin
  if not public.is_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  update public.entitlements set status = 'revoked', updated_at = now()
  where user_id = p_user and source = 'manual' and scope = p_scope;
  insert into public.crm_items (kind, area, title, body, status, source)
  select 'change', 'support', left('Cofnięty dostęp ręczny: ' || p_scope, 200), 'Konto: ' || email, 'done', 'dawid'
  from auth.users where id = p_user;
end;
$$;
revoke all on function public.crm_revoke(uuid, text) from public, anon;
grant execute on function public.crm_revoke(uuid, text) to authenticated;

-- 3. Week by week: new accounts, active families, plays, offers seen, purchases in the app and
-- their estimated value. Monday-based weeks, the current one last.
create or replace function public.crm_trend(p_weeks integer default 12)
returns jsonb language plpgsql stable security definer set search_path = public, auth as $$
declare
  v_weeks integer := least(greatest(coalesce(p_weeks, 12), 4), 52);
begin
  if not public.is_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  return (
    with weeks as (
      select w from generate_series(
        date_trunc('week', now()) - make_interval(weeks => v_weeks - 1),
        date_trunc('week', now()),
        interval '1 week') w
    )
    select coalesce(jsonb_agg(jsonb_build_object(
      'week', to_char(w, 'YYYY-MM-DD'),
      'accounts', (select count(*) from auth.users u
                   where u.created_at >= w and u.created_at < w + interval '1 week'
                     and not u.is_anonymous and u.deleted_at is null),
      'active', (select count(distinct coalesce(a.user_id::text, a.install_id::text)) from public.app_events a
                 where a.created_at >= w and a.created_at < w + interval '1 week'
                   and a.event in ('app_open', 'play_start')),
      'plays', (select count(*) from public.app_events a
                where a.created_at >= w and a.created_at < w + interval '1 week' and a.event = 'play_start'),
      'paywall_views', (select count(*) from public.app_events a
                        where a.created_at >= w and a.created_at < w + interval '1 week' and a.event = 'paywall_view'),
      'purchases', (select count(*) from public.app_events a
                    where a.created_at >= w and a.created_at < w + interval '1 week' and a.event = 'purchase_done'),
      'revenue', (select coalesce(sum(public.crm_price(a.props ->> 'product')), 0) from public.app_events a
                  where a.created_at >= w and a.created_at < w + interval '1 week' and a.event = 'purchase_done')
    ) order by w), '[]'::jsonb)
    from weeks
  );
end;
$$;
revoke all on function public.crm_trend(integer) from public, anon;
grant execute on function public.crm_trend(integer) to authenticated;

-- 4. The agent's rhythm, editable in Studio → CRM → Ustawienia.
insert into public.crm_settings (key, value) values
  ('coo_rhythm', '{"brief_daily": true, "ads_weekly": true, "newsletter_biweekly": true}')
on conflict (key) do nothing;

-- The coo function checks the cron with the same Vault secret as the ads cycle.
do $do$
begin
  if exists (select 1 from pg_available_extensions where name = 'pg_cron') then
    create extension if not exists pg_cron;
    create extension if not exists pg_net;
    -- 4:30 UTC: 6:30 in Polish summer time, 5:30 in winter (before the ads cycle).
    perform cron.schedule(
      'coo-daily-rhythm',
      '30 4 * * *',
      $job$
      select net.http_post(
        url := 'https://ypdxofcwewwdyoelamgy.supabase.co/functions/v1/coo',
        headers := jsonb_build_object(
          'content-type', 'application/json',
          'x-cron-secret', (select decrypted_secret from vault.decrypted_secrets where name = 'ads_cron_secret')
        ),
        body := '{"mode": "auto"}'::jsonb,
        timeout_milliseconds := 300000
      )
      $job$
    );
  end if;
end;
$do$;

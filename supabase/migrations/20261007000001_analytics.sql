-- Advanced first-party analytics for the Studio dashboard: completions, replays, moving on to
-- the next play, how often families come back (retention by first-open cohort), conversion
-- from a free play to a purchase and how long subscriptions last. Still our own database only
-- (Kids Category), counted per install with no data about the child.

-- New events: the welcome after the first sign-in, Szop’en's tour and the "Co teraz?" pick.
alter table public.app_events drop constraint app_events_event_check;
alter table public.app_events add constraint app_events_event_check check (event in (
  'first_open', 'app_open', 'onboarding_done',
  'play_start', 'play_complete',
  'paywall_view', 'purchase_start', 'purchase_done',
  'referral_open', 'referral_share', 'promo_view', 'promo_tap',
  'download_pack', 'reminder_on', 'news_alerts_on',
  'welcome_done', 'tour_done', 'quick_pick'
));
create index if not exists app_events_install_idx on public.app_events (install_id, created_at);

-- Percentage with one decimal, null when there is nothing to divide by.
create or replace function public.pct(a bigint, b bigint)
returns numeric language sql immutable as $$
  select case when b > 0 then round(100.0 * a / b, 1) end
$$;

create or replace function public.admin_analytics(p_days integer)
returns jsonb language sql stable security definer set search_path = public as $$
  with
  since as (select now() - make_interval(days => p_days) as t),
  ev as (select e.* from public.app_events e, since where e.created_at > since.t),
  plays as (
    select count(*) filter (where event = 'play_start') starts,
           count(*) filter (where event = 'play_complete') completes,
           count(*) filter (where event = 'play_start' and props ->> 'replay' = 'true') replays,
           count(*) filter (where event = 'play_start' and props ->> 'next' = 'true') nexts
    from ev),
  items as (
    select item_id,
           count(*) filter (where event = 'play_start') s,
           count(*) filter (where event = 'play_complete') c,
           count(*) filter (where event = 'play_start' and props ->> 'replay' = 'true') r
    from ev where item_id is not null and event in ('play_start', 'play_complete') group by item_id),
  -- How often: active days and plays per install that was active in the period.
  usage as (
    select install_id, count(distinct created_at::date) d, count(*) filter (where event = 'play_start') p
    from ev group by install_id),
  -- Coming back: every install's first day, then whether it was active on later days.
  first_seen as (select install_id, min(created_at)::date f from public.app_events group by install_id),
  activity as (select distinct install_id, created_at::date d from public.app_events),
  cohort as (
    select fs.install_id, fs.f,
           bool_or(a.d = fs.f + 1) d1,
           bool_or(a.d between fs.f + 1 and fs.f + 7) w1,
           bool_or(a.d between fs.f + 7 and fs.f + 13) w2,
           bool_or(a.d between fs.f + 28 and fs.f + 34) m1,
           bool_or(a.d between fs.f + 7 and fs.f + 13) k1,
           bool_or(a.d between fs.f + 14 and fs.f + 20) k2,
           bool_or(a.d between fs.f + 21 and fs.f + 27) k3,
           bool_or(a.d between fs.f + 28 and fs.f + 34) k4
    from first_seen fs join activity a using (install_id), since
    where fs.f > (since.t)::date - 35
    group by fs.install_id, fs.f),
  -- From a free play to paying (purchase in the app after a free play on the same install).
  free_players as (select install_id, min(created_at) t from ev
                   where event = 'play_start' and props ->> 'free' = 'true' group by install_id),
  buyers as (select install_id, min(created_at) t from public.app_events
             where event = 'purchase_done' group by install_id),
  subs as (
    select user_id,
           bool_or(status in ('active', 'grace') and (valid_until is null or valid_until > now())) active,
           bool_or(product_ref like '%yearly%') yearly
    from public.entitlements where scope = 'all_content' and source <> 'manual' group by user_id)
  select jsonb_build_object(
    'plays', (select jsonb_build_object(
      'starts', starts, 'completes', completes, 'replays', replays, 'next_plays', nexts,
      'completion_rate', public.pct(completes, starts),
      'replay_rate', public.pct(replays, starts),
      'next_rate', public.pct(nexts, completes)) from plays),
    'top_items', coalesce((
      select jsonb_agg(jsonb_build_object('item', item_id, 'starts', s, 'completion_rate', public.pct(c, s),
                                          'replay_rate', public.pct(r, s)) order by s desc)
      from (select * from items order by s desc limit 15) i), '[]'),
    'frequency', (select jsonb_build_object(
      'active_installs', count(*),
      'avg_active_days', round(avg(d), 1),
      'avg_plays', round(avg(p), 1),
      'days_1', count(*) filter (where d = 1),
      'days_2_3', count(*) filter (where d between 2 and 3),
      'days_4_7', count(*) filter (where d between 4 and 7),
      'days_8_plus', count(*) filter (where d >= 8)) from usage),
    'retention', (select jsonb_build_object(
      'd1', public.pct(count(*) filter (where d1 and f + 1 < current_date), count(*) filter (where f + 1 < current_date)),
      'week1', public.pct(count(*) filter (where w1 and f + 7 < current_date), count(*) filter (where f + 7 < current_date)),
      'week2', public.pct(count(*) filter (where w2 and f + 13 < current_date), count(*) filter (where f + 13 < current_date)),
      'month1', public.pct(count(*) filter (where m1 and f + 34 < current_date), count(*) filter (where f + 34 < current_date)),
      'new_installs', count(*)) from cohort),
    'cohorts', coalesce((
      select jsonb_agg(jsonb_build_object(
        'week', w, 'installs', n,
        'week1', case when w + 13 < current_date then public.pct(a1, n) end,
        'week2', case when w + 20 < current_date then public.pct(a2, n) end,
        'week3', case when w + 27 < current_date then public.pct(a3, n) end,
        'week4', case when w + 34 < current_date then public.pct(a4, n) end) order by w desc)
      from (select date_trunc('week', f)::date w, count(*) n, count(*) filter (where k1) a1,
                   count(*) filter (where k2) a2, count(*) filter (where k3) a3, count(*) filter (where k4) a4
            from cohort group by 1) c), '[]'),
    'conversion', (select jsonb_build_object(
      'free_players', (select count(*) from free_players),
      'paid_after_free', (select count(*) from free_players fp join buyers b using (install_id) where b.t > fp.t),
      'rate', public.pct((select count(*) from free_players fp join buyers b using (install_id) where b.t > fp.t),
                         (select count(*) from free_players)),
      'paywall_installs', (select count(distinct install_id) from ev where event = 'paywall_view'),
      'checkout_installs', (select count(distinct install_id) from ev where event = 'purchase_start'),
      'buyer_installs', (select count(distinct install_id) from ev where event = 'purchase_done'),
      'paywall_from', coalesce((select jsonb_object_agg(f, n) from (
        select coalesce(props ->> 'from', 'inne') f, count(*) n from ev where event = 'paywall_view' group by 1) x), '{}'))),
    'subscriptions', (select jsonb_build_object(
      'ever', count(*), 'active', count(*) filter (where active),
      'ended', count(*) filter (where not active),
      'retention', public.pct(count(*) filter (where active), count(*)),
      'active_yearly', count(*) filter (where active and yearly),
      'active_monthly', count(*) filter (where active and not yearly)) from subs),
    'onboarding', jsonb_build_object(
      'welcome_done', (select count(distinct install_id) from ev where event = 'welcome_done'),
      'tour_done', (select count(distinct install_id) from ev where event = 'tour_done'),
      'quick_picks', (select count(*) from ev where event = 'quick_pick'))
  )
$$;
revoke all on function public.admin_analytics(integer) from public, anon, authenticated;

-- The dashboard numbers now carry the analytics too (same admin function, no redeploy).
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
            from public.app_events, since where created_at > since.t group by 1) x), '[]'),
    'analytics', public.admin_analytics(p_days)
  )
$$;
revoke all on function public.admin_stats(integer) from public, anon, authenticated;

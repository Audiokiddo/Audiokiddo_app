-- Analytics annex (docs/ANEKS-ANALITYCZNY.md): the global parameters on every event, the
-- events the KPIs need (game_viewed, play_exit, checkout_failed, favourites, search, the
-- parent's answer where they heard of us) and admin_kpi(): North Star, activation, retention,
-- per-play table, drop-off map, monetisation, growth by source and data health.
-- A "family" is an install (one phone); nothing here names a person or a child.

alter table public.app_events
  add column if not exists session_id uuid,
  add column if not exists age_group text check (age_group is null or age_group in ('3-5', '5-7', '7-9')),
  add column if not exists plan text check (plan is null or plan in ('free', 'subscription', 'package_only')),
  add column if not exists source text check (source is null or source ~ '^[a-z_]{1,30}$'),
  add column if not exists country text check (country is null or country ~ '^[A-Z]{2}$');

alter table public.app_events drop constraint app_events_event_check;
alter table public.app_events add constraint app_events_event_check check (event in (
  'first_open', 'app_open', 'onboarding_done',
  'play_start', 'play_complete',
  'paywall_view', 'purchase_start', 'purchase_done',
  'referral_open', 'referral_share', 'promo_view', 'promo_tap',
  'download_pack', 'reminder_on', 'news_alerts_on',
  'welcome_done', 'tour_done', 'quick_pick',
  'game_viewed', 'play_exit', 'checkout_failed',
  'favorite_added', 'favorite_removed', 'search_performed', 'source_answered'
));
create index if not exists app_events_item_idx on public.app_events (item_id, event, created_at)
  where item_id is not null;

-- The plan of a store product: monthly, annual or a pack bought for good.
create or replace function public.plan_of(p_ref text)
returns text language sql immutable as $$
  select case
    when p_ref ilike '%sub.monthly%' then 'monthly'
    when p_ref ilike '%sub.yearly%' then 'annual'
    when p_ref is null then null
    else 'package'
  end
$$;

create or replace function public.admin_kpi(p_days integer, p_age text default null)
returns jsonb language sql stable security definer set search_path = public as $$
  with
  since as (select now() - make_interval(days => p_days) t),
  ev as (select * from public.app_events where p_age is null or age_group = p_age),
  -- Every family's first day with us and where they came from (their last answer).
  fam as (
    select install_id, min(created_at) first_at,
           (array_agg(source order by created_at desc) filter (where source is not null))[1] src
    from ev group by install_id),
  starts as (select install_id, item_id, created_at,
                    row_number() over (partition by install_id order by created_at) n
             from ev where event = 'play_start' and item_id is not null),
  completes as (select install_id, item_id, created_at from ev where event = 'play_complete' and item_id is not null),
  -- First play of each family and whether it was heard to the end.
  first_play as (
    select s.install_id, s.item_id, s.created_at,
           exists (select 1 from completes c where c.install_id = s.install_id and c.item_id = s.item_id
                     and c.created_at > s.created_at) done
    from starts s where s.n = 1),
  -- Activated: finished a play and then started another (a different play or a replay).
  activated as (
    select c.install_id, min(c.created_at) at
    from (select install_id, min(created_at) created_at from completes group by install_id) c
    where exists (select 1 from starts s where s.install_id = c.install_id and s.created_at > c.created_at)
    group by c.install_id),
  new_fam as (select f.* from fam f, since where f.first_at > since.t),
  -- Weekly Returning Families: finished something on 2+ different days of one week.
  done_days as (select distinct install_id, created_at::date d from completes),
  wrf as (
    select date_trunc('week', d)::date w, count(*) families
    from (select install_id, date_trunc('week', d) wk, min(d) d, count(*) days
          from done_days group by install_id, date_trunc('week', d)) x
    where days >= 2 group by 1),
  wrf_now as (
    select count(*) n from (select install_id from done_days where d > current_date - 7
                            group by install_id having count(*) >= 2) x),
  active_week as (
    select install_id, count(*) days from done_days where d > current_date - 7 group by install_id),
  -- Retention counted from activation: a finished play inside the window.
  ret as (
    select a.install_id, a.at::date a0,
           bool_or(dd.d between a.at::date + 7 and a.at::date + 13) d7,
           bool_or(dd.d between a.at::date + 28 and a.at::date + 34) d30,
           bool_or(dd.d between a.at::date + 30 and a.at::date + 59) m2,
           bool_or(dd.d between a.at::date + 60 and a.at::date + 89) m3
    from activated a left join done_days dd using (install_id)
    group by a.install_id, a.at),
  -- Per play: starts, families, finishes, 7-day replay per family, next play, exits.
  per_item as (
    select s.item_id,
           count(*) starts,
           count(distinct s.install_id) families,
           (select count(*) from completes c, since where c.item_id = s.item_id and c.created_at > since.t) completes
    from starts s, since where s.created_at > since.t group by s.item_id),
  replay7 as (
    select item_id, count(*) firsts,
           count(*) filter (where exists (
             select 1 from starts s2 where s2.install_id = f.install_id and s2.item_id = f.item_id
               and s2.created_at > f.created_at + interval '10 minutes'
               and s2.created_at <= f.created_at + interval '7 days')) replayed
    from (select install_id, item_id, min(created_at) created_at from starts group by 1, 2) f, since
    where f.created_at > since.t group by item_id),
  next_after as (
    select c.item_id, count(distinct c.install_id) finishers,
           count(distinct c.install_id) filter (where exists (
             select 1 from starts s where s.install_id = c.install_id and s.item_id <> c.item_id
               and s.created_at between c.created_at and c.created_at + interval '30 minutes')) went_on
    from completes c, since where c.created_at > since.t group by c.item_id),
  exits as (
    select item_id, (props ->> 'exit_second')::int sec, (props ->> 'pct')::int pct
    from ev, since
    where event = 'play_exit' and item_id is not null and created_at > since.t
      and props ->> 'exit_second' ~ '^[0-9]{1,6}$' and coalesce(props ->> 'pct', '0') ~ '^[0-9]{1,3}$'),
  -- Monetisation: families that played free, saw the offer, paid (in the app).
  free_fam as (select install_id, min(created_at) t from ev, since
               where event = 'play_start' and props ->> 'free' = 'true' and created_at > since.t group by 1),
  paywall_fam as (select distinct install_id from ev, since where event = 'paywall_view' and created_at > since.t),
  buy_fam as (select install_id, min(created_at) t from ev where event = 'purchase_done' group by 1),
  subs as (
    select user_id, product_ref, status, valid_until, updated_at,
           status in ('active', 'grace') and (valid_until is null or valid_until > now()) active
    from public.entitlements where scope = 'all_content' and source <> 'manual'),
  period_ev as (select e.* from ev e, since where e.created_at > since.t)
  select jsonb_build_object(
    'days', p_days,
    'age', p_age,
    'ceo', jsonb_build_object(
      'weekly_returning_families', (select n from wrf_now),
      'wrf_trend', coalesce((select jsonb_agg(jsonb_build_object('week', w, 'families', families) order by w)
                             from (select * from wrf order by w desc limit 12) t), '[]'),
      'new_families', (select count(*) from new_fam),
      'new_activated', (select count(*) from activated a join new_fam using (install_id)),
      'technical_activation', public.pct(
        (select count(*) from new_fam nf where exists (select 1 from starts s where s.install_id = nf.install_id)),
        (select count(*) from new_fam)),
      'true_activation', public.pct(
        (select count(*) from activated a join new_fam using (install_id)), (select count(*) from new_fam)),
      'first_game_completion', public.pct(
        (select count(*) from first_play fp join new_fam using (install_id) where fp.done),
        (select count(*) from first_play fp join new_fam using (install_id))),
      'minutes_to_first_play_median', (
        select round((percentile_cont(0.5) within group (order by extract(epoch from fp.created_at - nf.first_at)) / 60)::numeric, 1)
        from first_play fp join new_fam nf using (install_id)),
      'd7', public.pct(count(*) filter (where d7), count(*) filter (where a0 + 13 < current_date)) ,
      'd30', public.pct(count(*) filter (where d30), count(*) filter (where a0 + 34 < current_date)),
      'm2', public.pct(count(*) filter (where m2), count(*) filter (where a0 + 59 < current_date)),
      'm3', public.pct(count(*) filter (where m3), count(*) filter (where a0 + 89 < current_date)),
      'active_families_week', (select count(*) from active_week),
      'active_days_per_family_week', (select round(avg(days), 2) from active_week),
      'games_per_active_family_week', (
        select round(count(*)::numeric / nullif((select count(*) from active_week), 0), 2)
        from completes where created_at > now() - interval '7 days'),
      'funnel', jsonb_build_object(
        'new_families', (select count(*) from new_fam),
        'first_play', (select count(*) from first_play fp join new_fam using (install_id)),
        'first_done', (select count(*) from first_play fp join new_fam using (install_id) where fp.done),
        'activated', (select count(*) from activated a join new_fam using (install_id)),
        'paywall', (select count(*) from paywall_fam p join new_fam using (install_id)),
        'paid', (select count(*) from buy_fam b join new_fam using (install_id)))
    ) || (select jsonb_build_object(
      'active_subscribers', count(distinct user_id) filter (where active),
      'subs_monthly', count(distinct user_id) filter (where active and public.plan_of(product_ref) = 'monthly'),
      'subs_annual', count(distinct user_id) filter (where active and public.plan_of(product_ref) = 'annual'),
      -- Annual plans count as a twelfth a month, so a good month of annual sales does not explode.
      'mrr', round(coalesce(sum(case when not active then 0
                                     when public.plan_of(product_ref) = 'monthly' then public.crm_price(product_ref)
                                     when public.plan_of(product_ref) = 'annual' then public.crm_price(product_ref) / 12
                                     else 0 end), 0), 2),
      -- Churn: access really ended (not the cancel tap) this month, against those active at its start.
      'churn_month', public.pct(
        count(distinct user_id) filter (where not active and valid_until >= date_trunc('month', now())
                                         and valid_until <= now()),
        count(distinct user_id) filter (where valid_until is null or valid_until >= date_trunc('month', now()))))
      from subs) || jsonb_build_object('cohorts', coalesce((
      select jsonb_agg(jsonb_build_object(
        'week', w, 'activated', n,
        'd7', case when w + 13 < current_date then public.pct(a7, n) end,
        'd30', case when w + 34 < current_date then public.pct(a30, n) end,
        'm2', case when w + 59 < current_date then public.pct(am2, n) end,
        'm3', case when w + 89 < current_date then public.pct(am3, n) end) order by w desc)
      from (select date_trunc('week', a0)::date w, count(*) n, count(*) filter (where d7) a7,
                   count(*) filter (where d30) a30, count(*) filter (where m2) am2, count(*) filter (where m3) am3
            from ret group by 1 order by 1 desc limit 12) c), '[]')),
    'product', jsonb_build_object(
      'games', coalesce((
        select jsonb_agg(jsonb_build_object(
          'item', p.item_id, 'starts', p.starts, 'families', p.families,
          'completion', public.pct(p.completes, p.starts),
          'replay7', public.pct(r.replayed, r.firsts),
          'next_game', public.pct(n.went_on, n.finishers),
          'plays_per_family', round(p.starts::numeric / nullif(p.families, 0), 2),
          'exits', (select count(*) from exits x where x.item_id = p.item_id),
          'median_exit_pct', (select percentile_cont(0.5) within group (order by pct) from exits x
                              where x.item_id = p.item_id and x.pct is not null))
          order by p.starts desc)
        from per_item p left join replay7 r using (item_id) left join next_after n using (item_id)), '[]'),
      -- Where children stop, in half-minute steps, per play.
      'dropoff', coalesce((
        select jsonb_object_agg(item_id, buckets) from (
          select item_id, jsonb_agg(jsonb_build_array(b * 30, n) order by b) buckets
          from (select item_id, sec / 30 b, count(*) n from exits group by 1, 2) x group by item_id) y), '{}'),
      'searches', coalesce((
        select jsonb_agg(jsonb_build_object('query', q, 'count', n, 'no_results', z) order by n desc)
        from (select props ->> 'query' q, count(*) n, count(*) filter (where props ->> 'results' = '0') z
              from period_ev where event = 'search_performed' group by 1 order by 2 desc limit 30) s), '[]'),
      'favorites', coalesce((
        select jsonb_agg(jsonb_build_object('item', item_id, 'added', a) order by a desc)
        from (select item_id, count(*) a from period_ev where event = 'favorite_added' group by 1
              order by 2 desc limit 15) f), '[]'),
      'viewed_not_started', coalesce((
        select jsonb_agg(jsonb_build_object('item', item_id, 'viewers', v, 'started', s) order by v desc)
        from (select item_id, count(distinct install_id) v,
                     count(distinct install_id) filter (where exists (
                       select 1 from starts st where st.install_id = pe.install_id and st.item_id = pe.item_id
                         and st.created_at >= pe.created_at)) s
              from period_ev pe where event = 'game_viewed' group by 1 order by 2 desc limit 30) g), '[]')),
    'monetization', jsonb_build_object(
      'free_players', (select count(*) from free_fam),
      'free_to_paywall', public.pct((select count(*) from free_fam f join paywall_fam using (install_id)),
                                    (select count(*) from free_fam)),
      'paywall_to_purchase', public.pct(
        (select count(*) from paywall_fam p join buy_fam b using (install_id), since where b.t > since.t),
        (select count(*) from paywall_fam)),
      'free_to_paid_24h', public.pct((select count(*) from free_fam f join buy_fam b using (install_id)
                                      where b.t between f.t and f.t + interval '1 day'), (select count(*) from free_fam)),
      'free_to_paid_7d', public.pct((select count(*) from free_fam f join buy_fam b using (install_id)
                                     where b.t between f.t and f.t + interval '7 days'), (select count(*) from free_fam)),
      'free_to_paid_30d', public.pct((select count(*) from free_fam f join buy_fam b using (install_id)
                                      where b.t between f.t and f.t + interval '30 days'), (select count(*) from free_fam)),
      'paywall_from', coalesce((select jsonb_object_agg(f, n) from (
        select coalesce(props ->> 'from', 'inne') f, count(distinct install_id) n from period_ev
        where event = 'paywall_view' group by 1) x), '{}'),
      'checkout', jsonb_build_object(
        'started', (select count(*) from period_ev where event = 'purchase_start'),
        'failed', coalesce((select jsonb_object_agg(e, n) from (
          select coalesce(props ->> 'error_type', 'inne') e, count(*) n from period_ev
          where event = 'checkout_failed' group by 1) x), '{}'),
        'done', (select count(*) from period_ev where event = 'purchase_done'))),
    'growth', coalesce((
      select jsonb_agg(jsonb_build_object(
        'source', s, 'new_families', n, 'activated', a, 'paid', p,
        'activation', public.pct(a, n), 'paid_rate', public.pct(p, n)) order by n desc)
      from (select coalesce(nf.src, 'brak odpowiedzi') s, count(*) n,
                   count(*) filter (where exists (select 1 from activated a where a.install_id = nf.install_id)) a,
                   count(*) filter (where exists (select 1 from buy_fam b where b.install_id = nf.install_id)) p
            from new_fam nf group by 1) g), '[]'),
    'data_health', (select jsonb_build_object(
      'events', count(*),
      'with_user', public.pct(count(*) filter (where user_id is not null), count(*)),
      'with_age_group', public.pct(count(*) filter (where age_group is not null), count(*)),
      'with_session', public.pct(count(*) filter (where session_id is not null), count(*)),
      'families_with_source', public.pct((select count(*) from new_fam where src is not null),
                                         (select count(*) from new_fam)),
      -- The same event for the same play within two seconds: probably sent twice.
      'suspect_duplicates', (select count(*) from (
        select 1 from period_ev a join period_ev b on a.install_id = b.install_id and a.event = b.event
          and a.item_id is not distinct from b.item_id and a.id < b.id
          and b.created_at - a.created_at < interval '2 seconds'
        where a.event in ('play_start', 'play_complete', 'purchase_done')) d),
      'purchases_app_vs_store', jsonb_build_object(
        'app_events', (select count(*) from period_ev where event = 'purchase_done'),
        'store_entitlements', (select count(*) from public.entitlements, since
                               where source in ('app_store', 'google_play') and updated_at > since.t)),
      'versions', coalesce((select jsonb_object_agg(v, n) from (
        select coalesce(app_version, '?') || ' ' || coalesce(platform, '?') v, count(distinct install_id) n
        from period_ev group by 1) x), '{}'),
      'starts_without_end', public.pct(
        count(*) filter (where event = 'play_start') - count(*) filter (where event in ('play_complete', 'play_exit')),
        count(*) filter (where event = 'play_start')))
      from period_ev)
  )
  from ret
$$;
revoke all on function public.admin_kpi(integer, text) from public, anon, authenticated;

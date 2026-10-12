-- Why parents leave (asked once before the store's subscription settings open) and where
-- recommendations are sent, for Studio › KPI.

alter table public.app_events drop constraint app_events_event_check;
alter table public.app_events add constraint app_events_event_check check (event in (
  'first_open', 'app_open', 'onboarding_done',
  'play_start', 'play_complete',
  'paywall_view', 'purchase_start', 'purchase_done',
  'referral_open', 'referral_share', 'promo_view', 'promo_tap',
  'download_pack', 'reminder_on', 'news_alerts_on',
  'welcome_done', 'tour_done', 'quick_pick',
  'game_viewed', 'play_exit', 'checkout_failed',
  'favorite_added', 'favorite_removed', 'search_performed', 'source_answered',
  'cancel_reason'
));

create or replace function public.admin_signals(p_days integer)
returns jsonb language sql stable security definer set search_path = public as $$
  with ev as (select * from public.app_events where created_at > now() - make_interval(days => p_days))
  select jsonb_build_object(
    'cancel_reasons', coalesce((select jsonb_object_agg(r, n) from (
      select coalesce(props ->> 'reason', 'other') r, count(distinct install_id) n from ev
      where event = 'cancel_reason' group by 1) x), '{}'),
    'referral_channels', coalesce((select jsonb_object_agg(c, n) from (
      select coalesce(props ->> 'channel', 'unknown') c, count(*) n from ev
      where event = 'referral_share' group by 1) x), '{}'),
    'referral_families', (select count(distinct install_id) from ev where event = 'referral_share'),
    'win_back_views', (select count(distinct install_id) from ev where event = 'paywall_view' and props ->> 'from' = 'win_back')
  )
$$;
revoke all on function public.admin_signals(integer) from public, anon, authenticated;

-- Ad spend per month and channel (typed in Studio › KPI › Growth), so the KPIs can show CAC:
-- spend / new paying customers, overall and per channel. Admins only.

create table public.ad_spend (
  month date not null check (month = date_trunc('month', month)::date),
  channel text not null check (channel in ('meta', 'tiktok', 'google', 'influencer', 'other')),
  amount numeric(12, 2) not null check (amount >= 0),
  note text not null default '' check (length(note) <= 200),
  updated_at timestamptz not null default now(),
  primary key (month, channel)
);
alter table public.ad_spend enable row level security;
create policy "admins manage ad spend" on public.ad_spend for all to authenticated
  using (public.is_admin()) with check (public.is_admin());
grant select, insert, update, delete on public.ad_spend to authenticated;

-- New paying customers in the period, all ways to pay: shop orders (first completed order of an
-- e-mail), gifts bought in the shop (one per order) and the first store purchase of an account.
-- The parent's answer "Skąd o nas wiecie?" ties app buyers to a channel; shop buyers come with
-- WooCommerce's own order attribution (utm), which is read in the shop, not here.
create or replace function public.admin_economics(p_days integer)
returns jsonb language sql stable security definer set search_path = public as $$
  with
  since as (select (now() - make_interval(days => p_days)) t),
  web_new as (
    select count(*) n from (
      select email_normalized, min(created_at) first_at from public.web_purchases_pending
      where order_status = 'completed' group by 1) w, since where w.first_at > since.t),
  gift_new as (select count(distinct woo_order_id) n from public.gift_codes, since where created_at > since.t),
  app_payers as (
    select e.user_id, min(e.updated_at) first_at from public.entitlements e
    where e.source in ('app_store', 'google_play') group by 1),
  app_new as (select count(*) n from app_payers, since where first_at > since.t),
  -- Channel of app buyers from their events' source answer.
  app_by_channel as (
    select case
             when s in ('instagram', 'facebook', 'ad') then 'meta'
             when s = 'tiktok' then 'tiktok'
             when s = 'search' then 'google'
             when s = 'influencer' then 'influencer'
             else 'other' end channel,
           count(*) n
    from (select ap.user_id,
                 (select source from public.app_events ev where ev.user_id = ap.user_id and source is not null
                  order by created_at desc limit 1) s
          from app_payers ap, since where ap.first_at > since.t) x
    group by 1),
  spend as (
    select channel, sum(amount) amount from public.ad_spend, since
    where month + interval '1 month' > since.t and month <= now() group by 1),
  total as (select coalesce(sum(amount), 0) amount from spend)
  select jsonb_build_object(
    'spend_total', (select amount from total),
    'new_paying_web', (select n from web_new),
    'new_paying_gifts', (select n from gift_new),
    'new_paying_app', (select n from app_new),
    'new_paying_total', (select w.n + g.n + a.n from web_new w, gift_new g, app_new a),
    'cac_total', (select case when w.n + g.n + a.n > 0 then round(t.amount / (w.n + g.n + a.n), 2) end
                  from web_new w, gift_new g, app_new a, total t),
    'channels', coalesce((
      select jsonb_agg(jsonb_build_object(
        'channel', c, 'spend', coalesce(s.amount, 0), 'new_paying_app', coalesce(a.n, 0),
        'cac_app', case when coalesce(a.n, 0) > 0 then round(s.amount / a.n, 2) end) order by c)
      from (select channel c from spend union select channel from app_by_channel) ch
      left join spend s on s.channel = ch.c left join app_by_channel a on a.channel = ch.c), '[]'),
    'months', coalesce((
      select jsonb_agg(jsonb_build_object('month', month, 'channel', channel, 'amount', amount, 'note', note)
                       order by month desc, channel)
      from public.ad_spend where month > now() - interval '13 months'), '[]')
  )
$$;
revoke all on function public.admin_economics(integer) from public, anon, authenticated;

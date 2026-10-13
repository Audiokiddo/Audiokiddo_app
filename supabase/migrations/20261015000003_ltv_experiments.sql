-- 1. LTV and cohorts: how much a paying family brings, how long it stays, how much an ad
--    may cost to bring one. Purchases get the date they started (until now only the date
--    of the last change was kept).
-- 2. A/B tests of the offer: the app shows each install one variant (stable), events carry
--    it, the CRM compares how many families bought.

alter table public.entitlements add column if not exists created_at timestamptz;
update public.entitlements set created_at = updated_at where created_at is null;
alter table public.entitlements alter column created_at set default now();
alter table public.entitlements alter column created_at set not null;

create or replace function public.crm_ltv()
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  v_active bigint;
  v_mrr numeric;
  v_ended bigint;
  v_start bigint;
  v_churn numeric;
  v_arpu numeric;
  v_packs numeric;
  v_buyers bigint;
begin
  if not public.is_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  -- Paying subscriptions now and their monthly value (gross).
  select count(distinct user_id),
         coalesce(sum(case when product_ref ilike '%.monthly%' then public.crm_price(product_ref)
                           when product_ref ilike '%.yearly%' then public.crm_price(product_ref) / 12 else 0 end), 0)
  into v_active, v_mrr
  from public.entitlements
  where scope = 'all_content' and source <> 'manual' and status in ('active', 'grace')
    and (valid_until is null or valid_until > now());
  -- Monthly churn: families whose subscription ended in the last 30 days, against those
  -- paying at the start of that time.
  select count(distinct user_id) into v_ended from public.entitlements
  where scope = 'all_content' and source <> 'manual' and status in ('expired', 'revoked', 'refunded')
    and updated_at > now() - interval '30 days';
  select count(distinct user_id) into v_start from public.entitlements
  where scope = 'all_content' and source <> 'manual' and created_at < now() - interval '30 days'
    and (valid_until is null or valid_until > now() - interval '30 days');
  v_churn := case when v_start > 0 then greatest(v_ended::numeric / v_start, 0.03) else null end;
  v_arpu := case when v_active > 0 then v_mrr / v_active end;
  -- One-time packs: average per buyer.
  select coalesce(sum(public.crm_price(product_ref)), 0), count(distinct user_id) into v_packs, v_buyers
  from (select distinct on (user_id, store_original_tx_id) user_id, product_ref
        from public.entitlements where source <> 'manual' and scope like 'pack:%') p;
  return jsonb_build_object(
    'paying', v_active,
    'arpu_gross', round(v_arpu, 2),
    -- Net: without 23% VAT and about 15% store fees.
    'arpu_net', round(v_arpu / 1.23 * 0.85, 2),
    'churn_month', round(v_churn * 100, 1),
    'lifetime_months', case when v_churn is not null then round(1 / v_churn, 1) end,
    'ltv_net', case when v_churn is not null and v_arpu is not null then round(v_arpu / 1.23 * 0.85 / v_churn) end,
    'pack_buyers', v_buyers,
    'pack_value_net', case when v_buyers > 0 then round(v_packs / v_buyers / 1.23 * 0.85, 2) end,
    'by_source', coalesce((
      select jsonb_object_agg(source, n) from (
        select source::text, count(distinct user_id) n from public.entitlements
        where scope = 'all_content' and source <> 'manual' and status in ('active', 'grace')
          and (valid_until is null or valid_until > now())
        group by source) s), '{}'::jsonb),
    -- Families by the month they first paid, and the share still paying 1, 2, 3 and 6 months
    -- later (a subscription's end date moves with every renewal).
    'cohorts', coalesce((
      select jsonb_agg(c order by c ->> 'month') from (
        select jsonb_build_object(
          'month', to_char(first_paid, 'YYYY-MM'),
          'families', count(*),
          'm1', round(100.0 * count(*) filter (where last_until >= first_paid + interval '1 month') / count(*)),
          'm2', case when first_paid + interval '2 months' <= now() then
                  round(100.0 * count(*) filter (where last_until >= first_paid + interval '2 months') / count(*)) end,
          'm3', case when first_paid + interval '3 months' <= now() then
                  round(100.0 * count(*) filter (where last_until >= first_paid + interval '3 months') / count(*)) end,
          'm6', case when first_paid + interval '6 months' <= now() then
                  round(100.0 * count(*) filter (where last_until >= first_paid + interval '6 months') / count(*)) end
        ) c
        from (
          select user_id, date_trunc('month', min(created_at)) first_paid,
                 max(coalesce(valid_until, 'infinity'::timestamptz)) last_until
          from public.entitlements
          where scope = 'all_content' and source <> 'manual'
          group by user_id
        ) f
        group by first_paid
      ) cohorts), '[]'::jsonb)
  );
end;
$$;
revoke all on function public.crm_ltv() from public, anon;
grant execute on function public.crm_ltv() to authenticated;

-- 2. Experiments --------------------------------------------------------------------------

create table public.experiments (
  key text primary key check (key ~ '^[a-z_]{2,40}$'),
  name text not null check (length(name) <= 120),
  variants text[] not null check (cardinality(variants) between 2 and 4),
  active boolean not null default false,
  started_at timestamptz,
  ended_at timestamptz,
  note text not null default '' check (length(note) <= 1000)
);
alter table public.experiments enable row level security;
create policy "admins manage experiments" on public.experiments for all to authenticated
  using (public.is_admin()) with check (public.is_admin());
grant select, insert, update, delete on public.experiments to authenticated;

-- The tests the app knows how to show (it ignores any other key).
insert into public.experiments (key, name, variants, note) values
  ('paywall_period', 'Oferta: który okres zaznaczony na starcie', '{rocznie,miesiecznie}',
   'rocznie: przełącznik na Rocznie (obecnie); miesiecznie: na Miesięcznie, chmurka z oszczędnością zostaje'),
  ('paywall_cta', 'Oferta: tekst głównego przycisku', '{proba,oszczednosc}',
   'proba: „Wypróbuj 7 dni za darmo”; oszczednosc: „Zacznij za darmo i oszczędzaj X zł rocznie”')
on conflict (key) do nothing;

-- What the app reads at start (anyone may: it holds only test names and variants).
create or replace function public.app_experiments()
returns jsonb language sql stable security definer set search_path = public as $$
  select coalesce(jsonb_object_agg(key, to_jsonb(variants)), '{}'::jsonb) from public.experiments where active
$$;
revoke all on function public.app_experiments() from public;
grant execute on function public.app_experiments() to anon, authenticated;

-- Results: per variant, how many phones saw the offer, started and finished a purchase.
create or replace function public.crm_experiment(p_key text)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  v_since timestamptz;
begin
  if not public.is_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  select coalesce(started_at, now() - interval '90 days') into v_since from public.experiments where key = p_key;
  return coalesce((
    select jsonb_agg(jsonb_build_object(
      'variant', variant, 'saw', saw, 'started', started, 'bought', bought,
      'conversion', case when saw > 0 then round(100.0 * bought / saw, 1) end) order by variant)
    from (
      select a.props -> 'ab' ->> p_key variant,
             count(distinct a.install_id) filter (where a.event = 'paywall_view') saw,
             count(distinct a.install_id) filter (where a.event = 'purchase_start') started,
             count(distinct a.install_id) filter (where a.event = 'purchase_done') bought
      from public.app_events a
      where a.created_at >= v_since and a.props -> 'ab' ? p_key
        and a.event in ('paywall_view', 'purchase_start', 'purchase_done')
      group by 1
    ) v
  ), '[]'::jsonb);
end;
$$;
revoke all on function public.crm_experiment(text) from public, anon;
grant execute on function public.crm_experiment(text) to authenticated;

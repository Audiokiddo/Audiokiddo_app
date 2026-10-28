-- Subscription plans by the number of children, easy to remember for a parent:
--   1 dziecko (the existing products), 2 dzieci: +5 zł a month, 3–5 dzieci: +10 zł a month.
-- A plan grants all_content plus `children:N`, the number of child profiles it covers. A
-- subscription without `children:N` (the web shop, codes, manual) covers the whole family.
-- All monthly and yearly plans sit in one subscription group in App Store Connect and one
-- subscription in Google Play, so moving up or down is the store's own upgrade.

alter table public.entitlements drop constraint if exists entitlements_scope_check;
alter table public.entitlements add constraint entitlements_scope_check
  check (scope ~ '^(all_content|pack:[a-z0-9-]+|item:[a-z0-9-]+|children:[1-9])$');

update public.store_products set scopes = '{all_content,children:1}'
where product_ref in (
  'ios:pl.audiokiddo.sub.monthly', 'android:pl.audiokiddo.sub.monthly',
  'ios:pl.audiokiddo.sub.yearly', 'android:pl.audiokiddo.sub.yearly'
);

insert into public.store_products (product_ref, scopes) values
  ('ios:pl.audiokiddo.sub.duo.monthly', '{all_content,children:2}'),
  ('android:pl.audiokiddo.sub.duo.monthly', '{all_content,children:2}'),
  ('ios:pl.audiokiddo.sub.duo.yearly', '{all_content,children:2}'),
  ('android:pl.audiokiddo.sub.duo.yearly', '{all_content,children:2}'),
  ('ios:pl.audiokiddo.sub.family.monthly', '{all_content,children:5}'),
  ('android:pl.audiokiddo.sub.family.monthly', '{all_content,children:5}'),
  ('ios:pl.audiokiddo.sub.family.yearly', '{all_content,children:5}'),
  ('android:pl.audiokiddo.sub.family.yearly', '{all_content,children:5}')
on conflict (product_ref) do update set scopes = excluded.scopes;

-- Revenue estimates in the CRM know the new plans (the longer names first).
create or replace function public.crm_price(p_ref text)
returns numeric language sql immutable as $$
  select case
    when p_ref ilike '%sub.family.monthly%' then 34.99
    when p_ref ilike '%sub.family.yearly%' then 335.88
    when p_ref ilike '%sub.duo.monthly%' then 29.99
    when p_ref ilike '%sub.duo.yearly%' then 287.88
    when p_ref ilike '%sub.monthly%' then 24.99
    when p_ref ilike '%sub.yearly%' then 239.88
    when p_ref ilike '%bundle.three%' then 159.99
    when p_ref ilike '%bundle.two%' then 89.99
    when p_ref ilike '%pack.detektyw%' then 69.99
    when p_ref ilike '%pack.%' then 49.99
    else 0
  end
$$;

-- MRR and subscription counts include the plans for more children.
create or replace function public.crm_numbers()
returns jsonb language sql stable security definer set search_path = public, auth as $$
  with paid as (
    select user_id, product_ref, scope, status, valid_until, source
    from public.entitlements where source <> 'manual'
  ),
  active as (
    select * from paid where status in ('active', 'grace') and (valid_until is null or valid_until > now())
  ),
  costs as (
    select coalesce(sum((v.value)::numeric), 0) total
    from public.crm_settings s, jsonb_each_text(s.value) v
    where s.key = 'monthly_costs' and v.value ~ '^[0-9]+(\.[0-9]+)?$'
  ),
  mrr as (
    select coalesce(sum(case when product_ref ilike '%.monthly%' then public.crm_price(product_ref)
                             when product_ref ilike '%.yearly%' then public.crm_price(product_ref) / 12
                             else 0 end), 0) gross
    from active where scope = 'all_content'
  )
  select jsonb_build_object(
    'users_total', (select count(*) from auth.users),
    'users_7d', (select count(*) from auth.users where created_at > now() - interval '7 days'),
    'users_30d', (select count(*) from auth.users where created_at > now() - interval '30 days'),
    'paying_families', (select count(distinct user_id) from active),
    'subs_monthly', (select count(distinct user_id) from active where product_ref ilike '%sub.%monthly%'),
    'subs_yearly', (select count(distinct user_id) from active where product_ref ilike '%sub.%yearly%'),
    'subs_multi_child', (select count(distinct user_id) from active
                         where product_ref ilike '%sub.duo.%' or product_ref ilike '%sub.family.%'),
    'packs_sold', (select count(*) from paid where scope like 'pack:%'),
    -- A plan's children:N row is the same purchase as its all_content row: counted once.
    'revenue_total_gross', (select coalesce(sum(public.crm_price(product_ref)), 0) from paid
                            where scope not like 'children:%'),
    'revenue_30d_gross', (select coalesce(sum(public.crm_price(product_ref)), 0) from public.entitlements
                          where source <> 'manual' and scope not like 'children:%'
                            and updated_at > now() - interval '30 days'),
    'mrr_gross', (select round(gross, 2) from mrr),
    -- Net: without 23% VAT and about 15% store fees.
    'mrr_net', (select round(gross / 1.23 * 0.85, 2) from mrr),
    'monthly_costs', (select total from costs),
    'profit_month_estimate', (select round(m.gross / 1.23 * 0.85 - c.total, 2) from mrr m, costs c),
    'recent_users', coalesce((
      select jsonb_agg(jsonb_build_object('email', u.email, 'created_at', u.created_at,
                                          'paying', exists (select 1 from active a where a.user_id = u.id))
                       order by u.created_at desc)
      from (select id, email, created_at from auth.users order by created_at desc limit 25) u), '[]'),
    'open_tasks', (select count(*) from public.crm_items where kind = 'task' and status not in ('done', 'archived')),
    'pending_decisions', (select count(*) from public.crm_items where decision = 'pending')
  )
$$;
revoke all on function public.crm_numbers() from public, anon, authenticated;

-- One subscription for the whole family (strategy 2026-10-08, "jeden abonament"): monthly
-- 29,99 zł or yearly 269,99 zł, no plans by the number of children. Child profiles are not
-- limited, and every subscriber may share the plan with a second parent.

-- Subscriptions open the whole library and nothing else.
update public.store_products set scopes = '{all_content}'
where product_ref in (
  'ios:pl.audiokiddo.sub.monthly', 'android:pl.audiokiddo.sub.monthly',
  'ios:pl.audiokiddo.sub.yearly', 'android:pl.audiokiddo.sub.yearly'
);

-- The plans for 2 and 3–5 children are gone (nothing was ever sold under them).
delete from public.store_products
where product_ref ilike '%sub.duo.%' or product_ref ilike '%sub.family.%';

-- Any subscription with all_content may be shared with a second parent.
create or replace function public.can_share(p_user uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select 'all_content' = any(public.own_scopes(p_user))
$$;
revoke all on function public.can_share(uuid) from public, anon, authenticated;

-- Revenue estimates in the CRM: the new subscription prices (packs and bundles as on audiokiddo.pl).
create or replace function public.crm_price(p_ref text)
returns numeric language sql immutable as $$
  select case
    when p_ref ilike '%sub.monthly%' then 29.99
    when p_ref ilike '%sub.yearly%' then 269.99
    when p_ref ilike '%bundle.three%' then 159.99
    when p_ref ilike '%bundle.two%' then 89.99
    when p_ref ilike '%pack.detektyw%' then 69.99
    when p_ref ilike '%pack.%' then 49.99
    else 0
  end
$$;

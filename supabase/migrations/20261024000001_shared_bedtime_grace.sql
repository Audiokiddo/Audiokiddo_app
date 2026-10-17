-- Local fix after the tester-readiness audit. Sharing must not require a still-active
-- subscription for the narrow bedtime grace window. Ordinary access_scopes stays unchanged.
create or replace function public.bedtime_grace(p_user uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.entitlements e
    where e.scope = 'all_content'
      and e.status in ('active', 'grace', 'expired')
      and e.valid_until is not null
      and e.valid_until <= now()
      and (e.valid_until at time zone 'Europe/Warsaw')::date = (now() at time zone 'Europe/Warsaw')::date
      and (e.user_id = p_user
           or e.user_id in (select l.owner_id from public.family_links l where l.member_id = p_user))
  )
$$;
revoke all on function public.bedtime_grace(uuid) from public, anon, authenticated;

-- Deliver the expired all_content row to the linked member so the app can make the
-- same bedtime-only decision. Do not revive it or expose the owner's unrelated purchases.
create or replace function public.my_entitlements()
returns table (scope text, status text, source text, valid_until timestamptz, shared boolean)
language sql stable security definer set search_path = public as $$
  select e.scope, e.status::text, e.source::text, e.valid_until, false
  from public.entitlements e where e.user_id = auth.uid()
  union all
  select e.scope, e.status::text, e.source::text, e.valid_until, true
  from public.family_links l
  join public.entitlements e on e.user_id = l.owner_id
  where l.member_id = auth.uid() and (
    public.can_share(l.owner_id)
    or (e.scope = 'all_content'
        and e.status in ('active', 'grace', 'expired')
        and e.valid_until is not null
        and e.valid_until <= now()
        and (e.valid_until at time zone 'Europe/Warsaw')::date = (now() at time zone 'Europe/Warsaw')::date)
  )
$$;
revoke all on function public.my_entitlements() from public, anon;
grant execute on function public.my_entitlements() to authenticated;

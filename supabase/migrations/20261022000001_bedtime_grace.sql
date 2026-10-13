-- "Dobranoc zawsze działa" (research 2026-10-12): when the whole library ended earlier today
-- (Polish time), the bedtime plays of the published catalog still download until midnight, so
-- a child is not left without the evening play. Refunds and revoked access get no grace. The
-- app applies the same rule (catalog_providers.dart, bedtimeGrace).

-- Whether [p_user]'s whole library (their own, or the owner's they share) ended today.
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
           or e.user_id in (select l.owner_id from public.family_links l
                            where l.member_id = p_user and public.can_share(l.owner_id)))
  )
$$;
revoke all on function public.bedtime_grace(uuid) from public, anon, authenticated;

-- Items marked "przed snem" in the catalog the app reads now.
create or replace function public.is_bedtime_item(p_item_id text)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1
    from public.catalog_pointer p
    join public.catalog_versions v on v.version = p.version
    cross join lateral jsonb_array_elements(coalesce(v.manifest -> 'items', '[]')) it
    where it ->> 'id' = p_item_id and coalesce(it -> 'situations', '[]') ? 'przed_snem'
  )
$$;
revoke all on function public.is_bedtime_item(text) from public, anon, authenticated;

create or replace function public.can_download(p_user_id uuid, p_path text)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.content_files f
    cross join lateral (select public.access_scopes(p_user_id) s) a
    where f.path = p_path
      and (f.free or 'all_content' = any(a.s) or ('item:' || f.item_id) = any(a.s)
           or ('pack:' || f.pack_id) = any(a.s)
           or (f.item_id is not null and public.bedtime_grace(p_user_id) and public.is_bedtime_item(f.item_id)))
  )
$$;
revoke all on function public.can_download(uuid, text) from public, anon, authenticated;
grant execute on function public.can_download(uuid, text) to service_role;

-- 1. A second parent on the family's access: the plans for 2 and for 3–5 children (and a
--    family subscription from the web shop) let the owner invite one partner, who then plays
--    with everything the owner has. The plan for one child is for one account.
-- 2. Letters from Szop’en to parents who asked for them (weekly, and after a break).
-- 3. Shop orders for the CRM, with whether the buyer opened them in the app.

-- 1. Family -----------------------------------------------------------------------------

create table public.family_links (
  member_id uuid primary key references auth.users (id) on delete cascade,
  owner_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  check (member_id <> owner_id)
);
create unique index family_links_owner_idx on public.family_links (owner_id);

create table public.family_invites (
  code text primary key check (code ~ '^[A-Z0-9]{6}$'),
  owner_id uuid not null references auth.users (id) on delete cascade,
  expires_at timestamptz not null default now() + interval '7 days',
  used_at timestamptz
);
alter table public.family_links enable row level security;
alter table public.family_invites enable row level security;
-- Read and changed only through the functions below.

-- Own access that is active now.
create or replace function public.own_scopes(p_user uuid)
returns text[] language sql stable security definer set search_path = public as $$
  select coalesce(array_agg(distinct scope), '{}')
  from public.entitlements
  where user_id = p_user and status in ('active', 'grace') and (valid_until is null or valid_until > now())
$$;
revoke all on function public.own_scopes(uuid) from public, anon, authenticated;

-- Whether [p_user]'s access may be shared with a second parent: a plan for 2+ children, or
-- a subscription without a children limit (web shop, codes).
create or replace function public.can_share(p_user uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select 'all_content' = any(s) and (
    not exists (select 1 from unnest(s) x where x like 'children:%')
    or exists (select 1 from unnest(s) x where x like 'children:%' and split_part(x, ':', 2)::int >= 2))
  from (select public.own_scopes(p_user) s) o
$$;
revoke all on function public.can_share(uuid) from public, anon, authenticated;

-- What a parent may play with: their own access plus the owner's, if they are the partner
-- of an owner whose plan allows it.
create or replace function public.access_scopes(p_user uuid)
returns text[] language sql stable security definer set search_path = public as $$
  select array(select distinct x from unnest(
    public.own_scopes(p_user) ||
    coalesce((select public.own_scopes(l.owner_id) from public.family_links l
              where l.member_id = p_user and public.can_share(l.owner_id)), '{}')) x)
$$;
revoke all on function public.access_scopes(uuid) from public, anon, authenticated;

-- What the app reads instead of the entitlements table: own rows and, for a partner, the
-- owner's rows marked as shared.
create or replace function public.my_entitlements()
returns table (scope text, status text, source text, valid_until timestamptz, shared boolean)
language sql stable security definer set search_path = public as $$
  select e.scope, e.status::text, e.source::text, e.valid_until, false
  from public.entitlements e where e.user_id = auth.uid()
  union all
  select e.scope, e.status::text, e.source::text, e.valid_until, true
  from public.family_links l
  join public.entitlements e on e.user_id = l.owner_id
  where l.member_id = auth.uid() and public.can_share(l.owner_id)
$$;
revoke all on function public.my_entitlements() from public, anon;
grant execute on function public.my_entitlements() to authenticated;

-- The owner makes a code for the partner (valid 7 days; a new one replaces the old).
create or replace function public.family_invite()
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_code text;
begin
  if auth.uid() is null then
    raise exception 'auth' using errcode = '42501';
  end if;
  if exists (select 1 from public.family_links where member_id = auth.uid()) then
    raise exception 'member' using errcode = '22023';
  end if;
  if exists (select 1 from public.family_links where owner_id = auth.uid()) then
    raise exception 'full' using errcode = '22023';
  end if;
  if not public.can_share(auth.uid()) then
    raise exception 'plan' using errcode = '22023';
  end if;
  delete from public.family_invites where owner_id = auth.uid();
  loop
    -- No 0/O and 1/I: easy to read aloud and type.
    v_code := (select string_agg(substr('ABCDEFGHJKLMNPQRSTUVWXYZ23456789', 1 + floor(random() * 32)::int, 1), '')
               from generate_series(1, 6));
    exit when not exists (select 1 from public.family_invites where code = v_code);
  end loop;
  insert into public.family_invites (code, owner_id) values (v_code, auth.uid());
  return jsonb_build_object('code', v_code, 'expires_at', now() + interval '7 days');
end;
$$;
revoke all on function public.family_invite() from public, anon;
grant execute on function public.family_invite() to authenticated;

-- The partner joins with the code.
create or replace function public.family_join(p_code text)
returns void language plpgsql security definer set search_path = public as $$
declare
  v_owner uuid;
begin
  if auth.uid() is null then
    raise exception 'auth' using errcode = '42501';
  end if;
  select owner_id into v_owner from public.family_invites
  where code = upper(trim(p_code)) and used_at is null and expires_at > now();
  if v_owner is null then
    raise exception 'code' using errcode = '22023';
  end if;
  if v_owner = auth.uid() then
    raise exception 'self' using errcode = '22023';
  end if;
  if exists (select 1 from public.family_links where member_id = auth.uid() or owner_id = auth.uid()) then
    raise exception 'linked' using errcode = '22023';
  end if;
  if exists (select 1 from public.family_links where owner_id = v_owner) then
    raise exception 'full' using errcode = '22023';
  end if;
  if not public.can_share(v_owner) then
    raise exception 'plan' using errcode = '22023';
  end if;
  insert into public.family_links (member_id, owner_id) values (auth.uid(), v_owner);
  update public.family_invites set used_at = now() where code = upper(trim(p_code));
end;
$$;
revoke all on function public.family_join(text) from public, anon;
grant execute on function public.family_join(text) to authenticated;

-- Who is in the family: for the owner the partner, for the partner the owner (e-mails half
-- hidden), and whether a code can be made.
create or replace function public.family_status()
returns jsonb language plpgsql stable security definer set search_path = public, auth as $$
declare
  v_link record;
  v_invite record;
begin
  if auth.uid() is null then
    return null;
  end if;
  select l.*, u.email into v_link from public.family_links l join auth.users u on u.id = l.owner_id
  where l.member_id = auth.uid();
  if v_link.member_id is not null then
    return jsonb_build_object('role', 'member', 'partner', public.mask_email(v_link.email),
                              'shared', public.can_share(v_link.owner_id));
  end if;
  select l.*, u.email into v_link from public.family_links l join auth.users u on u.id = l.member_id
  where l.owner_id = auth.uid();
  if v_link.member_id is not null then
    return jsonb_build_object('role', 'owner', 'partner', public.mask_email(v_link.email),
                              'shared', public.can_share(auth.uid()));
  end if;
  select code, expires_at into v_invite from public.family_invites
  where owner_id = auth.uid() and used_at is null and expires_at > now();
  return jsonb_build_object('role', 'none', 'can_invite', public.can_share(auth.uid()),
                            'code', v_invite.code, 'expires_at', v_invite.expires_at);
end;
$$;
revoke all on function public.family_status() from public, anon;
grant execute on function public.family_status() to authenticated;

-- The partner leaves, or the owner removes the partner.
create or replace function public.family_leave()
returns void language sql security definer set search_path = public as $$
  delete from public.family_links where member_id = auth.uid() or owner_id = auth.uid()
$$;
revoke all on function public.family_leave() from public, anon;
grant execute on function public.family_leave() to authenticated;

create or replace function public.mask_email(p_email text)
returns text language sql immutable as $$
  select case when p_email is null or position('@' in p_email) < 2 then p_email
              else left(p_email, 2) || '•••@' || split_part(p_email, '@', 2) end
$$;

-- 2. Letters ------------------------------------------------------------------------------

create table public.parent_letters (
  user_id uuid primary key references auth.users (id) on delete cascade,
  weekly boolean not null default false,
  missed boolean not null default false,
  token uuid not null unique default gen_random_uuid(),
  last_weekly_at timestamptz,
  last_missed_at timestamptz,
  updated_at timestamptz not null default now()
);
alter table public.parent_letters enable row level security;
create policy "parents see their letters" on public.parent_letters for select to authenticated
  using (user_id = auth.uid());
create policy "parents choose their letters" on public.parent_letters for insert to authenticated
  with check (user_id = auth.uid());
create policy "parents change their letters" on public.parent_letters for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
grant select, insert on public.parent_letters to authenticated;
grant update (weekly, missed, updated_at) on public.parent_letters to authenticated;

-- Who gets a letter now, with what they played and can play (the mailer function only).
create or replace function public.letters_due(p_kind text)
returns table (user_id uuid, email text, token uuid, week text[], ever text[], scopes text[])
language sql stable security definer set search_path = public, auth as $$
  select l.user_id, u.email, l.token,
    coalesce((select array_agg(a.item_id order by a.created_at desc) from public.app_events a
              where a.user_id = l.user_id and a.event = 'play_start' and a.item_id is not null
                and a.created_at > now() - interval '7 days'), '{}'),
    coalesce((select array_agg(distinct a.item_id) from public.app_events a
              where a.user_id = l.user_id and a.event = 'play_start' and a.item_id is not null), '{}'),
    public.access_scopes(l.user_id)
  from public.parent_letters l
  join auth.users u on u.id = l.user_id
  where u.email is not null and u.deleted_at is null and (
    (p_kind = 'weekly' and l.weekly
      and (l.last_weekly_at is null or l.last_weekly_at < now() - interval '6 days'))
    or (p_kind = 'missed' and l.missed
      and (l.last_missed_at is null or l.last_missed_at < now() - interval '30 days')
      and exists (select 1 from public.app_events a where a.user_id = l.user_id and a.event = 'play_start')
      and not exists (select 1 from public.app_events a where a.user_id = l.user_id and a.event = 'play_start'
                      and a.created_at > now() - interval '14 days')))
  order by l.user_id
  limit 300
$$;
revoke all on function public.letters_due(text) from public, anon, authenticated;

-- 3. Shop orders --------------------------------------------------------------------------

create or replace function public.crm_orders(p_days integer default 60)
returns jsonb language plpgsql stable security definer set search_path = public, auth as $$
declare
  v_since timestamptz := now() - make_interval(days => least(greatest(coalesce(p_days, 60), 1), 365));
begin
  if not public.is_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  return coalesce((
    select jsonb_agg(o order by o ->> 'at' desc)
    from (
      -- Not opened in the app yet.
      select jsonb_build_object('order', w.woo_order_id, 'product', w.product_ref, 'email', w.email_normalized,
        'status', w.order_status, 'at', w.created_at, 'claimed', false,
        'scopes', (select to_jsonb(p.scopes) from public.store_products p where p.product_ref = w.product_ref)) o
      from public.web_purchases_pending w
      where w.created_at > v_since and w.claimed_by is null
      union all
      -- On an account (bought with the account's e-mail, or claimed later).
      select distinct on (e.store_original_tx_id, e.user_id) jsonb_build_object(
        'order', case when split_part(e.store_original_tx_id, ':', 2) ~ '^\d+$'
                      then split_part(e.store_original_tx_id, ':', 2)::bigint end,
        'product', e.product_ref, 'email', u.email, 'status', e.status, 'at', e.updated_at, 'claimed', true,
        'scopes', (select to_jsonb(p.scopes) from public.store_products p where p.product_ref = e.product_ref)) o
      from public.entitlements e join auth.users u on u.id = e.user_id
      where e.source = 'woocommerce' and e.updated_at > v_since
    ) orders
  ), '[]'::jsonb);
end;
$$;
revoke all on function public.crm_orders(integer) from public, anon;
grant execute on function public.crm_orders(integer) to authenticated;

-- 4. Mail on schedule: Dawid's morning digest and the parents' letters.
do $do$
begin
  if exists (select 1 from pg_available_extensions where name = 'pg_cron') then
    create extension if not exists pg_cron;
    create extension if not exists pg_net;
    -- 5:30 UTC: 7:30 in summer, 6:30 in winter (after the agent and the ads cycle).
    perform cron.schedule('mail-morning-digest', '30 5 * * *', $job$
      select net.http_post(
        url := 'https://ypdxofcwewwdyoelamgy.supabase.co/functions/v1/mailer',
        headers := jsonb_build_object('content-type', 'application/json',
          'x-cron-secret', (select decrypted_secret from vault.decrypted_secrets where name = 'ads_cron_secret')),
        body := '{"action": "digest"}'::jsonb, timeout_milliseconds := 60000)
    $job$);
    -- 16:00 UTC: 18:00 in summer. Sundays the weekly letter, every day the "we miss you" one.
    perform cron.schedule('mail-parent-letters', '0 16 * * *', $job$
      select net.http_post(
        url := 'https://ypdxofcwewwdyoelamgy.supabase.co/functions/v1/mailer',
        headers := jsonb_build_object('content-type', 'application/json',
          'x-cron-secret', (select decrypted_secret from vault.decrypted_secrets where name = 'ads_cron_secret')),
        body := '{"action": "letters"}'::jsonb, timeout_milliseconds := 300000)
    $job$);
  end if;
end;
$do$;

-- 5. Recordings follow the shared access too: the partner downloads what the family has.
create or replace function public.can_download(p_user_id uuid, p_path text)
returns boolean language sql stable security definer set search_path = public as $$
  select exists (
    select 1 from public.content_files f
    cross join lateral (select public.access_scopes(p_user_id) s) a
    where f.path = p_path
      and (f.free or 'all_content' = any(a.s) or ('item:' || f.item_id) = any(a.s)
           or ('pack:' || f.pack_id) = any(a.s))
  )
$$;
revoke all on function public.can_download(uuid, text) from public, anon, authenticated;
grant execute on function public.can_download(uuid, text) to service_role;

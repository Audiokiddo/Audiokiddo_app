-- Access codes (gifts, testers, reviewers, promotions) and shop orders claimed by number.
-- Both only add entitlements to the caller's account; the e-mail match of sync-web-purchases
-- stays the main way for shop buyers. Everything here is for the service role (Edge Functions).

-- A code is stored only as the SHA-256 of its normalised text, like a password.
create table public.access_codes (
  code_hash text primary key check (code_hash ~ '^[0-9a-f]{64}$'),
  scopes text[] not null check (cardinality(scopes) > 0),
  note text not null default '',
  max_uses integer not null default 1 check (max_uses between 1 and 1000),
  uses integer not null default 0 check (uses >= 0),
  expires_at timestamptz,
  -- Access lasts this many days after redeeming; null = for good.
  access_days integer check (access_days is null or access_days between 1 and 3650),
  created_at timestamptz not null default now()
);
alter table public.access_codes enable row level security;

create table public.code_redemptions (
  code_hash text not null references public.access_codes (code_hash) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  redeemed_at timestamptz not null default now(),
  primary key (code_hash, user_id)
);
alter table public.code_redemptions enable row level security;

-- Wrong guesses are limited per account: 10 failures an hour.
create table public.claim_attempts (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  kind text not null check (kind in ('code', 'order')),
  at timestamptz not null default now(),
  ok boolean not null
);
create index claim_attempts_user_idx on public.claim_attempts (user_id, at desc);
alter table public.claim_attempts enable row level security;

create or replace function public.claim_rate_limited(p_user_id uuid)
returns boolean language sql stable security definer set search_path = public as $$
  select count(*) >= 10 from public.claim_attempts
  where user_id = p_user_id and not ok and at > now() - interval '1 hour'
$$;

-- A failure the function found before the database could (an order number that does not match
-- its e-mail): counted like any other wrong guess.
create or replace function public.note_claim_failure(p_user_id uuid, p_kind text)
returns void language sql security definer set search_path = public as $$
  insert into public.claim_attempts (user_id, kind, ok) values (p_user_id, p_kind, false)
$$;

-- Redeems a code for a user. Returns {status, scopes}; status is one of
-- ok, already, invalid, expired, used_up, rate_limited. Never raises for a bad code, so the
-- failed attempt is kept (and counted) in the same transaction.
create or replace function public.redeem_access_code(p_user_id uuid, p_code_hash text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_code public.access_codes;
  v_scope text;
  v_until timestamptz;
begin
  if public.claim_rate_limited(p_user_id) then
    return jsonb_build_object('status', 'rate_limited', 'scopes', '[]'::jsonb);
  end if;
  select * into v_code from public.access_codes where code_hash = p_code_hash for update;
  if not found then
    insert into public.claim_attempts (user_id, kind, ok) values (p_user_id, 'code', false);
    return jsonb_build_object('status', 'invalid', 'scopes', '[]'::jsonb);
  end if;
  if v_code.expires_at is not null and v_code.expires_at < now() then
    insert into public.claim_attempts (user_id, kind, ok) values (p_user_id, 'code', false);
    return jsonb_build_object('status', 'expired', 'scopes', '[]'::jsonb);
  end if;
  if exists (select 1 from public.code_redemptions where code_hash = p_code_hash and user_id = p_user_id) then
    return jsonb_build_object('status', 'already', 'scopes', to_jsonb(v_code.scopes));
  end if;
  if v_code.uses >= v_code.max_uses then
    insert into public.claim_attempts (user_id, kind, ok) values (p_user_id, 'code', false);
    return jsonb_build_object('status', 'used_up', 'scopes', '[]'::jsonb);
  end if;

  v_until := case when v_code.access_days is null then null else now() + make_interval(days => v_code.access_days) end;
  insert into public.code_redemptions (code_hash, user_id) values (p_code_hash, p_user_id);
  update public.access_codes set uses = uses + 1 where code_hash = p_code_hash;
  foreach v_scope in array v_code.scopes loop
    -- One row per user and code: the unique key (source, tx, scope) must not clash between users.
    insert into public.entitlements
      (user_id, source, scope, status, valid_until, product_ref, store_original_tx_id)
    values (p_user_id, 'manual', v_scope, 'active', v_until, 'code',
            'code:' || left(p_code_hash, 16) || ':' || p_user_id)
    on conflict (source, store_original_tx_id, scope) do update
      set status = 'active', valid_until = excluded.valid_until, updated_at = now();
  end loop;
  insert into public.claim_attempts (user_id, kind, ok) values (p_user_id, 'code', true);
  return jsonb_build_object('status', 'ok', 'scopes', to_jsonb(v_code.scopes));
end;
$$;

-- Gives the caller the app products of one shop order after the function proved that the
-- order number and the billing e-mail belong together. Returns ok, taken (another account
-- already holds it), not_paid (refunded or cancelled), nothing (no app product in the order)
-- or rate_limited.
create or replace function public.claim_order(
  p_user_id uuid,
  p_order_id bigint,
  p_email text,
  p_status text,
  p_product_refs text[]
) returns text language plpgsql security definer set search_path = public as $$
declare
  v_ref text;
  v_granted integer := 0;
begin
  if public.claim_rate_limited(p_user_id) then
    return 'rate_limited';
  end if;
  if p_status <> 'completed' then
    insert into public.claim_attempts (user_id, kind, ok) values (p_user_id, 'order', false);
    return 'not_paid';
  end if;
  -- The account that already holds this order keeps it (upsert_entitlement would move it).
  if exists (
    select 1 from public.entitlements
    where source = 'woocommerce' and store_original_tx_id like 'woo:' || p_order_id || ':%'
      and user_id <> p_user_id and status in ('active', 'grace', 'billing_retry')
  ) then
    insert into public.claim_attempts (user_id, kind, ok) values (p_user_id, 'order', false);
    return 'taken';
  end if;
  foreach v_ref in array coalesce(p_product_refs, '{}') loop
    continue when not exists (select 1 from public.store_products where product_ref = v_ref);
    insert into public.web_purchases_pending (woo_order_id, product_ref, email_normalized, order_status, claimed_by)
    values (p_order_id, v_ref, lower(trim(p_email)), 'completed', p_user_id)
    on conflict (woo_order_id, product_ref) do update set claimed_by = excluded.claimed_by, order_status = 'completed';
    perform public.upsert_entitlement(
      p_user_id, 'woocommerce', v_ref, 'woo:' || p_order_id || ':' || v_ref, 'active', null
    );
    v_granted := v_granted + 1;
  end loop;
  insert into public.claim_attempts (user_id, kind, ok) values (p_user_id, 'order', v_granted > 0);
  return case when v_granted > 0 then 'ok' else 'nothing' end;
end;
$$;

revoke all on function public.claim_rate_limited(uuid) from public, anon, authenticated;
revoke all on function public.note_claim_failure(uuid, text) from public, anon, authenticated;
revoke all on function public.redeem_access_code(uuid, text) from public, anon, authenticated;
revoke all on function public.claim_order(uuid, bigint, text, text, text[]) from public, anon, authenticated;

-- Supabase grants new tables to the API roles by default; these are for the service role only.
revoke all on public.access_codes, public.code_redemptions, public.claim_attempts from anon, authenticated;

-- Audit 2026-09-28 (docs/audyt-2026-09-28/RAPORT.md, P1 1, 3, 4, 5):
-- 1. A store document may only overwrite state that is not newer than itself. An old, still
--    validly signed transaction can no longer reactivate a refunded purchase.
-- 3. A store event is recorded and applied in one transaction: a redelivery changes nothing,
--    and a failed update leaves no "seen" mark behind, so the store's retry still works.
-- 4. Ownership of a store purchase is decided server-side (is the current holder anonymous?).
-- 5. The WooCommerce webhook is one atomic operation for the same reason as 3.

alter table public.entitlements add column source_signed_at timestamptz;

comment on column public.entitlements.source_signed_at is
  'When the store signed the document this state comes from (Apple signedDate, Google fetch time). Older documents never overwrite newer state.';

drop function if exists public.upsert_entitlement(uuid, public.entitlement_source, text, text, public.entitlement_status, timestamptz);

create or replace function public.upsert_entitlement(
  p_user_id uuid,
  p_source public.entitlement_source,
  p_product_ref text,
  p_tx_id text,
  p_status public.entitlement_status,
  p_valid_until timestamptz,
  p_signed_at timestamptz default null
) returns integer language plpgsql security definer set search_path = public as $$
declare
  v_scopes text[];
  v_scope text;
begin
  select scopes into v_scopes from public.store_products where product_ref = p_product_ref;
  if v_scopes is null then
    raise exception 'unknown product %', p_product_ref using errcode = 'P0002';
  end if;
  foreach v_scope in array v_scopes loop
    insert into public.entitlements
      (user_id, source, scope, status, valid_until, product_ref, store_original_tx_id, source_signed_at)
    values (p_user_id, p_source, v_scope, p_status, p_valid_until, p_product_ref, p_tx_id, p_signed_at)
    on conflict (source, store_original_tx_id, scope) do update
      set status = excluded.status, valid_until = excluded.valid_until, user_id = excluded.user_id,
          source_signed_at = coalesce(excluded.source_signed_at, entitlements.source_signed_at),
          updated_at = now()
      -- Shop claims carry no signing time; store documents must not be older than what we have.
      where entitlements.source_signed_at is null
         or excluded.source_signed_at is null
         or excluded.source_signed_at >= entitlements.source_signed_at;
  end loop;
  return cardinality(v_scopes);
end;
$$;

-- Status of every scope of one purchase (refunds, replaced subscriptions), newest wins.
create or replace function public.set_entitlement_status(
  p_source public.entitlement_source,
  p_tx_id text,
  p_status public.entitlement_status,
  p_signed_at timestamptz
) returns integer language plpgsql security definer set search_path = public as $$
declare
  v_count integer;
begin
  update public.entitlements
     set status = p_status, source_signed_at = p_signed_at, updated_at = now()
   where source = p_source and store_original_tx_id = p_tx_id
     and (source_signed_at is null or p_signed_at >= source_signed_at);
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

-- One store event, applied once. Returns 'updated', 'duplicate' or 'stale' (older than the
-- state we already have). Everything happens in this function's transaction: an error rolls
-- the event mark back as well, so the store can deliver it again.
create or replace function public.apply_store_event(
  p_event_id text,
  p_source public.entitlement_source,
  p_payload_hash text,
  p_tx_id text,
  p_status public.entitlement_status,
  p_signed_at timestamptz,
  p_user_id uuid default null,
  p_product_ref text default null,
  p_valid_until timestamptz default null
) returns text language plpgsql security definer set search_path = public as $$
declare
  v_before timestamptz;
begin
  insert into public.store_events (event_id, source, payload_hash)
  values (p_event_id, p_source, p_payload_hash)
  on conflict (event_id) do nothing;
  if not found then
    return 'duplicate';
  end if;
  select max(source_signed_at) into v_before
    from public.entitlements where source = p_source and store_original_tx_id = p_tx_id;
  if v_before is not null and p_signed_at < v_before then
    return 'stale';
  end if;
  if p_product_ref is null then
    perform public.set_entitlement_status(p_source, p_tx_id, p_status, p_signed_at);
  else
    perform public.upsert_entitlement(p_user_id, p_source, p_product_ref, p_tx_id, p_status, p_valid_until, p_signed_at);
  end if;
  return 'updated';
end;
$$;

-- Anonymous purchase holders (ARCHITECTURE D4) may hand a purchase over to the parent's
-- account; a real account keeps what it bought.
create or replace function public.is_anonymous_user(p_user_id uuid)
returns boolean language sql stable security definer set search_path = public, auth as $$
  select coalesce((select u.is_anonymous from auth.users u where u.id = p_user_id), false)
$$;

-- WooCommerce order.updated, atomically: event mark, pending rows, and (when the buyer already
-- has an account with this confirmed e-mail) the entitlements. Returns 'applied',
-- 'duplicate' or 'pending' (no account yet).
create or replace function public.apply_woo_order(
  p_event_id text,
  p_payload_hash text,
  p_order_id bigint,
  p_email text,
  p_status text,
  p_product_refs text[]
) returns text language plpgsql security definer set search_path = public as $$
declare
  v_user uuid;
  v_ref text;
begin
  insert into public.store_events (event_id, source, payload_hash)
  values (p_event_id, 'woocommerce', p_payload_hash)
  on conflict (event_id) do nothing;
  if not found then
    return 'duplicate';
  end if;
  foreach v_ref in array coalesce(p_product_refs, '{}') loop
    insert into public.web_purchases_pending (woo_order_id, product_ref, email_normalized, order_status)
    values (p_order_id, v_ref, lower(trim(p_email)), p_status)
    on conflict (woo_order_id, product_ref) do update
      set order_status = excluded.order_status, email_normalized = excluded.email_normalized;
  end loop;
  v_user := public.user_id_for_email(p_email);
  if v_user is null then
    return 'pending';
  end if;
  perform public.claim_web_purchases(v_user, p_email);
  return 'applied';
end;
$$;

revoke all on function public.upsert_entitlement(uuid, public.entitlement_source, text, text, public.entitlement_status, timestamptz, timestamptz) from public, anon, authenticated;
revoke all on function public.set_entitlement_status(public.entitlement_source, text, public.entitlement_status, timestamptz) from public, anon, authenticated;
revoke all on function public.apply_store_event(text, public.entitlement_source, text, text, public.entitlement_status, timestamptz, uuid, text, timestamptz) from public, anon, authenticated;
revoke all on function public.is_anonymous_user(uuid) from public, anon, authenticated;
revoke all on function public.apply_woo_order(text, text, bigint, text, text, text[]) from public, anon, authenticated;

grant execute on function public.upsert_entitlement(uuid, public.entitlement_source, text, text, public.entitlement_status, timestamptz, timestamptz) to service_role;
grant execute on function public.set_entitlement_status(public.entitlement_source, text, public.entitlement_status, timestamptz) to service_role;
grant execute on function public.apply_store_event(text, public.entitlement_source, text, text, public.entitlement_status, timestamptz, uuid, text, timestamptz) to service_role;
grant execute on function public.is_anonymous_user(uuid) to service_role;
grant execute on function public.apply_woo_order(text, text, bigint, text, text, text[]) to service_role;

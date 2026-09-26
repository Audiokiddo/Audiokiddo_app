-- AudioKiddo: initial schema (ARCHITECTURE §6.1, §7, §7a).
-- No child data is stored on the server. Writes to entitlements happen only through
-- server functions (service role); signed-in users can read their own rows.

create extension if not exists pgcrypto;

-- Accounts --------------------------------------------------------------------------

create table public.accounts (
  user_id uuid primary key references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);

create table public.admins (
  user_id uuid primary key references auth.users (id) on delete cascade
);

create or replace function public.is_admin() returns boolean
language sql stable security definer set search_path = public as $$
  select exists (select 1 from public.admins where user_id = auth.uid());
$$;

-- Products and entitlements ---------------------------------------------------------

create type public.entitlement_source as enum ('app_store', 'google_play', 'woocommerce', 'manual');
create type public.entitlement_status as enum ('active', 'grace', 'billing_retry', 'expired', 'revoked', 'refunded');

-- Store or shop product → scopes it grants, e.g. 'woo:1234' → {pack:wyobraznia}.
create table public.store_products (
  product_ref text primary key,
  scopes text[] not null check (cardinality(scopes) > 0)
);

create table public.entitlements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  source public.entitlement_source not null,
  scope text not null check (scope ~ '^(all_content|pack:[a-z0-9-]+|item:[a-z0-9-]+)$'),
  status public.entitlement_status not null,
  valid_until timestamptz,
  product_ref text not null,
  -- iOS originalTransactionId, Android purchaseToken, 'woo:<order>:<product>' or a manual note.
  store_original_tx_id text not null,
  updated_at timestamptz not null default now(),
  unique (source, store_original_tx_id, scope)
);

create index entitlements_user_idx on public.entitlements (user_id);

-- Idempotency of store notifications and shop webhooks (redeliveries are ignored).
create table public.store_events (
  event_id text primary key,
  source public.entitlement_source not null,
  payload_hash text not null,
  received_at timestamptz not null default now()
);

-- Shop orders whose buyer has no app account yet; claimed after e-mail sign-in.
create table public.web_purchases_pending (
  woo_order_id bigint not null,
  product_ref text not null,
  email_normalized text not null,
  order_status text not null check (order_status in ('completed', 'refunded', 'cancelled')),
  created_at timestamptz not null default now(),
  claimed_by uuid references auth.users (id) on delete set null,
  primary key (woo_order_id, product_ref)
);

create index web_purchases_pending_email_idx on public.web_purchases_pending (email_normalized);

-- Content managed in Studio -----------------------------------------------------------

create table public.packs (
  id text primary key check (id ~ '^[a-z0-9-]+$'),
  data jsonb not null,
  updated_at timestamptz not null default now()
);

create table public.content_items (
  id text primary key check (id ~ '^[a-z0-9-]+$'),
  data jsonb not null,
  status text not null default 'draft' check (status in ('draft', 'published', 'withdrawn')),
  updated_at timestamptz not null default now(),
  updated_by uuid references auth.users (id) on delete set null
);

-- Immutable published snapshots; publishing or rolling back only moves the pointer.
create table public.catalog_versions (
  version integer generated always as identity primary key,
  manifest jsonb not null,
  manifest_sha256 text not null,
  note text,
  created_at timestamptz not null default now(),
  created_by uuid references auth.users (id) on delete set null
);

create table public.catalog_pointer (
  singleton boolean primary key default true check (singleton),
  version integer not null references public.catalog_versions (version)
);

-- Server-side operations (called by Edge Functions with the service role) ------------

-- Records a notification/webhook once; returns false for a redelivery.
create or replace function public.record_store_event(
  p_event_id text, p_source public.entitlement_source, p_payload_hash text
) returns boolean language plpgsql security definer set search_path = public as $$
begin
  insert into public.store_events (event_id, source, payload_hash) values (p_event_id, p_source, p_payload_hash);
  return true;
exception when unique_violation then
  return false;
end;
$$;

-- Grants or updates every scope of a product for one purchase/transaction.
create or replace function public.upsert_entitlement(
  p_user_id uuid,
  p_source public.entitlement_source,
  p_product_ref text,
  p_tx_id text,
  p_status public.entitlement_status,
  p_valid_until timestamptz
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
    insert into public.entitlements (user_id, source, scope, status, valid_until, product_ref, store_original_tx_id)
    values (p_user_id, p_source, v_scope, p_status, p_valid_until, p_product_ref, p_tx_id)
    on conflict (source, store_original_tx_id, scope) do update
      set status = excluded.status, valid_until = excluded.valid_until,
          user_id = excluded.user_id, updated_at = now();
  end loop;
  return cardinality(v_scopes);
end;
$$;

-- Moves shop orders for a verified e-mail into the account (ARCHITECTURE §7a).
create or replace function public.claim_web_purchases(p_user_id uuid, p_email text)
returns integer language plpgsql security definer set search_path = public as $$
declare
  v_row public.web_purchases_pending;
  v_count integer := 0;
begin
  for v_row in
    select * from public.web_purchases_pending
    where email_normalized = lower(trim(p_email))
      and exists (select 1 from public.store_products sp where sp.product_ref = web_purchases_pending.product_ref)
  loop
    perform public.upsert_entitlement(
      p_user_id, 'woocommerce', v_row.product_ref,
      'woo:' || v_row.woo_order_id || ':' || v_row.product_ref,
      case v_row.order_status when 'completed' then 'active' else 'revoked' end::public.entitlement_status,
      null
    );
    update public.web_purchases_pending set claimed_by = p_user_id
    where woo_order_id = v_row.woo_order_id and product_ref = v_row.product_ref;
    v_count := v_count + 1;
  end loop;
  return v_count;
end;
$$;

-- Nobody but the service role may call the write helpers.
revoke all on function public.record_store_event(text, public.entitlement_source, text) from public, anon, authenticated;
revoke all on function public.upsert_entitlement(uuid, public.entitlement_source, text, text, public.entitlement_status, timestamptz) from public, anon, authenticated;
revoke all on function public.claim_web_purchases(uuid, text) from public, anon, authenticated;

-- Row level security ------------------------------------------------------------------

alter table public.accounts enable row level security;
alter table public.admins enable row level security;
alter table public.store_products enable row level security;
alter table public.entitlements enable row level security;
alter table public.store_events enable row level security;
alter table public.web_purchases_pending enable row level security;
alter table public.packs enable row level security;
alter table public.content_items enable row level security;
alter table public.catalog_versions enable row level security;
alter table public.catalog_pointer enable row level security;

create policy "own account" on public.accounts for select to authenticated using (user_id = auth.uid());
create policy "own entitlements" on public.entitlements for select to authenticated using (user_id = auth.uid());

create policy "admins read admins" on public.admins for select to authenticated using (public.is_admin());
create policy "admins manage packs" on public.packs for all to authenticated
  using (public.is_admin()) with check (public.is_admin());
create policy "admins manage content" on public.content_items for all to authenticated
  using (public.is_admin()) with check (public.is_admin());
create policy "admins read versions" on public.catalog_versions for select to authenticated using (public.is_admin());
create policy "admins read pointer" on public.catalog_pointer for select to authenticated using (public.is_admin());
create policy "admins manage products" on public.store_products for all to authenticated
  using (public.is_admin()) with check (public.is_admin());
-- store_events and web_purchases_pending: no policies = service role only.

-- Grants follow the policies; RLS decides the rows.
grant select on public.accounts, public.entitlements to authenticated;
grant select on public.admins, public.catalog_versions, public.catalog_pointer to authenticated;
grant select, insert, update, delete on public.packs, public.content_items, public.store_products to authenticated;

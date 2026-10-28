-- Gifts bought on audiokiddo.pl: a gift product in the shop gives the buyer an access code
-- (sent as a customer note on the order, so WooCommerce e-mails it) instead of access on the
-- buyer's own account. The person who gets the gift types the code in the app.
-- The code is derived from a server secret and the order, so a webhook retry gives the same
-- code; only its SHA-256 is stored, like every access code.

-- Which shop products are gifts, what they unlock and for how long (null = for good).
create table public.gift_products (
  product_ref text primary key check (product_ref ~ '^woo:[0-9]+$'),
  scopes text[] not null check (cardinality(scopes) > 0),
  access_days integer check (access_days is null or access_days between 1 and 3650),
  label text not null default '' check (length(label) <= 80)
);
alter table public.gift_products enable row level security;

-- One code per gift product in an order; note_sent once the buyer was told the code.
create table public.gift_codes (
  woo_order_id bigint not null,
  product_ref text not null,
  code_hash text not null references public.access_codes (code_hash) on delete cascade,
  note_sent boolean not null default false,
  created_at timestamptz not null default now(),
  primary key (woo_order_id, product_ref)
);
alter table public.gift_codes enable row level security;
revoke all on public.gift_products, public.gift_codes from anon, authenticated;

-- Issues the code of one gift line (idempotent). Returns 'not_gift', 'send' (the note still has
-- to go out) or 'sent' (nothing to do).
create or replace function public.issue_gift_code(p_order_id bigint, p_product_ref text, p_code_hash text)
returns text language plpgsql security definer set search_path = public as $$
declare
  v_gift public.gift_products;
  v_sent boolean;
begin
  select * into v_gift from public.gift_products where product_ref = p_product_ref;
  if not found then
    return 'not_gift';
  end if;
  select note_sent into v_sent from public.gift_codes where woo_order_id = p_order_id and product_ref = p_product_ref;
  if found then
    return case when v_sent then 'sent' else 'send' end;
  end if;
  insert into public.access_codes (code_hash, scopes, note, max_uses, access_days)
  values (p_code_hash, v_gift.scopes, 'Prezent woo:' || p_order_id, 1, v_gift.access_days)
  on conflict (code_hash) do nothing;
  insert into public.gift_codes (woo_order_id, product_ref, code_hash) values (p_order_id, p_product_ref, p_code_hash);
  return 'send';
end;
$$;

create or replace function public.mark_gift_note_sent(p_order_id bigint, p_product_ref text)
returns void language sql security definer set search_path = public as $$
  update public.gift_codes set note_sent = true where woo_order_id = p_order_id and product_ref = p_product_ref
$$;

-- A refunded or cancelled gift order: the code stops working and access given through it ends.
create or replace function public.revoke_gift_codes(p_order_id bigint)
returns integer language plpgsql security definer set search_path = public as $$
declare
  v_hash text;
  v_count integer := 0;
begin
  for v_hash in select code_hash from public.gift_codes where woo_order_id = p_order_id loop
    update public.access_codes set expires_at = now() where code_hash = v_hash;
    update public.entitlements set status = 'revoked', updated_at = now()
    where product_ref = 'code' and store_original_tx_id like 'code:' || left(v_hash, 16) || ':%';
    v_count := v_count + 1;
  end loop;
  return v_count;
end;
$$;

revoke all on function public.issue_gift_code(bigint, text, text) from public, anon, authenticated;
revoke all on function public.mark_gift_note_sent(bigint, text) from public, anon, authenticated;
revoke all on function public.revoke_gift_codes(bigint) from public, anon, authenticated;

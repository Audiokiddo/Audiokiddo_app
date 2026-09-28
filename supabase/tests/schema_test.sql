-- Behavioural tests for the schema: run by tool/test_db.sh after the migrations.
\set ON_ERROR_STOP 1

insert into auth.users (id, email, email_confirmed_at) values
  ('00000000-0000-0000-0000-000000000001', 'rodzic1@example.com', now()),
  ('00000000-0000-0000-0000-000000000002', 'Rodzic2@example.com', now()),
  ('00000000-0000-0000-0000-000000000003', 'niepotwierdzony@example.com', null);

-- 0. Shop buyers are matched only to confirmed e-mails.
do $$
begin
  assert public.user_id_for_email(' rodzic2@EXAMPLE.com') = '00000000-0000-0000-0000-000000000002';
  assert public.user_id_for_email('niepotwierdzony@example.com') is null, 'unconfirmed e-mail ignored';
  assert public.user_id_for_email('nikt@example.com') is null;
end $$;

insert into public.store_products (product_ref, scopes) values
  ('woo:101', '{pack:wyobraznia}'),
  ('ios:pl.audiokiddo.bundle.three', '{pack:wyobraznia,pack:slowa-i-wiedza,pack:detektyw}'),
  ('ios:pl.audiokiddo.sub.yearly', '{all_content}')
on conflict (product_ref) do nothing; -- the store products migration may already have them

-- 1. A bundle grants every pack; repeating the same transaction is idempotent.
do $$
begin
  assert public.upsert_entitlement('00000000-0000-0000-0000-000000000001', 'app_store',
    'ios:pl.audiokiddo.bundle.three', 'tx-1', 'active', null) = 3;
  perform public.upsert_entitlement('00000000-0000-0000-0000-000000000001', 'app_store',
    'ios:pl.audiokiddo.bundle.three', 'tx-1', 'active', null);
  assert (select count(*) from public.entitlements where store_original_tx_id = 'tx-1') = 3, 'idempotent upsert';
  -- A refund notification flips the same rows.
  perform public.upsert_entitlement('00000000-0000-0000-0000-000000000001', 'app_store',
    'ios:pl.audiokiddo.bundle.three', 'tx-1', 'refunded', null);
  assert (select bool_and(status = 'refunded') from public.entitlements where store_original_tx_id = 'tx-1');
  perform public.upsert_entitlement('00000000-0000-0000-0000-000000000001', 'app_store',
    'ios:pl.audiokiddo.sub.yearly', 'tx-2', 'active', now() + interval '1 year');
end $$;

-- 2. Unknown products are rejected.
do $$
begin
  perform public.upsert_entitlement('00000000-0000-0000-0000-000000000001', 'app_store', 'ios:nope', 'tx-x', 'active', null);
  raise exception 'should have failed';
exception when sqlstate 'P0002' then null;
end $$;

-- 3. Store notifications are processed once.
do $$
begin
  assert public.record_store_event('apple-uuid-1', 'app_store', 'h1');
  assert not public.record_store_event('apple-uuid-1', 'app_store', 'h1'), 'redelivery ignored';
end $$;

-- 4. Shop orders are claimed after e-mail sign-in; unknown shop products are skipped.
insert into public.web_purchases_pending (woo_order_id, product_ref, email_normalized, order_status) values
  (501, 'woo:101', 'rodzic2@example.com', 'completed'),
  (502, 'woo:999', 'rodzic2@example.com', 'completed'),
  (503, 'woo:101', 'ktos@example.com', 'completed');
do $$
begin
  assert public.claim_web_purchases('00000000-0000-0000-0000-000000000002', '  Rodzic2@Example.com ') = 1;
  assert exists (select 1 from public.entitlements
    where user_id = '00000000-0000-0000-0000-000000000002' and scope = 'pack:wyobraznia'
      and source = 'woocommerce' and status = 'active'), 'shop pack granted';
  assert (select claimed_by from public.web_purchases_pending where woo_order_id = 501)
    = '00000000-0000-0000-0000-000000000002';
  assert (select claimed_by from public.web_purchases_pending where woo_order_id = 503) is null, 'other e-mail untouched';
end $$;

-- 5. RLS: a parent sees only their own entitlements and cannot grant themselves anything.
set role authenticated;
do $$ begin perform set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000002', false); end $$;
do $$
begin
  assert (select count(*) from public.entitlements) = 1, 'only own rows visible';
  begin
    insert into public.entitlements (user_id, source, scope, status, product_ref, store_original_tx_id)
    values ('00000000-0000-0000-0000-000000000002', 'manual', 'all_content', 'active', 'x', 'x');
    raise exception 'insert should be denied';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.upsert_entitlement('00000000-0000-0000-0000-000000000002', 'manual', 'woo:101', 'hack', 'active', null);
    raise exception 'function should be denied';
  exception when insufficient_privilege then null;
  end;
  begin
    perform count(*) from public.store_events;
    raise exception 'store_events should be denied';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.content_items (id, data) values ('x', '{}');
    raise exception 'non-admin content write should be denied';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;

-- 6. Admins (Dawid, Nela) manage content through Studio.
insert into public.admins (user_id) values ('00000000-0000-0000-0000-000000000001');
set role authenticated;
do $$ begin perform set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000001', false); end $$;
insert into public.content_items (id, data) values ('magiczny-sklep', '{"title": "Magiczny sklep"}');
do $$ begin assert (select count(*) from public.content_items) = 1; end $$;
reset role;

-- 7. Deleting an account removes its entitlements and unlinks shop claims.
delete from auth.users where id = '00000000-0000-0000-0000-000000000002';
do $$
begin
  assert not exists (select 1 from public.entitlements where user_id = '00000000-0000-0000-0000-000000000002');
  assert (select claimed_by from public.web_purchases_pending where woo_order_id = 501) is null;
end $$;

select 'schema tests passed' as result;

-- 9. Anonymous clients have no table privileges at all.
do $$ begin
  assert not has_table_privilege('anon', 'public.entitlements', 'select'), 'anon cannot read entitlements';
  assert not has_table_privilege('anon', 'public.store_products', 'select'), 'anon cannot read products';
  assert not has_function_privilege('anon', 'public.claim_web_purchases(uuid, text)', 'execute'), 'anon cannot claim';
  assert has_table_privilege('authenticated', 'public.entitlements', 'select'), 'parents read own entitlements';
end $$;
select 'grant tests passed';

-- 10. Real shop products are mapped (bundle of three grants all packs).
do $$ begin
  assert (select cardinality(scopes) from public.store_products where product_ref = 'woo:6235') = 3, 'bundle of three';
  assert (select scopes from public.store_products where product_ref = 'woo:7339') = '{pack:detektyw}', 'detective pack';
end $$;
select 'shop product tests passed';

-- 11. Store products: both stores, subscriptions give everything, a store purchase upserts.
insert into auth.users (id, email) values ('00000000-0000-0000-0000-000000000009', null);
do $$ begin
  assert (select scopes from public.store_products where product_ref = 'ios:pl.audiokiddo.sub.yearly') = '{all_content}', 'yearly';
  assert (select scopes from public.store_products where product_ref = 'android:pl.audiokiddo.sub.monthly') = '{all_content}', 'monthly';
  assert (select cardinality(scopes) from public.store_products where product_ref = 'ios:pl.audiokiddo.bundle.three') = 3, 'bundle of three';
  assert exists (select 1 from public.store_products where product_ref = 'android:pl.audiokiddo.item.magiczny_sklep'), 'single item';
  perform public.upsert_entitlement('00000000-0000-0000-0000-000000000009', 'app_store', 'ios:pl.audiokiddo.sub.yearly', 'orig-1', 'active', now() + interval '1 year');
  perform public.upsert_entitlement('00000000-0000-0000-0000-000000000009', 'app_store', 'ios:pl.audiokiddo.sub.yearly', 'orig-1', 'refunded', null);
  assert (select status from public.entitlements where store_original_tx_id = 'orig-1') = 'refunded', 'same purchase is updated, not duplicated';
  assert (select count(*) from public.entitlements where store_original_tx_id = 'orig-1') = 1;
end $$;
select 'store product tests passed';

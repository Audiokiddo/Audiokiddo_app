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

-- 12. Audit 2026-09-28: newer store state wins, events are atomic, guests are recognised.
insert into auth.users (id, email, is_anonymous) values ('00000000-0000-0000-0000-00000000000a', null, true);
do $$
declare
  v text;
begin
  -- A refund signed later survives a replay of the older purchase document.
  perform public.upsert_entitlement('00000000-0000-0000-0000-000000000009', 'app_store', 'ios:pl.audiokiddo.pack.wyobraznia', 'orig-2', 'active', null, '2026-09-01');
  v := public.apply_store_event('apple:refund-2', 'app_store', 'h', 'orig-2', 'refunded', '2026-09-10');
  assert v = 'updated', 'refund applied: ' || v;
  perform public.upsert_entitlement('00000000-0000-0000-0000-000000000009', 'app_store', 'ios:pl.audiokiddo.pack.wyobraznia', 'orig-2', 'active', null, '2026-09-01');
  assert (select status from public.entitlements where store_original_tx_id = 'orig-2') = 'refunded', 'old document does not win';

  -- The same event twice: the second changes nothing, even after other changes.
  v := public.apply_store_event('apple:renew-3', 'app_store', 'h', 'orig-2', 'active', '2026-09-05',
    '00000000-0000-0000-0000-000000000009', 'ios:pl.audiokiddo.pack.wyobraznia', null);
  assert v = 'stale', 'older than the refund: ' || v;
  v := public.apply_store_event('apple:renew-3', 'app_store', 'h', 'orig-2', 'active', '2026-09-20',
    '00000000-0000-0000-0000-000000000009', 'ios:pl.audiokiddo.pack.wyobraznia', null);
  assert v = 'duplicate', 'redelivery: ' || v;
  assert (select status from public.entitlements where store_original_tx_id = 'orig-2') = 'refunded';

  -- A failing event (unknown product) leaves no mark, so the store's retry is processed.
  begin
    perform public.apply_store_event('apple:bad-4', 'app_store', 'h', 'orig-3', 'active', now(),
      '00000000-0000-0000-0000-000000000009', 'ios:nope', null);
  exception when sqlstate 'P0002' then null;
  end;
  assert not exists (select 1 from public.store_events where event_id = 'apple:bad-4'), 'rolled back';

  assert public.is_anonymous_user('00000000-0000-0000-0000-00000000000a'), 'guest';
  assert not public.is_anonymous_user('00000000-0000-0000-0000-000000000009'), 'parent';

  -- WooCommerce: one call applies the order for an existing account; a retry is a duplicate.
  v := public.apply_woo_order('woo:d-1', 'h', 7001, ' Rodzic1@Example.com ', 'completed', '{woo:372}');
  assert v = 'applied', 'woo: ' || v;
  assert exists (select 1 from public.entitlements where store_original_tx_id = 'woo:7001:woo:372'
    and user_id = '00000000-0000-0000-0000-000000000001' and status = 'active'), 'woo granted';
  assert public.apply_woo_order('woo:d-1', 'h', 7001, 'rodzic1@example.com', 'completed', '{woo:372}') = 'duplicate';
  assert public.apply_woo_order('woo:d-2', 'h', 7002, 'nikt@example.com', 'completed', '{woo:372}') = 'pending';
  assert not has_function_privilege('authenticated', 'public.apply_store_event(text, public.entitlement_source, text, text, public.entitlement_status, timestamptz, uuid, text, timestamptz)', 'execute');
end $$;
select 'store order tests passed';

-- 13. Downloads: free files for anyone, paid files only with a live entitlement.
do $$ begin
  assert public.can_download(null, 'audio/wyobraznia/magiczny-sklep.m4a'), 'free item';
  assert not public.can_download(null, 'audio/wyobraznia/zaginiony-skarb.m4a'), 'paid item without account';
  assert not public.can_download('00000000-0000-0000-0000-000000000009', 'audio/wyobraznia/zaginiony-skarb.m4a'), 'refunded subscription';
  perform public.upsert_entitlement('00000000-0000-0000-0000-000000000009', 'app_store', 'ios:pl.audiokiddo.sub.yearly', 'orig-5', 'active', now() + interval '1 year', now());
  assert public.can_download('00000000-0000-0000-0000-000000000009', 'audio/wyobraznia/zaginiony-skarb.m4a'), 'yearly subscription covers all';
  assert not public.can_download('00000000-0000-0000-0000-000000000009', 'audio/../secret.m4a'), 'unknown path';
  assert not public.can_download('00000000-0000-0000-0000-00000000000a', 'audio/detektyw/tajemnicze-znaki.m4a'), 'guest without purchase';
  assert public.can_download(null, 'previews/detektyw/tajemnicze-znaki.m4a'), 'a preview of a paid item is free';
  assert public.can_download(null, 'pdf/detektyw/przewodnik.pdf'), 'a pack guide is free';
  assert not public.can_download(null, 'pdf/detektyw/tajemnicze-znaki.pdf'), 'case files stay paid';
end $$;
select 'download tests passed';

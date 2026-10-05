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

-- 14. Access codes and orders claimed by number.
do $$
declare
  u1 constant uuid := '00000000-0000-0000-0000-000000000001';
  u9 constant uuid := '00000000-0000-0000-0000-000000000009';
  ua constant uuid := '00000000-0000-0000-0000-00000000000a';
  h1 constant text := repeat('a', 64);
  h2 constant text := repeat('b', 64);
  h3 constant text := repeat('c', 64);
  r jsonb;
begin
  insert into public.access_codes (code_hash, scopes, note, max_uses) values (h1, '{pack:detektyw}', 'test', 2);
  insert into public.access_codes (code_hash, scopes, expires_at) values (h2, '{all_content}', now() - interval '1 day');
  insert into public.access_codes (code_hash, scopes, access_days) values (h3, '{pack:wyobraznia}', 30);

  assert (public.redeem_access_code(ua, repeat('f', 64))->>'status') = 'invalid', 'unknown code';
  assert (public.redeem_access_code(ua, h2)->>'status') = 'expired', 'expired code';
  r := public.redeem_access_code(ua, h1);
  assert r->>'status' = 'ok' and r->'scopes' = '["pack:detektyw"]', 'redeemed: ' || r::text;
  assert public.can_download(ua, 'audio/detektyw/tajemnicze-znaki.m4a'), 'the code unlocks the pack for the guest account';
  assert not public.can_download(ua, 'audio/wyobraznia/zaginiony-skarb.m4a'), 'only that pack';
  assert (public.redeem_access_code(ua, h1)->>'status') = 'already', 'the same account twice';
  assert (select uses from public.access_codes where code_hash = h1) = 1, 'uses counted once';
  assert (public.redeem_access_code(u9, h1)->>'status') = 'ok', 'second use';
  assert (select count(*) from public.entitlements where product_ref = 'code' and scope = 'pack:detektyw') = 2,
    'two accounts hold their own rows (no clash on the unique key)';
  assert (public.redeem_access_code(u1, h1)->>'status') = 'used_up', 'used up';

  perform public.redeem_access_code(u1, h3);
  assert (select valid_until from public.entitlements where user_id = u1 and scope = 'pack:wyobraznia' and product_ref = 'code')
    between now() + interval '29 days' and now() + interval '31 days', 'timed access';

  -- Guessing is limited: ten failures an hour, then even a good code waits.
  for i in 1..10 loop
    perform public.redeem_access_code(u9, repeat(i::text, 64));
  end loop;
  assert (public.redeem_access_code(u9, h3)->>'status') = 'rate_limited', 'rate limit after ten failures';

  -- Orders: user 1 claims order 9100 (Detektyw) by number.
  assert public.claim_order(ua, 9100, 'kupujacy@example.com', 'refunded', '{woo:7339}') = 'not_paid', 'refunded order';
  assert public.claim_order(ua, 9100, 'kupujacy@example.com', 'completed', '{woo:999999}') = 'nothing', 'no app product';
  assert public.claim_order(ua, 9100, 'kupujacy@example.com', 'completed', '{woo:7339,woo:999999}') = 'ok', 'claimed';
  assert exists (select 1 from public.entitlements where user_id = ua and store_original_tx_id = 'woo:9100:woo:7339' and status = 'active'), 'granted';
  assert public.claim_order(ua, 9100, 'kupujacy@example.com', 'completed', '{woo:7339}') = 'ok', 'the holder can claim again';
  assert public.claim_order(u1, 9100, 'kupujacy@example.com', 'completed', '{woo:7339}') = 'taken', 'another account cannot take it';
  assert (select user_id from public.entitlements where store_original_tx_id = 'woo:9100:woo:7339') = ua, 'still with the first';
  perform public.note_claim_failure(u1, 'order');
  assert (select count(*) from public.claim_attempts where user_id = u1 and kind = 'order' and not ok) >= 1, 'function-side failures are counted';
  assert not has_function_privilege('authenticated', 'public.note_claim_failure(uuid, text)', 'execute'), 'service role only';
  assert not has_function_privilege('authenticated', 'public.redeem_access_code(uuid, text)', 'execute'), 'service role only';
  assert not has_function_privilege('authenticated', 'public.claim_order(uuid, bigint, text, text, text[])', 'execute'), 'service role only';
  assert not has_table_privilege('authenticated', 'public.access_codes', 'select'), 'codes are not readable';
end $$;
select 'access code tests passed';

-- Referrals: the friend gets 14 days, the parent who shared the code gets 30 days after the
-- friend's first purchase; own code and a second referral are refused.
insert into auth.users (id, email, email_confirmed_at) values
  ('00000000-0000-0000-0000-0000000000a1', 'polecajacy@example.com', now()),
  ('00000000-0000-0000-0000-0000000000a2', 'znajomy@example.com', now());
do $$
declare
  v_code text;
begin
  v_code := public.referral_code_for('00000000-0000-0000-0000-0000000000a1', 'POLECABCDEF') ->> 'code';
  assert v_code = 'POLECABCDEF';
  assert public.referral_code_for('00000000-0000-0000-0000-0000000000a1', 'POLECZZZZZZ') ->> 'code' = 'POLECABCDEF', 'one code per parent';
  assert public.redeem_referral('00000000-0000-0000-0000-0000000000a1', v_code) ->> 'status' = 'invalid', 'own code refused';
  assert public.redeem_referral('00000000-0000-0000-0000-0000000000a2', v_code) ->> 'status' = 'ok';
  assert public.redeem_referral('00000000-0000-0000-0000-0000000000a2', v_code) ->> 'status' = 'already';
  assert exists (select 1 from public.entitlements where user_id = '00000000-0000-0000-0000-0000000000a2'
    and scope = 'all_content' and valid_until > now() + interval '13 days'), 'friend trial';
  assert not exists (select 1 from public.entitlements where user_id = '00000000-0000-0000-0000-0000000000a1'), 'no reward before a purchase';
  perform public.upsert_entitlement('00000000-0000-0000-0000-0000000000a2', 'app_store',
    'ios:pl.audiokiddo.sub.yearly', 'tx-ref', 'active', null);
  assert exists (select 1 from public.entitlements where user_id = '00000000-0000-0000-0000-0000000000a1'
    and product_ref = 'referral-reward' and valid_until > now() + interval '29 days'), 'reward after purchase';
  assert (public.referral_code_for('00000000-0000-0000-0000-0000000000a1', 'POLECZZZZZZ') ->> 'rewards')::int = 1;
end $$;

-- Statistics, promotions and the published catalog.
do $$
declare
  v integer;
begin
  insert into public.app_events (install_id, event, item_id) values
    ('11111111-1111-1111-1111-111111111111', 'first_open', null),
    ('11111111-1111-1111-1111-111111111111', 'play_start', 'magiczny-sklep'),
    ('22222222-2222-2222-2222-222222222222', 'play_start', 'magiczny-sklep');
  assert (public.admin_stats(30) -> 'events' -> 'play_start' ->> 'installs')::int = 2;

  insert into public.promotions (title, starts_at, ends_at) values
    ('Mikołajki', now() - interval '1 day', now() + interval '1 day'),
    ('Za tydzień', now() + interval '7 days', now() + interval '8 days');

  v := public.publish_catalog(
    '{"packs":[],"items":[{"id":"nowa","pack_id":null,"access":"free","audio":[{"path":"audio/nowa.m4a"}]}]}',
    'abc', 'test', null);
  assert (public.published_catalog() ->> 'version')::int = v;
  assert exists (select 1 from public.content_files where path = 'audio/nowa.m4a' and free and item_id = 'nowa');
end $$;

-- The app may add events but not read them; it sees only promotions that are running.
set role anon;
do $$
begin
  insert into public.app_events (install_id, event) values ('33333333-3333-3333-3333-333333333333', 'app_open');
  assert (select count(*) from public.promotions) = 1, 'only the running promotion';
  begin
    perform 1 from public.app_events;
    assert false, 'anon must not read events';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.app_events (install_id, event) values ('33333333-3333-3333-3333-333333333333', 'hack');
    assert false, 'unknown event refused';
  exception when check_violation then null;
  end;
end $$;
reset role;

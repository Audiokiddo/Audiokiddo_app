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
  -- A subscription opens everything and says how many children it covers.
  assert (select scopes from public.store_products where product_ref = 'ios:pl.audiokiddo.sub.yearly') = '{all_content,children:1}', 'yearly';
  assert (select scopes from public.store_products where product_ref = 'android:pl.audiokiddo.sub.monthly') = '{all_content,children:1}', 'monthly';
  assert (select scopes from public.store_products where product_ref = 'ios:pl.audiokiddo.sub.duo.yearly') = '{all_content,children:2}', 'duo';
  assert (select scopes from public.store_products where product_ref = 'android:pl.audiokiddo.sub.family.monthly') = '{all_content,children:5}', 'family';
  assert (select cardinality(scopes) from public.store_products where product_ref = 'ios:pl.audiokiddo.bundle.three') = 3, 'bundle of three';
  assert exists (select 1 from public.store_products where product_ref = 'android:pl.audiokiddo.item.magiczny_sklep'), 'single item';
  perform public.upsert_entitlement('00000000-0000-0000-0000-000000000009', 'app_store', 'ios:pl.audiokiddo.sub.yearly', 'orig-1', 'active', now() + interval '1 year');
  perform public.upsert_entitlement('00000000-0000-0000-0000-000000000009', 'app_store', 'ios:pl.audiokiddo.sub.yearly', 'orig-1', 'refunded', null);
  assert (select status from public.entitlements where store_original_tx_id = 'orig-1' and scope = 'all_content') = 'refunded', 'same purchase is updated, not duplicated';
  assert (select count(*) from public.entitlements where store_original_tx_id = 'orig-1') = 2, 'all_content and children:1';
  assert (select bool_and(status = 'refunded') from public.entitlements where store_original_tx_id = 'orig-1'), 'both rows follow the store';
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

-- Advanced analytics: completion, replay, next play, retention and conversion.
do $$
declare
  a jsonb;
begin
  insert into public.app_events (install_id, event, item_id, props, created_at) values
    ('44444444-4444-4444-4444-444444444444', 'first_open', null, '{}', now() - interval '9 days'),
    ('44444444-4444-4444-4444-444444444444', 'play_start', 'magiczny-sklep', '{"free":true}', now() - interval '9 days'),
    ('44444444-4444-4444-4444-444444444444', 'play_complete', 'magiczny-sklep', '{}', now() - interval '9 days'),
    ('44444444-4444-4444-4444-444444444444', 'play_start', 'co-to-za-dzwiek', '{"free":true,"next":true}', now() - interval '9 days'),
    ('44444444-4444-4444-4444-444444444444', 'app_open', null, '{}', now() - interval '8 days'),
    ('44444444-4444-4444-4444-444444444444', 'play_start', 'magiczny-sklep', '{"free":true,"replay":true}', now() - interval '8 days'),
    ('44444444-4444-4444-4444-444444444444', 'purchase_done', null, '{}', now() - interval '8 days'),
    ('55555555-5555-5555-5555-555555555555', 'first_open', null, '{}', now() - interval '9 days'),
    ('55555555-5555-5555-5555-555555555555', 'welcome_done', null, '{}', now() - interval '9 days');
  a := public.admin_stats(30) -> 'analytics';
  assert (a -> 'plays' ->> 'replays')::int = 1, a::text;
  assert (a -> 'plays' ->> 'next_plays')::int = 1;
  assert (a -> 'retention' ->> 'd1')::numeric = 50, a -> 'retention';
  assert (a -> 'conversion' ->> 'paid_after_free')::int = 1, a -> 'conversion';
  assert (a -> 'onboarding' ->> 'welcome_done')::int = 1;
  assert jsonb_typeof(a -> 'cohorts') = 'array';
end $$;

-- CRM: only admins see or change it.
insert into auth.users (id, email) values ('00000000-0000-0000-0000-0000000000c1', 'szef@audiokiddo.pl'),
  ('00000000-0000-0000-0000-0000000000c2', 'rodzic@example.com');
insert into public.admins (user_id) values ('00000000-0000-0000-0000-0000000000c1');
set role authenticated;
do $$ begin perform set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-0000000000c2', false); end $$;
do $$
begin
  assert (select count(*) from public.crm_items) = 0, 'a parent sees no CRM items';
  begin
    perform public.crm_overview();
    assert false, 'a parent cannot read the CRM numbers';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into public.crm_items (kind, title) values ('task', 'hack');
    assert false, 'a parent cannot add CRM items';
  exception when insufficient_privilege then null;
  end;
end $$;
do $$ begin perform set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-0000000000c1', false); end $$;
do $$
declare
  o jsonb;
begin
  assert (select count(*) from public.crm_items where kind = 'task') >= 5, 'the starting board';
  insert into public.crm_items (kind, area, title, source, decision) values ('idea', 'pack', 'Pakiet Kosmos', 'ai', 'pending');
  update public.crm_items set decision = 'approved' where title = 'Pakiet Kosmos';
  o := public.crm_overview();
  assert (o ->> 'users_total')::int >= 2, o::text;
  assert (o ->> 'monthly_costs')::numeric = 107, o::text;
  assert jsonb_typeof(o -> 'recent_users') = 'array';
end $$;
reset role;
select 'crm tests passed';

-- CRM support and trends: admins find a customer, give and take back access; parents cannot.
set role authenticated;
do $$ begin perform set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-0000000000c2', false); end $$;
do $$
begin
  begin
    perform public.crm_customer('rodzic@example.com');
    assert false, 'a parent cannot look customers up';
  exception when insufficient_privilege then null;
  end;
  begin
    perform public.crm_grant('00000000-0000-0000-0000-0000000000c2', 'all_content', 30, 'hack');
    assert false, 'a parent cannot give themselves access';
  exception when insufficient_privilege then null;
  end;
end $$;
do $$ begin perform set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-0000000000c1', false); end $$;
do $$
declare
  c jsonb;
  t jsonb;
begin
  assert public.crm_customer('nikt@example.com') is null, 'unknown e-mail';
  perform public.crm_grant('00000000-0000-0000-0000-0000000000c2', 'pack:detektyw', 30, 'reklamacja');
  c := public.crm_customer('  Rodzic@Example.com ');
  assert c ->> 'email' = 'rodzic@example.com', c::text;
  assert jsonb_array_length(c -> 'entitlements') = 1, c::text;
  assert c -> 'entitlements' -> 0 ->> 'status' = 'active';
  assert (select count(*) from public.crm_items where area = 'support' and data->>'plan' is null) = 1, 'noted in the history';
  perform public.crm_grant('00000000-0000-0000-0000-0000000000c2', 'pack:detektyw', 60, null);
  c := public.crm_customer('rodzic@example.com');
  assert jsonb_array_length(c -> 'entitlements') = 1, 'extended, not doubled';
  perform public.crm_revoke('00000000-0000-0000-0000-0000000000c2', 'pack:detektyw');
  assert public.crm_customer('rodzic@example.com') -> 'entitlements' -> 0 ->> 'status' = 'revoked';
  begin
    perform public.crm_grant('00000000-0000-0000-0000-0000000000c2', 'children:5', 30, null);
    assert false, 'only content scopes by hand';
  exception when invalid_parameter_value then null;
  end;
  t := public.crm_trend(8);
  assert jsonb_array_length(t) = 8, t::text;
  assert (t -> 7 ->> 'week') = to_char(date_trunc('week', now()), 'YYYY-MM-DD'), 'the current week last';
end $$;
reset role;
select 'crm support tests passed';

-- Errors, ranking and the watchdog.
set role anon;
insert into public.app_errors (install_id, kind, error_type, message, fingerprint, platform)
select '66666666-6666-6666-6666-666666666666', 'flutter', 'StateError', 'Bad state', 'abcdef12', 'ios'
from generate_series(1, 105);
reset role;
do $$
begin
  assert (select count(*) from public.app_errors where install_id = '66666666-6666-6666-6666-666666666666') = 100,
    'one phone in a loop is capped at 100 a day';
end $$;
set role anon;
do $$
begin
  begin
    perform 1 from public.app_errors;
    assert (select count(*) from public.app_errors) = 0, 'the app cannot read errors back';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;
insert into public.app_errors (install_id, kind, error_type, message, fingerprint, platform)
select ('77777777-7777-7777-7777-77777777777' || g)::uuid, 'async', 'TypeError', 'null', '12345678', 'android'
from generate_series(1, 3) g;
insert into public.app_events (install_id, event, item_id, props) values
  ('77777777-7777-7777-7777-777777777771', 'play_start', 'magiczny-sklep', '{}'),
  ('77777777-7777-7777-7777-777777777771', 'play_complete', 'magiczny-sklep', '{}'),
  ('77777777-7777-7777-7777-777777777772', 'play_start', 'magiczny-sklep', '{"replay":true}');
set role authenticated;
do $$ begin perform set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-0000000000c2', false); end $$;
do $$
begin
  begin
    perform public.crm_alerts_now();
    assert false, 'a parent sees no alerts';
  exception when insufficient_privilege then null;
  end;
end $$;
do $$ begin perform set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-0000000000c1', false); end $$;
do $$
declare
  e jsonb;
  p jsonb;
  a jsonb;
  sklep jsonb;
begin
  e := public.crm_errors(7);
  assert e -> 0 ->> 'fingerprint' = 'abcdef12' and (e -> 0 ->> 'count')::int = 100, e::text;
  assert (e -> 1 ->> 'installs')::int = 3;
  p := public.crm_plays(30);
  select x into sklep from jsonb_array_elements(p) x where x ->> 'id' = 'magiczny-sklep';
  assert (sklep ->> 'starts')::int >= 2 and (sklep ->> 'replays')::int >= 1, p::text;
  a := public.crm_alerts_now();
  assert exists (select 1 from jsonb_array_elements(a) x where x ->> 'code' = 'errors_spike'), a::text;
  assert exists (select 1 from jsonb_array_elements(a) x where x ->> 'code' = 'new_error:12345678'), a::text;
  perform public.crm_ack((a -> 0 ->> 'id')::uuid);
end $$;
reset role;
delete from public.app_errors;
do $$
begin
  perform public.crm_watch();
  assert not exists (select 1 from public.crm_alerts where code = 'errors_spike' and resolved_at is null),
    'an alert closes when it passes';
end $$;
select 'quality tests passed';

-- Family, letters and orders.
insert into auth.users (id, email) values
  ('00000000-0000-0000-0000-0000000000f1', 'mama@example.com'),
  ('00000000-0000-0000-0000-0000000000f2', 'tata@example.com'),
  ('00000000-0000-0000-0000-0000000000f3', 'ktos@example.com');
insert into public.entitlements (user_id, source, scope, status, valid_until, product_ref, store_original_tx_id) values
  ('00000000-0000-0000-0000-0000000000f1', 'app_store', 'all_content', 'active', now() + interval '1 month', 'ios:pl.audiokiddo.sub.monthly', 'fam-1'),
  ('00000000-0000-0000-0000-0000000000f1', 'app_store', 'children:1', 'active', now() + interval '1 month', 'ios:pl.audiokiddo.sub.monthly', 'fam-1');
set role authenticated;
do $$ begin perform set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-0000000000f1', false); end $$;
do $$
begin
  begin
    perform public.family_invite();
    assert false, 'the plan for one child is for one account';
  exception when invalid_parameter_value then null;
  end;
  assert (public.family_status() ->> 'can_invite')::boolean = false;
end $$;
reset role;
update public.entitlements set scope = 'children:2' where store_original_tx_id = 'fam-1' and scope = 'children:1';
set role authenticated;
do $$ begin perform set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-0000000000f1', false); end $$;
create temporary table invite as select public.family_invite() ->> 'code' code;
do $$ begin perform set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-0000000000f2', false); end $$;
do $$
declare
  v_code text := (select code from invite);
begin
  assert (select count(*) from public.my_entitlements()) = 0, 'nothing before joining';
  perform public.family_join(lower(v_code));
  assert (select count(*) from public.my_entitlements() where shared and scope = 'all_content') = 1, 'the owner''s plan is shared';
  assert public.family_status() ->> 'role' = 'member';
  assert public.family_status() ->> 'partner' = 'ma•••@example.com', public.family_status()::text;
end $$;
do $$ begin perform set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-0000000000f3', false); end $$;
do $$
begin
  begin
    perform public.family_join((select code from invite));
    assert false, 'a code works once';
  exception when invalid_parameter_value then null;
  end;
  insert into public.parent_letters (user_id, weekly, missed) values ('00000000-0000-0000-0000-0000000000f3', true, true);
  begin
    update public.parent_letters set last_weekly_at = now() where user_id = '00000000-0000-0000-0000-0000000000f3';
    assert false, 'only the server marks letters as sent';
  exception when insufficient_privilege then null;
  end;
end $$;
reset role;
do $$
begin
  assert public.can_download('00000000-0000-0000-0000-0000000000f2', 'audio/detektyw/gadajacy-smietnik.m4a'),
    'the partner downloads the family''s recordings';
  assert not public.can_download('00000000-0000-0000-0000-0000000000f3', 'audio/detektyw/gadajacy-smietnik.m4a');
  assert exists (select 1 from public.letters_due('weekly') where email = 'ktos@example.com'), 'weekly letter due';
  assert not exists (select 1 from public.letters_due('missed') where email = 'ktos@example.com'), 'never played: no "we miss you"';
end $$;
set role authenticated;
do $$ begin perform set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-0000000000c1', false); end $$;
do $$ begin assert jsonb_typeof(public.crm_orders(60)) = 'array'; end $$;
do $$ begin perform set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-0000000000f2', false); end $$;
do $$ begin perform public.family_leave(); assert (select count(*) from public.my_entitlements()) = 0, 'after leaving'; end $$;
reset role;
select 'family and letters tests passed';

-- LTV, cohorts and experiments.
update public.experiments set active = true, started_at = now() - interval '1 day' where key = 'paywall_cta';
set role anon;
do $$ begin assert public.app_experiments() = '{"paywall_cta": ["proba", "oszczednosc"]}'::jsonb, public.app_experiments()::text; end $$;
insert into public.app_events (install_id, event, props) values
  ('88888888-8888-8888-8888-888888888881', 'paywall_view', '{"ab": {"paywall_cta": "proba"}}'),
  ('88888888-8888-8888-8888-888888888881', 'purchase_done', '{"ab": {"paywall_cta": "proba"}}'),
  ('88888888-8888-8888-8888-888888888882', 'paywall_view', '{"ab": {"paywall_cta": "oszczednosc"}}');
reset role;
set role authenticated;
do $$ begin perform set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-0000000000c1', false); end $$;
do $$
declare
  r jsonb := public.crm_experiment('paywall_cta');
  l jsonb := public.crm_ltv();
begin
  assert r -> 1 ->> 'variant' = 'proba' and (r -> 1 ->> 'conversion')::numeric = 100, r::text;
  assert (r -> 0 ->> 'bought')::int = 0, r::text;
  assert jsonb_typeof(l -> 'cohorts') = 'array' and (l ->> 'paying')::int >= 1, l::text;
end $$;
reset role;
select 'ltv and experiment tests passed';

-- Ads growth: new kinds of change, creatives, keywords; admins read, others do not.
insert into public.ads_actions (platform, entity_id, action, params, title)
  values ('google_ads', '1', 'add_negative', '{"term": "bajki youtube"}', 'Wykluczyć');
insert into public.ads_creatives (platform, format, content) values ('google_ads', 'rsa', '{"headlines": ["a", "b", "c"]}');
insert into public.ads_competitor_ads (ad_archive_id, page_id, bodies) values ('1', 'p', '{"Tekst"}');
update public.seo_keywords set trend = '[{"month": "2026-07", "searches": 10}]', use_for = 'blog' where keyword = 'zabawy w aucie dla dzieci';
do $$ begin
  begin
    insert into public.ads_creatives (platform, format) values ('tiktok', 'rsa');
    assert false, 'unknown platform accepted';
  exception when check_violation then null;
  end;
end $$;
set role authenticated;
do $$ begin perform set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-0000000000c1', false); end $$;
do $$ begin
  assert (select count(*) from public.ads_creatives) = 1, 'admin reads creatives';
  assert (select count(*) from public.ads_competitor_ads) = 1, 'admin reads competitors';
end $$;
do $$ begin perform set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-0000000000f2', false); end $$;
do $$ begin assert (select count(*) from public.ads_creatives) = 0, 'a parent reads no creatives'; end $$;
reset role;
select 'ads growth tests passed';

-- Analytics annex: North Star, activation, per-play table, drop-off and growth by source.
do $$
declare
  k jsonb;
  g jsonb;
  f constant uuid := '66666666-6666-6666-6666-666666666666';
  h constant uuid := '77777777-7777-7777-7777-777777777777';
begin
  insert into public.app_events (install_id, event, item_id, props, created_at, age_group, source, session_id) values
    -- Family F: new, finishes a play, starts another (activated), back the next day (returning).
    (f, 'first_open', null, '{}', now() - interval '3 days', '3-5', 'tiktok', gen_random_uuid()),
    (f, 'game_viewed', 'zgubiona-gwiazdka', '{}', now() - interval '3 days' + interval '1 minute', '3-5', 'tiktok', null),
    (f, 'play_start', 'zgubiona-gwiazdka', '{"free":true,"play_number":1}', now() - interval '3 days' + interval '2 minutes', '3-5', 'tiktok', null),
    (f, 'play_complete', 'zgubiona-gwiazdka', '{}', now() - interval '3 days' + interval '12 minutes', '3-5', 'tiktok', null),
    (f, 'play_start', 'magiczny-sklep', '{"play_number":1}', now() - interval '3 days' + interval '13 minutes', '3-5', 'tiktok', null),
    (f, 'play_exit', 'magiczny-sklep', '{"exit_second":395,"pct":40}', now() - interval '3 days' + interval '20 minutes', '3-5', 'tiktok', null),
    (f, 'play_start', 'zgubiona-gwiazdka', '{"play_number":2}', now() - interval '2 days', '3-5', 'tiktok', null),
    (f, 'play_complete', 'zgubiona-gwiazdka', '{}', now() - interval '2 days' + interval '10 minutes', '3-5', 'tiktok', null),
    (f, 'search_performed', null, '{"query":"dinozaury","results":0}', now() - interval '2 days', '3-5', 'tiktok', null),
    -- Family H: new, starts once and leaves early, never finishes.
    (h, 'first_open', null, '{}', now() - interval '2 days', '7-9', null, null),
    (h, 'play_start', 'magiczny-sklep', '{"free":true,"play_number":1}', now() - interval '2 days' + interval '30 minutes', '7-9', null, null),
    (h, 'play_exit', 'magiczny-sklep', '{"exit_second":410,"pct":42}', now() - interval '2 days' + interval '37 minutes', '7-9', null, null);
  k := public.admin_kpi(30);
  assert (k -> 'ceo' ->> 'weekly_returning_families')::int >= 1, k -> 'ceo';
  assert (k -> 'ceo' ->> 'new_activated')::int >= 1, k -> 'ceo';
  assert (k -> 'ceo' -> 'funnel' ->> 'first_play')::int >= 2, k -> 'ceo' -> 'funnel';
  assert k -> 'product' -> 'dropoff' -> 'magiczny-sklep' @> '[[390, 2]]', k -> 'product' -> 'dropoff';
  assert k -> 'product' -> 'searches' -> 0 ->> 'query' = 'dinozaury', k -> 'product' -> 'searches';
  select x into g from jsonb_array_elements(k -> 'growth') x where x ->> 'source' = 'tiktok';
  assert (g ->> 'activated')::int = 1, k -> 'growth';
  assert (k -> 'data_health' ->> 'events')::int > 0;
  -- Per age band: only the 7-9 family.
  k := public.admin_kpi(30, '7-9');
  assert (k -> 'ceo' ->> 'new_activated')::int = 0, k -> 'ceo';
  begin
    insert into public.app_events (install_id, event, age_group) values (h, 'app_open', '4');
    assert false, 'age groups are bands only';
  exception when check_violation then null;
  end;
end $$;
select 'analytics annex tests passed';

-- Gifts from the shop: one code per gift line, retry-safe, ended by a refund.
do $$
declare
  h constant text := repeat('ab', 32);
  u constant uuid := '00000000-0000-0000-0000-0000000000d1';
begin
  insert into auth.users (id, email) values (u, 'obdarowany@example.com');
  insert into public.gift_products (product_ref, scopes, label) values ('woo:900', '{all_content}', 'Rok AudioKiddo');
  assert public.issue_gift_code(77, 'woo:1', h) = 'not_gift';
  assert public.issue_gift_code(77, 'woo:900', h) = 'send';
  assert public.issue_gift_code(77, 'woo:900', h) = 'send', 'a retry before the note went out sends it again';
  perform public.mark_gift_note_sent(77, 'woo:900');
  assert public.issue_gift_code(77, 'woo:900', h) = 'sent';
  assert (select max_uses from public.access_codes where code_hash = h) = 1;
  assert public.redeem_access_code(u, h) ->> 'status' = 'ok';
  assert exists (select 1 from public.entitlements where user_id = u and scope = 'all_content' and status = 'active');
  assert public.revoke_gift_codes(77) = 1;
  assert not exists (select 1 from public.entitlements where user_id = u and status = 'active'), 'refund ends the gift';
end $$;
select 'gift tests passed';

-- Ad spend and CAC.
do $$
declare
  m jsonb;
begin
  insert into public.ad_spend (month, channel, amount) values (date_trunc('month', now())::date, 'meta', 300);
  insert into public.web_purchases_pending (woo_order_id, product_ref, email_normalized, order_status)
    values (5001, 'woo:1', 'nowa@example.com', 'completed'), (5002, 'woo:1', 'druga@example.com', 'completed');
  m := public.admin_economics(30);
  assert (m ->> 'spend_total')::numeric = 300, m::text;
  assert (m ->> 'new_paying_web')::int >= 2, m::text;
  assert (m ->> 'cac_total')::numeric > 0, m::text;
  begin
    insert into public.ad_spend (month, channel, amount) values ('2026-10-15', 'meta', 1);
    assert false, 'months are whole months';
  exception when check_violation then null;
  end;
end $$;
select 'ad spend tests passed';

-- Cancel reasons and referral channels.
do $$
declare
  s jsonb;
begin
  insert into public.app_events (install_id, event, props) values
    ('88888888-8888-8888-8888-888888888888', 'cancel_reason', '{"reason":"price"}'),
    ('88888888-8888-8888-8888-888888888888', 'referral_share', '{"channel":"whatsapp"}');
  s := public.admin_signals(30);
  assert (s -> 'cancel_reasons' ->> 'price')::int = 1, s::text;
  assert (s -> 'referral_channels' ->> 'whatsapp')::int = 1, s::text;
end $$;
select 'signals tests passed';

-- The launch plan on the CRM board: tasks for each of us, calendar entries, nothing twice.
do $$
begin
  assert (select count(*) from public.crm_items where data->>'plan' = 'premiera-2026' and kind = 'task') >= 100, 'plan tasks';
  assert (select count(*) from public.crm_items where data->>'plan' = 'premiera-2026' and kind = 'calendar') >= 10, 'plan calendar';
  assert (select count(distinct owner) from public.crm_items where data->>'plan' = 'premiera-2026') = 3, 'Dawid, Nela, Razem';
  assert not exists (select 1 from public.crm_items where source = 'system' and title = 'Założyć konto Apple Developer' and status = 'todo'),
    'the old account task gave way to the plan';
end $$;
create temp table plan_before as select count(*) n from public.crm_items where data->>'plan' = 'premiera-2026';
\ir ../migrations/20261019000001_launch_plan.sql
do $$
begin
  assert (select count(*) from public.crm_items where data->>'plan' = 'premiera-2026') = (select n from plan_before), 'running it again adds nothing';
end $$;
select 'launch plan tests passed';

-- Time estimates on the plan, added once.
do $$
begin
  assert (select count(*) from public.crm_items where data->>'plan' = 'premiera-2026' and kind = 'task' and data ? 'hours')
    = (select count(*) from public.crm_items where data->>'plan' = 'premiera-2026' and kind = 'task'), 'every task has hours';
  assert (select body from public.crm_items where data->>'key' = 'f1-social') like '%Claude przygotował%', 'the prepared texts';
end $$;
\ir ../migrations/20261019000002_launch_plan_hours.sql
do $$
begin
  assert (select count(*) from public.crm_items where body like '%Czas: ok.%Czas: ok.%') = 0, 'the note is added once';
end $$;
select 'launch plan hours tests passed';

-- The faster plan: premiere on 2 November, a task moved on the board stays where it was put.
do $$
begin
  assert (select due from public.crm_items where data->>'key' = 'c-premiere') = '2026-11-02', 'premiere moved';
  assert (select due from public.crm_items where data->>'key' = 'f1-submit') = '2026-10-12', 'iOS review earlier';
  assert (select title from public.crm_items where data->>'key' = 'f1-measure') like 'Maile:%', 'Pixel and Analytics done';
  assert (select body from public.crm_items where data->>'key' = 'f1-measure') like '%Czas: ok. 1,5 h.%', 'hours kept in the note';
  assert (select body from public.crm_items where data->>'key' = 'f1-closed') like '%26.10.%Czas: ok.%', 'new words, same note';
end $$;
update public.crm_items set due = '2026-10-20' where data->>'key' = 'f1-video';
\ir ../migrations/20261019000003_launch_plan_faster.sql
do $$
begin
  assert (select due from public.crm_items where data->>'key' = 'f1-video') = '2026-10-20', 'moved on the board, stays';
  assert (select count(*) from public.crm_items where body like '%Czas: ok.%Czas: ok.%') = 0, 'no doubled notes';
end $$;
select 'faster plan tests passed';

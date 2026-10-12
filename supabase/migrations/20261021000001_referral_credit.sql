-- Referrals pay in credit (2026-10-12): when a friend creates an account and redeems a parent's
-- code, BOTH get 30 zł to spend in the app (a month of everything, a pack or single plays).
-- A code rewards at most 3 friends per calendar year. Credit cannot be bought, only earned.
-- Replaces the 14-day trial for the friend and the month for the parent after a purchase.
-- Everything here is for the service role (Edge Functions redeem-code, referral-code, credit).

create table public.credit_ledger (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users (id) on delete cascade,
  -- Grosze: + earned, - spent.
  amount integer not null check (amount <> 0),
  reason text not null check (reason in ('referral_friend', 'referral_referrer', 'spend', 'manual')),
  -- What it is for, once only: 'referral:friend:<friend>', 'referral:referrer:<friend>', 'spend:<uuid>'.
  ref text not null unique,
  scope text,
  created_at timestamptz not null default now()
);
create index credit_ledger_user_idx on public.credit_ledger (user_id);
alter table public.credit_ledger enable row level security;

-- What credit buys, at the app's prices (docs/WYDANIE.md §5). all_content is 30 days.
create table public.credit_prices (
  scope text primary key,
  price integer not null check (price > 0),
  title text not null,
  sort integer not null default 100
);
alter table public.credit_prices enable row level security;

insert into public.credit_prices (scope, price, title, sort) values
  ('all_content', 2999, 'Miesiąc całej biblioteki', 0),
  ('pack:wyobraznia', 4999, 'Pakiet Wyobraźnia', 10),
  ('pack:slowa-i-wiedza', 4999, 'Pakiet Słowa i wiedza', 11),
  ('pack:detektyw', 6999, 'Pakiet Detektyw', 12),
  ('item:magiczny-sklep', 999, 'Magiczny sklep', 20),
  ('item:mikstura', 999, 'Mikstura', 21),
  ('item:moj-superbohater', 999, 'Mój superbohater', 22),
  ('item:podroz-na-inna-planete', 999, 'Podróż na inną planetę', 23),
  ('item:wymysl-znaczenie', 999, 'Wymyśl znaczenie', 24),
  ('item:zaginiony-skarb', 999, 'Zaginiony skarb', 25);

-- How many friends a parent's code may still reward this calendar year (Polish time).
create or replace function public.referrals_left_this_year(p_referrer uuid)
returns integer language sql stable security definer set search_path = public as $$
  select greatest(0, 3 - count(*)::integer) from public.referral_redemptions
  where referrer_id = p_referrer
    and rewarded_at is not null
    and date_trunc('year', rewarded_at at time zone 'Europe/Warsaw')
      = date_trunc('year', now() at time zone 'Europe/Warsaw')
$$;

create or replace function public.credit_balance(p_user uuid)
returns integer language sql stable security definer set search_path = public as $$
  select coalesce(sum(amount), 0)::integer from public.credit_ledger where user_id = p_user
$$;

-- The parent's code, friends and rewards, plus what is left this year and the credit balance.
create or replace function public.referral_code_for(p_user_id uuid, p_candidate text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_code text;
begin
  select code into v_code from public.referral_codes where user_id = p_user_id;
  if v_code is null then
    begin
      insert into public.referral_codes (user_id, code) values (p_user_id, p_candidate)
      returning code into v_code;
    exception when unique_violation then
      select code into v_code from public.referral_codes where user_id = p_user_id;
      if v_code is null then return null; end if;
    end;
  end if;
  return jsonb_build_object(
    'code', v_code,
    'friends', (select count(*) from public.referral_redemptions where referrer_id = p_user_id),
    'rewards', (select count(*) from public.referral_redemptions where referrer_id = p_user_id and rewarded_at is not null),
    'left_this_year', public.referrals_left_this_year(p_user_id),
    'balance', public.credit_balance(p_user_id)
  );
end;
$$;

-- A friend redeems a code: 30 zł for the friend and 30 zł for the parent who shared it.
-- Answers: ok (with credit) | already | invalid | account_required (a guest account: the friend
-- signs up first) | used_up (the code rewarded 3 friends this year) | rate_limited.
create or replace function public.redeem_referral(p_user_id uuid, p_code text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_referrer uuid;
begin
  if public.claim_rate_limited(p_user_id) then
    return jsonb_build_object('status', 'rate_limited', 'scopes', '[]'::jsonb);
  end if;
  select user_id into v_referrer from public.referral_codes where code = p_code;
  if v_referrer is null or v_referrer = p_user_id then
    insert into public.claim_attempts (user_id, kind, ok) values (p_user_id, 'code', false);
    return jsonb_build_object('status', 'invalid', 'scopes', '[]'::jsonb);
  end if;
  if exists (select 1 from public.referral_redemptions where friend_id = p_user_id) then
    return jsonb_build_object('status', 'already', 'scopes', '[]'::jsonb);
  end if;
  if coalesce((select is_anonymous from auth.users where id = p_user_id), true) then
    return jsonb_build_object('status', 'account_required', 'scopes', '[]'::jsonb);
  end if;
  -- One redemption at a time per code, so two friends at once cannot pass the yearly limit.
  perform 1 from public.referral_codes where user_id = v_referrer for update;
  if public.referrals_left_this_year(v_referrer) = 0 then
    return jsonb_build_object('status', 'used_up', 'scopes', '[]'::jsonb);
  end if;
  insert into public.referral_redemptions (friend_id, referrer_id, rewarded_at)
  values (p_user_id, v_referrer, now());
  insert into public.credit_ledger (user_id, amount, reason, ref) values
    (p_user_id, 3000, 'referral_friend', 'referral:friend:' || p_user_id),
    (v_referrer, 3000, 'referral_referrer', 'referral:referrer:' || p_user_id);
  insert into public.claim_attempts (user_id, kind, ok) values (p_user_id, 'code', true);
  return jsonb_build_object('status', 'ok', 'scopes', '[]'::jsonb, 'credit', 3000);
end;
$$;

-- The reward no longer waits for the friend's purchase.
drop trigger if exists entitlements_reward_referrer on public.entitlements;
drop function if exists public.reward_referrer();

-- What the parent can take with their credit now: price list without what they already own.
create or replace function public.credit_offers(p_user uuid)
returns jsonb language sql stable security definer set search_path = public as $$
  select jsonb_build_object(
    'balance', public.credit_balance(p_user),
    'offers', coalesce((
      select jsonb_agg(jsonb_build_object('scope', p.scope, 'title', p.title, 'price', p.price) order by p.sort, p.scope)
      from public.credit_prices p
      -- A month of everything can always be added on top; a pack or play only when not owned.
      where p.scope = 'all_content' or not (p.scope = any(public.own_scopes(p_user)))
    ), '[]'::jsonb)
  )
$$;

-- Spends credit on [p_scope]. Answers: ok (with balance, scopes) | insufficient | unknown | owned.
-- A month of everything starts when the last one bought with credit ends.
create or replace function public.spend_credit(p_user uuid, p_scope text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare
  v_price integer;
  v_balance integer;
  v_ledger bigint;
  v_from timestamptz;
begin
  select price into v_price from public.credit_prices where scope = p_scope;
  if v_price is null then
    return jsonb_build_object('status', 'unknown', 'balance', public.credit_balance(p_user));
  end if;
  -- Spends one at a time per parent (two taps, two phones).
  perform pg_advisory_xact_lock(hashtext('credit:' || p_user));
  v_balance := public.credit_balance(p_user);
  if p_scope <> 'all_content' and p_scope = any(public.own_scopes(p_user)) then
    return jsonb_build_object('status', 'owned', 'balance', v_balance);
  end if;
  if v_balance < v_price then
    return jsonb_build_object('status', 'insufficient', 'balance', v_balance);
  end if;
  insert into public.credit_ledger (user_id, amount, reason, ref, scope)
  values (p_user, -v_price, 'spend', 'spend:' || gen_random_uuid(), p_scope)
  returning id into v_ledger;
  if p_scope = 'all_content' then
    select greatest(now(), coalesce(max(valid_until), now())) into v_from from public.entitlements
      where user_id = p_user and product_ref = 'credit' and scope = 'all_content' and status = 'active';
    insert into public.entitlements (user_id, source, scope, status, valid_until, product_ref, store_original_tx_id)
    values (p_user, 'manual', 'all_content', 'active', v_from + interval '30 days', 'credit', 'credit:' || v_ledger);
  else
    insert into public.entitlements (user_id, source, scope, status, valid_until, product_ref, store_original_tx_id)
    values (p_user, 'manual', p_scope, 'active', null, 'credit', 'credit:' || v_ledger);
  end if;
  return jsonb_build_object('status', 'ok', 'balance', v_balance - v_price, 'scopes', jsonb_build_array(p_scope));
end;
$$;

revoke all on function public.referrals_left_this_year(uuid) from public, anon, authenticated;
revoke all on function public.credit_balance(uuid) from public, anon, authenticated;
revoke all on function public.referral_code_for(uuid, text) from public, anon, authenticated;
revoke all on function public.redeem_referral(uuid, text) from public, anon, authenticated;
revoke all on function public.credit_offers(uuid) from public, anon, authenticated;
revoke all on function public.spend_credit(uuid, text) from public, anon, authenticated;
revoke all on public.credit_ledger, public.credit_prices from anon, authenticated;

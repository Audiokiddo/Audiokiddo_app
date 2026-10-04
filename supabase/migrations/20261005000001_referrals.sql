-- Referrals: every parent has one code ("POLEC-7K3M9Q") to share. A friend who redeems it gets
-- 14 days of everything; when that friend later buys anything (App Store, Google Play or the
-- shop), the parent who shared the code gets 30 days of everything, up to 12 times.
-- Everything here is for the service role (Edge Functions referral-code and redeem-code).

create table public.referral_codes (
  user_id uuid primary key references auth.users (id) on delete cascade,
  code text not null unique check (code ~ '^POLEC[A-HJ-NP-Z2-9]{6}$'),
  created_at timestamptz not null default now()
);
alter table public.referral_codes enable row level security;

-- One referral per friend's account, whoever shared it.
create table public.referral_redemptions (
  friend_id uuid primary key references auth.users (id) on delete cascade,
  referrer_id uuid not null references auth.users (id) on delete cascade,
  redeemed_at timestamptz not null default now(),
  rewarded_at timestamptz,
  check (friend_id <> referrer_id)
);
create index referral_redemptions_referrer_idx on public.referral_redemptions (referrer_id);
alter table public.referral_redemptions enable row level security;

-- The parent's code, made on first ask. [p_candidate] is a fresh random code from the Edge
-- Function; a clash with another parent's code returns null and the function tries again.
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
    'rewards', (select count(*) from public.referral_redemptions where referrer_id = p_user_id and rewarded_at is not null)
  );
end;
$$;

-- A friend redeems a code: 14 days of everything. Answers like redeem_access_code:
-- ok | already | invalid | rate_limited (a parent's own code counts as invalid).
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
    return jsonb_build_object('status', 'already', 'scopes', '["all_content"]'::jsonb);
  end if;
  insert into public.referral_redemptions (friend_id, referrer_id) values (p_user_id, v_referrer);
  insert into public.entitlements (user_id, source, scope, status, valid_until, product_ref, store_original_tx_id)
  values (p_user_id, 'manual', 'all_content', 'active', now() + interval '14 days', 'referral',
          'referral-trial:' || p_user_id)
  on conflict (source, store_original_tx_id, scope) do nothing;
  insert into public.claim_attempts (user_id, kind, ok) values (p_user_id, 'code', true);
  return jsonb_build_object('status', 'ok', 'scopes', '["all_content"]'::jsonb, 'days', 14);
end;
$$;

-- The friend's first purchase after redeeming rewards the parent who shared the code:
-- 30 more days of everything (added after any reward still running), at most 12 rewards.
create or replace function public.reward_referrer()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  v_ref public.referral_redemptions;
  v_from timestamptz;
begin
  if new.source = 'manual' or new.status <> 'active' then return new; end if;
  select * into v_ref from public.referral_redemptions
    where friend_id = new.user_id and rewarded_at is null and redeemed_at <= now()
    for update;
  if not found then return new; end if;
  if (select count(*) from public.referral_redemptions where referrer_id = v_ref.referrer_id and rewarded_at is not null) >= 12 then
    return new;
  end if;
  select greatest(now(), coalesce(max(valid_until), now())) into v_from from public.entitlements
    where user_id = v_ref.referrer_id and product_ref = 'referral-reward' and status = 'active';
  insert into public.entitlements (user_id, source, scope, status, valid_until, product_ref, store_original_tx_id)
  values (v_ref.referrer_id, 'manual', 'all_content', 'active', v_from + interval '30 days', 'referral-reward',
          'referral-reward:' || new.user_id)
  on conflict (source, store_original_tx_id, scope) do nothing;
  update public.referral_redemptions set rewarded_at = now() where friend_id = new.user_id;
  return new;
end;
$$;

create trigger entitlements_reward_referrer
  after insert on public.entitlements
  for each row execute function public.reward_referrer();

revoke all on function public.referral_code_for(uuid, text) from public, anon, authenticated;
revoke all on function public.redeem_referral(uuid, text) from public, anon, authenticated;
revoke all on function public.reward_referrer() from public, anon, authenticated;

-- Supabase grants new tables to the API roles by default; these are for the service role only.
revoke all on public.referral_codes, public.referral_redemptions from anon, authenticated;

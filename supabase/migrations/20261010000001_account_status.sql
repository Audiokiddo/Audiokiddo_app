-- Sign-in asks for the e-mail first and then shows a password field (existing account) or the
-- registration (new one). The account-status function answers that question; lookups are
-- limited per caller so the endpoint cannot be used to test lists of addresses.

create table public.account_lookups (
  id bigint generated always as identity primary key,
  caller text not null,
  at timestamptz not null default now()
);
create index account_lookups_caller_idx on public.account_lookups (caller, at desc);
alter table public.account_lookups enable row level security;

-- Whether a parent account (not a guest, not deleted) uses this e-mail. Returns null when the
-- caller asked too often (30 times an hour).
create or replace function public.account_exists(p_email text, p_caller text)
returns boolean language plpgsql security definer set search_path = public as $$
begin
  if (select count(*) from public.account_lookups
      where caller = p_caller and at > now() - interval '1 hour') >= 30 then
    return null;
  end if;
  insert into public.account_lookups (caller) values (p_caller);
  delete from public.account_lookups where at < now() - interval '1 day';
  return exists (
    select 1 from auth.users
    where lower(email) = lower(trim(p_email))
      and deleted_at is null
      and coalesce(is_anonymous, false) = false
  );
end;
$$;

revoke all on function public.account_exists(text, text) from public, anon, authenticated;
revoke all on public.account_lookups from anon, authenticated;

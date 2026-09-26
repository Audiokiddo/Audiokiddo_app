-- Finds the app account for a shop buyer. Only confirmed e-mails count, so nobody can
-- claim someone else's shop order by typing their address (ARCHITECTURE §7a).
create or replace function public.user_id_for_email(p_email text)
returns uuid language sql stable security definer set search_path = public, auth as $$
  select id from auth.users
  where lower(trim(email)) = lower(trim(p_email)) and email_confirmed_at is not null
  limit 1;
$$;

revoke all on function public.user_id_for_email(text) from public, anon, authenticated;

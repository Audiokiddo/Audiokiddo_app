-- Closed-test testers at a glance (2026-10-17): for each e-mail on Dawid's list, whether the
-- account exists, when the app was last opened, how many plays and how many real minutes. Google
-- shows only totals; this says who still has to install or open the app.
create or replace function public.crm_testers(p_emails text[])
returns jsonb language plpgsql stable security definer set search_path = public, auth as $$
begin
  if not public.is_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  return coalesce((
    select jsonb_agg(entry order by entry ->> 'email')
    from (
      select jsonb_build_object(
        'email', e.email,
        'account', u.id is not null,
        'created_at', u.created_at,
        'last_seen', act.last_seen,
        'days', coalesce(act.days, 0),
        'plays', coalesce(act.plays, 0),
        'minutes', round(coalesce(act.seconds, 0) / 60.0),
        'platform', act.platform,
        'app_version', act.app_version
      ) entry
      from (select distinct lower(trim(x)) email from unnest(coalesce(p_emails, '{}')) x where trim(x) like '%@%') e
      left join lateral (
        select id, created_at from auth.users
        where lower(email) = e.email and deleted_at is null
        order by created_at desc limit 1
      ) u on true
      left join lateral (
        select max(a.created_at) last_seen,
               count(distinct (a.created_at at time zone 'Europe/Warsaw')::date) days,
               count(*) filter (where a.event = 'play_start') plays,
               sum(greatest(coalesce((a.props ->> 'active_seconds')::int, 0), 0))
                 filter (where a.event in ('play_complete', 'play_exit')) seconds,
               (array_agg(a.platform order by a.created_at desc) filter (where a.platform is not null))[1] platform,
               (array_agg(a.app_version order by a.created_at desc) filter (where a.app_version is not null))[1] app_version
        from public.app_events a where a.user_id = u.id
      ) act on true
      limit 200
    ) t
  ), '[]'::jsonb);
end;
$$;
revoke all on function public.crm_testers(text[]) from public, anon;
grant execute on function public.crm_testers(text[]) to authenticated;

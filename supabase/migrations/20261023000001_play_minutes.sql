-- Real minutes of play (decision 2026-10-13): how long a child really keeps listening, so the
-- site and ads say only measured numbers. The app sends with every play event the sitting it
-- belongs to (plays with under 10 minutes between them) and the seconds the sound was really on
-- (no data about the child; the age group column stays for older events and reads 'bez profilu').

create or replace function public.crm_play_minutes(p_days integer default 30)
returns jsonb language plpgsql stable security definer set search_path = public as $$
declare
  v_since timestamptz := now() - make_interval(days => least(greatest(coalesce(p_days, 30), 1), 365));
begin
  if not public.is_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  return coalesce((
    with ends as (
      -- One row per play that ended (to the end or left): its real seconds.
      select coalesce(a.user_id::text, a.install_id::text) family,
             (a.props ->> 'sitting')::bigint sitting,
             nullif(a.props ->> 'age', '')::int age,
             greatest(coalesce((a.props ->> 'active_seconds')::int, 0), 0) seconds
      from public.app_events a
      where a.created_at > v_since
        and a.event in ('play_complete', 'play_exit')
        and a.props ? 'sitting' and a.props ? 'active_seconds'
    ),
    sittings as (
      select family, sitting, max(age) age, sum(seconds) seconds, count(*) plays
      from ends group by family, sitting
      having sum(seconds) >= 30
    ),
    grouped as (
      select case when age is null then 'bez profilu'
                  when age <= 4 then '3–4'
                  when age <= 6 then '5–6'
                  else '7–9' end age_group,
             seconds, plays
      from sittings
    )
    select jsonb_agg(jsonb_build_object(
      'age_group', age_group,
      'sittings', n,
      'median_minutes', median_minutes,
      'p75_minutes', p75_minutes,
      'avg_plays', avg_plays
    ) order by age_group)
    from (
      select age_group, count(*) n,
             round((percentile_cont(0.5) within group (order by seconds) / 60)::numeric, 1) median_minutes,
             round((percentile_cont(0.75) within group (order by seconds) / 60)::numeric, 1) p75_minutes,
             round(avg(plays)::numeric, 1) avg_plays
      from grouped group by age_group
    ) g
  ), '[]'::jsonb);
end;
$$;
revoke all on function public.crm_play_minutes(integer) from public, anon;
grant execute on function public.crm_play_minutes(integer) to authenticated;

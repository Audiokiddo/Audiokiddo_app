-- Store reviews in the CRM (functions/reviews): what parents wrote in the App Store and on
-- Google Play, the reply the agent drafted, and whether it was published after approval.
create table public.store_reviews (
  store text not null check (store in ('app_store', 'google_play')),
  review_id text not null check (length(review_id) between 1 and 200),
  rating smallint not null check (rating between 0 and 5),
  title text not null default '' check (length(title) <= 300),
  body text not null default '' check (length(body) <= 4000),
  author text not null default '' check (length(author) <= 100),
  territory text,
  app_version text,
  created_at timestamptz not null,
  -- The reply on the store (ours, published), and the draft waiting for Dawid.
  reply text check (reply is null or length(reply) <= 1000),
  draft text check (draft is null or length(draft) <= 1000),
  status text not null default 'new' check (status in ('new', 'draft', 'published', 'failed', 'skipped')),
  error text,
  synced_at timestamptz not null default now(),
  primary key (store, review_id)
);
create index store_reviews_time_idx on public.store_reviews (created_at desc);
alter table public.store_reviews enable row level security;
create policy "admins read reviews" on public.store_reviews for select to authenticated using (public.is_admin());
grant select on public.store_reviews to authenticated;

do $do$
begin
  if exists (select 1 from pg_available_extensions where name = 'pg_cron') then
    create extension if not exists pg_cron;
    create extension if not exists pg_net;
    -- 6:00 UTC daily: new reviews and drafted replies, waiting in CRM → Opinie.
    perform cron.schedule('reviews-daily', '0 6 * * *', $job$
      select net.http_post(
        url := 'https://ypdxofcwewwdyoelamgy.supabase.co/functions/v1/reviews',
        headers := jsonb_build_object('content-type', 'application/json',
          'x-cron-secret', (select decrypted_secret from vault.decrypted_secrets where name = 'ads_cron_secret')),
        body := '{"action": "cycle"}'::jsonb, timeout_milliseconds := 150000)
    $job$);
  end if;
end;
$do$;

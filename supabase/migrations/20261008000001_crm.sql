-- The CRM in Studio: Dawid's daily workspace. Tasks, ideas (packs, plays, ads, features),
-- the publication calendar, mailings, updates and change proposals, and the decisions on what
-- the AI director (COO) proposes. Only admins (public.admins) can read or write any of it.

create table public.crm_items (
  id uuid primary key default gen_random_uuid(),
  -- task: a to-do on the board; idea: packs, plays, ads, app features; calendar: a dated
  -- publication; mailing: a newsletter or automation; change: an update or a proposal;
  -- briefing: the COO's daily summary.
  kind text not null check (kind in ('task', 'idea', 'calendar', 'mailing', 'change', 'briefing')),
  -- Finer type, e.g. pack, scenario, ad, feature, post, reel, newsletter, automation,
  -- promotion, release, update, proposal.
  area text check (area is null or area ~ '^[a-z_]{1,30}$'),
  title text not null check (length(title) between 1 and 200),
  body text not null default '' check (length(body) <= 20000),
  -- Board column or progress: todo, doing, done, archived (ideas: new, chosen, in_production, published).
  status text not null default 'todo' check (length(status) <= 30),
  priority smallint not null default 2 check (priority between 1 and 3),
  owner text check (owner is null or length(owner) <= 40),
  due date,
  -- Who proposed it, and the owner's decision on AI proposals.
  source text not null default 'dawid' check (source in ('dawid', 'ai', 'system')),
  decision text check (decision is null or decision in ('pending', 'approved', 'rejected')),
  data jsonb not null default '{}' check (octet_length(data::text) <= 100000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index crm_items_kind_idx on public.crm_items (kind, status, due);
create index crm_items_decision_idx on public.crm_items (decision) where decision = 'pending';

create or replace function public.crm_touch() returns trigger language plpgsql as $$
begin
  new.updated_at := now();
  return new;
end;
$$;
create trigger crm_items_touch before update on public.crm_items
  for each row execute function public.crm_touch();

-- Settings: monthly costs, goals, the brand voice for the AI.
create table public.crm_settings (
  key text primary key check (key ~ '^[a-z_]{1,40}$'),
  value jsonb not null,
  updated_at timestamptz not null default now()
);

alter table public.crm_items enable row level security;
alter table public.crm_settings enable row level security;
create policy "admins manage crm items" on public.crm_items for all to authenticated
  using (public.is_admin()) with check (public.is_admin());
create policy "admins manage crm settings" on public.crm_settings for all to authenticated
  using (public.is_admin()) with check (public.is_admin());
grant select, insert, update, delete on public.crm_items, public.crm_settings to authenticated;

-- Gross price of a product reference (store or shop), for revenue estimates.
create or replace function public.crm_price(p_ref text)
returns numeric language sql immutable as $$
  select case
    when p_ref ilike '%sub.monthly%' then 24.99
    when p_ref ilike '%sub.yearly%' then 239.88
    when p_ref ilike '%bundle.three%' then 159.99
    when p_ref ilike '%bundle.two%' then 89.99
    when p_ref ilike '%pack.detektyw%' then 69.99
    when p_ref ilike '%pack.%' then 49.99
    else 0
  end
$$;

-- The CRM numbers (service role and the admin wrapper below only).
create or replace function public.crm_numbers()
returns jsonb language sql stable security definer set search_path = public, auth as $$
  with paid as (
    select user_id, product_ref, scope, status, valid_until, source
    from public.entitlements where source <> 'manual'
  ),
  active as (
    select * from paid where status in ('active', 'grace') and (valid_until is null or valid_until > now())
  ),
  costs as (
    select coalesce(sum((v.value)::numeric), 0) total
    from public.crm_settings s, jsonb_each_text(s.value) v
    where s.key = 'monthly_costs' and v.value ~ '^[0-9]+(\.[0-9]+)?$'
  ),
  mrr as (
    select coalesce(sum(case when product_ref ilike '%sub.monthly%' then 24.99
                             when product_ref ilike '%sub.yearly%' then 239.88 / 12 else 0 end), 0) gross
    from active where scope = 'all_content'
  )
  select jsonb_build_object(
    'users_total', (select count(*) from auth.users),
    'users_7d', (select count(*) from auth.users where created_at > now() - interval '7 days'),
    'users_30d', (select count(*) from auth.users where created_at > now() - interval '30 days'),
    'paying_families', (select count(distinct user_id) from active),
    'subs_monthly', (select count(distinct user_id) from active where product_ref ilike '%sub.monthly%'),
    'subs_yearly', (select count(distinct user_id) from active where product_ref ilike '%sub.yearly%'),
    'packs_sold', (select count(*) from paid where scope like 'pack:%'),
    'revenue_total_gross', (select coalesce(sum(public.crm_price(product_ref)), 0) from paid),
    'revenue_30d_gross', (select coalesce(sum(public.crm_price(product_ref)), 0) from public.entitlements
                          where source <> 'manual' and updated_at > now() - interval '30 days'),
    'mrr_gross', (select round(gross, 2) from mrr),
    -- Net: without 23% VAT and about 15% store fees.
    'mrr_net', (select round(gross / 1.23 * 0.85, 2) from mrr),
    'monthly_costs', (select total from costs),
    'profit_month_estimate', (select round(m.gross / 1.23 * 0.85 - c.total, 2) from mrr m, costs c),
    'recent_users', coalesce((
      select jsonb_agg(jsonb_build_object('email', u.email, 'created_at', u.created_at,
                                          'paying', exists (select 1 from active a where a.user_id = u.id))
                       order by u.created_at desc)
      from (select id, email, created_at from auth.users order by created_at desc limit 25) u), '[]'),
    'open_tasks', (select count(*) from public.crm_items where kind = 'task' and status not in ('done', 'archived')),
    'pending_decisions', (select count(*) from public.crm_items where decision = 'pending')
  )
$$;
revoke all on function public.crm_numbers() from public, anon, authenticated;

-- What Studio calls: the numbers, for admins only.
create or replace function public.crm_overview()
returns jsonb language plpgsql stable security definer set search_path = public as $$
begin
  if not public.is_admin() then
    raise exception 'forbidden' using errcode = '42501';
  end if;
  return public.crm_numbers();
end;
$$;
revoke all on function public.crm_overview() from public, anon;
grant execute on function public.crm_overview() to authenticated;

-- A start for the board: what is open today.
insert into public.crm_settings (key, value) values
  ('monthly_costs', '{"Supabase": 0, "Serwer LH.pl": 30, "Claude API": 40, "MailerLite": 0, "Apple Developer": 37, "Google Play": 0}'),
  ('goals', '{"paying_families_2026_12_31": 150, "subscriptions_2027_06_30": 1000}');

insert into public.crm_items (kind, area, title, body, status, priority, owner, due, source) values
  ('task', 'launch', 'Założyć konto Apple Developer', 'developer.apple.com, 99 USD rocznie. Potrzebne do App Store, zakupów i logowania Apple.', 'todo', 1, 'Dawid', current_date + 3, 'system'),
  ('task', 'launch', 'Założyć konto Google Play Console', 'play.google.com/console, 25 USD jednorazowo. Konto firmowe skraca test zamknięty.', 'todo', 1, 'Dawid', current_date + 3, 'system'),
  ('task', 'crm', 'Wpisać klucz Claude API w Supabase', 'Supabase → Edge Functions → Secrets: ANTHROPIC_API_KEY. Bez tego agent COO nie działa.', 'todo', 1, 'Dawid', current_date + 1, 'system'),
  ('task', 'marketing', 'Założyć MailerLite i wpisać klucz', 'Konto MailerLite, domena nadawcy audiokiddo.pl, klucz API w Supabase jako MAILERLITE_API_KEY.', 'todo', 2, 'Dawid', current_date + 7, 'system'),
  ('task', 'marketing', 'Formularz zapisu na newsletter na audiokiddo.pl', 'Formularz MailerLite osadzony na stronie, z prezentem: darmowa karta zabaw do druku.', 'todo', 2, 'Dawid', current_date + 10, 'system'),
  ('task', 'server', 'Usunąć stary plik przewodnik.pdf z serwera', 'FileZilla: nagrania/pdf/przewodnik.pdf (niepotrzebny po usunięciu przewodników PDF).', 'todo', 3, 'Dawid', null, 'system'),
  ('mailing', 'automation', 'Powitanie nowego rodzica (3 maile)', 'Dzień 0: jak zacząć i darmowe zabawy. Dzień 2: tryb dziecka i pobieranie offline. Dzień 5: abonament z nowym pakietem co miesiąc.', 'todo', 2, 'Dawid', null, 'system'),
  ('mailing', 'newsletter', 'Newsletter co 2 tygodnie: tip, rolka, zabawa', 'Stały układ: jeden tip wychowawczy, jedna rolka dla rodziców, jedna zabawa bez ekranu na dziś, nowość w aplikacji.', 'todo', 2, 'Dawid', null, 'system');

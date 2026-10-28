-- The December pack becomes three episodes: Szop'en visits the heroes of the three paid packs
-- (docs/pakiety/swieta-z-szopenem.md). Subscribers get it on 30 November, everyone for free
-- from 6 December (St Nicholas) to 6 January, then it stays in the subscription. Less recording,
-- and no store product to set up. Only words still as the plan wrote them change.

update public.crm_items c
set title = case when c.title = v.old_title then v.new_title else c.title end,
    body = case when v.new_body is null then c.body
                when v.old_body = '' then v.new_body || case when c.body = '' then '' else ' ' || c.body end
                when position(v.old_body in c.body) = 1 then v.new_body || substr(c.body, length(v.old_body) + 1)
                else c.body end,
    data = case when v.hours is null then c.data else c.data || jsonb_build_object('hours', v.hours) end
from (values
  ('p-grudzien-0', 'Pakiet „Święta z Szop’enem”: temat i lista 5 zabaw', 'Pakiet „Święta z Szop’enem”: 3 odcinki u bohaterów pakietów',
   'Wybór na podstawie rankingu zabaw (CRM → Analiza) i pomysłów agenta.', 'Propozycja odcinków i decyzja „za darmo czy płatnie”: docs/pakiety/swieta-z-szopenem.md.', null::numeric),
  ('p-grudzien-2', 'Pakiet „Święta z Szop’enem”: scenariusze', 'Pakiet „Święta z Szop’enem”: scenariusze 3 odcinków', null, null, 5),
  ('p-grudzien-3', 'Pakiet „Święta z Szop’enem”: nagrania', 'Pakiet „Święta z Szop’enem”: nagrania 3 odcinków', null, null, 5),
  ('p-grudzien-4', 'Pakiet „Święta z Szop’enem”: montaż i okładka', 'Pakiet „Święta z Szop’enem”: montaż i okładki odcinków', null, null, 5),
  ('p-grudzien-5', 'Pakiet „Święta z Szop’enem”: zabawy w Studio, produkt w obu sklepach', 'Pakiet „Święta z Szop’enem”: odcinki w Studio (abonenci od 30.11, wszyscy od 6.12)',
   'Studio → Treści; produkt jednorazowy w App Store Connect i Play Console.', 'Studio → Treści. Bez produktu w sklepach: od 6.12 do 6.01 odcinki są darmowe dla wszystkich.', 1.5)
) as v(key, old_title, new_title, old_body, new_body, hours)
where c.data->>'plan' = 'premiera-2026' and c.data->>'key' = v.key;

-- The hours in the notes follow (8 h → 5 h for the episodes, 3 h → 1,5 h in Studio).
update public.crm_items
set body = replace(body, 'Czas: ok. 8 h.', 'Czas: ok. 5 h.')
where data->>'plan' = 'premiera-2026' and data->>'key' in ('p-grudzien-2', 'p-grudzien-3', 'p-grudzien-4');
update public.crm_items
set body = replace(body, 'Czas: ok. 3 h.', 'Czas: ok. 1,5 h.')
where data->>'plan' = 'premiera-2026' and data->>'key' = 'p-grudzien-5';

insert into public.crm_items (kind, area, title, body, status, priority, owner, due, source, data)
select 'calendar', v.area, v.title, v.body, 'todo', 2, v.owner, v.due, 'system',
       jsonb_build_object('plan', 'premiera-2026', 'key', v.key)
from (values
  ('c-swieta-free', 'promotion', 'Święta z Szop’enem za darmo dla wszystkich', 'Do 6.01. Wydarzenie w sklepach, newsletter, zapis na stronie.', 'Razem', date '2026-12-06'),
  ('c-swieta-end', 'promotion', 'Koniec darmowych odcinków świątecznych', 'Od jutra odcinki są w abonamencie.', 'Dawid', date '2027-01-06')
) as v(key, area, title, body, owner, due)
where not exists (select 1 from public.crm_items c where c.data->>'plan' = 'premiera-2026' and c.data->>'key' = v.key);

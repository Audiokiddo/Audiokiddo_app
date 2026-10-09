-- Social content from the content base (docs/marketing/baza-contentu.html, plan in
-- docs/marketing/PLAN-TRESCI.md): two filming sessions, editing, gathering the parents' stories,
-- measuring after 48 hours and 7 days, and the ten reels in the calendar up to the premiere.
-- Each row carries its plan key, so running this again adds nothing twice.

insert into public.crm_items (kind, area, title, body, status, priority, owner, due, source, data)
select v.kind, v.area, v.title, v.body, 'todo', v.priority, v.owner, v.due, 'system', v.data
from (values
  ('s-scripts', 'task', 'reel', 'Treści: przeczytać scenariusze 10 rolek, obsada i rekwizyty', 'Baza contentu: docs/marketing/baza-contentu.html. Scenariusz: docs/marketing/PLAN-TRESCI.md. Czas: ok. 1 h. Claude przygotował: scenariusze 10 rolek: docs/marketing/PLAN-TRESCI.md.', 2, 'Nela', date '2026-10-12', jsonb_build_object('plan', 'premiera-2026', 'key', 's-scripts', 'hours', 1)),
  ('s-film1', 'task', 'reel', 'Treści: sesja nagrań 1 (rolki 02, 04, 03, 01)', 'Nela i Dawid grają dorosłe postacie, dziecko tylko poza kadrem. Scenariusz: docs/marketing/PLAN-TRESCI.md. Czas: ok. 4 h.', 1, 'Razem', date '2026-10-14', jsonb_build_object('plan', 'premiera-2026', 'key', 's-film1', 'hours', 4)),
  ('s-edit1', 'task', 'reel', 'Treści: montaż rolek z sesji 1 (02 jeszcze 14.10)', 'Napisy na ekranie, pion, 20–40 s. Scenariusz: docs/marketing/PLAN-TRESCI.md. Czas: ok. 4 h.', 2, 'Dawid', date '2026-10-15', jsonb_build_object('plan', 'premiera-2026', 'key', 's-edit1', 'hours', 4)),
  ('s-film2', 'task', 'reel', 'Treści: sesja nagrań 2 (rolki 05, 06, 10, 08, 07)', 'Rolka 08 z aplikacją na premierę 2.11. Scenariusz: docs/marketing/PLAN-TRESCI.md. Czas: ok. 4 h.', 1, 'Razem', date '2026-10-21', jsonb_build_object('plan', 'premiera-2026', 'key', 's-film2', 'hours', 4)),
  ('s-edit2', 'task', 'reel', 'Treści: montaż rolek z sesji 2', 'Scenariusz: docs/marketing/PLAN-TRESCI.md. Czas: ok. 5 h.', 2, 'Dawid', date '2026-10-22', jsonb_build_object('plan', 'premiera-2026', 'key', 's-edit2', 'hours', 5)),
  ('s-spis', 'task', 'post', 'Treści: zebrać zgłoszenia do Narodowego spisu i karuzeli 09', 'Komentarze i wiadomości po rolce 04, anonimowo, bez zrzutów ekranu. Scenariusz: docs/marketing/PLAN-TRESCI.md. Czas: ok. 1 h.', 2, 'Nela', date '2026-10-23', jsonb_build_object('plan', 'premiera-2026', 'key', 's-spis', 'hours', 1)),
  ('s-measure1', 'task', 'crm', 'Treści: pomiar rolek po 48 h i 7 dniach', 'Zasięg, udostępnienia, komentarze i zapisy na 1000 odbiorców, wejścia w profil, nowy pomysł z komentarzy. Zapis w karcie publikacji w Kalendarzu. Czas: ok. 1 h.', 2, 'Dawid', date '2026-10-26', jsonb_build_object('plan', 'premiera-2026', 'key', 's-measure1', 'hours', 1)),
  ('s-cycle2', 'task', 'reel', 'Treści: plan drugiego cyklu (briefy 11–24) po pomiarze', 'Proporcje 60/20/10/10. Sezon: brief 11 (prezent) na grudzień, 16 przed feriami. Czas: ok. 2 h.', 2, 'Razem', date '2026-10-30', jsonb_build_object('plan', 'premiera-2026', 'key', 's-cycle2', 'hours', 2)),
  ('s-measure2', 'task', 'crm', 'Treści: pomiar rolek z premiery', 'Jak 26.10, osobno organiczne i płatne. Czas: ok. 1 h.', 2, 'Dawid', date '2026-11-09', jsonb_build_object('plan', 'premiera-2026', 'key', 's-measure2', 'hours', 1)),
  ('s-post-02', 'calendar', 'reel', 'Rolka 02: Twój stary policjant: Zgubiona rękawiczka', '19:30, Instagram, Facebook, TikTok. Scenariusz: docs/marketing/PLAN-TRESCI.md.', 2, 'Nela', date '2026-10-15', jsonb_build_object('plan', 'premiera-2026', 'key', 's-post-02')),
  ('s-post-04', 'calendar', 'reel', 'Rolka 04: Narodowy spis dziwnych zdań', '19:30, Instagram, Facebook, TikTok. Scenariusz: docs/marketing/PLAN-TRESCI.md.', 2, 'Nela', date '2026-10-18', jsonb_build_object('plan', 'premiera-2026', 'key', 's-post-04')),
  ('s-post-03', 'calendar', 'reel', 'Rolka 03: Komunikat dla ludności: Przedłużenie wieczoru', '19:30, Instagram, Facebook, TikTok. Scenariusz: docs/marketing/PLAN-TRESCI.md.', 2, 'Nela', date '2026-10-20', jsonb_build_object('plan', 'premiera-2026', 'key', 's-post-03')),
  ('s-post-01', 'calendar', 'reel', 'Rolka 01: Mama vs Matka Aureliusza: Grupa przedszkolna', '19:30, Instagram, Facebook, TikTok. Scenariusz: docs/marketing/PLAN-TRESCI.md.', 2, 'Nela', date '2026-10-22', jsonb_build_object('plan', 'premiera-2026', 'key', 's-post-01')),
  ('s-post-09', 'calendar', 'reel', 'Rolka 09: Instytut: Rekwizyt na jutro (karuzela)', '19:30, Instagram, Facebook, TikTok. Scenariusz: docs/marketing/PLAN-TRESCI.md.', 2, 'Nela', date '2026-10-25', jsonb_build_object('plan', 'premiera-2026', 'key', 's-post-09')),
  ('s-post-05', 'calendar', 'reel', 'Rolka 05: Twój stary policjant: Brokat', '19:30, Instagram, Facebook, TikTok. Scenariusz: docs/marketing/PLAN-TRESCI.md.', 2, 'Nela', date '2026-10-27', jsonb_build_object('plan', 'premiera-2026', 'key', 's-post-05')),
  ('s-post-06', 'calendar', 'reel', 'Rolka 06: Mama vs Matka Aureliusza: Bal', '19:30, Instagram, Facebook, TikTok. Scenariusz: docs/marketing/PLAN-TRESCI.md.', 2, 'Nela', date '2026-10-29', jsonb_build_object('plan', 'premiera-2026', 'key', 's-post-06')),
  ('s-post-10', 'calendar', 'reel', 'Rolka 10: Komunikat dla ludności: Wyjście za pięć minut', '19:30, Instagram, Facebook, TikTok. Scenariusz: docs/marketing/PLAN-TRESCI.md.', 2, 'Nela', date '2026-11-01', jsonb_build_object('plan', 'premiera-2026', 'key', 's-post-10')),
  ('s-post-08', 'calendar', 'reel', 'Rolka 08: Świat Audiokiddo: Nuda i karton (premiera)', '19:30, Instagram, Facebook, TikTok. Scenariusz: docs/marketing/PLAN-TRESCI.md.', 2, 'Nela', date '2026-11-02', jsonb_build_object('plan', 'premiera-2026', 'key', 's-post-08')),
  ('s-post-07', 'calendar', 'reel', 'Rolka 07: Twój stary policjant: Nożyczki', '19:30, Instagram, Facebook, TikTok. Scenariusz: docs/marketing/PLAN-TRESCI.md.', 2, 'Nela', date '2026-11-03', jsonb_build_object('plan', 'premiera-2026', 'key', 's-post-07'))
) as v(key, kind, area, title, body, priority, owner, due, data)
where not exists (
  select 1 from public.crm_items c where c.data->>'plan' = 'premiera-2026' and c.data->>'key' = v.key
);

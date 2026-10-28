-- AudioKiddo Care pilot ("Uszy w górę", docs/care/): the consultant, the word bank, the lawyer,
-- the data audit, the read-through, the recordings, the families and the four-week pilot.
-- Each row carries its plan key, so running this again adds nothing twice.

insert into public.crm_items (kind, area, title, body, status, priority, owner, due, source, data)
select v.kind, v.area, v.title, v.body, 'todo', v.priority, v.owner, v.due, 'system', v.data
from (values
  ('care-konsultant', 'task', 'product', 'Care: rozmowa z logopedą (Malechowo), konsultant i zakres pilota', 'Prezentacja: docs/care/AudioKiddo-Care-prezentacja.pdf. Sześć pytań z ostatniego slajdu. Do ustalenia: nazwisko i kwalifikacje konsultanta, czy zaczynamy od sz–s i cz–c, zgoda na akceptację słów, próbek i montażu. Czas: ok. 2 h.', 1, 'Dawid', date '2026-10-29', jsonb_build_object('plan', 'premiera-2026', 'key', 'care-konsultant', 'hours', 2)),
  ('care-slowa', 'task', 'product', 'Care: lista słów i kolejność od konsultanta', 'Kontrasty, słowa znane 5–6-latkom, pary i słowa pojedyncze, miejsce głoski w słowie, słowa do wycięcia. Komplet z ChatGPT: docs/care/komplet-promptow-0-5.md. Czas: ok. 2 h.', 1, 'Dawid', date '2026-11-05', jsonb_build_object('plan', 'premiera-2026', 'key', 'care-slowa', 'hours', 2)),
  ('care-audyt', 'task', 'product', 'Care: audyt przepływów danych aplikacji pod pilota', 'Claude przygotuje opis: co aplikacja zapisuje i wysyła (konto, zdarzenia, kody), co dotyczy Care, czego brakuje w polityce prywatności. Dawid sprawdza i zatwierdza. Bez tego nie piszemy „tylko dane zbiorcze”. Czas: ok. 2 h.', 1, 'Dawid', date '2026-11-03', jsonb_build_object('plan', 'premiera-2026', 'key', 'care-audyt', 'hours', 2)),
  ('care-prawnik', 'task', 'product', 'Care: opinia prawnika (wyrób medyczny, RODO, treść reklam)', 'Przeznaczenie i funkcje oprogramowania, dane rodzin w pilocie, słownik komunikacji z raportu (bez „leczy”, „diagnozuje”). Czas: ok. 2 h.', 1, 'Dawid', date '2026-11-12', jsonb_build_object('plan', 'premiera-2026', 'key', 'care-prawnik', 'hours', 2)),
  ('care-czytanie', 'task', 'product', 'Care: czytanie próbne odcinków 0, 1 i 4', 'Nela czyta Szuszu, Dawid Szop’ena. Sprawdzamy czas, pauzy, wymowę par i czy brzmi jak zabawa, a nie lista. Czas: ok. 2 h.', 2, 'Razem', date '2026-11-10', jsonb_build_object('plan', 'premiera-2026', 'key', 'care-czytanie', 'hours', 2)),
  ('care-karta', 'task', 'product', 'Care: karta dla gabinetów (1 strona) i mail z propozycją pilota', 'Treść z kompletu promptów, część 5. Uzupełnić: działający kod lub QR, nazwisko konsultanta, informacja o prywatności. Czas: ok. 2 h.', 2, 'Nela', date '2026-11-17', jsonb_build_object('plan', 'premiera-2026', 'key', 'care-karta', 'hours', 2)),
  ('care-nagranie', 'task', 'product', 'Care: nagranie wprowadzenia i dwóch odcinków pilota', 'Po akceptacji słów. Szop’en głosem „szop”, Szuszu głosem Neli. Osobne ścieżki: głos, efekty, muzyka. Czas: ok. 6 h.', 2, 'Razem', date '2026-11-24', jsonb_build_object('plan', 'premiera-2026', 'key', 'care-nagranie', 'hours', 6)),
  ('care-rodziny', 'task', 'product', 'Care: test z trzema rodzinami i wybór 5–8 gabinetów do pilota', 'Pytania: czy polecenia są zrozumiałe, co przeszkadza, czy dziecko prosi o jeszcze raz. Bez danych dzieci. Czas: ok. 3 h.', 2, 'Dawid', date '2026-12-03', jsonb_build_object('plan', 'premiera-2026', 'key', 'care-rodziny', 'hours', 3)),
  ('care-pilot', 'task', 'product', 'Care: start pilota (4 tygodnie)', 'Tydzień 1: wprowadzenie i odcinek 1, 2–3: odcinek 4 i powtórki, 4: rozmowa w gabinecie. Mierzymy wygodę, zrozumiałość i chęć powrotu, nie poprawę wymowy. Czas: ok. 2 h.', 2, 'Dawid', date '2026-12-07', jsonb_build_object('plan', 'premiera-2026', 'key', 'care-pilot', 'hours', 2))
) as v(key, kind, area, title, body, priority, owner, due, data)
where not exists (
  select 1 from public.crm_items c where c.data->>'plan' = 'premiera-2026' and c.data->>'key' = v.key
);

# Uzupełnienie Skarbnicy: sesja w chmurze, 28 października 2026

Do dopisania w Skarbnicy (`07-zadania-i-otwarte-sprawy/`) obok `PRZEKAZANIE-SESJI-2026-10-28.md`. Sesja w chmurze nie miała dostępu do Maca, Skarbnicy, kodu Care ani ElevenLabs. Wszystko poniżej jest w repozytorium `Audiokiddo/Audiokiddo_app`, gałąź `claude/busy-babbage-aeq1ro` (ostatni commit: `d86a80e` i nowsze).

## 1. Co zrobiono

| Obszar | Wynik | Gdzie |
|---|---|---|
| Raporty | Przeczytane: raport rynkowy (1841 opinii), „Mowa w wieku 4–6 lat”, podręcznik tworzenia audiozabaw v1.3 (Nela) | `docs/care/`, wnioski w KONCEPCJA-CARE.md |
| Prompty dla ChatGPT | Komplet promptów 0–5 i wyniki ChatGPT | `docs/care/komplet-promptow-0-5.md` |
| Prezentacja dla logopedy | 10 slajdów, makiety ekranów, 6 pytań do dyrektora | `docs/care/AudioKiddo-Care-prezentacja.pdf` |
| Koncepcja v2 „Uszy w górę” | Mechanizmy uczenia, pakiety, funkcje pilota i później, dane i prawo | `docs/care/KONCEPCJA-CARE.md` |
| Projekt ekranu Care i połączenia ze Startem | Siedem problemów ze zrzutu, nowy układ, integracja ze Startem, kryteria odbioru | `docs/care/EKRAN-CARE-PROJEKT.md` |
| Odcinek próbny „Tacka czy taczka?” | Scenariusz JSON i czytelna wersja, 25 wypowiedzi, 1983 znaki | `docs/care/odcinki/` |
| Narzędzie do nagrania | `tool/care_episode.py` (ElevenLabs, głosy „szop” i „nela”); przetestowane z ciszą zamiast mowy | `tool/care_episode.py` |
| CRM | 9 zadań Care (klucze `care-*`) wstawionych do produkcji tym samym idempotentnym SQL-em | migracja `20261101000001_care_pilot.sql` |
| Sklep | Słowo kluczowe „logopedia” zastąpione „rymy” w dokumencie do wklejenia | `docs/sklepy/KARTA-DO-WKLEJENIA.md` |

## 2. Decyzje

- Care dla dziecka i rodzica nazywa się **„Uszy w górę”**; „Care” zostaje nazwą wewnętrzną i dla logopedów.
- Pilot bez mikrofonu i bez rozpoznawania mowy; bez nagrań dzieci i diagnoz; karta tygodnia (PDF) powstaje w telefonie rodzica.
- Pilot: pakiet „Szop’en i Szumiąca Szafa”, kontrasty sz–s i cz–c (ż–z i dż–dz tylko po zatwierdzeniu konsultanta); wprowadzenie plus odcinki 1 i 4.
- Kolejność pakietów: Szafa, Koszyk Rymusia, Kot Bąbel. Odłożone: Biuro Ciekawych Dźwięków, „r”, „k–g”.
- Głosy: Szop’en = „szop” (Dawid), Szuszu = „nela”.
- **Świąteczne odcinki Szop’ena zostają bez zmian** (decyzja Dawida: nie robić wersji neutralnej wobec tradycji).
- Oceny w Care wystawia rodzic („łatwo / w sam raz / trudno”); aplikacja nie ocenia wymowy ani nie pokazuje procentów.

## 3. Stan produkcji (Supabase)

- Projekt `audiokiddo` (eu-central-1). Produkcja ma migracje do `20261031000001`; repo w chmurze ich nie ma (są w lokalnym repo). Wersja `20261029000001` jest zajęta (`review_bonus`), dlatego migracja Care ma numer `20261101000001`.
- Dziewięć zadań `care-*` wstawiono przez narzędzie Supabase (`execute_sql`), nie przez `db push`. Późniejszy `db push` niczego nie zdubluje.
- W produkcji plan `premiera-2026` ma 27 wierszy (według migracji powinno być więcej): do sprawdzenia, czy zadania zostały zrobione, czy usunięte.

## 4. Otwarte sprawy

1. **Kod Care:** wypchnąć z Maca na gałąź (np. `claude/care`); w chmurze go nie ma.
2. **Nagranie odcinka próbnego:** `python3 tool/care_episode.py tacka-czy-taczka --dry-run`, potem bez `--dry-run`; sprawdzić głos Szuszu („nela”).
3. **Przebudowa zakładki Care i Start:** według `EKRAN-CARE-PROJEKT.md`, prompt w `PROMPT-SESJA-LOKALNA.md` i `PROMPT-NOWY-WATEK.md`.
4. **Rozmowa w Malechowie (29.10):** konsultant (nazwisko, kwalifikacje, akceptacja słów, próbek i montażu), zakres pilota, 6 pytań ze slajdu 10. Odpowiedzi zapisać i przekazać.
5. **Audyt przepływów danych aplikacji** (do 3.11), **opinia prawnika** (do 12.11): bez nich nie piszemy „tylko dane zbiorcze”.
6. **Strona audiokiddo.pl:** hasła „polecane przez logopedów i pedagogów”, „Sprawdzone przez logopedkę”, „Sprawdź zabawy, które polecają specjaliści” wymagają potwierdzenia źródła i zgody (nazwisko).
7. **Wtyczka strony 3.25.2–3.25.3:** kodu nie ma w żadnej gałęzi na GitHubie; wypchnąć z Maca na osobną gałąź i scalić z 3.26.0 z `claude/szop-glos-gry`.
8. **Sklepy:** Apple (umowa płatnych aplikacji, dane bankowe, W-8BEN, DSA), Google Play (konto, 12 testerów na 14 dni). Zmiana słowa kluczowego w App Store Connect, jeśli „logopedia” już tam wpisano.
9. **Głos Szop’ena w aplikacji:** `python3 tool/ui_voice.py --voice szop` (dry-run, potem `--only hello`, potem całość).

## 5. Granice sesji w chmurze

Brak: Maca, iPhone’a, Skarbnicy, lokalnego repo z Care, dostępu do ElevenLabs i audiokiddo.pl. Można: dokumenty, scenariusze, specyfikacje, narzędzia testowane z ciszą, kod w tym repo, testy bazy, zapis do Supabase po wyraźnej zgodzie w czacie.

## 6. Pliki do skopiowania do Skarbnicy

Z repo (po `git pull origin claude/busy-babbage-aeq1ro`): cały folder `docs/care/` do `03-aplikacja/CARE-v2-2026-10-28/` oraz ten plik do `07-zadania-i-otwarte-sprawy/`.

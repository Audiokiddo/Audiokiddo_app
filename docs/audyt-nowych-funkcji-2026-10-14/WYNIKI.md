> Aktualizacja 15.10.2026: poniżej jest historyczny stan przed naprawami. Aktualne lokalne zmiany i wyniki opisuje [przekazanie dla Claude’a](../../ZMIANY-DLA-CLAUDE-2026-10-15.md).

# Wyniki — 14.10.2026, commit 193d620

| Weryfikacja | Wynik |
| --- | --- |
| Pełne testy aplikacji, ustawienia domyślne | 284 zaliczone, 1 pominięty |
| Pełne testy aplikacji, PARENT_GATE_EVERYWHERE=true, REDEEM_CODES=false | 282 zaliczone, 3 pominięte |
| Dodatkowe pozytywne próby wyszukiwania, sortowania i trwałości kart | 3 zaliczone |
| Nowe próby: pomijanie kurtyny, dodawanie przy zakończeniu, zamiana po zmianie nagrania | 3 niezaliczone — odtworzone błędy |
| Granice czasu dostępu i premiery | 2 niezaliczone — odtworzone błędy |
| Nawigacja, 3 istniejące scenariusze + dodatkowa próba helpera | 3 zaliczone, 1 niezaliczony; ostatni nie jest potwierdzonym przebiegiem obecnego UI |
| Pobieranie po aktualizacji zawartości pliku w katalogu | 1 niezaliczony — odtworzony błąd |
| Analiza Flutter | 1 warning w istniejącym plan_screens_test.dart:3, kod wyjścia 1 |
| Wszystkie migracje i schema_test.sql, lokalna tymczasowa baza PostgreSQL 17 | kod wyjścia 0 |

Pełne zestawy uruchomiono oddzielnie od dodatkowych prób. Testów ponownie uruchomionych nie sumować jako odrębnego pokrycia. Probe testy korzystają z atrap audio/sieci: nie są pomiarem zachowania systemowego odtwarzacza na fizycznym telefonie.

Wersja źródłowa pozostała bez zmian. W projekcie dodano tylko ten raport, logi i pliki prób. Nie publikowano nowego builda ani funkcji serwerowych w tym przebiegu.

# AudioKiddo — audyt i propozycja rozwoju

Data: 28.09.2026. Zakres: kod aplikacji Flutter, wspólny silnik, panel Studio, migracje i funkcje Supabase, materiały marki oraz publiczna strona audiokiddo.pl.

## Ocena

To rozbudowany prototyp z wartościową logiką i dużą liczbą testów, ale jeszcze nie kompletna aplikacja gotowa do płatnego wydania. Najpierw trzeba domknąć dostarczanie treści i odporność obsługi zakupów, równolegle można rozwijać wygląd z Goldenem.

Dokumentacja historyczna zawiera plany i oznaczenia „Etap 3”, które nie zawsze odpowiadają obecnemu kodowi. Traktowałem ją jako materiał do porównania, a nie polecenia do wdrażania. Nie zmieniałem działania aplikacji, kont, danych klientów ani usług produkcyjnych.

## Wyniki sprawdzeń

| Obszar | Wynik |
|---|---|
| Istniejące testy aplikacji | 112 zaliczonych |
| Wspólna logika ak_core | 65 zaliczonych |
| Istniejące testy zakupów / podpisów Deno | 23 zaliczone |
| Studio | 7 zaliczonych, 1 niezaliczony |
| Dodatkowe reprodukcje audytowe | 4 scenariusze potwierdziły niepożądane zachowanie |

Cztery testy w `purchase-audit.test.ts` są testami diagnostycznymi: ich sukces oznacza odtworzenie luki, a nie potwierdzenie bezpieczeństwa. Używają własnych certyfikatów testowych i pamięciowej imitacji bazy, bez połączenia ze sklepami i produkcją. Po naprawie należy odwrócić oczekiwania, aby stały się testami regresji.

Nie uruchamiałem pełnej aplikacji na urządzeniu, zakupów w sandboxach Apple/Google, testów migracji na Postgres ani skanowania wdrożonych usług. Ocena interfejsu aplikacji wynika z kodu i testów układu, nie z pełnego audytu wszystkich ekranów na telefonie. Nie jest to certyfikacja bezpieczeństwa ani audyt prawny.

## Najważniejsze luki i błędy

### 1. P1 — stary dowód zakupu Apple przywraca dostęp po zwrocie

**Dowód:** `supabase/functions/_shared/purchases.ts:87–97`, `store_status.ts:40–45`; potwierdzone testem audytowym.

Scenariusz: zakup jednorazowy zostaje zweryfikowany → powiadomienie o zwrocie ustawia `refunded` → klient ponownie wysyła oryginalny, nadal poprawnie podpisany dokument zakupu → kod ustawia `active`. Podpis potwierdza autentyczność dokumentu, ale nie jego aktualność.

**Skutek:** posiadacz starego dowodu może odzyskać płatny pakiet po refundacji. Nie wymaga podrobienia podpisu Apple.

**Naprawa:** weryfikować aktualny stan po stronie Apple, zapisywać historię i kolejność zmian oraz nie pozwalać starszemu dokumentowi nadpisywać późniejszego zwrotu. Status, wersję zdarzenia i aktualizację uprawnień zapisywać atomowo.

### 2. P1 — brak rozdzielenia Sandbox i Production w weryfikacji Apple

**Dowód:** `purchases.ts:87`; pole `environment` jest zdefiniowane w `apple_jws.ts`, ale nie jest sprawdzane. Test audytowy nadaje dostęp dla `Sandbox` bez żadnej konfiguracji dopuszczającej to środowisko.

**Skutek:** jeżeli ten sam kod i katalog produktów obsługują produkcję, prawidłowo podpisany zakup testowy może dać rzeczywisty dostęp. Test wykazuje lukę w logice; nie dowodzi wykorzystania jej na wdrożonym serwerze.

**Naprawa:** jawnie skonfigurować oczekiwane środowisko, osobne dane i endpointy testowe oraz sprawdzać środowisko transakcji i powiadomień. Obsłużyć świadomie przepływ TestFlight / recenzji sklepu, bez mieszania go z uprawnieniami produkcyjnymi.

### 3. P1 — powtórne stare powiadomienie zmienia stan mimo odpowiedzi „duplicate”

**Dowód:** `purchases.ts:119–131`; potwierdzone testem audytowym.

Kod najpierw przyznaje dostęp, a dopiero potem sprawdza identyfikator zdarzenia. Powtórka starego zdarzenia aktywacji po zwrocie przywraca `active`, choć funkcja zwraca `duplicate`. Brakuje też ochrony przed zdarzeniami dostarczonymi poza kolejnością.

**Naprawa:** jedna transakcja bazy: sprawdzenie/założenie zdarzenia, kontrola aktualności, zmiana uprawnień i oznaczenie przetworzenia. Nie przenosić samego `recordEvent` przed zapis — błąd po takim zapisie spowodowałby utratę ponowienia, jak w punkcie 5.

### 4. P1 — posiadacz dowodu może przenieść zakup na inne konto

**Dowód:** `purchases.ts:89–97`, Google `:149–150` i analogiczna logika produktów; `supabase/migrations/20260926000001_init.sql:136–138`. Reprodukcja Apple potwierdzona lokalnie.

To zachowanie zostało celowo opisane jako „przywrócenie na innym koncie”, jednak endpoint nie odróżnia bezpiecznej migracji od ponownego wysłania skopiowanego dowodu. Nadpisuje właściciela na konto wywołujące, mimo innego `appAccountToken`. Warunkiem nadużycia jest posiadanie cudzego poprawnego dowodu/tokena — nie wystarczy znać e-mail ofiary.

**Naprawa:** domyślnie przypiąć zakup do właściciela, sprawdzać identyfikatory kont w danych sklepu, a przeniesienie zapewnić osobnym, kontrolowanym procesem. Zachować legalne przywracanie zakupów po reinstalacji i reguły współdzielenia rodzinnego.

### 5. P1 — webhook WooCommerce może zgubić aktualizację po chwilowym błędzie

**Dowód:** `supabase/functions/woo-webhook/index.ts:32–55`; analiza przepływu, bez testu awarii prawdziwej bazy.

Zdarzenie zostaje trwale zapisane przed aktualizacją zamówienia i uprawnień. Jeśli kolejny zapis się nie powiedzie, odpowiedź 500 zachęca sklep do ponowienia, ale ponowienie trafia w „duplicate” i już nie wykonuje operacji. Może to opóźnić odblokowanie zakupu albo pozostawić dostęp po zwrocie. Dodatkowo błąd `user_id_for_email` jest pomijany.

**Naprawa:** atomowa operacja w bazie lub trwała kolejka ze stanami oczekujące/przetworzone/błąd; rejestrować zakończenie dopiero razem z kompletną zmianą uprawnień. Dodać test awarii pomiędzy etapami i ponowienia.

### 6. P1 — domyślna wersja release nie dochodzi do pierwszego ekranu

**Dowód:** `app/lib/features/content/content_urls.dart:23–30`, `features/downloads/download_providers.dart:13–20`, `main.dart:37–44`; statycznie potwierdzony łańcuch wywołań.

Poza debugiem, bez `CONTENT_BASE_URL`, resolver rzuca `UnsupportedError`. Jest potrzebny podczas inicjalizacji menedżera pobrań przed `runApp`. Ręczne ustawienie adresu usuwa ten konkretny błąd, ale nie zapewnia autoryzacji dostępu do plików.

W repozytorium brak implementacji `download-url`. `BaseUrlResolver` jedynie łączy stały adres ze ścieżką. Przy publicznym hostingu płatnych MP3 lokalna blokada odtwarzania nie chroniłaby bezpośrednich URL-i. Nie sprawdzałem rzeczywistej dostępności prywatnych plików na serwerze.

**Naprawa:** prywatny magazyn plików, sprawdzanie uprawnień po stronie serwera i krótkotrwałe podpisane URL-e. Konfigurację release sprawdzać przy budowaniu; przy problemie uruchamiać zrozumiały ekran błędu zamiast przerywać start.

### 7. P2 — katalog i Studio nadal pracują lokalnie

**Dowód:** `app/lib/features/catalog/catalog_providers.dart:31` zawsze wybiera `BundledCatalogSource`; `studio/lib/io/studio_io.dart` zapisuje szkic w przeglądarce, a `pickAsset` odczytuje jedynie metadane pliku. `studio/README.md` opisuje eksport JSON jako lokalną publikację.

**Skutek:** publikacja nowej zabawy w Studio nie aktualizuje automatycznie bibliotek na telefonach. Wybór pliku nie oznacza przesłania nagrania. Nie należy mylić lokalnego panelu z gotowym CMS online.

**Naprawa:** autoryzacja administratorów, upload plików, wersjonowana publikacja manifestu, aktualizacja katalogu z zachowaniem ostatniej poprawnej wersji. Istniejące migracje RLS są dobrym punktem wyjścia, ale same nie podłączają Studio do serwera.

### 8. P2 — logowanie po anonimowym zakupie nie łączy tożsamości

**Dowód:** `app/lib/features/account/account_service.dart:99–105` i `:121`: zwykłe logowanie OTP / Apple, bez ścieżki łączenia anonimowego konta zakupowego. `purchaseAccountId` tworzy osobną anonimową tożsamość.

**Ryzyko wymagające testu integracyjnego:** po zakupie bez konta, a następnie zalogowaniu do innego użytkownika Supabase uprawnienia mogą pozostać na poprzednim UUID. Możliwość przywrócenia zakupu nie zastępuje płynnego łączenia kont, a obecny swobodny transfer z punktu 4 nie jest dobrą naprawą.

**Naprawa:** zaprojektować świadome przekształcenie anonimowej tożsamości lub kontrolowane przeniesienie danych. Test: zakup jako gość → OTP → restart → dostęp zachowany.

### 9. P2 — jeden test Studio jest nieaktualny

**Dowód:** `studio/test/studio_test.dart:45` oczekuje 32 pozycji, podczas gdy importowany katalog zawiera 33. Test kończy się przed kolejnym sprawdzeniem poprawności publikacji.

**Naprawa:** sprawdzać zgodność importu z wejściowym katalogiem i stabilnymi wymaganiami treści, zamiast liczby zmieniającej się przy dodaniu zabawy. Sam ten wynik nie dowodzi uszkodzenia importera.

### 10. P3 — ograniczenie ruchu nie obejmuje całej istniejącej maskotki

**Dowód:** `app/lib/core/widgets/kiddo.dart:127–131`: ograniczane są oddech i podskok, ale mruganie, usta i machanie nadal otrzymują zmieniające się wartości. Kontrolery także nie są w tym miejscu zatrzymywane.

**Naprawa przy wdrażaniu Goldena:** respektować ustawienia ograniczania animacji dla całej postaci, zatrzymywać pracę poza widocznym ekranem i w tle. Zapewnić nieruchomy wariant.

## Co warto zachować

- Wspólny parser i walidator treści dla aplikacji oraz Studio.
- Weryfikacja sum plików przy pobieraniu i rozdzielenie logiki dostępu od UI.
- RLS ograniczające odczyt uprawnień do właściciela w sprawdzonych migracjach.
- Weryfikacja podpisów webhooków i łańcucha certyfikatów Apple — potrzebuje domknięcia logiki stanu, nie wyrzucenia całej implementacji.
- Tryb dziecka z ochroną nawigacji także po restarcie, testy małych ekranów i powiększonego tekstu.
- Brak konieczności przenoszenia profili dziecka do serwera w obecnym projekcie.

Publiczny klucz Supabase w aplikacji jest kluczem publikowalnym; sama jego obecność nie jest wykrytą luką ani ujawnieniem klucza administracyjnego.

## Kierunek wyglądu

Makieta: `golden-koncepcja.png`. Szczegółowy brief: `GOLDEN-I-INTERFEJS.md`.

Główna zmiana to rozpoznawalny golden retriever i mniej decyzji na pierwszym ekranie. Obecnie Start zawiera główną kartę, cztery tryby, pierwsze kroki, pytanie do rozmowy i nowości. Proponuję: jedna propozycja do odtworzenia, „Wróć do słuchania”, dwa stałe skróty kontekstowe oraz bibliotekę. Plan pozostaje dostępny w „Moje”; nie należy usuwać istniejącej funkcji.

Aktualne `dayPartOf` już rozróżnia pory dnia. Można je wykorzystać, uzupełniając odświeżanie po powrocie aplikacji na pierwszy plan i zmianie godziny. Stroje Goldena mają być bezpłatną częścią tożsamości marki, bez mechaniki kolekcjonowania czy presji codziennych powrotów.

Na stronie głównej i stronie „O audiozabawach” nie odnalazłem wzoru Goldena; nie było go również w podanych materiałach pod rozpoznawalną nazwą. Obraz przedstawia interpretację postaci do uzgodnienia z oryginałem. Nie jest wiernym odwzorowaniem potwierdzonej maskotki. Makieta pokazuje kierunek, nie ukończony, animowany interfejs.

## Kolejność realizacji

1. Zamknąć P1: start release, prywatne audio, aktualność zakupów, środowiska, transfer i odporność webhooków.
2. Połączyć katalog, Studio i bezpieczne łączenie kont. Przeprowadzić testy rzeczywistych zakupów, zwrotów, przywracania i pracy offline na obu systemach.
3. Uzgodnić oryginalny wygląd Goldena; przygotować postać z osobnymi elementami do animacji, stroje oraz nagrania.
4. Wdrożyć nowy Start i odtwarzacz, potem pozostałe ekrany. Sprawdzić mały telefon, duży tekst, czytnik ekranu, tryb nocny i ograniczanie ruchu.

## Źródła i ograniczenia

Główne dowody: wskazane pliki lokalnego kodu i logi testów zapisane w tym katalogu. Sprawdzone strony marki: https://audiokiddo.pl/ i https://audiokiddo.pl/czym-sa-audiozabawy-2/. Rekomendacja animacji: dokumentacja runtime Flutter https://rive.app/docs/runtimes/flutter/flutter.

Nie wprowadzono poprawek produkcyjnych. Przed wdrożeniem trzeba uwzględnić istniejące zakupy i migrację danych — zamiana właściciela lub zasad odczytu bez tego mogłaby pozbawić klientów dostępu.

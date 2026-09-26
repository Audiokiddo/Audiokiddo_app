# AudioKiddo: raport z Etapu 3, część A (bez kont)

Data: 2026-09-26. Zakres: wszystko z Etapu 3, co nie wymaga kont Supabase, Apple, Google ani kluczy WooCommerce.

## Zaimplementowane

| Element | Szczegóły |
|---|---|
| Bramka rodzicielska | Zadanie „dotknij liczby czterdzieści siedem”; wśród odpowiedzi jest liczba z zamienionymi cyframi (74), więc zgadywanie nie działa; 3 błędy dają 30 s blokady; to **nie** jest weryfikacja wieku ani zgoda rodzica |
| Gdzie działa bramka | Odblokowanie (ekran zakupu), karty PDF (podgląd, druk, udostępnianie), wyjście z trybu dziecka |
| Tryb dziecka | Rodzic wybiera wiek i opcję „tylko pobrane” (na podróż). Dziecko widzi duże okładki wyłącznie dostępnych zabaw: bez kłódek, cen, linków i menu. Nawigacja (wstecz, linki, restart) nie wyprowadzi z trybu. Ustawienie czytane przed pierwszą klatką, więc strefa rodzica nie mignie |
| Karty PDF (Detektyw) | Pobierane razem z nagraniem (działają bez internetu); podgląd, drukowanie i udostępnianie za bramką |
| Ekran zakupu | Subskrypcja roczna i miesięczna (7 dni za darmo, gdy sklep go przyzna), pakiet, zestawy, pojedyncza zabawa („Cały pakiet kosztuje…”), przywracanie zakupów, pełne informacje o odnawianiu i anulowaniu, linki do regulaminu i polityki |
| Logika zakupu | Wspólny interfejs sklepu: **symulowany sklep** (wersja robocza, Twoje ceny) i **adapter Apple/Google** (oficjalna wtyczka, StoreKit 2). Dostęp przyznaje wyłącznie weryfikator; transakcja jest zamykana w sklepie dopiero po zapisaniu uprawnienia, więc błąd sieci nigdy nie daje dostępu „na słowo” |
| Narzędzia deweloperskie | Wynik symulowanego zakupu (udany, anulowany, czeka na zgodę, błąd), czyszczenie symulowanych zakupów |
| Serwer: schemat | Tabele, RLS i funkcje: przyznawanie uprawnień, idempotencja powiadomień, zakupy ze strony tylko dla potwierdzonego e-maila, kaskadowe usuwanie |
| Serwer: funkcje | Webhook WooCommerce (podpis HMAC, idempotencja, przyznanie lub odebranie), synchronizacja zakupów ze strony, usuwanie konta; wspólna logika statusów Apple i Google |

## Przetestowane

| Test | Wynik |
|---|---|
| Aplikacja: 56 testów (+16), w tym bramka, tryb dziecka z próbą ucieczki, pełny zakup w symulowanym sklepie, błąd weryfikacji bez przyznania dostępu, anulowanie i „czeka na zgodę”, trial raz na użytkownika | ✅ |
| `ak_core`: 28 testów | ✅ |
| Schemat na prawdziwym PostgreSQL 17 (imitacja `auth`): 8 scenariuszy (tylko własne zakupy, brak samodzielnego dopisania zakupu, zakazane funkcje, idempotencja, zestawy, zwroty, zakupy ze strony, usuwanie konta) | ✅ |
| Logika serwera (Deno): podpis WooCommerce, parsowanie zamówień, statusy Apple i Google: 6 testów | ✅ |
| `deno check` i `deno lint` funkcji | ✅ |
| Emulator Androida: tryb dziecka, bramka (poprawna i błędna odpowiedź), wyjście przez bramkę, PDF z drukowaniem i udostępnianiem, ekran zakupu, zakup roczny → „Gotowe!” → „Słuchaj” | ✅ |

Znalezione i poprawione:
1. Aplikacja wisiała na starcie. Kontroler odtwarzania trafiał do kontenera bez odtwarzacza, a widać to było tylko przy prawdziwym uruchomieniu, bo testy podstawiały zależności.
2. Nieczytelna zaznaczona etykieta w narzędziach deweloperskich.

## Nie sprawdzone lub zablokowane

- **Prawdziwe sklepy**: adapter Apple/Google jest napisany, ale nieuruchomiony. Wymaga produktów w App Store Connect i Play Console oraz testerów sandbox.
- **Trial na iOS**: wtyczka nie udostępnia informacji o ofercie wstępnej StoreKit 2. Do czasu dopisania kodu natywnego ekran na iOS nie pokazuje triala (niczego nie obiecuje), a App Store i tak go naliczy.
- **Funkcje na Supabase**: nieuruchomione (brak projektu). Weryfikacja zakupów Apple/Google, powiadomienia serwerowe, podpisane adresy plików i publikacja katalogu czekają na konta.
- **Konto rodzica w aplikacji** (logowanie e-mailem i Apple, usuwanie konta z poziomu aplikacji) oraz **Studio**: kolejna część Etapu 3.
- **Głosowy komunikat „Zawołaj rodzica”** dla dzieci, które nie czytają: czeka na nagranie lektora.

## Potrzebne od Dawida

1. **Projekt Supabase w regionie UE**: kroki są w `supabase/README.md`. Sekrety wpisujesz w swoim terminalu.
2. **WooCommerce**: klucz REST tylko do odczytu, webhook i ID produktów (instrukcja w tym samym pliku).
3. **Konta deweloperskie Apple i Google**: po ich założeniu zakładam produkty i testuję zakupy w sandboxie.

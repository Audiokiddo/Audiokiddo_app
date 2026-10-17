# Sklep, zakup, dostęp w aplikacji, aplikacja i sklepy mobilne

Źródła w repo: `docs/DOSTEP-Z-SKLEPU.md`, `docs/SKLEP-W-APLIKACJI.md`, `docs/WYDANIE.md`, `docs/SKLEPY.md`,
`docs/PRZEKAZANIE-PROJEKTU.md`, `ARCHITECTURE.md`. Tu tylko to, co trzeba wiedzieć na co dzień.

## Droga klienta (to pokazuje sekcja „Kupujesz raz. Masz wszędzie.” na stronie)

1. Klient wybiera pakiet w sklepie WooCommerce i płaci (PayU i inne bramki). **Konto w sklepie nie jest
   potrzebne** (zamówienia gości działają).
2. Dostaje **mail z linkami do plików MP3** (a przy Detektywie także PDF z aktami sprawy). Strona
   „Dziękujemy” i maile mówią to samo (`inc/woo.php`, funkcja `ak_access_words()`). Prosimy o zajrzenie
   do Spamu i Ofert.
3. **Ten sam pakiet jest od razu w aplikacji**: klient loguje się w niej **tym samym e-mailem co w zamówieniu**.
   Dostaje 6-cyfrowy kod mailem (bez haseł; hasło można ustawić później). Aplikacja sama pobiera zamówienia
   z tego adresu (funkcja `sync-web-purchases`), a nowe zamówienie trafia do niej od razu (webhook sklepu).
4. Jeśli klient użył innego adresu: w aplikacji Sklep → „Masz już dostęp z audiokiddo.pl?” → numer zamówienia
   i e-mail z zamówienia (`claim-order`). Zła para zawsze daje tę samą odpowiedź „nie znaleźliśmy”
   (nikt nie sprawdzi cudzych zamówień).
5. **Kody dostępu** `AK-7K3M-9QXD` (prezenty, testerzy, recenzenci, konkursy), generowane `tool/make_codes.py`.
   Kod jest jednorazowy na konto, w bazie tylko jako skrót. Uwaga: Apple może zakwestionować kody (zasada 3.1.1);
   pole kodu da się wyłączyć flagą `--dart-define=REDEEM_CODES=false` dla wersji iOS. Do decyzji przed zgłoszeniem.

Zasady bezpieczeństwa: zamówienie ma jednego właściciela; 10 błędnych prób na godzinę na konto; zwrócone lub
anulowane zamówienie nie daje dostępu; wszystko działa też bez konta (konto gościa bez danych osobowych,
z podpowiedzią, by zalogować się e-mailem, bo inaczej dostęp zginie przy zmianie telefonu).

Dopóki aplikacji nie ma w sklepach, strona obiecuje tylko pliki (i „gdy aplikacja trafi do sklepów, te same
pakiety odblokujesz logując się adresem z zamówienia”). Gdy w ustawieniach wtyczki pojawi się link do App Store
lub Google Play (`ak_app_live()`), teksty i przyciski przełączają się na wersję „aplikacja jest”.

**Sprzedaż subskrypcji na stronie ma zostać wyłączona** (Ustawienia → AudioKiddo strona, „Włącz sprzedaż
subskrypcji na stronie”, wg `strona/audiokiddo-strona/INSTRUKCJA.md`), dopóki połączenie sklepu z aplikacją
nie obsłuży czasu ważności, odnowień i anulowań (dziś rozpoznaje tylko zakupy pakietów). Abonament wybiera się
w aplikacji (zakupy w sklepach). Aktualnego stanu tego przełącznika nie sprawdzano.

## Co klient może zrobić z kupionym pakietem

W aucie (głośnik samochodu), w domu przy obiedzie i sprzątaniu, na głośniku Bluetooth, **bez internetu** po
pobraniu plików, przy stole z kartami do druku (Detektyw), u babci (pliki zabiera ze sobą), a w aplikacji:
plan dnia, tryb „W drogę”, wieczorny rytuał, tryb dziecka (duże okładki bez zakupów i linków).

## Aplikacja (skrót)

- **Flutter**, Riverpod 3, go_router, just_audio + audio_service, drift (lokalna baza), mikrofon i
  rozpoznawanie mowy **na urządzeniu** (iOS; na Androidzie słowa wyłączone, dziecko klaszcze). Dane dzieci
  zostają w telefonie. Kategoria „Kids”: zakupy i linki zewnętrzne za bramką rodzica.
- Backend: **Supabase** (migracje SQL, Edge Functions w Deno: `download-url` linki 4 h, `verify-purchase`,
  `woo-webhook`, `redeem-code`, `claim-order`, `sync-web-purchases`). Zdalne `supabase db push` i
  `functions deploy` uruchamia Dawid (nie chmura).
- Pliki zabaw na serwerze LH.pl (wtyczka WP „AudioKiddo – pliki aplikacji”), weryfikacja
  `python3 tool/verify_server_files.py`. Pliki robocze (`dev_content/`, `AudioKiddo-materialy/`) są tylko na
  Macu Dawida, **nie w repo**.
- Identyfikatory: `pl.audiokiddo.app` (iOS i Android), nazwa „AudioKiddo”, wersja w `app/pubspec.yaml`.
- Kompilację na iPhone (`tool/phone_build.sh`), ElevenLabs i wgrywanie plików robi się **na Macu Dawida**
  (lokalna sesja Claude Code), nie w chmurze.

## Wydanie w sklepach (stan z dokumentów z 27.9–4.10.2026)

Wymagane (Dawid): konto Apple Developer (99 USD/rok; firma wymaga numeru D-U-N-S, do ok. 2 tygodni),
Google Play Console (25 USD; nowe konto prywatne musi przejść test zamknięty przez 14 dni), umowa „Paid Apps”,
konto bankowe i podatki, deklaracje prywatności i Kids. Materiały do sklepów (opisy, słowa kluczowe, kategorie)
są w `docs/SKLEPY.md`, polityka prywatności i regulamin w `docs/prawne/`. Strona ma już podstrony
„Polityka prywatności aplikacji” i „Usuwanie konta i danych w aplikacji AudioKiddo”.

## Marketing (decyzje z 4.10.2026, `docs/STRATEGIA-5000-DO-MILIONA.md`)

Budżet startowy reklam **5 000 zł**, cel to **zysk** (1 mln zł), nie obrót. To budżet walidacyjny: pytanie,
czy płacącego rodzica da się pozyskać taniej, niż zostaje z jego zakupu. Podział na 30 dni: Meta 1 500 zł
(dni 1–10), Meta 2 000 zł (dni 11–24), Google Search 500 zł, rezerwa 1 000 zł. Jedna strona wejściowa na
jeden problem („Pomysł na zabawę, kiedy Ty potrzebujesz chwili”), na pierwszym ekranie krótki film i darmowa
próbka bez konta. Skalowanie dopiero po 20–30 opłaconych zamówieniach i sprawdzeniu zwrotów. Źródłem prawdy są
zamówienia i zwroty ze sklepu, nie panel reklamowy. Kampanii nie uruchamiano.

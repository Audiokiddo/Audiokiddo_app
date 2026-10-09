# AudioKiddo: publikacja krok po kroku

Stan: 6 października 2026, wersja 0.2.0 (build 2). Ten plik zbiera wszystko w jednej kolejności: serwer, strony, Apple, Google, Studio z CRM i reklamy. Odhaczaj `[ ]` po kolei.

**Zasady przez cały czas:**
- Hasła, klucze i pliki `.p8`, `.json`, `.jks` wpisujesz tylko w swoim terminalu albo w panelach. Nigdy nie wklejasz ich do rozmowy.
- Komendy wpisujesz w Terminalu. Każdą serię zaczynasz od przejścia do folderu projektu:
  ```
  cd ~/Desktop/"claude folder"/audiokiddo-app
  ```
  (Wcześniej `supabase` nie działał, bo terminal był w folderze `claude folder`, a nie w `audiokiddo-app`.)
- Szczegóły starszych kroków są w `docs/KROKI-DLA-DAWIDA.md` (konta), `docs/WYDANIE.md` (podpisywanie) i `docs/SKLEPY.md` (teksty do sklepów). Tu jest kolejność i to, co się zmieniło.

---

## Etap 1. Serwer: wgranie zaległych zmian (15 min, dziś)

- [ ] 1.1 Otwórz Terminal i przejdź do projektu:
  ```
  cd ~/Desktop/"claude folder"/audiokiddo-app
  ```
- [ ] 1.2 Wgraj bazę danych. Doda: sprawdzanie maila przy logowaniu, kampanie w Studio, jeden abonament bez limitu dzieci (migracja `20261020000001_single_plan.sql`).
  ```
  supabase db push
  ```
  Jeśli zapyta o hasło bazy, wklej je z aplikacji Hasła (tylko w terminalu). Na pytanie „Do you want to push these migrations?” wpisz `Y` i Enter.
- [ ] 1.3 Wgraj wszystkie funkcje serwera jedną komendą (są wśród nich nowe: `mailer`, `reviews`, `ads`, `account-status`):
  ```
  supabase functions deploy
  ```
  Jeśli zapyta o projekt, wybierz `ypdxofcwewwdyoelamgy (audiokiddo)` strzałkami i Enter. Ostrzeżenie „Docker is not running” możesz zignorować.
- [ ] 1.4 Popraw klucz Claude. Z poprzednich notatek wynika, że w sekrecie jest dosłownie tekst `twój_klucz`:
  1. Wejdź na console.anthropic.com → API Keys → Create Key. Nazwij go `audiokiddo-supabase` i skopiuj.
  2. Ustaw limit wydatków: Settings → Limits, np. 30 USD miesięcznie.
  3. Supabase (supabase.com/dashboard) → projekt audiokiddo → Edge Functions → **Secrets**.
  4. Przy `ANTHROPIC_API_KEY` kliknij edycję, wklej klucz i zapisz.
- [ ] 1.5 Sprawdź, że działa. W aplikacji wpisz swój e-mail i stuknij „Dalej”: przy istniejącym koncie ma się pokazać pole hasła. Agenta sprawdzisz w Studio (etap 9).

## Etap 1a. Nowe funkcje: sekrety (15 min, gdy chcesz je włączyć)

Każdą funkcję włączasz osobno. Bez swojego sekretu po prostu czeka. Wpisujesz je w Supabase → Edge Functions → **Secrets**, nigdy w rozmowie.

| Funkcja | Sekrety | Skąd |
|---|---|---|
| Poranny mail do Ciebie i listy do rodziców | `SMTP_HOST` = `mail-serwer335689.lh.pl`, `SMTP_PORT` = `465`, `SMTP_USER` = `no-reply@audiokiddo.pl`, `SMTP_PASS` = hasło skrzynki, `MAIL_FROM` = `Szop’en z AudioKiddo <no-reply@audiokiddo.pl>`, `REPORT_TO` = Twój e-mail | skrzynka z kroku 14 w KROKI-DLA-DAWIDA |
| Kupujący ze sklepu w MailerLite | `MAILERLITE_BUYERS_GROUP` | `docs/marketing/NEWSLETTER.md` |
| Opinie z App Store | `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_APP_ID`, `ASC_PRIVATE_KEY` (cała treść pliku .p8) | App Store Connect → Użytkownicy i dostęp → Integracje → **App Store Connect API** → klucz z rolą „Customer Support”; `ASC_APP_ID` to „Apple ID” aplikacji w Informacjach o aplikacji |
| Opinie z Google Play | ten sam `GOOGLE_SERVICE_ACCOUNT_JSON` co do zakupów | konto usługi potrzebuje w Play Console uprawnienia „Odpowiadanie na opinie” |

Codzienna kopia bazy ustawia się w GitHubie, nie w Supabase: `docs/KOPIA-BAZY.md`.

Sprawdzenie: Studio → CRM → Ustawienia → „Wyślij poranny raport teraz” i „Przykładowy list do mnie”.

## Etap 2. Konta deweloperskie (czeka się na weryfikację, więc zacznij dziś)

Konta zakłada **Nela**, bo działalność to jej JDG. Przychód ze sklepów trafia wtedy do firmy. Ciebie dodaje jako użytkownika.

- [ ] 2.1 Apple Developer Program, 99 USD rocznie. Pełna lista kroków: `KROKI-DLA-DAWIDA.md`, krok 3.
  1. Nela instaluje aplikację **Apple Developer** na iPhonie i loguje się swoim Apple ID z włączonym 2FA.
  2. Account → **Enroll Now** → typ „Individual” (przy JDG Apple przyjmuje tylko taki), skan dowodu, płatność.
  3. Czeka na mail „Welcome to the Apple Developer Program”, zwykle do 48 godzin.
- [ ] 2.2 Google Play Console, 25 USD jednorazowo. Pełna lista kroków: `KROKI-DLA-DAWIDA.md`, krok 4.
  1. Wejdź na play.google.com/console/signup.
  2. Przy JDG wybierz konto organizacji z numerem D-U-N-S. Jeśli Google je odrzuci, załóż konto osobiste: wtedy obowiązuje test 12 osób przez 14 dni (krok 7.10).
  3. Przejdź weryfikację dowodu i telefonu z Androidem.
- [ ] 2.3 Po założeniu kont Nela zaprasza Ciebie:
  - App Store Connect → Użytkownicy i dostęp → **+**, rola „Administrator”;
  - Play Console → Użytkownicy i uprawnienia → Zaproś, uprawnienia administratora.

## Etap 3. Strony na audiokiddo.pl (1 h)

Sklepy wymagają tych adresów przed wysłaniem do recenzji. Gotowy kod jest w `docs/strona/sklepy/`.

- [ ] 3.1 Wyślij prawnikowi `docs/prawne/polityka-prywatnosci-aplikacji.md` i `docs/prawne/regulamin-aplikacji.md` (dzieci, RODO, subskrypcje). Opisz jeden abonament: 29,99 zł miesięcznie albo 269,99 zł rocznie (etap 6).
- [ ] 3.2 Załóż w WordPressie stronę **Polityka prywatności aplikacji**:
  1. Strony → Dodaj nową.
  2. Tytuł „Polityka prywatności aplikacji”, adres (slug) `polityka-prywatnosci-aplikacji`.
  3. Dodaj blok „Własny HTML” i wklej zawartość `polityka-prywatnosci-aplikacji.html`.
  4. Kliknij Opublikuj.
- [ ] 3.3 Tak samo strona **Kontakt**: slug `kontakt`, plik `kontakt-aplikacja.html`.
- [ ] 3.4 Tak samo strona **Usuwanie konta**: slug `usuwanie-konta`, plik `usuwanie-konta.html` (wymóg Google).
- [ ] 3.5 Strona **Regulamin aplikacji**: slug `regulamin`, tekst po akceptacji prawnika.
- [ ] 3.6 Otwórz wszystkie cztery adresy w przeglądarce w trybie prywatnym i sprawdź, że działają:
  - `https://audiokiddo.pl/polityka-prywatnosci-aplikacji/`
  - `https://audiokiddo.pl/kontakt/`
  - `https://audiokiddo.pl/usuwanie-konta/`
  - `https://audiokiddo.pl/regulamin/`

## Etap 4. Apple: aplikacja i podpisywanie (po etapie 2.1, ok. 1 h)

- [ ] 4.1 developer.apple.com/account → Certificates, IDs & Profiles → **Identifiers** → **+** → App IDs → App:
  - opis `AudioKiddo`, Bundle ID **Explicit** `pl.audiokiddo.app`;
  - zaznacz **In-App Purchase**, **Sign in with Apple**, **App Groups** → Continue → Register.
- [ ] 4.2 Identifiers → **+** → **App Groups** → identyfikator `group.pl.audiokiddo.app` → Register. Widżet czyta z niej plan dziecka.
- [ ] 4.3 Wróć do `pl.audiokiddo.app` → App Groups → Edit → zaznacz `group.pl.audiokiddo.app` → Save.
- [ ] 4.4 Identifiers → **+** → App IDs → `pl.audiokiddo.app.widget` (opis „AudioKiddo widżet”), zaznacz tylko **App Groups** i tę samą grupę.
- [ ] 4.5 Na Macu: Xcode → Settings → Accounts → **+** → Apple ID → zaloguj się (konto Neli albo Twoje, jeśli jesteś w zespole).
- [ ] 4.6 Otwórz `app/ios/Runner.xcworkspace` w Xcode:
  1. Po lewej kliknij **Runner** (niebieska ikona), potem cel **Runner** → zakładka **Signing & Capabilities**.
  2. Zaznacz *Automatically manage signing* i jako Team wybierz zespół Neli.
  3. Powtórz to samo dla celu **AudioKiddoWidget**.
  4. Jeśli Xcode pokaże czerwony błąd przy App Groups, kliknij „Try Again” albo „Register”.
- [ ] 4.7 W celu Runner sprawdź, czy są capabilities: **In-App Purchase**, **Sign in with Apple**, **App Groups**, **Background Modes → Audio**. Brakujące dodasz przyciskiem **+ Capability**.
- [ ] 4.8 appstoreconnect.apple.com → Aplikacje → **+** → Nowa aplikacja:
  - platforma iOS, nazwa **AudioKiddo**;
  - język podstawowy: polski;
  - Bundle ID `pl.audiokiddo.app`;
  - SKU `audiokiddo-ios`;
  - dostęp: pełny.
- [ ] 4.9 App Store Connect → **Biznes** (Umowy, podatki i bankowość):
  - zaakceptuj **Paid Apps**;
  - dodaj konto bankowe firmy;
  - wypełnij formularz podatkowy **W-8BEN** (polski NIP);
  - zadeklaruj status przedsiębiorcy (DSA).

  Bez tego zakupy nie działają nawet w testach.
- [ ] 4.10 App Store Connect → Twoja aplikacja → Informacje o aplikacji → **App Store Server Notifications**. Wersja 2, ten sam adres dla produkcji i sandboxa:
  `https://ypdxofcwewwdyoelamgy.supabase.co/functions/v1/store-notifications/apple`
  Potem kliknij „Wyślij powiadomienie testowe”.
- [ ] 4.11 Użytkownicy i dostęp → **Sandbox** → Testerzy → **+**: utwórz dwa konta testowe na adresy `kontakt.audiokiddo+sandbox1@gmail.com` i `kontakt.audiokiddo+sandbox2@gmail.com`. Hasła zapisz w aplikacji Hasła.
- [ ] 4.12 Supabase → Authentication → Sign In / Providers → **Apple** → włącz, w *Client IDs* wpisz `pl.audiokiddo.app` → Save.

## Etap 5. Android: klucz i podpisywanie (po etapie 2.2, 15 min)

- [ ] 5.1 W Terminalu wygeneruj klucz. Wymyśl mocne hasło, zapisz je w aplikacji Hasła, w kraju wpisz `PL`:
  ```
  "/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool" -genkey -v -keystore ~/audiokiddo-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
  ```
- [ ] 5.2 W TextEdit utwórz zwykły plik tekstowy `audiokiddo-app/app/android/key.properties` (Format → Utwórz zwykły tekst). Zamiast `HASLO` wpisz swoje hasło:
  ```
  storePassword=HASLO
  keyPassword=HASLO
  keyAlias=upload
  storeFile=/Users/dawidkubiak/audiokiddo-upload.jks
  ```
  Ten plik nie trafia do repozytorium.
- [ ] 5.3 Kopia zapasowa: zaszyfrowany obraz dysku (`KROKI-DLA-DAWIDA.md`, krok 5.3), do niego plik `.jks`, plus druga kopia na pendrivie.

## Etap 6. Produkty i ceny w obu sklepach (ok. 2 h)

**Ceny (strategia z 8.10.2026, jeden abonament, bez poziomów i bez limitu dzieci):**

| Plan | Cena |
|---|---|
| Miesięcznie | 29,99 zł |
| Rocznie (z góry) | 269,99 zł (około 22,50 zł miesięcznie) |

Identyfikatory muszą być **dokładnie** takie jak niżej (aplikacja i serwer już je znają).

**Subskrypcje (2 produkty):**

| ID | Nazwa | Okres | Cena |
|---|---|---|---|
| `pl.audiokiddo.sub.monthly` | AudioKiddo miesięcznie | 1 miesiąc | 29,99 zł |
| `pl.audiokiddo.sub.yearly` | AudioKiddo rocznie | 1 rok | 269,99 zł |

Do tego jednorazowe: 3 pakiety (49,99 / 49,99 / 69,99 zł) i 2 zestawy (89,99 / 159,99 zł), ceny jak na audiokiddo.pl. Pojedyncze zabawy na razie nie są w sklepie.

**Stan na 9.10.2026 (App Store Connect, konto Neli, Polska):** subskrypcje założone według tej tabeli; brakuje zrzutu ekranu do recenzji (dodaje się przy wysyłce pierwszej wersji). Pakiety i zestawy: patrz punkt 6.4.

**Apple (App Store Connect → Twoja aplikacja → Monetyzacja):**
- [x] 6.1 Subskrypcje → **Grupa subskrypcji** `AudioKiddo`.
- [x] 6.2 W grupie 2 subskrypcje z tabeli: identyfikator i czas, cena dla Polski, dostępność tylko Polska, lokalizacja (polski). Zrzut ekranu do recenzji: ekran Sklep z aplikacji. Bez oferty wprowadzającej.
- [ ] 6.4 Zakupy w aplikacji → **+** → *Bez odnawiania* (Non-Consumable): 3 pakiety i 2 zestawy z `WYDANIE.md` §5 (ceny jak na audiokiddo.pl, dostępność: Polska, kraj bazowy Polska/PLN).

**Google (Play Console → Zarabianie → Produkty):**

Google pokaże produkty dopiero po wgraniu pierwszego builda, więc najpierw krok 7.4, potem wróć tutaj.
- [ ] 6.5 **Subskrypcje** → Utwórz subskrypcję, **2 razy**, po jednej dla każdego ID z tabeli. W każdej:
  1. Dodaj jeden **abonament podstawowy**: automatyczne odnawianie, okres jak w tabeli, cena dla Polski.
  2. Aktywuj go.
  3. Bez oferty z okresem próbnym (decyzja ze strategii 8.10.2026: darmowe demonstracje zamiast próby z kartą).
- [ ] 6.6 **Produkty w aplikacji**: 3 pakiety i 2 zestawy z `WYDANIE.md` §5, każdy aktywny.
- [ ] 6.7 Konto usługi Google i Pub/Sub do sprawdzania zakupów: `KROKI-DLA-DAWIDA.md`, krok 7, punkty 1–8 (zakończone komendą `tool/set_store_secrets.sh`).

## Etap 7. Wersje testowe (po etapach 4–6)

**iPhone (TestFlight):**
- [ ] 7.1 Zbuduj wersję sklepową (sama ustawi pytanie z liczbą i ukryje pole kodów, czego wymaga Apple w kategorii Kids):
  ```
  tool/release_build.sh ios
  ```
- [ ] 7.2 Zainstaluj z Mac App Store aplikację **Transporter**. Zaloguj się Apple ID, przeciągnij plik `.ipa` z `app/build/ios/ipa/` i kliknij **Dostarcz**.
- [ ] 7.3 Po 10–30 minutach build pojawi się w App Store Connect → **TestFlight**. Wtedy:
  1. Uzupełnij „Informacje o testach” (opis po polsku, e-mail).
  2. Na pytanie o szyfrowanie odpowiedz: tylko standardowe (HTTPS).
  3. Dodaj testerów wewnętrznych: siebie i Nelę.

**Android (test wewnętrzny):**
- [ ] 7.4 Zbuduj pakiet:
  ```
  tool/release_build.sh android
  ```
- [ ] 7.5 Play Console → Testowanie → **Testy wewnętrzne** → Utwórz wersję:
  1. Przy pierwszym razie zostaw włączone **Play App Signing**.
  2. Wgraj `app/build/app/outputs/bundle/release/app-release.aab`.
  3. Nazwa wersji `0.2.0`, opis „Pierwsza wersja testowa”.
  4. Zapisz → Sprawdź → Wdróż.
- [ ] 7.6 Testerzy → utwórz listę e-maili (Ty, Nela). Skopiuj link do testu i otwórz go na telefonie z Androidem.

**Co sprawdzić na obu telefonach** (zakupy na koncie sandbox i licencji testowej, nic nie płacisz):
- [ ] 7.7 Rejestracja nowego konta:
  - e-mail → „Dalej” → hasło → kod z maila;
  - samouczek Szop’ena;
  - pytania o dziecko;
  - ekran mikrofonu (obie zgody);
  - przypomnienia.
- [ ] 7.8 Zakupy:
  - abonament roczny z próbą 7 dni;
  - zmiana okresu (Więcej → Zarządzaj subskrypcją → Zmień okres);
  - „Przywróć zakupy” po ponownej instalacji;
  - zakup jednego pakietu.
- [ ] 7.9 Odtwarzanie:
  - zabawa w tle przy zablokowanym ekranie;
  - wybór głośnika Bluetooth w odtwarzaczu;
  - zabawa głosowa z mikrofonem;
  - tryb dziecka i wyjście z niego (pytanie z liczbą);
  - widżet na ekranie głównym i na ekranie blokady.
- [ ] 7.10 Tylko przy **osobistym** koncie Google: test zamknięty z co najmniej 12 testerami przez 14 dni bez przerwy (Testowanie → Testy zamknięte). Dopiero potem da się wysłać wersję produkcyjną.

## Etap 8. Karty w sklepach i wysłanie do recenzji

Teksty do wklejenia są w `docs/SKLEPY.md`.

**App Store Connect → aplikacja → wersja 1.0:**
- [ ] 8.1 Zrzuty ekranu 6,9″ (1320 × 2868), 4–8 sztuk według listy w `SKLEPY.md`. Mogę je zrobić na symulatorze, napisz „zrób zrzuty”.
- [ ] 8.2 Wklej z `SKLEPY.md`: tekst promocyjny, opis, słowa kluczowe, adres wsparcia `https://audiokiddo.pl/kontakt/` i adres marketingowy `https://audiokiddo.pl`.
- [ ] 8.3 Wybierz build z TestFlight.
- [ ] 8.4 Informacje o aplikacji:
  - kategoria **Edukacja**, druga **Rozrywka**;
  - **Kids Category: 6–8 lat** (rekomendacja; po wydaniu trudno zmienić);
  - klasyfikacja wiekowa: wszędzie „Brak”;
  - polityka prywatności: `https://audiokiddo.pl/polityka-prywatnosci-aplikacji/`.
- [ ] 8.5 **Prywatność aplikacji**: zaznacz dokładnie tabelę z `SKLEPY.md` (e-mail, identyfikator, zakupy, interakcje; brak śledzenia).
- [ ] 8.6 **Informacje o recenzji aplikacji**:
  - konto demo: e-mail i hasło konta testowego. Załóż je w aplikacji i nadaj mu dostęp komendą `tool/grant_test_access.sh`; zapytaj mnie, jeśli nie pamiętasz jak;
  - notatka po angielsku z `SKLEPY.md`.
- [ ] 8.7 Subskrypcje i zakupy z etapu 6: przy pierwszej wersji zaznacz je do recenzji razem z aplikacją (sekcja „Zakupy w aplikacji i subskrypcje” na stronie wersji).
- [ ] 8.8 Kliknij **Dodaj do recenzji** → **Prześlij do recenzji**. Recenzja trwa zwykle 1–3 dni.

**Play Console:**
- [ ] 8.9 Zasady i programy → **Zawartość aplikacji**. Każdą pozycję wypełnij według `SKLEPY.md`:
  - polityka prywatności;
  - reklamy: nie;
  - dostęp do aplikacji: konto testowe jak w 8.6;
  - klasyfikacja treści IARC;
  - grupa docelowa: dzieci 5 i mniej, 6–8, 9–12 (program Families);
  - bezpieczeństwo danych (Data safety);
  - identyfikator reklamowy: nie;
  - usługa na pierwszym planie `mediaPlayback` z krótkim nagraniem ekranu: zabawa gra przy zablokowanym ekranie;
  - usuwanie konta: `https://audiokiddo.pl/usuwanie-konta/`.
- [ ] 8.10 Obecność w sklepie → **Główna strona aplikacji**:
  - krótki i pełny opis z `SKLEPY.md`;
  - ikona 512 × 512 (`app/assets/icon/` albo napisz, przygotuję);
  - grafika 1024 × 500;
  - zrzuty telefonu.
- [ ] 8.11 Produkcja → Utwórz wersję → ten sam `.aab` (albo „Promuj wersję” z testów) → kraj: Polska → **Wyślij do sprawdzenia**.

**Możliwe pytania recenzentów i odpowiedzi:**
- *Logowanie przed użyciem* (Apple 5.1.1). Jeśli Apple zakwestionuje, że darmowe zabawy wymagają konta, odpisz: konto rodzica trzyma plan dziecka i zakupy na wielu urządzeniach. Jeśli to nie wystarczy, napisz mi, a otworzę darmowe zabawy bez logowania.
- *Bramka rodzica* (Apple 1.3). W wersji iOS pytanie z liczbą jest przed zakupami i linkami, ustawia to `tool/release_build.sh`. Opis jest w notatce dla recenzenta.
- *Kody prezentowe* (Apple 3.1.1). W wersji iOS pole kodu jest ukryte, kody działają przez stronę i na Androidzie.

## Etap 9. Studio i CRM w przeglądarce (30 min, można od razu)

- [ ] 9.1 Zbuduj Studio:
  ```
  bash tool/studio_build.sh
  ```
- [ ] 9.2 W FileZilli połącz się z LH.pl i wgraj **zawartość** folderu `studio/build/web` (nie sam folder) do `public_html/studio`. Na pytanie o nadpisanie wybierz „Nadpisz”.
- [ ] 9.3 Wejdź na `https://audiokiddo.pl/studio/` → zakładka CRM → zaloguj się kodem z maila. Konto musi być w tabeli `admins`; jeśli nie wpuszcza, napisz mi.
- [ ] 9.4 CRM → **Decyzje** → „Raport COO”. Gdy pojawi się raport, klucz z kroku 1.4 działa.
- [ ] 9.5 Opcjonalnie MailerLite: klucz API w Supabase → Edge Functions → Secrets jako `MAILERLITE_API_KEY`, a `MAILERLITE_FROM` = `kontakt@audiokiddo.pl`.

## Etap 10. Reklamy, Pixel i Analytics (gdy zaczynasz kampanie)

Pełna instrukcja: `docs/REKLAMY.md`. W skrócie:

- [ ] 10.1 Na audiokiddo.pl zainstaluj wtyczki (WordPress → Wtyczki → Dodaj nową):
  - **Meta for WooCommerce** (Pixel z Conversions API);
  - **Site Kit by Google** (Analytics 4);
  - baner zgód **Complianz** z trybem zgody Google.
- [ ] 10.2 Meta: utwórz użytkownika systemu i token. W Supabase → Secrets wpisz `META_ACCESS_TOKEN`, `META_AD_ACCOUNT_ID` i `META_PIXEL_ID`.
- [ ] 10.3 Google: klient OAuth i refresh token z OAuth Playground oraz token programisty Google Ads. W Secrets wpisz klucze `GOOGLE_…` i `GA4_PROPERTY_ID`.
- [ ] 10.4 Studio → CRM → **Kampanie** → „Pobierz dane teraz”. Kafelki źródeł mają się zazielenić.
- [ ] 10.5 Ustaw **Limity agenta** (maksymalny budżet dzienny, maksymalna zmiana naraz, docelowy koszt zakupu). Od następnego ranka agent sam robi przegląd, a propozycje czekają na Twoje „Zatwierdzam i wprowadź”.

## Etap 11. Dzień premiery

- [ ] 11.1 Po akceptacji Apple: wersja → „Wydaj tę wersję” (albo wydanie automatyczne ustawione w 8.8).
- [ ] 11.2 Google: po akceptacji wersja produkcyjna wychodzi sama, jeśli nie włączysz publikacji zarządzanej.
- [ ] 11.3 Supabase → Settings → Billing: przejdź na plan **Pro** (25 USD miesięcznie). Darmowy usypia projekt po tygodniu bez ruchu.
- [ ] 11.4 Na audiokiddo.pl dodaj przyciski App Store i Google Play (sekcja `docs/strona/sekcja-aplikacja.html`).
- [ ] 11.5 Newsletter o premierze: Studio → CRM → Decyzje → „Newsletter” z wskazówką „premiera aplikacji”, potem „Szkic w MailerLite”.
- [ ] 11.6 Przez pierwszy tydzień codziennie zaglądaj do Studio → Serwer → Statystyki (instalacje, ukończenia, zakupy) i do recenzji w sklepach.

## Przy każdej kolejnej wersji

1. Podbij `version` w `app/pubspec.yaml`, np. `0.2.1+3`. Numer po `+` musi rosnąć.
2. `tool/release_build.sh ios` i `tool/release_build.sh android`.
3. Wyślij: Transporter dla Apple, Play Console dla Google.
4. Wpisz „Co nowego” po polsku i wyślij do recenzji.

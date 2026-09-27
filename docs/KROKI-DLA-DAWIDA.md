# AudioKiddo: co masz zrobić, krok po kroku

Stan: 2026-09-27. Kolejność ma znaczenie: najpierw rzeczy, na które się czeka (weryfikacja kont), potem reszta. Przy każdym kroku: ile to trwa, co mi potem napisać i czego **nigdy** nie wklejać do rozmowy.

**Zasada sekretów.** Hasła, klucze `.p8` i `.json`, `service_role` / `secret key`, `cs_…` z WooCommerce, sekret webhooka i hasła do klucza Androida trzymasz w menedżerze haseł. Do serwera trafiają przez komendy wpisane w **Twoim** terminalu. Mnie wystarczą identyfikatory (np. ID projektu, ID produktów), a przy każdym kroku piszę, które to.

---

## Krok 0. Porządek na start (15 min, dzisiaj)

1. **E-mail do kont:** używaj jednego, np. `kontakt.audiokiddo@gmail.com`. Włącz w nim weryfikację dwuetapową.
2. **Menedżer haseł:** aplikacja **Hasła** w macOS (Cmd+Spacja → „Hasła”; to osobna aplikacja, nie Ustawienia systemowe). Plik → **Nowa udostępniona grupa** „AudioKiddo”, dodaj Nelę. Pliki kluczy (`.jks`, `.p8`, `.json`) trzymaj w zaszyfrowanym obrazie dysku (krok 5), bo aplikacja Hasła nie przechowuje plików.
3. **Dane firmy pod ręką:** pełna nazwa, NIP, REGON, adres z CEIDG/KRS, telefon, numer konta (IBAN) i kod SWIFT banku.
4. ✅ Narzędzia Maca zaktualizowane, Supabase CLI i GitHub CLI zainstalowane (2026-09-27).

## Krok 1. Decyzja: konto firmowe czy prywatne

To decyduje, czyje nazwisko zobaczą klienci w sklepie.

| Twoja forma działalności | Apple | Google |
|---|---|---|
| **Spółka** (np. sp. z o.o.) | konto **organizacji**, potrzebny numer D-U-N-S | konto **organizacji**, D-U-N-S |
| **Jednoosobowa działalność (JDG)**, u nas: JDG Neli | konto **indywidualne** (Apple przyjmuje JDG tylko jako osobę; w sklepie widać imię i nazwisko) | spróbuj konta organizacji z D-U-N-S; jeśli Google odrzuci, konto osobiste |

**D-U-N-S** (bezpłatny): sprawdź lub zamów na developer.apple.com/enroll/duns-lookup. Czeka się do ok. 2 tygodni, więc zamów od razu, jeśli go potrzebujesz.

**Nasz przypadek:** działalność to JDG „Biznesowelove Nela Mariak”, więc konta sklepów zakłada **Nela** (jej Apple ID, jej dowód, konto bankowe firmy), a Ciebie dodaje jako użytkownika. Inaczej przychód ze sklepów trafiałby do Ciebie prywatnie, a nie do firmy. Do księgowej: rejestracja **VAT-UE** (wypłaty przychodzą od irlandzkich spółek Apple i Google, czyli to usługa dla firmy z UE) i dopisanie PKD wydawania oprogramowania (58.21.Z / 58.29.Z).

Konto osobiste w Google ma dodatkowy wymóg: przed publikacją 12 testerów przez 14 dni bez przerwy (patrz krok 9).

Unijny akt o usługach cyfrowych (DSA): oba sklepy każą zadeklarować status „przedsiębiorcy” i **publicznie** pokazują adres, telefon i e-mail. Przy JDG to adres z CEIDG. Jeśli nie chcesz pokazywać domowego adresu, rozważ adres biura lub wirtualnego biura.

## Krok 2. Supabase, czyli serwer (20 min, dzisiaj, za darmo)

1. Wejdź na **supabase.com → Start your project**, zarejestruj się e-mailem z kroku 0 i włącz 2FA (Account → Security).
2. **New organization:** nazwa `AudioKiddo`, plan **Free**.
3. **New project:**
   - nazwa `audiokiddo`;
   - **Region: Central EU (Frankfurt)** (ważne dla RODO, później nie da się zmienić);
   - hasło bazy: kliknij „Generate a password” i **zapisz w menedżerze haseł**.
4. Umowa powierzenia danych (RODO): Organization → Settings → Legal Documents → **DPA**. Podpisz ją i zachowaj PDF.
5. **Napisz mi:** „Supabase gotowy” i **Project ref**. To ciąg ok. 20 liter z adresu `https://supabase.com/dashboard/project/<ref>`, nie jest tajny.
   **Nie wysyłaj:** hasła bazy ani klucza `service_role` / `secret`.
6. Potem, gdy zainstaluję CLI, wpiszesz w swoim terminalu dwie komendy (dam Ci je gotowe): `supabase login` i `supabase link`. Dalej wdrażam ja.

Plan darmowy wystarczy do budowy. Uwaga: darmowy projekt usypia się po tygodniu bez ruchu (budzi się jednym kliknięciem). Przed publikacją przejdziemy na **Pro za 25 USD/mies. (ok. 100 zł)**.

## Krok 3. Apple Developer Program (1–3 dni, 99 USD rocznie)

1. Na iPhonie lub Macu zainstaluj aplikację **Apple Developer** z App Store. Zaloguj się Apple ID (e-mail z kroku 0, z włączonym 2FA).
2. **Account → Enroll Now.** Wybierz typ z kroku 1, zeskanuj dowód osobisty, podaj dane i zapłać. Przy koncie organizacji podajesz D-U-N-S, a Apple może zadzwonić, żeby potwierdzić.
3. Poczekaj na e-mail „Welcome to the Apple Developer Program” (zwykle do 48 h).
4. **App Store Connect** (appstoreconnect.apple.com) → **Business / Umowy**:
   - zaakceptuj umowę **Paid Apps**;
   - dodaj konto bankowe;
   - wypełnij formularz podatkowy USA: **W-8BEN** (osoba / JDG) lub **W-8BEN-E** (spółka), z polskim NIP-em; umowa PL–USA obniża podatek;
   - zadeklaruj status przedsiębiorcy (DSA).

   Bez tego zakupy nie działają nawet w testach.
5. **Certificates, IDs & Profiles** (developer.apple.com/account) → Identifiers → **+** → App IDs → App. Opis: `AudioKiddo`, Bundle ID **Explicit**: `pl.audiokiddo.app`, zostaw zaznaczone „In-App Purchase”.
6. **App Store Connect → Aplikacje → + → Nowa aplikacja:**
   - platforma iOS, nazwa **AudioKiddo**;
   - język główny: **polski**;
   - Bundle ID: `pl.audiokiddo.app`;
   - SKU: `audiokiddo-ios`.
7. **Użytkownicy i dostęp:** zaproś Nelę (rola „Menedżer aplikacji”).
8. **Użytkownicy i dostęp → Sandbox → Testerzy:** utwórz 2 konta testowe na adresy, których nie używasz w Apple, np. `kontakt.audiokiddo+sandbox1@gmail.com` (Gmail dostarczy to na Twoją skrzynkę). Hasła do menedżera.
9. **Xcode → Settings → Accounts → +:** zaloguj się tym samym Apple ID.
10. **Napisz mi:** „Apple gotowe” i **Team ID** (Membership details, 10 znaków, nie jest tajny).

Klucze do serwera (klucz zakupów `.p8`) i produkty zrobimy w kroku 7, gdy serwer będzie gotowy.

## Krok 4. Google Play Console (1–7 dni, 25 USD jednorazowo)

1. Wejdź na **play.google.com/console/signup**, zaloguj się kontem Google z kroku 0 i wybierz typ konta z kroku 1.
2. Podaj dane, zapłać 25 USD i przejdź **weryfikację tożsamości** (dowód; przy organizacji także D-U-N-S i dokumenty firmy). Potwierdź telefon i e-mail.
3. Google każe potwierdzić dostęp do **fizycznego telefonu z Androidem**: zainstaluj na nim aplikację **Google Play Console** i zaloguj się.
4. **Ustawienia → Profil płatności:** utwórz konto sprzedawcy (dane firmy, konto bankowe). Google sam rozlicza VAT od sprzedaży klientom w UE.
5. **Wszystkie aplikacje → Utwórz aplikację:**
   - nazwa **AudioKiddo**;
   - język domyślny: polski;
   - typ: aplikacja (nie gra);
   - **bezpłatna** (zakupy są w środku);
   - zaakceptuj deklaracje.
6. **Użytkownicy i uprawnienia:** zaproś Nelę.
7. **Napisz mi:** „Google gotowe”.

Produkty w Google da się dodać dopiero po wgraniu pierwszego builda (krok 6).

## Krok 5. Klucz do podpisywania Androida (10 min, po kroku 4)

1. W swoim terminalu (program zapyta o hasło: wymyśl mocne i zapisz w menedżerze; imię, firma, kraj `PL`):

```bash
"/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool" -genkey -v -keystore ~/audiokiddo-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. Utwórz plik `audiokiddo-app/app/android/key.properties` (np. w TextEdit, zapis jako zwykły tekst) z czterema liniami, z Twoim hasłem w miejsce `HASLO`:

```
storePassword=HASLO
keyPassword=HASLO
keyAlias=upload
storeFile=/Users/dawidkubiak/audiokiddo-upload.jks
```

3. Zrób zaszyfrowany „sejf” na pliki kluczy (poda hasło, zapisz je w aplikacji Hasła), przenieś do niego `audiokiddo-upload.jks` i trzymaj drugą kopię na pendrivie:

```bash
hdiutil create -size 100m -encryption AES-256 -fs APFS -volname AudioKiddoKlucze ~/Documents/AudioKiddoKlucze.dmg
```
4. **Napisz mi:** „klucz gotowy”. Zbuduję pakiet `.aab` i sprawdzę podpis, nie zaglądając do hasła.

## Krok 6. Pierwszy build testowy w sklepach (ze mną, ok. 1 h)

Zrobimy to razem, po krokach 3–5:
- **Google:** wgrywasz `.aab` do Testy → Testy wewnętrzne. Przy pierwszym wgraniu włącz **Play App Signing** (domyślne). Dodaj siebie i Nelę jako testerów.
- **Apple:** buduję `.ipa`, a Ty wysyłasz go aplikacją **Transporter** (z App Store) albo ja przez Xcode na Twoim zalogowanym koncie. Build pojawi się w TestFlight.

## Krok 7. Produkty i klucze sklepów do serwera (ok. 1–2 h)

**Produkty** (32 pozycje: 2 subskrypcje, 3 pakiety, 2 zestawy, 25 pojedynczych zabaw) są w tabeli w `docs/WYDANIE.md` §5. Dwie drogi:
- ręcznie w obu panelach (ok. 2 h);
- albo napiszę skrypt, który **Ty** uruchomisz w swoim terminalu z kluczem API na dysku. Klucz nie trafi do rozmowy.

Ustawienia subskrypcji: grupa „AudioKiddo”, plany 24,99 zł/mies. i 149,99 zł/rok, **oferta wstępna 7 dni za darmo** na obu. Kraj: Polska.

**Apple, klucz do sprawdzania zakupów:**
1. App Store Connect → Użytkownicy i dostęp → Integracje → **Zakup w aplikacji** → Wygeneruj klucz.
2. Pobierz plik `.p8`. Da się to zrobić **tylko raz**, więc od razu zapisz go w menedżerze.
3. **Napisz mi:** Key ID i Issuer ID (nie są tajne). Plik `.p8` wgrasz komendą, którą Ci dam.
4. Adres powiadomień serwera (App Store Server Notifications, wersja 2) podam, gdy funkcja będzie wdrożona.

**Google, konto usługi do sprawdzania zakupów:**
1. **console.cloud.google.com:** nowy projekt `audiokiddo`. Włącz „Google Play Android Developer API” i „Cloud Pub/Sub API”.
2. IAM → **Konta usługi** → Utwórz: nazwa `audiokiddo-server`, bez ról. Potem Klucze → Dodaj klucz → JSON. Plik zapisz w menedżerze.
3. **Play Console → Użytkownicy i uprawnienia → Zaproś:** e-mail konta usługi (`audiokiddo-server@….iam.gserviceaccount.com`), uprawnienia „Wyświetlanie danych finansowych” i „Zarządzanie zamówieniami i subskrypcjami”.
4. **Pub/Sub → Tematy → Utwórz** `play-notifications`. W uprawnieniach tematu dodaj `google-play-developer-notifications@system.gserviceaccount.com` z rolą „Publikujący Pub/Sub”.
5. Play Console → Zarabianie → Konfiguracja zarabiania: wpisz pełną nazwę tematu `projects/<id-projektu>/topics/play-notifications`.
6. **Napisz mi:** ID projektu Google Cloud i e-mail konta usługi (nie są tajne).

## Krok 8. WooCommerce na audiokiddo.pl (15 min, można już teraz)

1. **ID produktów:** WordPress → Produkty. Po najechaniu na produkt widać „ID: 1234”. **Napisz mi** ID trzech pakietów i dwóch zestawów, z nazwami. Nie są tajne.
2. **Klucz tylko do odczytu:**
   - WooCommerce → Ustawienia → Zaawansowane → REST API → **Dodaj klucz**;
   - opis `AudioKiddo aplikacja`, użytkownik: Ty, uprawnienia: **Odczyt**;
   - `ck_…` i `cs_…` pokazują się **raz**, więc zapisz oba w menedżerze.
3. **Sekret webhooka:** w swoim terminalu wygeneruj losowy ciąg i zapisz go w menedżerze:

```bash
openssl rand -hex 32
```

4. **Webhook** założymy razem po kroku 2, bo potrzebny jest adres funkcji:
   - Zaawansowane → Webhooki → Dodaj;
   - status „Aktywny”, temat **Zamówienie zaktualizowane**;
   - adres `https://<ref>.functions.supabase.co/woo-webhook`;
   - sekret z punktu 3, wersja API: WP REST API v3.
5. Klucze wpisujesz w swoim terminalu jedną komendą `supabase secrets set …` (gotowa w `supabase/README.md`).

## Krok 9. Testerzy (zacznij zbierać od razu)

- **Konto osobiste w Google:** potrzebne **12 osób**, które przez **14 dni** mają aplikację z testu zamkniętego. Najprościej: grupa Google (groups.google.com) „AudioKiddo testerzy” i lista rodzin ze znajomych lub klientów. Każdy potrzebuje konta Google i Androida.
- **iPhone:** TestFlight, do 100 osób z e-maila, bez recenzji Apple. Tester instaluje aplikację **TestFlight**.
- Poproś testerów o zgodę na krótką ankietę po tygodniu.

## Krok 10. Materiały (wrzuć do folderu `Desktop/claude folder/AudioKiddo-materialy/`)

| Co | Format | Uwagi |
|---|---|---|
| Logo | SVG, AI albo PDF (wektor) + PNG | wersja pozioma i sam znak |
| Ikona aplikacji | PNG 1024×1024, **bez przezroczystości i bez zaokrągleń** | mogę ją przygotować z logo |
| Okładki zabaw | kwadrat, min. 1400×1400 px | 25 zabaw + piosenki; mogą być te ze strony |
| Postacie (Max, Mila i inne) | PNG z przezroczystością lub wektor | do ekranów i trybu dziecka |
| Nagrania zabaw | WAV albo MP3 320 kb/s | tak jak w pakietach na stronie |
| Piosenki | WAV albo MP3 320 kb/s + tytuły | |
| Kwestie lektora do nowych gier | lista w `docs/NAGRANIA-DO-GIER.md` | nagrać według tej listy |
| Akta Detektywa do druku | PDF | te, które klienci dostają ze strony |

**Napisz mi**, co wrzuciłeś. Zajmę się konwersją, nazwami i wgraniem do Studio.

## Krok 11. Prawo i strony www

1. Wyślij prawnikowi szkice z `docs/prawne/`: politykę prywatności aplikacji i regulamin. Dotyczą dzieci, RODO i subskrypcji, więc sprawdzenie jest konieczne.
2. Po akceptacji opublikuj na audiokiddo.pl cztery strony (mogę przygotować gotowy kod pod WordPress):
   - polityka prywatności aplikacji;
   - regulamin aplikacji;
   - **usuwanie konta i danych** (wymóg Google);
   - kontakt/wsparcie.
3. **Napisz mi** ich adresy.

## Krok 12. Telefony do testów

**Android** (mikrofon w grach, Bluetooth, TalkBack):
1. Ustawienia → Informacje o telefonie → **7 razy stuknij „Numer kompilacji”**.
2. Ustawienia → System → Opcje programisty → włącz **Debugowanie USB**.
3. Podłącz kablem do Maca i na telefonie zaakceptuj „Zezwolić na debugowanie?”.
4. Napisz mi.

**iPhone** (po kroku 3):
1. Podłącz do Maca kablem, na telefonie „Ufaj temu komputerowi”.
2. Ustawienia → Prywatność i ochrona → **Tryb dewelopera** → włącz (telefon się zrestartuje).
3. Napisz mi.

## Krok 13. GitHub (opcjonalnie, 10 min, po kroku 0)

1. Załóż konto na github.com (e-mail z kroku 0, 2FA).
2. W swoim terminalu wpisz poniższą komendę i przejdź logowanie w przeglądarce:

```bash
gh auth login
```

3. Napisz mi. Utworzę **prywatne** repozytorium i wyślę kod, a testy zaczną się uruchamiać automatycznie.

---

## Kolejność w skrócie

| Kiedy | Co |
|---|---|
| **Dziś** | 0 (narzędzia), 1 (decyzja + D-U-N-S), 2 (Supabase), 3 i 4 (zapisy do Apple i Google, bo czeka się na weryfikację), 8 (ID produktów, klucz Woo), 12 (telefon z Androidem) |
| **W tym tygodniu** | 10 (materiały), 11 (prawnik), 9 (lista testerów), 13 (GitHub) |
| **Po weryfikacji kont** | 5 (klucz Androida), 6 (pierwszy build), 7 (produkty i klucze sklepów) |
| **Na koniec** | 14 dni testu zamkniętego (przy koncie osobistym w Google), formularze sklepów z `docs/SKLEPY.md`, wysyłka do recenzji |

Równolegle, gdy tylko dostanę Supabase, kończę Etap 3: konto rodzica, sprawdzanie zakupów na serwerze i połączenie Studio z serwerem.

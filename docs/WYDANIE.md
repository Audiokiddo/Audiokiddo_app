# AudioKiddo: wydanie w App Store i Google Play

Stan: 2026-09-27. Lista kroków od założenia kont do publikacji. Punkty oznaczone **Dawid** wymagają Twojego konta, danych firmy albo haseł, więc robisz je sam. Hasła, klucze i certyfikaty wpisujesz tylko we własnym terminalu lub w panelach sklepów, nigdy w rozmowie.

## 1. Konta deweloperskie (Dawid)

| | Apple Developer Program | Google Play Console |
|---|---|---|
| Koszt | 99 USD rocznie | 25 USD jednorazowo |
| Typ konta | firma (organizacja) albo osoba prywatna | firma (organizacja) albo osoba prywatna |
| Na firmę potrzebne | numer D-U-N-S (bezpłatny, czeka się do ok. 2 tygodni), strona firmy, firmowy e-mail | numer D-U-N-S, weryfikacja firmy |
| Nazwa sprzedawcy w sklepie | nazwa firmy (albo imię i nazwisko przy koncie prywatnym) | nazwa dewelopera z konta |

**Zalecenie: konta firmowe.** Nazwa sprzedawcy będzie nazwą firmy, a nie Twoim nazwiskiem. Na Google Play nowe konto **prywatne** musi też przed publikacją przejść test zamknięty: co najmniej 12 testerów przez 14 dni bez przerwy. Konto firmowe tego nie wymaga.

Po założeniu kont:
- **App Store Connect → Umowy, podatki i bankowość:** zaakceptować umowę „Paid Apps”, podać konto bankowe i formularze podatkowe. Bez tego zakupy nie działają nawet w testach.
- **Play Console → Profil płatności:** połączyć konto sprzedawcy (Google Payments).
- Dodać Nelę jako użytkownika w obu panelach (rola: administrator lub marketing, według potrzeb).

## 2. Identyfikatory (ustalone, nie do zmiany po pierwszym wydaniu)

| Co | Wartość |
|---|---|
| Nazwa w sklepach | AudioKiddo |
| Identyfikator iOS (Bundle ID) | `pl.audiokiddo.app` |
| Identyfikator Androida (applicationId) | `pl.audiokiddo.app` |
| Wersja | w `app/pubspec.yaml`, pole `version: 0.1.0+1` (numer po `+` rośnie przy każdym wysłaniu) |
| Minimalne systemy | iOS 15, Android zgodnie z Flutterem (API 24) |

## 3. Podpisywanie Androida (Dawid, jednorazowo)

Google Play wymaga podpisania pakietu. Używamy **Play App Signing**: Google przechowuje klucz aplikacji, a my mamy tylko klucz przesyłania (upload key). Zgubiony klucz przesyłania da się zresetować przez pomoc Google.

1. Wygeneruj klucz we własnym terminalu. Program zapyta o hasło i dane (imię, firma, kraj PL):

```bash
keytool -genkey -v -keystore ~/audiokiddo-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. Utwórz plik `app/android/key.properties` (jest w `.gitignore`, nie trafi do repozytorium) z czterema liniami:

```
storePassword=<hasło z kroku 1>
keyPassword=<hasło z kroku 1>
keyAlias=upload
storeFile=/Users/dawidkubiak/audiokiddo-upload.jks
```

3. Zrób kopię zapasową pliku `.jks` i haseł w menedżerze haseł (np. Pęk kluczy / 1Password). Nie w chmurze bez szyfrowania i nie w repozytorium.

4. Zbuduj pakiet dla sklepu:

```bash
cd app && flutter build appbundle --release
```

Wynik: `app/build/app/outputs/bundle/release/app-release.aab`. Bez pliku `key.properties` build podpisze się kluczem debug i Play Console go odrzuci (tak jest ustawione w `app/android/app/build.gradle.kts`, sprawdzone kluczem testowym 2026-09-27).

## 4. Podpisywanie iOS (Dawid, jednorazowo)

1. Xcode → Settings → Accounts: zaloguj się kontem Apple Developer.
2. Otwórz `app/ios/Runner.xcworkspace`, cel **Runner → Signing & Capabilities**: zaznacz „Automatically manage signing” i wybierz zespół (Team). Xcode sam utworzy certyfikat i profil.
3. W tym samym miejscu dodaj funkcję **In-App Purchase**. „Background Modes → Audio” jest już ustawione.
4. W App Store Connect utwórz aplikację: nazwa AudioKiddo, język główny polski, Bundle ID `pl.audiokiddo.app`, SKU np. `audiokiddo-ios`.

Build do wysłania:

```bash
cd app && flutter build ipa --release
```

Wysyłka: aplikacja **Transporter** (z App Store) albo Xcode → Organizer → Distribute App. Po kilkunastu minutach build pojawi się w TestFlight.

## 5. Produkty w sklepach

Identyfikatory muszą być **identyczne** w App Store Connect, Play Console i w aplikacji (`app/lib/features/purchases/offer_catalog.dart`, katalog treści). Ceny jak na audiokiddo.pl, pojedyncze zabawy tańsze, żeby pakiet był bardziej opłacalny.

| ID produktu | Typ | Nazwa | Cena |
|---|---|---|---|
| `pl.audiokiddo.sub.monthly` | Subskrypcja auto-odnawialna (grupa „AudioKiddo”) | AudioKiddo miesięcznie | 24,99 zł, oferta wstępna: 7 dni za darmo |
| `pl.audiokiddo.sub.yearly` | Subskrypcja auto-odnawialna (grupa „AudioKiddo”) | AudioKiddo rocznie | 149,99 zł, oferta wstępna: 7 dni za darmo |
| `pl.audiokiddo.pack.wyobraznia` | Jednorazowy (non-consumable) | Pakiet Wyobraźnia | 49,99 zł |
| `pl.audiokiddo.pack.slowa_i_wiedza` | Jednorazowy (non-consumable) | Pakiet Słowa i Wiedza | 49,99 zł |
| `pl.audiokiddo.pack.detektyw` | Jednorazowy (non-consumable) | Pakiet Detektyw | 69,99 zł |
| `pl.audiokiddo.bundle.two` | Jednorazowy (non-consumable) | Zestaw 2 pakietów (Wyobraźnia + Słowa i Wiedza) | 89,99 zł |
| `pl.audiokiddo.bundle.three` | Jednorazowy (non-consumable) | Zestaw 3 pakietów | 159,99 zł |
| `pl.audiokiddo.item.magiczny_sklep` | Jednorazowy (non-consumable) | Magiczny sklep | 9,99 zł |
| `pl.audiokiddo.item.zaginiony_skarb` | Jednorazowy (non-consumable) | Zaginiony skarb | 9,99 zł |
| `pl.audiokiddo.item.podroz_na_inna_planete` | Jednorazowy (non-consumable) | Podróż na inną planetę | 9,99 zł |
| `pl.audiokiddo.item.wymysl_znaczenie` | Jednorazowy (non-consumable) | Wymyśl znaczenie | 9,99 zł |
| `pl.audiokiddo.item.mikstura` | Jednorazowy (non-consumable) | Mikstura | 9,99 zł |
| `pl.audiokiddo.item.moj_superbohater` | Jednorazowy (non-consumable) | Mój superbohater | 9,99 zł |
| `pl.audiokiddo.item.dokoncz_historie` | Jednorazowy (non-consumable) | Dokończ historię | 9,99 zł |
| `pl.audiokiddo.item.mistrz_kuchni` | Jednorazowy (non-consumable) | Mistrz kuchni | 9,99 zł |
| `pl.audiokiddo.item.magiczny_teatr` | Jednorazowy (non-consumable) | Magiczny teatr | 9,99 zł |
| `pl.audiokiddo.item.co_oni_odpowiedzieli` | Jednorazowy (non-consumable) | Co oni odpowiedzieli? | 9,99 zł |
| `pl.audiokiddo.item.co_to_za_przedmiot` | Jednorazowy (non-consumable) | Co to za przedmiot? | 9,99 zł |
| `pl.audiokiddo.item.co_to_za_dzwiek` | Jednorazowy (non-consumable) | Co to za dźwięk? | 9,99 zł |
| `pl.audiokiddo.item.szybkie_skojarzenia` | Jednorazowy (non-consumable) | Szybkie skojarzenia | 9,99 zł |
| `pl.audiokiddo.item.co_tu_nie_pasuje` | Jednorazowy (non-consumable) | Co tu nie pasuje? | 9,99 zł |
| `pl.audiokiddo.item.wymien_trzy` | Jednorazowy (non-consumable) | Wymień trzy | 9,99 zł |
| `pl.audiokiddo.item.znajdz_przeciwienstwo` | Jednorazowy (non-consumable) | Znajdź przeciwieństwo | 9,99 zł |
| `pl.audiokiddo.item.znajdz_synonimy` | Jednorazowy (non-consumable) | Znajdź synonimy | 9,99 zł |
| `pl.audiokiddo.item.uloz_zdanie` | Jednorazowy (non-consumable) | Ułóż zdanie | 9,99 zł |
| `pl.audiokiddo.item.dokoncz_zgodnie_z_prawda` | Jednorazowy (non-consumable) | Dokończ zgodnie z prawdą | 9,99 zł |
| `pl.audiokiddo.item.kto_to_powiedzial` | Jednorazowy (non-consumable) | Kto to powiedział? | 9,99 zł |
| `pl.audiokiddo.item.zlodziej_naszyjnika` | Jednorazowy (non-consumable) | Złodziej naszyjnika | 19,99 zł |
| `pl.audiokiddo.item.znikajace_dzwonki` | Jednorazowy (non-consumable) | Znikające dzwonki rowerowe | 19,99 zł |
| `pl.audiokiddo.item.na_ratunek_budce_z_lodami` | Jednorazowy (non-consumable) | Na ratunek budce z lodami | 19,99 zł |
| `pl.audiokiddo.item.tajemnicze_znaki` | Jednorazowy (non-consumable) | Tajemnicze znaki i inne poszlaki | 19,99 zł |
| `pl.audiokiddo.item.gadajacy_smietnik` | Jednorazowy (non-consumable) | Gadający śmietnik | 19,99 zł |

Ustawienia:
- **Subskrypcje:** jedna grupa „AudioKiddo” (Apple) / jedna subskrypcja z dwoma planami bazowymi (Google: miesięczny i roczny). Na obu planach oferta wstępna **7 dni za darmo**, tylko dla nowych subskrybentów. Sklep sam decyduje, komu ją przyznać.
- **Kraje:** na start Polska. Inne kraje dopiero z tłumaczeniem aplikacji i opisów.
- **Opis produktu** (widoczny przy zakupie): krótko, co odblokowuje, np. „Wszystkie zabawy z pakietu Detektyw, na zawsze”.
- **Zrzut ekranu do recenzji produktu (Apple):** ekran zakupu z aplikacji.
- Google: po utworzeniu produktów wysłać choć jeden build do testu wewnętrznego, inaczej produkty nie będą widoczne w aplikacji.

## 6. Serwer (Etap 3, przed pierwszym wydaniem z zakupami)

Kroki w `supabase/README.md`. Dla sklepów potrzebne dodatkowo:
- **Apple:** klucz API App Store Server (App Store Connect → Użytkownicy i dostęp → Integracje → In-App Purchase) oraz adres powiadomień serwera (App Store Server Notifications v2) wskazujący na naszą funkcję.
- **Google:** konto usługi w Google Cloud z dostępem do Play Console (uprawnienie do finansów i zamówień) i temat Pub/Sub dla powiadomień w czasie rzeczywistym (RTDN).
- Pliki kluczy wgrywasz jako sekrety Supabase we własnym terminalu (`supabase secrets set ...`), nie w rozmowie i nie w repozytorium.

## 7. Formularze w sklepach

Gotowe teksty i odpowiedzi: `docs/SKLEPY.md`. Uprawnienia i biblioteki: `docs/AUDYT-SDK.md`.

**App Store Connect**
- Kategoria Edukacja + **Kids Category, 5 lat i młodsze** (po wydaniu nie da się z niej łatwo wyjść).
- Kwestionariusz klasyfikacji wiekowej, etykiety prywatności (App Privacy).
- Adres polityki prywatności i wsparcia: `[TODO(Dawid): np. audiokiddo.pl/polityka-prywatnosci-aplikacji i audiokiddo.pl/kontakt]`.
- Notatka dla recenzenta z opisem bramki rodzicielskiej i konto testowe do odblokowania zakupów ze strony.

**Play Console**
- Grupa docelowa i treści: dzieci (program Families), deklaracja „brak reklam”.
- Bezpieczeństwo danych (Data safety), klasyfikacja IARC.
- Deklaracja usługi pierwszoplanowej `mediaPlayback` z krótkim nagraniem ekranu (odtwarzanie przy zablokowanym ekranie).
- Deklaracja identyfikatora reklamowego: **nie używamy** (usunięty z manifestu).
- Adres do usuwania konta i danych (wymóg Google): strona na audiokiddo.pl `[TODO(Dawid)]`.

## 8. Testy przed publikacją

1. **Wewnętrzne:** TestFlight (do 100 osób z zespołu, bez recenzji) i test wewnętrzny w Play Console (do 100 osób).
2. **Zamknięte:** rodziny testowe. Przy prywatnym koncie Google: minimum 12 osób przez 14 dni.
3. **Zakupy testowe:** Apple Sandbox (konto testowe w App Store Connect) i licencjonowani testerzy Google (płatności testowe bez obciążenia karty). Sprawdzić: zakup, przywracanie, wygaśnięcie i odnowienie subskrypcji, zwrot, brak internetu, tryb dziecka.
4. **Urządzenia fizyczne:** mikrofon w grach, słuchawki Bluetooth, TalkBack/VoiceOver, telefon z małą ilością miejsca.
5. Przechwycenie ruchu sieciowego wersji release (lista w `docs/AUDYT-SDK.md`).

## 9. Przed każdym wydaniem

- [ ] `version` w `app/pubspec.yaml` podbita (numer po `+` większy niż poprzednio wysłany).
- [ ] Wszystkie testy przechodzą (lokalnie albo w GitHub Actions).
- [ ] `docs/AUDYT-SDK.md` aktualny: nowe biblioteki, uprawnienia (`aapt2 dump permissions`).
- [ ] `PrivacyInfo.xcprivacy`, App Privacy i Data safety zgodne z tym, co aplikacja robi.
- [ ] Brak śladów trybu testowego: ikona klucza (symulacja zakupów) i adres `127.0.0.1` działają tylko w wersji debug (sprawdzone w kodzie przez `kDebugMode`).
- [ ] Opis „Co nowego” po polsku.
- [ ] Zrzuty ekranu aktualne, jeśli zmienił się wygląd.

## 10. Automatyczne testy i buildy (GitHub Actions)

Plik `.github/workflows/ci.yml` uruchamia przy każdej zmianie: testy logiki, aplikacji i Studio, testy bazy (PostgreSQL 17) i funkcji serwera, build Androida (plik APK do pobrania z wyników) oraz build iOS bez podpisu. Zadziała po założeniu **prywatnego** repozytorium na GitHubie i wysłaniu kodu. Podpisywanie i wysyłkę do sklepów na razie robimy ręcznie; automatyczną wysyłkę można dodać później (sekrety w ustawieniach repozytorium, nie w plikach).

Uwaga o `NSAllowsLocalNetworking` w `ios/Runner/Info.plist`: pozwala wersji debug łączyć się z lokalnym serwerem testowym. Apple nie wymaga uzasadnienia tego wyjątku i nie osłabia on połączeń z internetem (te zawsze idą przez HTTPS), więc może zostać w wersji sklepowej.

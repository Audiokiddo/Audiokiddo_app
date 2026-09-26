# AudioKiddo: materiały do sklepów (szkic, Etap 5)

Stan: 2026-09-27. Deklaracje opisują aplikację **po podłączeniu serwera i zakupów (Etap 3)**. Przed wysłaniem do sklepów trzeba je porównać z faktyczną implementacją i z aktualnymi formularzami. Uwaga: przed Etapem 3 aplikacja nie wysyła jeszcze żadnych danych na nasz serwer.

## Opis w sklepach (PL)

| Pole | Limit | Tekst |
|---|---|---|
| Nazwa | 30 | **AudioKiddo** |
| Podtytuł (App Store) | 30 | Audiozabawy dla dzieci |
| Krótki opis (Google Play) | 80 | Interaktywne audiozabawy i piosenki dla dzieci. Słuchacie, bawicie się, bez ekranu. |
| Tekst promocyjny (App Store) | 170 | Nowe zabawy dźwiękowe: dziecko słucha, odpowiada na głos i wykonuje zadania, a telefon leży ekranem do dołu. |
| Słowa kluczowe (App Store) | 100 | audiobajki,bajki,dla dzieci,zagadki,przedszkolak,podróż,bez ekranu,słuchowisko,piosenki,zabawy |

**Pełny opis:**

> AudioKiddo to interaktywne audiozabawy dla dzieci. Nie trzeba patrzeć w ekran: włączasz zabawę, odkładasz telefon, a dziecko słucha, odpowiada na głos, rozwiązuje zagadki i wymyśla własne historie.
>
> **Co znajdziesz w aplikacji**
> • Pakiet Wyobraźnia: zabawy, w których dziecko tworzy własne historie (3+)
> • Pakiet Słowa i Wiedza: zagadki, skojarzenia i zabawy słowne (3+)
> • Pakiet Detektyw: sprawy Maxa i Mili z aktami do wydrukowania (6+)
> • Piosenki i nowe gry dźwiękowe
>
> **Dla rodziców**
> • Tryb dziecka: duże okładki, bez zakupów, linków i ustawień
> • Pobrane zabawy działają bez internetu, idealnie w podróży
> • Timer snu i tryb bez patrzenia
> • Bez reklam i bez śledzenia
>
> Część zabaw jest za darmo. Pozostałe odblokujesz subskrypcją (miesięczną lub roczną, z 7 dniami za darmo, jeśli sklep je przyzna) albo kupując wybrane pakiety na zawsze.

`[TODO(Dawid): sprawdzić ton, dodać opinie specjalistek tylko za ich zgodą]`

## Kategoria i wiek

| Sklep | Ustawienie | Wartość |
|---|---|---|
| App Store | Kategoria główna / Kids Category | Edukacja / **Kids, przedział 5 lat i młodsze** (decyzja D8) |
| App Store | Klasyfikacja wiekowa | 4+ (brak treści niedozwolonych), odpowiedzi w kwestionariuszu: brak przemocy, brak nieograniczonego dostępu do sieci, brak treści tworzonych przez użytkowników |
| Google Play | Grupa docelowa | tylko dzieci: **5 lat i młodsze** oraz **6–8 lat** `[TODO: potwierdzić, Detektyw jest 6+]` → obowiązuje program Families |
| Google Play | Klasyfikacja IARC | Wszyscy / PEGI 3 (odpowiedzi: brak przemocy, zakupów losowych, komunikacji między użytkownikami) |
| Obie | Reklamy | **Brak reklam** |

## Apple: App Privacy (etykiety prywatności)

| Typ danych | Zbierane | Powiązane z użytkownikiem | Śledzenie | Cel |
|---|---|---|---|---|
| Informacje kontaktowe: e-mail | Tak (tylko przy założeniu konta) | Tak | Nie | Działanie aplikacji |
| Identyfikatory: identyfikator użytkownika (losowy, anonimowy) | Tak | Tak | Nie | Działanie aplikacji |
| Zakupy: historia zakupów | Tak | Tak | Nie | Działanie aplikacji |
| Dźwięk (mikrofon) | **Nie** (przetwarzanie tylko w telefonie) | nie dotyczy | nie dotyczy | nie dotyczy |
| Pozostałe (lokalizacja, kontakty, dane użycia, diagnostyka, reklamy) | Nie | nie dotyczy | nie dotyczy | nie dotyczy |

Plik `ios/Runner/PrivacyInfo.xcprivacy` deklaruje brak śledzenia. Po Etapie 3 trzeba w nim uzupełnić zbierane typy danych.

## Google Play: Data safety

- **Zbierane dane:**
  - adres e-mail (opcjonalny, zarządzanie kontem i działanie aplikacji);
  - historia zakupów (działanie aplikacji);
  - identyfikatory urządzenia lub inne: **nie** (identyfikator konta jest losowy i serwerowy) `[TODO: potwierdzić z formularzem]`.
- **Udostępniane stronom trzecim:** brak (Supabase to podmiot przetwarzający).
- **Szyfrowanie przesyłanych danych:** tak.
- **Usuwanie:** w aplikacji i przez stronę `[TODO: URL]`.
- **Mikrofon:** jeśli funkcja zostanie włączona, zadeklarować przetwarzanie „audio” lokalnie, bez zbierania.
- **Uprawnienia (build release, zweryfikowane 2026-09-27):** patrz `docs/AUDYT-SDK.md`.
- **Usługi pierwszoplanowe:** `mediaPlayback`. Uzasadnienie: odtwarzanie audiozabaw przy zablokowanym ekranie, na żądanie użytkownika. Nagranie wideo do deklaracji: `[TODO]`.

## Notatki dla recenzentów

**App Store Review:**
> AudioKiddo is an audio-first app for children (Kids Category, 5 and under). All purchases, external links, sharing/printing and leaving Kids Mode are behind a parental gate: the adult must tap the number written in Polish words (e.g. „czterdzieści siedem” = 47). The app has no ads and no third-party analytics. Purchases use StoreKit and are verified on our server. Web purchases from audiokiddo.pl are unlocked after sign-in with the buyer's email (Guideline 3.1.3(b)); the app contains no links or references to buying outside the App Store. Demo: free sample items are playable without an account. `[TODO: test account for web-purchase unlock]`

**Google Play:**
> Aplikacja dla dzieci (Families). Bez reklam i bez SDK firm trzecich zbierających dane. Bramka rodzicielska chroni zakupy, linki i ustawienia. Konto rodzica jest opcjonalne.

## Zrzuty ekranu (plan)

Rozmiary: iPhone 6,9″ i 6,5″, iPad 13″ (jeśli wspieramy iPad), Android telefon. Kolejność:

1. Start z „Zabawą dnia” i trybem dziecka. Napis: „Zabawy bez patrzenia w ekran”.
2. Tryb dziecka z dużymi okładkami. Napis: „Tryb dziecka: bez zakupów i ustawień”.
3. Szczegóły zabawy z opisem dla rodzica. Napis: „Wiesz, co ćwiczy każda zabawa”.
4. Pobieranie bez internetu. Napis: „Działa w samochodzie, bez internetu”.
5. Tryb bez patrzenia lub gra. Napis: „Połóż telefon i słuchajcie”.
6. Timer snu. Napis: „Spokojne zasypianie”.

`[TODO: zrzuty po otrzymaniu prawdziwych okładek i logo]`

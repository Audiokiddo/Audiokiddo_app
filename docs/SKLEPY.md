# AudioKiddo: materiały do formularzy App Store i Google Play

Stan: 5 października 2026 (ceny: 24,99 zł miesięcznie, 239,88 zł rocznie), wersja aplikacji 0.2.0 (build 2). Teksty i odpowiedzi do wklejenia przy zakładaniu aplikacji w App Store Connect i Play Console. Przed wysłaniem do recenzji trzeba porównać je z aktualnym formularzem, bo sklepy zmieniają pytania.

Adresy stron (gotowe fragmenty HTML w `docs/strona/sklepy/`, do wklejenia w WordPressie):

| Strona | Adres | Plik |
|---|---|---|
| Polityka prywatności aplikacji | `https://audiokiddo.pl/polityka-prywatnosci-aplikacji/` | `polityka-prywatnosci-aplikacji.html` |
| Wsparcie / kontakt | `https://audiokiddo.pl/kontakt/` | `kontakt-aplikacja.html` |
| Usuwanie konta i danych (Google) | `https://audiokiddo.pl/usuwanie-konta/` | `usuwanie-konta.html` |

## Opis w sklepach (PL)

| Pole | Limit | Tekst |
|---|---|---|
| Nazwa | 30 | **AudioKiddo** |
| Podtytuł (App Store) | 30 | Audiozabawy dla dzieci 3–9 lat |
| Krótki opis (Google Play) | 80 | Polskie audiozabawy bez ekranu od Neli i Dawida. Dziecko jest bohaterem. |
| Tekst promocyjny (App Store) | 170 | Polska rodzinna marka: zabawy piszą i nagrywają Nela i Dawid. Włącz, połóż telefon, a dziecko odpowiada, rusza się i wymyśla. |
| Słowa kluczowe (App Store) | 100 | audiozabawy,polska,zabawy dla dzieci,przedszkolak,bez ekranu,zagadki,detektyw,podróż,słowa |

**Pełny opis:**

> AudioKiddo to polska aplikacja tworzona przez parę: Nelę i Dawida. Sami wymyślamy zabawy, piszemy scenariusze, podkładamy głosy i odpowiadamy na Wasze maile. Bez korporacji, bez reklam, z sercem.
>
> To interaktywne audiozabawy dla dzieci w wieku 3–9 lat. Dziecko nie tylko słucha: odpowiada, szuka, rusza się, wymyśla i decyduje. Jest bohaterem przygody. Ty włączasz zabawę, kładziesz telefon i masz chwilę dla siebie.
>
> **Co znajdziesz w aplikacji**
> • Pakiet Wyobraźnia (3–9 lat): magiczny sklep, podróż na inną planetę, mistrz kuchni i inne zabawy, w których dziecko tworzy własne historie
> • Pakiet Słowa i Wiedza (3–9 lat): zagadki, skojarzenia, synonimy i zabawy słowne
> • Pakiet Detektyw (7+): sprawy Maxa i Mili z aktami do wydrukowania i rozwiązania ołówkiem
> • Gry, w których dziecko odpowiada głosem (rozpoznawanie mowy działa w telefonie, nic nie jest wysyłane)
>
> **Dla rodziców**
> • Tryb dziecka: duże okładki, bez zakupów, linków i ustawień
> • Pobrane zabawy działają bez internetu: w aucie, samolocie i na działce
> • Cykl zabaw do auta z 5 sekundami na zatrzymanie przed kolejną
> • Timer snu, tryb bez patrzenia, kolejka i ulubione
> • Bez reklam i bez śledzenia
>
> Część zabaw jest za darmo. Pozostałe odblokujesz abonamentem: wszystkie zabawy teraz i jeden nowy pakiet co miesiąc (miesięcznie albo rocznie, z 7 dniami za darmo dla nowych subskrybentów). Możesz też kupić wybrane pakiety na zawsze.

## Kategoria i wiek

| Sklep | Ustawienie | Wartość |
|---|---|---|
| App Store | Kategoria główna | Edukacja (druga: Rozrywka) |
| App Store | Kids Category, przedział | **Do decyzji: „6–8” (rekomendacja)** albo „5 i młodsze”. Biblioteka jest dla dzieci 3–9 lat, Detektyw od 7 lat. Przedziału nie da się łatwo zmienić po wydaniu |
| App Store | Klasyfikacja wiekowa | 4+. W kwestionariuszu same odpowiedzi „Brak”: przemoc, strach, treści dla dorosłych, hazard; „Nieograniczony dostęp do sieci: Nie”; „Treści tworzone przez użytkowników: Nie” |
| Google Play | Grupa docelowa | Wyłącznie dzieci: **5 lat i młodsze, 6–8 lat, 9–12 lat**. Obowiązuje program Families i zasady Families |
| Google Play | Klasyfikacja IARC | Wszyscy / PEGI 3. Odpowiedzi: brak przemocy, brak zakupów losowych (loot box), brak komunikacji między użytkownikami, zakupy cyfrowe: tak |
| Obie | Reklamy | **Brak reklam** |

## Apple: App Privacy (etykiety prywatności)

Pytanie „Czy Ty lub partnerzy zbieracie dane z tej aplikacji?”: **Tak**.

| Typ danych | Powiązane z użytkownikiem | Śledzenie | Cel |
|---|---|---|---|
| Informacje kontaktowe: adres e-mail (tylko przy założeniu konta) | Tak | Nie | Działanie aplikacji |
| Identyfikatory: identyfikator użytkownika (losowy, także konto gościa) | Tak | Nie | Działanie aplikacji |
| Zakupy: historia zakupów | Tak | Nie | Działanie aplikacji |
| Dane użycia: interakcja z produktem (start, koniec i powtórka zabawy, pakiet, pierwsze kroki, wejście w ofertę, zakup; własny serwer) | Tak | Nie | Analityka |
| Dźwięk (mikrofon) | **Nie zbierane**: rozpoznawanie w telefonie, nic nie jest nagrywane ani wysyłane | | |
| Lokalizacja, kontakty, zdjęcia, diagnostyka, dane reklamowe | Nie zbierane | | |

Plik `app/ios/Runner/PrivacyInfo.xcprivacy` deklaruje to samo (zaktualizowany 6.10.2026).

## Google Play: Data safety

| Pytanie | Odpowiedź |
|---|---|
| Czy aplikacja zbiera lub udostępnia dane? | Zbiera; **nie udostępnia** stronom trzecim (Supabase i LH.pl to podmioty przetwarzające) |
| Dane osobowe: adres e-mail | Zbierane, opcjonalne, cel: zarządzanie kontem i działanie aplikacji |
| Dane osobowe: identyfikatory użytkownika | Zbierane (losowe), cel: działanie aplikacji |
| Informacje finansowe: historia zakupów | Zbierane, cel: działanie aplikacji |
| Aktywność w aplikacji: interakcje w aplikacji | Zbierane, cel: analityka (własny serwer, bez danych dziecka) |
| Dźwięk | **Nie zbierane** (przetwarzanie tylko na urządzeniu) |
| Szyfrowanie danych w trakcie przesyłania | Tak |
| Możliwość usunięcia danych | Tak: w aplikacji i na `https://audiokiddo.pl/usuwanie-konta/` |
| Identyfikator reklamowy | Nie używamy (usunięty z manifestu) |
| Usługa pierwszoplanowa | `mediaPlayback`: odtwarzanie audiozabaw przy zablokowanym ekranie, na żądanie rodzica. Potrzebne krótkie nagranie ekranu do deklaracji |

## Notatki dla recenzentów

**App Store Review (po angielsku):**

> AudioKiddo is an audio-first app of interactive play for children aged 3–9 (Kids Category). The child listens and answers aloud, moves, or draws; the parent starts a play and puts the phone down.
>
> Parental gate: purchases, links that leave the app (YouTube films, Drive files, e-mail, App Store rating), sharing files, enabling the microphone and leaving Kids Mode are behind a parental gate: the adult taps the number written in Polish words (e.g. "czterdzieści siedem" = 47). Viewing prices, printing case files and opening the account screen inside the app need no gate, as they keep the user in the app and involve no commerce.
>
> No ads, no third-party analytics or tracking SDKs. Usage statistics are first-party (our own Supabase database in the EU) and contain no data about the child. Purchases use StoreKit and are verified on our server.
>
> Web purchases from audiokiddo.pl are unlocked after the parent signs in with the buyer's e-mail or enters the order number (Guideline 3.1.3(b), multiplatform services; every product is also available as an in-app purchase at the same price). The app contains no buttons, links or prices that direct users to buy outside the App Store.
>
> Free plays are playable without an account. Demo account for web-purchase unlock: [TODO: e-mail and order number of a test order].
>
> Microphone: used only in voice games, only after the parent turns it on behind the gate. Recognition runs on the device; no audio is recorded or sent.

Uwaga: pole „Mam kod” (kody prezentowe i polecenia) może być przez Apple uznane za własny sposób odblokowywania treści (wytyczna 3.1.1). Jeśli recenzja to zakwestionuje, wersję na iOS budujemy z `--dart-define=REDEEM_CODES=false`, a kody prezentowe i polecenia obsługujemy przez stronę www.

**Google Play:**

> Aplikacja dla dzieci 3–9 lat (program Families). Bez reklam i bez SDK firm trzecich zbierających dane. Statystyki tylko na własnym serwerze, bez danych dziecka. Bramka rodzica chroni zakupy, linki poza aplikację, wysyłanie plików, mikrofon i wyjście z trybu dziecka. Konto rodzica jest opcjonalne.

## Zrzuty ekranu

Rozmiary: iPhone 6,9″ (1320 × 2868) i 6,5″ (1284 × 2778), iPad 13″ tylko jeśli wspieramy iPada, Android telefon (min. 1080 × 1920). 4–8 zrzutów, każdy z krótkim napisem nad ekranem.

1. Start z logo, Szop’enem i „Zacznij tutaj”. Napis: „Włącz, połóż telefon, odpocznij”.
8. Ekran „O nas” z flagą. Napis: „Polska marka. Zabawy nagrywają Nela i Dawid”.
2. Odtwarzacz z okładką. Napis: „Dziecko jest bohaterem przygody”.
3. Biblioteka z pakietami. Napis: „Setki minut zabaw bez ekranu”.
4. Pobrane. Napis: „Działa bez internetu, w aucie i w samolocie”.
5. Cykl do auta z odliczaniem. Napis: „Zabawa za zabawą na całą drogę”.
6. Detektyw z aktami sprawy. Napis: „Zagadki do rozwiązania ołówkiem” (z dopiskiem 7+).
7. Tryb dziecka. Napis: „Tryb dziecka: bez zakupów i ustawień”.

Zrzuty robimy na symulatorze w Xcode (iPhone 17 Pro Max) i na emulatorze Androida, na prawdziwych danych katalogu.

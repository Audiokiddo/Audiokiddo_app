# AudioKiddo: raport z Etapu 0 (discovery)

Data: 2026-09-26. Architektura techniczna jest w [`ARCHITECTURE.md`](../ARCHITECTURE.md). Oznaczenia [F] / [D] / [Z] / [DEC] / [SPIKE] mają to samo znaczenie co tam.

## 0. Odpowiedzi Dawida (2026-09-26) i ich skutki

| Pytanie | Odpowiedź | Skutek |
|---|---|---|
| 1. Kategoria dla dzieci | Tak | Apple Kids Category („5 i młodsze”), Google tylko dzieci (D8) |
| 2. Konto | Opcjonalne | D4 |
| 3. Klienci ze strony | Mają mieć dostęp do kupionych pakietów | Integracja WooCommerce **wchodzi do v1** (ARCHITECTURE §7a), +3–5 dni w Etapie 3 |
| 4. Model sprzedaży | Subskrypcja + pakiety w cenach ze strony + pojedyncze zabawy tańsze niż pakiet w przeliczeniu | ARCHITECTURE §7; ceny subskrypcji do ustalenia; propozycja 9,99 zł / 19,99 zł za pojedynczą zabawę |
| 5. Piosenki | Własne, autorskie | Brak blokady prawnej; w metadanych sklepu Wy jako autorzy |
| 6. Rynki | Polska na start, docelowo świat | Dystrybucja PL; interfejs od początku lokalizowalny |
| 7. Konta deweloperskie | Brak, będą zakładane | Rekomendacja niżej |
| 8. CMS | Własne Studio; Dawid i Nela | D2 |
| 9. Wiek pakietów | Jak na stronie głównej | Wyobraźnia 3+, Słowa i Wiedza 3+, Detektyw 6+ (warto też poprawić strony produktów) |
| 10. Budżet serwera | **bez odpowiedzi** | Otwarte |
| Weryfikacja zakupów | Własna na serwerze | D3 |

### Rekomendacja: zakładanie kont deweloperskich

- **Apple**: jednoosobowa działalność zapisuje się jako **osoba prywatna (Individual)**, bez numeru D-U-N-S. W sklepie jako sprzedawca widnieje wtedy „Dawid Kubiak”. Potrzebne Apple ID z weryfikacją dwuetapową, koszt 99 USD/rok. [F] Konto organizacji wymaga osobnego podmiotu prawnego (np. sp. z o.o.).
- **Google**: konto **organizacji** wymaga numeru D-U-N-S i dokumentów firmy. Dla jednoosobowej działalności weryfikacja bywa odrzucana, bo nie jest osobnym podmiotem prawnym. [F, źródła społecznościowe] Konto organizacji nie ma wymogu 12 testerów × 14 dni.
  - Propozycja: najpierw sprawdzić lub bezpłatnie zamówić D-U-N-S dla działalności (Dun & Bradstreet, zajmuje dni lub tygodnie) i spróbować konta organizacji.
  - Jeśli weryfikacja się nie uda, zakładamy konto osobiste i planujemy test zamknięty.
- Warto założyć konta **teraz**: weryfikacja tożsamości w obu sklepach trwa od kilku dni do kilku tygodni i nie blokuje Etapów 1–2.

## 1. Najważniejsze wnioski

1. **Środowisko nie jest gotowe do budowy aplikacji.** Na Macu nie ma Fluttera, Xcode, Android Studio, Android SDK ani środowiska Java. Wolne miejsce: 56 GB. Instalacja zajmie ok. 35–45 GB. Bez tego Etap 1 nie ruszy.
2. **Wszystkie 25 obecnych audiozabaw można wydać jako zwykłe audio.** Pauzy na odpowiedź są w nagraniach, więc silnik gier nie jest potrzebny do pierwszej wersji katalogu. [Z, do potwierdzenia odsłuchem]
3. **Zabawa przy zablokowanym telefonie**: zwykłe audio działa na obu systemach. Mikrofon i czujniki przy blokadzie są możliwe tylko warunkowo i wymagają prób na urządzeniach. Dlatego każda nowa zabawa ma wariant bazowy działający bez wejść.
4. **RevenueCat to udokumentowane ryzyko w kategorii dla dzieci**, stąd propozycja własnej weryfikacji zakupów (ok. 3–5 dni pracy więcej).
5. **Google Play: konto osobiste założone po 13.11.2023 wymaga zamkniętego testu z 12 testerami przez 14 dni** przed dostępem do produkcji. [F] To trzeba zaplanować w harmonogramie.
6. **Na stronie są rozbieżności wieku** pakietów (sekcja 6), a do metadanych sklepu potrzebna jest jedna wersja.

## 2. Środowisko: co sprawdziłem

| Element | Stan |
|---|---|
| Folder projektu | `audiokiddo-app/` z plikiem promptu i 3 zestawieniami klatek w `referencje/`. Brak repozytorium git |
| macOS | 26.5.2, Apple Silicon (arm64), 36 GB RAM |
| Flutter / Dart | **brak** |
| Xcode | **brak** (tylko Command Line Tools), więc nie ma symulatora iOS |
| Android Studio / SDK / emulator | **brak** |
| Java (JDK) | **brak** (jest tylko nakładka systemowa `/usr/bin/java` bez środowiska) |
| CocoaPods | brak (Flutter może używać Swift Package Manager, do ustalenia przy instalacji) |
| Homebrew, Node | są |
| Dysk | 56 GB wolnego z 926 GB |
| **Po instalacji (2026-09-26)** | Flutter 3.47.5 w `~/development/flutter`; Android Studio 2026.1.4, SDK 36/37, build-tools 37.0.0, emulator `AudioKiddo_Pixel` (Android 16, z Google Play) uruchomiony testowo; CocoaPods 1.17, mas 7.0. Ścieżki w `~/.zshrc`. `flutter doctor`: wszystko OK poza Xcode |
| Xcode (do zrobienia) | Xcode 27.0 w App Store wymaga macOS 26.6+, a zainstalowany jest 26.5.2. Najpierw aktualizacja macOS, potem Xcode; komendy wymagają hasła administratora |
| Urządzenia fizyczne | Nieznane. Nagrania referencji pochodzą z iPhone'a 1290×2796 (model Pro Max / Plus). Android: `TODO(Dawid)` |

## 3. Marka: co zaobserwowałem, a co proponuję

Podgląd materiałów pobranych ze strony: [`marka-podglad-ze-strony.jpg`](marka-podglad-ze-strony.jpg). Plik jest **tylko poglądowy**, nie do użytku w aplikacji.

**Zaobserwowane [F] (audiokiddo.pl, 2026-09-26):**

- **Logo**: odręczny napis „AUDIOKIDDO” z kreskami „dźwięku” nad ostatnią literą i podpisem „audiozabawy pełne przygód”. Na stronie jest tylko PNG 800×257, brak wersji wektorowej.
- **Kolory w grafikach**: turkus `#3EADB2`, lawenda `#A98EC1`, żółty `#FAC119` / `#FFCB03`, pomarańcz `#FF7600`, ciemnozielone tło logo (`#40645C`–`#253B35`), kremowy `#F4EDE7`. Kolory odczytane z CSS i grafik, więc wymagają potwierdzenia wzornikiem.
- **Krój**: Poppins (strona). Krój logo jest inny, nieznany.
- **Postacie**: Profesor Fantazjusz i Czarodziejka Nela (Wyobraźnia), Max i Mila (Detektyw), czarodziej z brodą na okładce Słów i Wiedzy (imię nieznane). Styl: realistyczne 3D w stylu animacji kinowej.
- **Ton**: ciepły, rodzicielski, „bez ekranów”, „w samochodzie, w podróży, w gościach”.
- **Kodowanie kolorem pakietów**: Wyobraźnia = lawenda, Słowa i Wiedza = turkus, Detektyw = żółty.
- **Twórcy**: „młoda para”, lektorstwo i projektowanie, lektor w zespole.

**Propozycja rozszerzenia (do akceptacji, Etap 1):**

- Zachować kodowanie pakietów kolorami, bo działa też jako nawigacja dla dziecka („fioletowe zabawy”).
- Tło aplikacji: kremowe w trybie jasnym, głęboka zieleń z logo w trybie ciemnym i wieczornym.
- Poppins w interfejsie (licencja OFL), krój logo tylko w samym logo.
- W trybie dziecka zamiast tekstu: okładki postaci i krótkie nagrania lektora („To Max i Mila! Dotknij, żeby zacząć”).
- **Nie tworzę nowych maskotek** ani wersji logo. Onboarding z humorem oprzemy na istniejących postaciach, jeśli Dawid potwierdzi prawa do nich.

## 4. Katalog treści: fakty ze strony [F]

| Pakiet | Zabawy | Czas 1 zabawy | Łącznie | Wiek na stronie produktu | Wiek na stronie głównej | Format |
|---|---|---|---|---|---|---|
| Wyobraźnia | 10 (np. Magiczny sklep, Mikstura, Mój superbohater) | ok. 5–9 min | ponad 60 min | **od 4 r.ż.** | 3+ | mp3 + prywatna playlista YouTube |
| Słowa i Wiedza | 10 (np. Co to za dźwięk?, Znajdź przeciwieństwo) | ok. 4–7 min | ponad 60 min | **od 4 r.ż.** | 3+ | mp3 + YouTube |
| Detektyw | 5 (np. Złodziej naszyjnika, Gadający śmietnik) + „akta sprawy” PDF do druku | ok. 16 min (wyliczone) | ponad 80 min | **od 7 r.ż.** | 6+ | mp3 + PDF |

Ceny na 2026-09-26: 49,99 / 49,99 / 69,99 zł, zestawy 89,99 i 159,99 zł. Darmowy pakiet: 3 zabawy za zapis do newslettera. Sprzedawca: jednoosobowa działalność Dawida (dane w regulaminie). Piosenki: **na stronie ich nie ma**, brak danych.

Uwaga: strona powołuje się na opinie fizjoterapeutki i logopedki. W aplikacji i opisie sklepu użyję ich tylko po potwierdzeniu zgody osób, a efekty rozwojowe opiszę jako cele zabaw, nie jako udowodnione efekty.

## 5. Referencje: co faktycznie otworzyłem

W `referencje/` są 3 zestawienia klatek (co 5–8 s) z dwóch nagrań. Samych nagrań wideo w folderze nie ma, więc widziałem wyłącznie te klatki.

- **GoGo!**: prośba o podgłośnienie, ekrany ładowania, humorystyczny regulamin z maskotkami, animacja „weryfikacji głosowej”, katalog z banerem, półki z czasem i liczbą graczy, zakładki sytuacyjne.
- **Pomelody**: logowanie (Google/Facebook/Apple/e-mail, trial 7 dni), 3 ekrany ankiety, dane dziecka (imię i rok urodzenia), home ze skrótami, grupy wiekowe, „Co robicie?”, lista albumu z kłódkami i „Wypróbuj za darmo”, „Moje produkty”, dolna nawigacja.
- **Nie widziałem**: odtwarzacza, paywalla, ustawień, przebiegu samej zabawy w GoGo!.

Świadomie **odchodzimy** od trzech rzeczy z referencji:

- **Zbieranie imienia i roku urodzenia dziecka** (Pomelody). U nas: przedział wieku, pseudonim opcjonalny, tylko lokalnie.
- **Animacja „nasłuchiwania” niezależna od mikrofonu** (GoGo!). U nas: uczciwy test mikrofonu i tylko po zgodzie rodzica.
- **Kłódki widoczne dla dziecka.** U nas: w trybie dziecka treści płatne są ukryte.

## 6. Sprzeczności, ryzyka i zależności

### Sprzeczności

| # | Sprzeczność | Propozycja |
|---|---|---|
| S1 | Wiek pakietów: 3+ vs od 4 r.ż.; 6+ vs od 7 r.ż. | Dawid wskazuje wiążące wartości (pytanie 9) |
| S2 | Prompt: „konto wyłącznie rodzica” vs Apple 5.1.1(v): bez istotnych funkcji kontowych aplikacja ma działać bez logowania | Konto opcjonalne (D4) |
| S3 | Kids Category zakazuje analityki firm trzecich, a strona używa GA i Facebook Pixel | Aplikacja bez nich; osobna polityka prywatności dla aplikacji |
| S4 | „Bez ekranu” vs dotyk jako wejście | Dotyk tylko na aktywnym ekranie; przy blokadzie wariant bazowy |
| S5 | Klienci, którzy kupili mp3 na stronie, nie dostaną dostępu w aplikacji v1 (WooCommerce poza zakresem) | Kody promocyjne Apple (offer codes) i Google (promo codes) na darmowy okres [DEC] |
| S6 | Apple 3.1.2 wymaga „ciągłej wartości” subskrypcji, a katalog startowy to 25 zabaw | Plan regularnych premier (np. 2 nowe zabawy miesięcznie) albo także pakiety jednorazowe |

### Ryzyka (od najwyższego)

| # | Ryzyko | Wpływ | Łagodzenie |
|---|---|---|---|
| R1 | Odrzucenie w Kids Category / Families (SDK, dane, bramka) | Opóźnienie o tygodnie | Brak SDK firm trzecich, audyt ruchu sieciowego, instrukcja dla recenzenta |
| R2 | Mikrofon i czujniki przy blokadzie nie działają niezawodnie | Mniej atrakcyjne gry | Wariant bazowy każdej gry, próby w Etapie 1 |
| R3 | Brak środowiska i fizycznego Androida | Blokada Etapów 1–2 | Instalacja narzędzi; zakup lub pożyczenie telefonu z Androidem 12+ |
| R4 | Prawa do piosenek (autorzy, wykonawcy, ZAiKS) i ilustracji (jeśli generowane przez AI: warunki narzędzia) | Blokada publikacji | Potwierdzenie praw przed Etapem 5 |
| R5 | Test zamknięty Google (12 testerów × 14 dni) | +2–3 tygodnie | Rekrutacja testerów (newsletter!) równolegle z Etapem 4 |
| R6 | Mały katalog a subskrypcja | Odrzucenie za 3.1.2 lub słaba konwersja | S6 |
| R7 | Własna weryfikacja zakupów: błędy stanów | Fałszywy brak dostępu | Testy stanów w sandboxie, idempotencja, dzienna rekonsyliacja |
| R8 | Publiczne dane przedsiębiorcy w sklepach (DSA, konto osobiste) | Prywatny adres widoczny publicznie | Rozważyć adres do doręczeń lub wirtualne biuro [DEC] |

### Zależności zewnętrzne

Konta Apple i Google, umowy płatnicze w obu konsolach (Paid Apps Agreement, profil płatności Google), dane bankowe i podatkowe, projekt Google Cloud (Pub/Sub dla RTDN), Supabase Pro, konsultacja prawna, nagrania lektora do nowych gier.

## 7. Mapa ekranów i ścieżki

### Mapa

```
Start
 ├─ Powitanie („Podgłośnij do wygodnego poziomu” + postacie)          [1. uruchomienie]
 ├─ Dla rodzica: 3 zdania o aplikacji, linki do regulaminu i prywatności [za bramką]
 ├─ Ankieta (opcjonalna, „Pomiń”): wiek dziecka, sytuacje dnia
 └─ Home rodzica
     ├─ Szukaj
     ├─ Zabawa dnia (baner)
     ├─ Półki: „Zacznij tu” (wiek), „Co robicie?” (podróż, przed snem, w domu, czekanie), pakiety, piosenki
     ├─ Szczegóły treści → Odtwarzacz (+ tryb bez patrzenia) / Pobierz / PDF
     ├─ Biblioteka: Audiozabawy | Piosenki | Pobrane  (filtry: wiek, czas, pakiet, sytuacja)
     ├─ Ulubione / Ostatnio słuchane
     ├─ [ Tryb dziecka ] ────────────────────────────────┐
     └─ Ustawienia (za bramką)                           │
         ├─ Profile dzieci (lokalne)                     │
         ├─ Konto: załóż / zaloguj / wyloguj / usuń      │
         ├─ Subskrypcja: paywall, przywróć, zarządzaj    │
         ├─ Pobrania i miejsce                           │
         ├─ Mikrofon: test i uprawnienie                 │
         ├─ Timer snu i domyślne limity                  │
         └─ Pomoc, regulamin, prywatność, kontakt        │
                                                          ▼
Tryb dziecka: siatka dużych okładek (wybrane przez rodzica) → Odtwarzacz dziecięcy (duża pauza) → koniec sesji
              ikona rodzica w rogu → bramka → Home rodzica
```

### Ścieżki kluczowe

1. **Pierwsza zabawa gościa**: instalacja, powitanie, pominięcie ankiety, Home, „Wypróbuj za darmo”, pobranie próbki, odtwarzanie. Bez konta i bez mikrofonu.
2. **Przygotowanie do podróży**: Home, „Co robicie? → Podróż”, zaznaczenie 5 zabaw, „Pobierz”, „Tryb dziecka” z tymi zabawami. W aucie telefon jest zablokowany, dziecko słucha przez Bluetooth.
3. **Zakup**: kłódka w strefie rodzica, bramka, paywall z cenami ze sklepu, zakup w sklepie, weryfikacja na serwerze, odblokowanie. Opcjonalnie „Załóż konto, by mieć dostęp na innych urządzeniach”.
4. **Zabawa interaktywna**: szczegóły z listą wymagań („potrzebny mikrofon — opcjonalnie”), prośba o mikrofon za bramką, start, tryb bez patrzenia.
5. **Dziecko próbuje wyjść**: przycisk wstecz lub gest nie reagują albo pokazują bramkę; restart aplikacji wraca do trybu dziecka.
6. **Usunięcie konta**: bramka, ustawienia, konto, „Usuń konto” z wyjaśnieniem, że subskrypcję anuluje się w App Store lub Google Play (link), potwierdzenie, usunięcie na serwerze i lokalnie.

## 8. Do dostarczenia przez Dawida

| # | Materiał | Potrzebne od |
|---|---|---|
| 1 | Zgoda na instalację Xcode, Android Studio i Fluttera (~40 GB) albo samodzielna instalacja | Etap 1 |
| 2 | Telefon z Androidem 12+ do testów (oraz model i wersja iOS iPhone'a) | Etap 1 |
| 3 | Logo w SVG / AI / PDF, krój logo, wzornik kolorów (jeśli istnieje) | Etap 1 |
| 4 | Ilustracje postaci i okładki w wysokiej rozdzielczości + potwierdzenie praw (w tym dla grafik generowanych AI) | Etap 1 |
| 5 | Pliki audio 25 zabaw (oryginały WAV lub najlepsze mp3) + karty PDF Detektywa | Etap 2 |
| 6 | Piosenki: lista, pliki, informacja o prawach (tekst, muzyka, wykonanie, ZAiKS) | Etap 2 |
| 7 | Skład darmowej próbki w aplikacji | Etap 2 |
| 8 | Konto Apple Developer (typ: osoba czy organizacja) i dostęp do App Store Connect | Etap 3 |
| 9 | Konto Google Play Console (data założenia, typ) i projekt Google Cloud | Etap 3 |
| 10 | Ceny subskrypcji (miesięczna i roczna) i trial | Etap 3 |
| 11 | Konto Supabase (organizacja na e-mail firmowy) | Etap 3 |
| 12 | Nagrania lektora do 3 prototypów (lista tekstów przygotuję w Etapie 4) | Etap 4 |
| 13 | 12+ testerów na Androidzie na 14 dni | Etap 5–6 |
| 14 | Konsultacja prawna: polityka prywatności, regulamin, warunki subskrypcji | Etap 5 |
| 15 | Dane do sklepów: e-mail wsparcia, adres do publikacji (DSA), URL polityki prywatności na audiokiddo.pl | Etap 6 |
| 16 | Zgoda specjalistek na użycie opinii (jeśli mają być w sklepie) | Etap 6 |

Klucze, hasła i certyfikaty **nie w czacie**. Gdy będą potrzebne, podam instrukcję wpisania ich bezpośrednio do sekretów Supabase lub pęku kluczy.

## 9. Pytania (najważniejsze na górze)

1. **Kategoria w sklepach**: Apple Kids Category (i wtedy wybór jednego przedziału: „5 i młodsze” albo „6–8”) oraz Google „tylko dzieci”? To zmienia deklaracje w sklepach i wymagania. Rekomendacja: tak, przedział **„5 i młodsze”**, bo większość treści jest od 4 lat, a Detektyw i tak pasuje starszym. Bez Kids Category nie wolno pisać „dla dzieci” w nazwie i opisie (Apple 2.3.8).
2. **Konto opcjonalne** (rekomendacja D4) czy wymagane przy zakupie?
3. **Klienci ze strony** (kupione mp3): czy mają dostać darmowy okres w aplikacji przez kody promocyjne sklepów?
4. **Model sprzedaży**: sama subskrypcja czy subskrypcja **plus** pakiety jako zakup jednorazowy w aplikacji? Orientacyjne ceny?
5. **Piosenki**: czyje są (autorzy, wykonawcy), ile ich jest, czy są gotowe i czy prawa obejmują dystrybucję w aplikacji z subskrypcją?
6. **Rynki**: tylko Polska czy wszystkie kraje (polonia w UK, DE, USA)? USA wnosi COPPA i stanowe przepisy o wieku w sklepach.
7. **Konta deweloperskie**: czy już istnieją? Konto Google osobiste czy organizacyjne i kiedy założone (test 12 × 14 dni)? Apple jako osoba prywatna (w sklepie wtedy „Dawid Kubiak”)?
8. **CMS**: czy akceptujesz własne Studio (D2)? Kto będzie dodawał treści: Ty czy partnerka?
9. **Wiek pakietów**: które wartości są wiążące (3+ / 4+, 6+ / 7+)?
10. **Budżet utrzymania**: czy ok. 100–150 zł miesięcznie na backend (Supabase Pro) jest akceptowalne?

## 10. Szacunek pracy

Założenia: implementacja prowadzona przeze mnie z Twoimi przeglądami po każdym etapie; środowisko zainstalowane; materiały dostarczane zgodnie z tabelą w sekcji 8. Dni to dni robocze implementacji i testów, bez czasu Twoich odpowiedzi i oczekiwania na sklepy.

| Etap | Zakres | Implementacja | Zależności / blokady |
|---|---|---|---|
| 0 | Discovery | zrobione | — |
| 1 | Fundament, system designu, mocki, 3 próby techniczne | 5–8 dni | Środowisko, telefony, logo |
| 2 | Audio, offline, tryb bez patrzenia | 6–10 dni | Pliki audio |
| 3 | Supabase, konto, Studio, płatności (subskrypcje, pakiety, pojedyncze zabawy), WooCommerce, bramka, usuwanie konta | 15–23 dni | Konta sklepów, umowy płatnicze, ceny, klucze WooCommerce |
| 4 | Silnik + 3 prototypy | 8–14 dni | Nagrania lektora, wyniki prób |
| 5 | Dopracowanie, dostępność, audyt, szkice dokumentów | 5–9 dni | Konsultacja prawna (poza mną) |
| 6 | Buildy, TestFlight, test zamknięty, metadane | 3–6 dni | 12 testerów × 14 dni (Google) |
| **Razem** | | **ok. 42–70 dni** | |

Kalendarz, orientacyjnie: **3–5 miesięcy do publicznego wydania**. Obejmuje to przerwy na odpowiedzi, przygotowanie treści (nagrania, okładki), test zamknięty Google (min. 14 dni) i review Apple (zwykle kilka dni, przy odrzuceniach w Kids Category dłużej).

**Koszty usług (orientacyjne, do weryfikacji w dniu zakupu):**

| Pozycja | Koszt |
|---|---|
| Apple Developer Program | 99 USD/rok |
| Google Play Console | 25 USD jednorazowo |
| Supabase Pro | ok. 25 USD/mies. + ewentualne nadwyżki (transfer audio) |
| Hosting Studio (strona statyczna) | darmowy plan |
| Google Cloud Pub/Sub dla powiadomień | prawdopodobnie w darmowym limicie |
| Prowizje sklepów od subskrypcji | zwykle 15% przy małym przychodzie (programy dla małych firm; do potwierdzenia) |
| Telefon z Androidem do testów | ok. 400–900 zł, jeśli trzeba kupić |
| Konsultacja prawna | `TODO(Dawid)` |

## 11. Rejestr źródeł (sprawdzone 2026-09-26)

| Źródło | Co z niego wynika |
|---|---|
| https://audiokiddo.pl/ | Oferta, FAQ, wartości, opinie, kolory i kroje w CSS (WordPress 7.1.2, Elementor, WooCommerce) |
| https://audiokiddo.pl/produkt/pakiet-wyobraznia/ | 10 zabaw, od 4 r.ż., mp3 + YouTube, czasy, postacie |
| https://audiokiddo.pl/produkt/pakiet_slowa_i_wiedza/ | 10 zabaw, od 4 r.ż., czasy |
| https://audiokiddo.pl/produkt/pakiet-detektywa/ | 5 zabaw, od 7 r.ż., 80+ min, akta do druku, Max i Mila |
| https://audiokiddo.pl/sklep/ | Ceny i zestawy |
| https://audiokiddo.pl/o-nas/ | Twórcy, lektorstwo |
| https://audiokiddo.pl/regulamin/, /polityka-prywatnosci/ | Sprzedawca, PayU; strona używa GA i Facebook Pixel |
| https://audiokiddo.pl/zapis-pakiet-darmowy/, /czym-sa-audiozabawy-2/ | Pakiet darmowy (3 zabawy), opis formatu |
| Instagram @audiokiddo.pl, YouTube | **Nie sprawdzone** (wymagają logowania / brak wiarygodnego potwierdzenia oficjalnego kanału). Pozycja na liście braków |
| https://developer.apple.com/app-store/review/guidelines/ | 1.3, 2.3.8, 3.1.1, 3.1.2, 4.8, 5.1.1(v), 5.1.4 (cytowane w ARCHITECTURE §14). Strona nie podaje daty aktualizacji |
| https://developer.apple.com/app-store/kids-apps/ | Bramka rodzicielska przed linkami, zakupami i prośbami o uprawnienia; przedziały 5 i młodsze / 6–8 / 9–11 |
| https://support.google.com/googleplay/android-developer/answer/9893335 | Families Policy: zakazane identyfikatory, SDK, `AD_ID`, ujawnianie danych z mikrofonu |
| https://support.google.com/googleplay/android-developer/answer/13327111 | Usuwanie konta: w aplikacji i przez stronę WWW |
| https://support.google.com/googleplay/android-developer/answer/14151465 | Test zamknięty 12 testerów × 14 dni dla nowych kont osobistych |
| https://developer.android.com/develop/background-work/services/fgs/service-types | FGS `mediaPlayback` i `microphone`; mikrofonu nie uruchomisz z tła; deklaracja w Play Console |
| https://developer.android.com/develop/sensors-and-location/sensors/sensors_overview | Android 9+: czujniki w tle nie wysyłają zdarzeń (zalecana usługa pierwszoplanowa) |
| https://community.revenuecat.com/sdks-51/how-should-i-answer-app-review-questions-about-the-kids-category-3041 | Odrzucenia Apple Kids z RevenueCat (2023) |
| https://community.revenuecat.com/sdks-51/data-practices-of-google-families-policy-on-kids-app-2402 | Problemy z Families Policy (2023–2024) |
| https://pub.dev (API pakietów), kanał Flutter releases | Wersje z ARCHITECTURE §3 |
| Apple Review Guidelines 3.1.3(b) (ten sam URL co wyżej) | Dostęp do treści kupionych na stronie, jeśli są też w IAP; zakaz zachęcania do zakupu poza aplikacją |
| https://support.google.com/googleplay/android-developer/answer/10281818 | FAQ Payments: aplikacje *consumption-only* mogą dawać dostęp do treści opłaconych gdzie indziej |
| https://support.google.com/googleplay/android-developer/answer/9858738 | Payments policy: zakaz kierowania do innych metod płatności |
| https://developer.apple.com/help/account/membership/program-enrollment/ | Jednoosobowa działalność zapisuje się jako Individual, bez D-U-N-S |
| https://support.google.com/googleplay/android-developer/answer/13634885 | Typy kont Google Play (osobiste i organizacji) |
| Wyniki wyszukiwania o `SpeechTranscriber` (iOS 26) | Obsługa polskiego **niepotwierdzona**; do sprawdzenia na urządzeniu |

Wymagania sklepów zmieniają się. Przed Etapem 5 powtórzę sprawdzenie i zaktualizuję ten rejestr.

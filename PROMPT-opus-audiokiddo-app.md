# PROMPT: Aplikacja mobilna AudioKiddo (iOS + Android)

## 1. Rola i cel

Jesteś senior mobile engineerem i product designerem w jednej osobie. Razem z Dawidem (agencja BiznesoweLove, dwie osoby) budujesz od zera aplikację mobilną **AudioKiddo** na **App Store** i **Google Play**.

Aplikacja ma być domem dla naszych interaktywnych audiozabaw i piosenek dla dzieci oraz platformą do dokładania kolejnych zabaw **bez ekranu** (dźwiękowych, ruchowych, głosowych). Ma być gotowa do przejścia review w obu sklepach, w tym w kategoriach dla dzieci (Apple Kids Category, Google Play Families).

Pracuj w języku polskim (komunikacja, teksty w aplikacji, dokumentacja). Kod, nazwy zmiennych i commity po angielsku.

## 2. Marka i produkt (zweryfikuj na https://audiokiddo.pl)

Zacznij od przejrzenia audiokiddo.pl (strona główna, /sklep/, /czym-sa-audiozabawy-2/, blog, /zapis-pakiet-darmowy/, strony produktów) oraz Instagrama @audiokiddo.pl i kanału YouTube. Wyciągnij stamtąd logo, paletę kolorów, typografię, ton komunikacji, postacie i okładki. Jeśli czegoś nie da się wiarygodnie pobrać (np. wektorowe logo), wpisz to na listę „Do dostarczenia przez Dawida" zamiast zgadywać.

Co już wiemy (potraktuj jako punkt wyjścia, nie prawdę objawioną):

- **Audiozabawy** = interaktywna zabawa bez ekranu, prowadzona głosem. Dziecko nie słucha biernie, tylko wykonuje zadania, rozwiązuje zagadki, naśladuje dźwięki, podejmuje decyzje (aktywne słuchanie). Jedna zabawa trwa od kilku do ok. 15 minut.
- **Pakiety w sklepie** (dziś sprzedawane jako pobierane pliki audio):
  - *Wyobraźnia* (3+), 10 audiozabaw, 49,99 zł
  - *Słowa i Wiedza* (3+), 10 audiozabaw, 49,99 zł
  - *Detektyw* (6+), 5 audiozabaw + karty pracy do druku, 69,99 zł
  - zestawy 2 i 3 pakietów w obniżonej cenie
  - bezpłatny pakiet próbny: 3 audiozabawy (po jednej z każdego pakietu) za zapis do newslettera
- **Wartości marki**: bez reklam, bezpiecznie, bez ekranu, rozwój wyobraźni, mowy i wiedzy, stworzone przez rodziców pod okiem specjalistów (pedagodzy, logopedzi), działa offline, do samochodu i w podróży.
- **Docelowo w aplikacji**: audiozabawy z 3 pakietów, piosenki dla dzieci oraz nowe zabawy bez ekranu (dźwiękowe, ruchowe, głosowe).

## 3. Referencje (inspiracja, NIE kopiowanie)

Dawid załączył nagrania dwóch aplikacji. Klatki z nich są w folderze `referencje/`. Pełnych nagrań nie widzisz, więc opieram się na opisie poniżej i na klatkach. Przejrzyj klatki uważnie. Nie kopiuj nazw, grafik, tekstów ani identyfikacji wizualnej. Bierz tylko mechanizmy i wzorce UX.

### 3.1 GoGo! (angielskojęzyczne audiogry dla dzieci, sterowane głosem)

Co nam się podoba i chcemy zaadaptować:

- **Onboarding z charakterem.** Ekran „Volume up to begin!" z animowaną ręką pokazującą przycisk głośności. Zabawne ekrany ładowania. Humorystyczny regulamin („Totally Normal Terms & Conditions") z maskotkami i przyciskiem „I agree". Efekt „weryfikacji głosowej": czarny ekran, fala dźwiękowa, „listening…", potem zielony ekran „Access granted" z otwieranym kłódką. To uczy dziecko i rodzica, że aplikacja słucha, a jednocześnie jest zabawą.
- **Ekran główny jak katalog zabaw**: duży karuzelowy baner z „zabawą dnia", poniżej poziome półki tematyczne z nagłówkami (u nas np. „Detektywistyczne zagadki", „Podróże wyobraźni") i kafelkami. Każdy kafelek pokazuje **czas trwania** i **liczbę graczy**.
- **Zakładki kontekstowe u góry** (Home / Great for groups / Play after dark). U nas np. „Dla wszystkich", „W podróży", „Przed snem".
- Śmiała, kontrastowa kolorystyka i wyraziste postacie. Gry naprawdę prowadzone głosem i mikrofonem.

### 3.2 Pomelody (polska aplikacja muzyczno-rodzicielska)

Co nam się podoba i chcemy zaadaptować:

- **Logowanie**: Google, Facebook, Apple, e-mail. Komunikat o darmowym okresie próbnym (7 dni).
- **Onboarding-ankieta** (kilka ekranów, „Możesz wybrać kilka odpowiedzi", przyciski „Dalej" i „Pomiń", kropki postępu): jakich treści potrzebujecie, jaki jest rytm dnia, jak możemy Cię wesprzeć w rodzicielstwie. Potem ekran „Opowiedz nam o swoich dzieciach" (imię, rok urodzenia, „Dodaj kolejne dziecko") i animacja rakiety z tekstem „Dobieramy treści pasujące do Was najlepiej".
- **Ekran główny**: wyszukiwarka, „Witaj, {imię}!", rząd szybkich skrótów (Co nowego?, Zajęcia, Moje produkty, Skanuj, Graj ulubione, Subskrypcja), baner promocyjny nowości, sekcja „Zacznij tu" z okrągłymi ikonami **grup wiekowych**, sekcja „Co robicie?" z dużymi kafelkami sytuacji (Koncertujemy, Tańczymy, Zasypiamy, Bawimy się).
- **Listy utworów w albumach** z okładką, sercem (ulubione), **kłódką** przy treściach płatnych i przyciskiem „Wypróbuj za darmo".
- **Dolna nawigacja**: Home, Audio, Ulubione, Wideo, Profil. Ekran „Moje produkty" z zakupionymi pakietami.
- Ręcznie rysowane, ciepłe ilustracje i spokojna, dojrzała paleta.

Uwaga: w klatkach nie widziałem odtwarzacza ani ekranu subskrypcji Pomelody. Zaprojektuj je samodzielnie zgodnie z dobrymi praktykami.

### 3.3 Synteza dla AudioKiddo

Bierzemy: onboarding z humorem i „testem głosu" (GoGo!), personalizację po wieku dziecka i sytuacji dnia oraz prostą nawigację (Pomelody). Aplikacja ma mieć **dwie strefy**:

1. **Strefa rodzica** (konto, ankieta, profile dzieci, subskrypcja, pobrane, ustawienia, wyszukiwarka). Może być ciepła i informacyjna.
2. **Tryb dziecka** (ogromne przyciski, minimum tekstu, wszystko obsługiwalne bez czytania, zero linków na zewnątrz, wyjście tylko przez parental gate).

## 4. Zasada nadrzędna: bez ekranu

Marka AudioKiddo to „zabawa bez ekranu". Aplikacja nie może być kolejnym ekranowym rozpraszaczem.

- Odtwarzanie audiozabawy działa z **wygaszonym ekranem** i zablokowanym telefonem (background audio, sterowanie z ekranu blokady i słuchawek, Bluetooth/CarPlay/Android Auto tam, gdzie to proste).
- **„Tryb bez ekranu"**: po starcie zabawy ekran przygasa do minimalnego UI z jednym wielkim przyciskiem pauzy. Dziecko nie ma na co patrzeć.
- Zaprojektuj limity (timer snu, „koniec zabawy" i miękkie zakończenie), które wspierają zdrowe użycie.

## 5. Zakres wersji 1.0

### 5.1 Ekrany i funkcje

1. **Splash i onboarding**: „Podgłośnij!", zabawny regulamin z maskotkami, opcjonalny „test głosu" (mikrofon, tylko po zgodzie rodzica).
2. **Konto rodzica**: Apple, Google, e-mail (Sign in with Apple obowiązkowo, jeśli jest Google/Facebook). Tryb gościa dla darmowej próbki.
3. **Ankieta** i **profile dzieci** (imię lub pseudonim, rok urodzenia, minimalne dane).
4. **Home**: baner „zabawa dnia", półki tematyczne, „Zacznij tu" po grupach wiekowych (3+, 6+, docelowo młodsze), „Co robicie?" (w drodze, przed snem, w domu, w kolejce).
5. **Biblioteka**: Audiozabawy (pakiety Wyobraźnia, Słowa i Wiedza, Detektyw) i Piosenki. Filtry: wiek, czas trwania, cel rozwojowy, pakiet.
6. **Szczegóły zabawy**: okładka, opis dla rodzica („co ćwiczy"), czas, wiek, przycisk Start, kłódka lub „Wypróbuj za darmo".
7. **Odtwarzacz**: pełne sterowanie, prędkość, timer snu, wznawianie od miejsca przerwania, tryb bez ekranu.
8. **Pobieranie offline** (kluczowa obietnica marki) z zarządzaniem miejscem.
9. **Ulubione**, **Ostatnio słuchane**, **wyszukiwarka**.
10. **Karty pracy do druku** (pakiet Detektyw): PDF w strefie rodzica.
11. **Subskrypcja (freemium)**: bezpłatna próbka (min. 3 audiozabawy jak w newsletterze) + subskrypcja miesięczna i roczna, okres próbny i przywracanie zakupów. Ceny i długość triala trzymaj w konfiguracji, nie w kodzie.
12. **Strefa rodzica z parental gate** (proste zadanie dla dorosłego, np. działanie matematyczne lub przytrzymanie), za nim płatności, ustawienia, linki, konto, usuwanie konta.
13. **Silnik gier bez ekranu** (5.3) z minimum 3 grami prototypowymi.

### 5.2 Poza zakresem v1 (zaprojektuj tak, by dało się dodać)

- Logowanie kontem ze sklepu audiokiddo.pl (WooCommerce) i odblokowanie zakupionych tam pakietów. **Nie implementuj**, ale zaprojektuj model uprawnień (entitlements) tak, by zewnętrzne źródło dało się dodać. Uwaga na zasady sklepów dot. płatności za treści cyfrowe.
- Wideo, sklep z produktami fizycznymi, społeczność, wiele języków (v1 tylko polski, ale teksty w plikach lokalizacji).

### 5.3 Silnik audiozabaw interaktywnych i gry bez ekranu

Zaprojektuj **silnik oparty na skryptach zabaw** (dane, nie kod), żeby Dawid mógł dodawać nowe zabawy bez wydawania aktualizacji:

- Zabawa = sekwencja segmentów audio, punkty pauzy, opcjonalne warunki przejścia i wejścia od dziecka.
- Rodzaje wejścia, wszystkie **bez patrzenia w ekran**: (a) dotyk gdziekolwiek na ekranie (duże strefy), (b) potrząśnięcie, (c) przechylenie i ruch (akcelerometr), (d) klaśnięcie i głośność (mikrofon, wykrywanie aktywności głosowej), (e) opcjonalnie odpowiedź głosowa. Rozpoznawanie mowy po polsku ma działać **na urządzeniu** bez wysyłania nagrań do chmury. Jeśli nie da się tego zrobić sensownie, użyj wykrywania „dziecko coś powiedziało" zamiast rozumienia słów.
- Każda gra ma **tryb awaryjny** (dotyk), bo małe dzieci i szum w aucie psują rozpoznawanie.
- Trzy gry prototypowe (zaproponuj i uzasadnij, przykłady): *Zgadnij dźwięk* (quiz dźwięków zwierząt i codzienności), *Zamrożony taniec* (muzyka gra, dziecko tańczy, gdy cichnie, stoi nieruchomo, wykrywanie ruchu akcelerometrem), *Echo rytmu* (aplikacja wystukuje rytm, dziecko powtarza klaśnięciem).
- Lektor i efekty dźwiękowe z plików audio dostarczonych przez nas. Do brakujących fragmentów użyj oznaczonych placeholderów.

## 6. Stos technologiczny i architektura

Wybór: **Flutter** (stabilna wersja, Dart 3, null safety), jedna baza kodu iOS i Android.

- Audio: `just_audio` + `audio_service` (tło, ekran blokady), pobieranie offline, cache segmentów. Zweryfikuj aktualne wersje i alternatywy.
- Stan i architektura: wybierz jeden spójny wzorzec (np. Riverpod, warstwy feature-first, repozytoria) i trzymaj się go. Bez przesadnej inżynierii.
- Backend (minimalny, zaproponuj i uzasadnij Supabase lub Firebase albo lekką alternatywę): uwierzytelnianie, profile, uprawnienia, katalog treści (manifest JSON/CMS, który Dawid może edytować bez kodu), pliki audio na CDN z podpisanymi URL-ami, kontrola dostępu do treści płatnych.
- Płatności: natywne **StoreKit 2** i **Google Play Billing**. Rozważ RevenueCat i **sprawdź, czy jego SDK jest dopuszczalne w kategoriach dla dzieci**, jeśli działa w strefie rodzica. Zapisz wniosek z uzasadnieniem.
- Analityka: **minimalna, anonimowa, bez reklamowych identyfikatorów**, bez trackerów firm trzecich w trybie dziecka. Zweryfikuj zgodność z wymaganiami Apple Kids i Google Families.
- CI/CD: lokalne buildy release (AAB i IPA) plus opis konfiguracji (Fastlane lub GitHub Actions) do podpisywania i wysyłki do TestFlight i Play Internal Testing.

## 7. Bezpieczeństwo dzieci, prywatność i zgodność (obowiązkowe)

Traktuj to jako wymagania, nie dodatki. Zanim zaczniesz, sprawdź **aktualne** zasady (moje informacje mogą być nieaktualne):

- **Apple**: App Store Review Guidelines (w tym 1.3 Kids Category, 5.1.4, 3.1.1 płatności za treści cyfrowe, 4.8 Sign in with Apple), App Privacy labels, prompty uprawnień (mikrofon i ruch z jasnym uzasadnieniem po polsku).
- **Google Play**: Families Policy / Designed for Families, Data safety form, wymagania dot. reklam i SDK w aplikacjach dla dzieci, Play Billing.
- **Prawo**: RODO (dane dzieci, zgoda rodzica, prawo do usunięcia konta i danych, także w aplikacji), COPPA, polskie prawo konsumenckie (subskrypcje, odstąpienie od umowy przy treściach cyfrowych, regulamin).
- Brak reklam, brak linków zewnętrznych bez parental gate, brak zbierania nagrań dziecka (mikrofon przetwarzany lokalnie), minimum danych o dziecku, możliwość usunięcia konta w aplikacji.
- Przygotuj **szkice**: polityki prywatności, regulaminu i tekstów do formularzy sklepów (do weryfikacji prawnej przez Dawida, nie jako porada prawna).

## 8. Design

- Marka: kolory, typografia i postacie z audiokiddo.pl. Jeśli strona ma jasny, minimalistyczny styl, zaproponuj jego rozszerzenie na aplikację (nie kopiuj ślepo stylu referencji).
- Ilustracyjny, ciepły, zabawny charakter. Wyraźne maskotki w onboardingu, ładowaniu i pustych stanach.
- **Tryb dziecka**: cele dotykowe min. 64 dp, minimum tekstu, ikony i dźwięk zamiast napisów.
- **Strefa rodzica**: czytelna typografia, hierarchia informacji jak w Pomelody.
- Mikroanimacje i haptyka z umiarem. Tryb ciemny (przydatny wieczorem) i większe czcionki (dostępność).
- Dostępność: VoiceOver/TalkBack, kontrast WCAG AA, obsługa Dynamic Type.
- Zaproponuj system designu (tokeny kolorów, typografia, komponenty) w jednym miejscu, zanim zbudujesz ekrany.

## 9. Sposób pracy

Pracuj etapami i **po każdym etapie zatrzymaj się na krótkie podsumowanie i pytania**. Nie zaczynaj kolejnego, dopóki Dawid nie potwierdzi.

- **Etap 0: Discovery.** Przejrzyj audiokiddo.pl i referencje. Napisz `ARCHITECTURE.md` (stos, model danych, model uprawnień, format skryptu zabawy, plan zgodności). Zadaj wszystkie pytania naraz (max 10, najważniejsze na górze). Podaj listę „Do dostarczenia przez Dawida" i szacunek pracy.
- **Etap 1: Fundament.** Projekt Flutter, system designu, nawigacja, dane testowe, ekrany Home/Biblioteka/Szczegóły (jeszcze bez backendu).
- **Etap 2: Audio.** Odtwarzacz, tło, ekran blokady, tryb bez ekranu, pobieranie offline, timer snu.
- **Etap 3: Konto, backend, subskrypcja.** Logowanie, profile dzieci, katalog z CMS, płatności, parental gate, usuwanie konta.
- **Etap 4: Silnik gier bez ekranu** i 3 prototypy.
- **Etap 5: Polish i zgodność.** Onboarding z humorem, ankieta, dostępność, wydajność, sprawdzenie zgodności ze sklepami, teksty polityk.
- **Etap 6: Wydanie.** Buildy release, checklisty App Store Connect i Play Console, opisy sklepowe po polsku (słowa kluczowe ASO), plan zrzutów ekranu, TestFlight i testy wewnętrzne.

Zasady jakości:

- Uruchamiaj i testuj aplikację na symulatorze iOS i emulatorze Androida (screenshoty). Nie twierdź, że coś działa, jeśli tego nie uruchomiłeś. Wyraźnie oddzielaj „przetestowane" od „napisane, nieprzetestowane" (np. płatności wymagają kont sklepowych).
- Testy jednostkowe dla logiki (silnik zabaw, uprawnienia, pobieranie). Testy widżetów dla kluczowych ekranów.
- Nie wymyślaj faktów o produktach ani cen. Brakujące dane oznaczaj `TODO(Dawid)`.
- Czytelny kod, krótkie komentarze, `README.md` z instrukcją uruchomienia. Bez martwego kodu i zbędnych zależności.
- Jeśli zasady sklepów wykluczają któryś pomysł z tego promptu, powiedz to wprost i zaproponuj bezpieczną alternatywę.

## 10. Dane od Dawida (uzupełnię przed startem)

- Apple Developer Program (organizacja czy osoba, D-U-N-S): `[TODO]`
- Google Play Console: `[TODO]`
- Bundle ID / package name: `[np. pl.audiokiddo.app]`
- Wydawca / dane firmy, e-mail supportu, URL polityki prywatności: `[TODO]`
- Pliki: audio (3 pakiety, piosenki), okładki, logo (SVG), maskotki, fonty: folder `[TODO]`
- Ceny subskrypcji (miesięczna/roczna) i długość okresu próbnego: `[TODO]`
- Które audiozabawy i piosenki są w bezpłatnej próbce: `[TODO]`
- Preferencje backendu (Supabase/Firebase), jeśli są: `[TODO]`

Zaczynasz od Etapu 0.

# Golden von Ekran — charakter, wygląd i ruch

Propozycja projektowa, 28.09.2026. Uwzględnia prośbę o cięty język dla rodziców, sympatię dzieci oraz animowaną postać. Nie jest jeszcze implementacją w aplikacji.

## Główna myśl

Golden to pies, który zna rodzinny chaos od podszewki. Jest bystry, trochę bezczelny i bardzo ciepły. Dla rodzica — kumpel puszczający oko. Dla dziecka — kompan przygód, który też czasem czegoś nie wie, gubi trop i daje się zaskoczyć.

Jego cięty język kierujemy w stronę sytuacji, przedmiotów i jego własnych psich słabości. Nie wyśmiewa dziecka, odpowiedzi, emocji, wyglądu ani umiejętności rodzica. Unikamy podziału „rodzice kontra dzieci”. Humor czytelny dla obu pokoleń: dziecko lubi zabawną scenkę z psem, dorosły rozpoznaje codzienne życie.

Sposób mówienia: krótkie zdania, naturalna polszczyzna, odrobina suchego dowcipu. Głos ciepły, lekko łobuzerski, bez kreskówkowego pisku. Żart trwa jedno zdanie; zaraz potem jest jasna propozycja zabawy. Nie udaje terapeuty ani eksperta od rozwoju dziecka.

## Przykładowe kwestie do nagrania

| Moment | Golden mówi | Reakcja |
|---|---|---|
| Rano, strefa rodzica | „Kawa znowu zimna? Ty ją ratuj, ja ogarnę zagadki.” | Unosi brew, krótko merda ogonem. |
| Rano, dziecko | „Uszy gotowe? Moje są duże. To trochę nie fair.” | Porusza jednym uchem i przechyla głowę. |
| Wyjście z domu | „Wszyscy gotowi? Czyli szukamy jeszcze jednego buta.” | Spogląda na swoje cztery łapy. |
| Podróż | „Korek. Jedyna wycieczka, na której spacer byłby szybszy.” | Krótkie spojrzenie w bok, potem zaprasza do zagadki. |
| Podróż, dziecko | „Ja pilnuję zagadek. Ty wypatruj czerwonego auta!” | Pokazuje łapą kierunek; bez zachęcania do patrzenia na telefon. |
| Początek przygody | „Plan mam świetny. Nie zapisałem, bo zjadłem ołówek.” | Dumnie podnosi głowę, po pauzie spuszcza uszy. |
| Po zabawie | „Ale pomysł! Mój był o kiełbasie. Znowu.” | Krótki uśmiech i kiwnięcie głową. Nie udaje oceny odpowiedzi przez AI. |
| Pauza | „Przerwa? Dobrze. Mój ogon pracuje bez umowy.” | Siada, ogon zwalnia. |
| Wieczór | „Jeszcze jedna sprawa przed snem? Negocjator w piżamie, szanuję.” | Ziewa i poprawia czapkę. |
| Dobranoc, dziecko | „Nos pod koc, uszy na poduszkę. Resztę przygód zostawimy na jutro.” | Układa głowę na łapach. |
| Brak internetu | „Internet poszedł na spacer. Pobranych zabaw nam nie zabrał.” | Przechyla głowę. Tylko gdy faktycznie są pobrane pliki. |
| Błąd pobierania | „Ten plik jest uparty. Nawet bardziej niż ja przy kąpieli.” | Unosi brew. Pod spodem zwykły komunikat „Nie udało się pobrać. Spróbuj ponownie”. |

Nigdy: „Znowu dajesz dziecku ekran?”, „Nie umiesz?”, „Grzeczne dzieci…”, straszenie utratą przyjaźni lub zakupem. Błędy płatności, usuwanie konta i zgody opisujemy rzeczowo, bez żartów maskujących konsekwencje.

## Stroje i rytm dnia

| Okazja | Wygląd | Tło / zachowanie |
|---|---|---|
| 05:00–10:59 | Turkusowa koszulka, żółta apaszka | Ciepła biel, miękkie poranne światło, krótki przeciąg. |
| 11:00–14:59 | Ta sama baza; opcjonalnie strój odkrywcy | Jasna mięta, ciekawość i przechylenie głowy. |
| 15:00–18:59 | Kamizelka odkrywcy, mały plecak | Turkus i lawenda, przywitanie po powrocie. |
| 19:00–04:59 | Lawendowa piżama i czapka | Granat, ziewanie, spokojny oddech. |
| Wybrany tryb podróży | Apaszka i plecak | Stały tryb podróży ma pierwszeństwo przed zegarem. |
| Pakiet Detektyw | Kapelusz i lupa | Krótka reakcja na wybór pakietu; nie zmienia całej aplikacji. |

Godziny to propozycja oparta na istniejącym `dayPartOf`, nie założenie o porach snu każdej rodziny. Rodzic może ręcznie wybrać „Dzień” / „Wieczór” / „Automatycznie”. Osobne ustawienie jasności interfejsu respektuje preferencje użytkownika. Przebranie nie przerywa trwającego audio i nie wymaga internetu.

Utrzymujemy jeden pysk, proporcje i kolor sierści we wszystkich strojach. Makieta jest pierwszą interpretacją. Przed produkcją trzeba porównać ją z oryginalnym Goldenem ze strony lub dostarczonego pliku.

## Animacje — konkretna specyfikacja

| Stan | Ruch | Czas i uruchomienie |
|---|---|---|
| Wejście na Start | Podnosi głowę, dwa ruchy ogona | 0,8–1,2 s, raz po wejściu, nie przy każdym odrysowaniu ekranu. |
| Spoczynek | Subtelny oddech i okazjonalne mrugnięcie | Oddech 4–6 s; mrugnięcie nieregularnie. Bez podskakiwania w pętli. |
| Dotknięcie psa | Brew, przechylenie głowy, krótka kwestia | Do 3 s. Kolejne dotknięcia nie nakładają animacji ani dźwięków. |
| Mówienie | Kilka delikatnych pozycji pyska | Wyłącznie podczas własnej kwestii Goldena. |
| Słuchanie | Głowa lekko w bok, jedno ucho uniesione | Krótka reakcja przy rozpoczęciu; potem nieruchoma pozycja. |
| Sukces / koniec | Kiwnięcie głową, dwa ruchy ogona | Około 1 s. Bez deszczu nagród i bez powtarzania. |
| Wieczór | Ziewnięcie, głowa na łapach | 2 s przy wejściu, potem spokój. |
| Pobieranie | Patrzy na zwykły pasek postępu | Animacja nie zastępuje procentów, anulowania ani informacji o błędzie. |
| Odtwarzanie audio | Golden uspokaja się, interfejs proponuje odłożenie telefonu | Nie uruchamia nowych żartów i nie mówi ponad nagraniem. |
| Tło / ekran blokady / ograniczony ruch | Nieruchomy wariant | Zatrzymane kontrolery; dźwięk zabawy pozostaje niezależny. |

Po rozpoczęciu odtwarzania rodzic ma widoczne „Możesz odłożyć telefon” oraz łatwo dostępną pauzę. Nie ustawiamy automatycznie jasności całego urządzenia. Tryb bez patrzenia korzysta z istniejącego odtwarzacza i obsługi ekranu blokady.

## Zasady wypowiadania żartów

- Powitanie tekstowe może pojawić się od razu. Głos Goldena domyślnie uruchamia świadome dotknięcie, nie samo otwarcie aplikacji.
- Dwie pule: rodzic i dziecko. W trybie dziecka kwestie proste i zapraszające do zabawy; w strefie rodzica możliwy bardziej suchy dowcip.
- Maksymalnie jedna kwestia na aktywację i co najmniej 30 s przerwy między żartami; brak nakładania dźwięków.
- Zapamiętywać lokalnie ostatnie kwestie, żeby nie powtarzać tej samej przy każdym wejściu. Nie potrzebuje to konta ani śledzenia zachowania dziecka.
- Reakcje zależą od prawdziwego stanu aplikacji. „Pobrane zabawy działają” tylko wtedy, gdy dostęp i pliki faktycznie na to pozwalają.
- Bez ciągłego nasłuchiwania mikrofonem. „Słuchanie” jako poza maskotki nie oznacza aktywnego mikrofonu. Faktyczne użycie mikrofonu ma odrębne, czytelne oznaczenie i uprawnienia.
- Stałe, napisane i zatwierdzone teksty na początek. Generowanie dowolnych odpowiedzi przez model nie jest potrzebne do osiągnięcia tego charakteru.

## Nowy ekran główny

Założenie robocze: obsługuje go głównie rodzic, dziecko potem słucha bez ekranu. Użytkownik nie potwierdził jeszcze wyboru odbiorcy w pytaniu pomocniczym.

1. Logo AudioKiddo i wejście do strefy rodzica. Oryginalne logo z materiałów; napis na wygenerowanej makiecie jest poglądowy.
2. Krótkie powitanie, opcjonalny dymek Goldena, ilustracja postaci zajmująca najwyżej około 1/3 użytecznej wysokości na małym telefonie.
3. Jedna konkretna propozycja: tytuł, rzeczywisty czas i wiek z katalogu, informacja o pobraniu, duże „Włącz”. Zablokowana treść ma inne działanie, nie udaje przycisku odtwarzania.
4. „Wróć do słuchania”, jeśli istnieje postęp.
5. Stałe skróty „W podróży” i „Na dobranoc”. Nie zmieniać im codziennie miejsc — obecny kod przestawia tryby według pory dnia.
6. Dolna nawigacja: Dziś / Biblioteka / Moje. Obecny Plan dostępny z Moje i kontekstowo z Dziś. Utrzymać mini-odtwarzacz oraz wszystkie funkcje.

Biblioteka: okładka, tytuł, długość, grupa wieku; czytelne filtry i „Pobrane”. Zakup oraz konto za właściwą bramką rodzicielską. Tryb dziecka: kilka dużych, dostępnych zabaw, mało tekstu; dotykowe cele co najmniej dotychczasowych 64 punktów logicznych.

## Styl

Ciepła biel zamiast dominującego pomarańczu; turkus, lawenda i żółty jako kolory marki. Granatowy wariant wieczorny. Poppins jest już w projekcie i może pozostać. Tekst ciemny na jasnych przyciskach; sprawdzić kontrast, nie przenosić bez pomiaru kolorów z obrazka. Jedna mocna ilustracja, mniej cieni i dekoracyjnych kafelków.

Makieta `golden-koncepcja.png` pokazuje nastrój. W implementacji należy zmniejszyć ilustrację na małych ekranach, zachować przycisk „Włącz” bez przewijania przy zwykłej wielkości tekstu, a przy dużym tekście umożliwić przewijanie. Wygenerowana wieczorna „Chwila wyciszenia” jest wyraźnie oznaczoną propozycją nowej treści, nie pozycją potwierdzoną w katalogu. Dekoracyjny napis o snach na ilustracji nie jest zatwierdzoną obietnicą produktu i nie powinien wejść do finalnej aplikacji.

## Wdrożenie we Flutterze

Postać powinna mieć oddzielne elementy do ruchu: głowę, oczy, powieki, brwi, pysk, uszy, tułów, łapy i ogon. Do tego nakładane warianty strojów. Pojedynczy PNG z makiety nie wystarczy do wiarygodnego merdania i mimiki.

Proponowany format: przygotowany plik Rive z maszyną stanów, integrowany przez runtime Flutter. Alternatywa zachowująca miękką stylistykę 3D: uprzednio wyrenderowane krótkie sekwencje; wybór wymaga próby rozmiaru plików i wydajności na telefonie. Rive nie zamieni automatycznie tej makiety w animowany model.

Źródło integracji: https://rive.app/docs/runtimes/flutter/flutter.

Adapter `GoldenMascot` może zastąpić obecny `Kiddo`, zachowując istniejące stany idle/talking/listening/happy/sleepy. Dodać strój, porę dnia i ograniczanie animacji. Dobór tekstu i dźwięku trzymać poza samym widgetem. Wszystkie pliki potrzebne do podstawowego działania pakować lokalnie.

Warunki akceptacji: ta sama postać w trzech strojach, brak urwanych animacji, żaden głos nie nakłada się na audiozabawę, poprawna obsługa ograniczonego ruchu, brak pracy animacji w tle, brak żartów powtarzanych przy każdym przejściu, poprawny wygląd na małym telefonie i przy dużej czcionce.

## Stan materiałów

Gotowe: statyczna makieta trzech pór dnia, zasady charakteru, przykładowe kwestie, specyfikacja ruchu i plan integracji.

Niegotowe: potwierdzenie zgodności z oryginalnym Goldenem, osobne elementy ilustracji / rig, plik animacji, nagrania lektora oraz wdrożenie Flutter. Próba wygenerowania osobnego arkusza postaci została odrzucona przez system bezpieczeństwa narzędzia graficznego (kategoria „other”, bez merytorycznego uzasadnienia). Nie powstał z niej plik; nie obchodzono blokady.

> Aktualizacja 15.10.2026: poniżej jest historyczny stan przed naprawami. Aktualne lokalne zmiany i wyniki opisuje [przekazanie dla Claude’a](../../ZMIANY-DLA-CLAUDE-2026-10-15.md).

# AudioKiddo — audyt nowych funkcji, 14.10.2026

## Wniosek

Nowe funkcje są w `audiokiddo-glos`, na gałęzi `build/iphone-2026-10-13`, commit `193d620`, a nie w pierwotnie wskazanym `audiokiddo-app`. Przed przekazaniem testerom trzeba połączyć nowe funkcje z wcześniejszymi poprawkami oraz poprawić edycję planu podczas odtwarzania. Sam zielony wynik obecnych testów nie oznacza braku błędów: dodatkowe próby odtworzyły problemy opisane poniżej.

Audyt nie zmienia kodu aplikacji ani produkcji. Próby wykonano w kopii `/private/tmp/ak-latest-audit`, bez prawdziwych płatności i bez modyfikowania kont użytkowników.

## 1. Najpierw ujednolicić wersję do wydania — P1

`audiokiddo-glos` nie zawiera poprawek wykonanych wcześniej w `audiokiddo-app`:

- DownloadManager nadal używa pojedynczego wyniku dla zdarzenia identyfikowanego skrótem pliku (`download_manager.dart:237`). Nie ma obsługi wspólnych plików, sprawdzania zgodności pobranego pliku z aktualnym katalogiem ani nowych mechanizmów ponowienia i limitów oczekiwania.
- Przywracanie zakupów nadal może pozostawić ekran w stanie oczekiwania po wyjątku (`purchase_controller.dart:219`); `restoreQuietly` także przekazuje wyjątek dalej.
- Uruchomienie aplikacji nadal czeka na inicjalizację pobierania przed pokazaniem interfejsu (`main.dart`).
- Lokalny `supabase/functions/claim-order/index.ts:27` ignoruje błąd ogranicznika prób. Poprawiona funkcja została wdrożona na serwer w poprzednim etapie; wdrożenie starszego pliku z tej gałęzi cofnęłoby zabezpieczenie.
- CI wciąż sprawdza typy tylko wybranych funkcji serwerowych.

**Odtworzenie:** pobranie pliku, następnie zmiana jego SHA w katalogu. `localAudioPath` w nowej gałęzi zwraca starą ścieżkę zamiast odrzucić nieaktualny plik. Test zakończony błędem oczekiwania: `audit_download_test.dart`, log `download.log`.

**Zalecenie:** przenieść wcześniejsze poprawki i testy, zachowując nowe funkcje. Nie zastępować całych katalogów starszą kopią. Z tej jednej połączonej wersji wykonać dopiero build dla testerów.

## 2. Zamiana zabawy może zmienić inną pozycję — P2

**Scenariusz:** gra A, przed nami B i C. Rodzic otwiera „Zamień B”. W czasie wybierania A się kończy i zaczyna B. Wybranie D zamienia C, chociaż rodzic wybrał B.

**Przyczyna:** `plan_editor.dart:135–137` przechowuje pozycję w liście przed oczekiwaniem na wybór. `session.dart:452–463` przelicza tę pozycję względem aktualnego miejsca odtwarzania. Po zmianie nagrania oznacza ona inny element.

**Dowód:** test widgetu korzystający z prawdziwego PlanEditor i SessionController; wynik `[A, B, D]` zamiast zachowania C. Log `new-functions.log`.

**Poprawka:** identyfikować pozycję stałym identyfikatorem kroku. Po zatwierdzeniu sprawdzić, czy wybrany krok nadal jest przed nami. Jeśli już gra albo został usunięty, anulować zamianę z krótkim komunikatem. Dodać test dla przejścia nagrania w trakcie otwartego wyboru.

## 3. Dodanie czasu przy końcu podróży pomija nową zabawę — P2

**Scenariusz:** ostatnia zabawa dobiegła końca, Szop’en wygłasza zakończenie, rodzic otwiera plan i dokłada zabawę/czas. Dodana zabawa nie jest odtwarzana; zakończenie może zabrzmieć ponownie.

**Przyczyna:** `plan.dart:52–56` wstawia nagranie po ostatnim ItemStep, czyli przed aktualnie wykonywanym komunikatem końcowym. Indeks pętli w SessionController nie jest dostosowywany.

**Dowód:** test z kontrolowanym końcowym komunikatem. Wynik: `item:A, line:trip_end, line:trip_end`, brak B. Log `new-functions.log`.

**Poprawka:** w trwającej sesji dodawać kroki wyłącznie przed nami, z uwzględnieniem aktualnego kroku. Alternatywnie zablokować dodawanie w fazie zakończenia i dać wyraźną opcję uruchomienia kolejnego planu.

## 4. Dotknięcie nie pomija kurtyny przy wolnym katalogu — P2

**Scenariusz:** katalog nadal się ładuje, rodzic dotyka ekranu, ale kurtyna pozostaje aż do uzyskania katalogu albo limitu czterech sekund.

**Przyczyna:** `launch_greeting.dart:155` najpierw czeka na `_news()`, a dopiero w linii 159 obsługuje sygnał pominięcia. Test samego LaunchCurtain sprawdza tylko wywołanie callbacku, nie rzeczywiste zamknięcie.

**Dowód:** test pełnego LaunchGreeting z celowo opóźnionym katalogiem; po dotknięciu i zakończeniu czasu animacji wyjścia kurtyna nadal jest widoczna. Log `new-functions.log`.

**Poprawka:** pominięcie ma zamykać kurtynę niezależnie od odczytu katalogu. Jeśli wiadomości nie są gotowe, zrezygnować z powitania w tym uruchomieniu, aby nie pojawiało się później pod palcem.

## 5. Wcześniejsze błędy czasu nadal występują

Kod `catalog_providers.dart` nie zmienił się względem poprzedniego audytu. Obie próby powtórzone na nowej gałęzi zakończyły się błędem:

- **P1:** wcześniej obliczone uprawnienie pozostaje `playable` po terminie ważności, dopóki nie nastąpi ponowne przeliczenie. Szczególnie istotne dla pobranych nagrań; serwer może odrzucać streaming niezależnie od stanu ekranu.
- **P2:** premiera nie pojawia się w już załadowanym katalogu po zmianie daty bez jego ponownego przeliczenia.

Zegar zwraca bieżącą datę, lecz nie wysyła powiadomienia o upływie czasu. Zalecane odświeżanie na granicach ważności/premiery i po powrocie aplikacji na pierwszy plan oraz ponowna kontrola dostępu przed rozpoczęciem odtwarzania.

Dowody: `audit_clock_test.dart`, log `extra.log`. Wcześniejszy problem „Dobranoc” na koncie członka rodziny także nie został naprawiony w tej gałęzi: migracja jest identyczna. Jego odtworzenie SQL i opis pozostają w raporcie poprzedniego audytu w `audiokiddo-app/docs/audyt-2026-10-14/AUDYT-DECYZJE.md`; w tym przebiegu nie powtarzano osobnej próby tego błędu.

## 6. Nawigacja odtwarzacza — podstawowa poprawka działa, pełna gwarancja wymaga doprecyzowania

Trzy istniejące testy przechodzą: powtórne otwarcie odtwarzacza, bezpośrednia zamiana odtwarzacza na grę oraz powrót z kolejki do odtwarzacza.

Dodatkowy test samego helpera wykazał, że stos `[Start, odtwarzacz, kolejka]` i żądanie otwarcia gry daje oba ekrany: odtwarzacz i grę. Helper sprawdza tylko szczyt i jeden poprzedni element (`open_player.dart:30–36`). **To ograniczenie funkcji, nie potwierdzony scenariusz dostępny w obecnym UI:** kolejka wyklucza gry interaktywne. Nie traktuję go jako blokera wydania. Warto przed rozbudową nawigacji zapewnić pojedynczy ekran odtwarzania w całym stosie. Dowód: `audit_navigation_test.dart`, log `extra.log`.

## Co sprawdzono i działa w objętych testami przypadkach

- Prawdziwe logo, animacja w jasnym i ciemnym motywie na małym ekranie, statyczny obraz przy ograniczonym ruchu.
- Domyślna płaska biblioteka, wyszukiwanie tytułu bez polskich liter i po słowie, filtr darmowych nagrań.
- Dodatkowe próby wyszukiwania po nazwie pakietu i kolejności „Najnowsze”/„Najkrótsze”.
- Ukrywanie i przywracanie kart. Dodatkowa próba odtworzenia providera z tą samą bazą sprawdza, że zapis jest trwały.
- Otwieranie planu przez tytuł karty obiadu, usuwanie pozycji, dokładanie czasu, uruchomienie sesji, otwarcie edycji w trakcie; warianty czasu podróży.
- Podstawowe operacje na planie: zamiana, usuwanie, przestawianie i dodawanie.
- Opisy gestów są dodane do samouczka i „Co potrafi AudioKiddo”. Pełne wykonanie gestów na fizycznym telefonie pozostaje do testu urządzeniowego.

## Testy i ograniczenia

Wyniki wykonania są podane w `WYNIKI.md`; pełne logi w `logs/`.

Analiza zgłasza jeden warning: nieużywany import w `app/test/plan_screens_test.dart:3`. To drobna poprawka, ale bieżące CI uruchamia `flutter analyze --fatal-infos`, więc należy ją usunąć przed wydaniem.

Testy małych ekranów wypisują ostrzeżenia o nietrafionych kliknięciach w samouczku (`small_screens_test.dart:145`). Zielony wynik nie potwierdza przejścia wszystkich jego kroków. Wzmocnić asercje: przycisk dostępny do dotknięcia, tytuł następnego kroku i faktyczne zniknięcie samouczka. W teście planu ignorowane kliknięcie „Zakończ” nie sprawdza zakończenia sesji.

Nie wykonywano nowego builda sklepowego tej gałęzi, rzeczywistych zakupów, testów na fizycznych iPhone/Android, przerw telefonicznych ani długiego odtwarzania w tle. Wcześniejsze udane buildy dotyczą innej wersji i nie są dowodem dla `193d620`. Audyt nie stanowi potwierdzenia braku wszystkich luk.

## Co warto wprowadzić

**Przed testerami:** jedna gałąź wydania; przeniesienie wcześniejszych poprawek; naprawy planu i czasu; test login → zakup sandbox → pobranie → restart offline → zmiana konta. Formularz zgłoszenia z numerem wersji/builda, modelem telefonu i krokami odtworzenia. Dodać widoczne ostrzeżenie, jeśli plan w trybie offline zawiera niepobrane nagrania.

**Mała optymalizacja:** `AllPlaysView` tworzy wszystkie wiersze listy podczas budowania ekranu, a przy wpisywaniu zapytania oblicza wyniki także dla statystyk. Zastosować listę budowaną na żądanie i wykorzystywać raz obliczony wynik. Korzyść zmierzyć na większym katalogu i starszym telefonie; nie stwierdzam na podstawie samego kodu, że bieżąca lista już klatkuje.

**Po pierwszej turze testów:** dopracować zapamiętywanie planu, kolejność i pamięć filtrów biblioteki oraz ewentualnie więcej opiekunów. Teraz większą wartość da stabilność odtwarzania i czytelne zgłaszanie błędów niż kolejne funkcje.

## Uruchamianie prób

Pliki `proby/*_test.dart` należy skopiować do `app/test/` w roboczej kopii tej wersji; korzystają z istniejących helperów testowych. Próby regresji celowo oczekują poprawnego zachowania i obecnie nie przechodzą. Dla pobierania załączono pojedynczy uruchomiony przypadek: `catalog update does not play the previous file and queues the new version`.

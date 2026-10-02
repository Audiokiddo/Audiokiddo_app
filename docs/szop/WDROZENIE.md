> Aktualizacja 2.10.2026: nowy układ przeszedł 127 testów i analizę; aktualny APK jest zbudowany. Szczegóły i galeria: [status przebudowy](../../docs/SCREEN-REFERENCE-STATUS.md). Poniżej zapis wcześniejszego etapu.

> Ten raport opisuje poprzedni etap. Przebudowa według screenów i najnowsza mimika wymagają ponownej weryfikacji — zobacz ../SCREEN-REFERENCE-STATUS.md.

# Szop’en von Ekran — wdrożenie lokalne

Wybrany przez użytkownika kierunek: oryginalne ilustracje 2D, imię Szop’en von Ekran (Szop’en).

## Co działa
- Rysowana wektorowo interpretacja szopa z referencji w istniejącym komponencie Kiddo: Start, zabawy, onboarding, podróż, dobranoc i inne dotychczasowe miejsca maskotki.
- Oddzielny ruch ogona, uszu, brwi, spojrzenia, mruganie, oddech i machanie. Dzieci otrzymują otwarte, przyjazne oczy; rodzice przymrużone oczy i uśmieszek.
- Dotknięcie maskotki otwiera panel; przycisk kolejnego tekstu wywołuje krótką wesołą reakcję.
- Zachowana rotacja 162 tekstów, odświeżone kwestie pracownika AudioKiddo, osobne pule dla dzieci i rodziców. Bez generowania i odtwarzania nowej mowy.
- Systemowe ograniczenie animacji, ustawienie aplikacji, zatrzymanie ruchu w tle i w ukrytych zakładkach.
- Statyczne, lekkie grafiki widgetów Android/iOS. Nazwy plików golden_* pozostawione dla zgodności natywnych integracji.
- Kremowe tło, kolorowe kafelki Startu, turkusowe akcje, fioletowy odtwarzacz, szop przy timerze i dopasowany tryb ciemny. Istniejące kolory marki pozostają w AkBrand.

## Granice wdrożenia
Rysunek jest rekonstrukcją wektorową, nie wyciętą identyczną naklejką z JPEG. Nie wszystkie scenki z arkuszy (fotel, uciekający mózg, płonący wózek) zostały odtworzone. Zrzuty w katalogu wdrozenie pokazują realne widoki Flutter z katalogiem testowym. Zmiany lokalne; aplikacja nie została opublikowana w sklepach. Nie zmieniano ani nie cięto nagrań.

## Podgląd
- wdrozenie/start.png
- wdrozenie/biblioteka.png
- wdrozenie/szopen-spotkanie.png
- wdrozenie/szopen-animacja.gif

Eksport: flutter test tool/render_golden_test.dart tool/render_szopen_screens_test.dart (z katalogu app).

## Weryfikacja
- Pełny zestaw aplikacji: 122 testy zakończone powodzeniem.
- Po ostatniej korekcie ciemnej palety: 18 testów kontrastu, sesji i małych ekranów zakończone powodzeniem.
- Osobno: 4 testy maskotki, w tym reakcja po kliknięciu, ograniczenie ruchu i zatrzymanie w tle.
- Eksport rzeczywistych widoków oraz sprawdzenie odtwarzacza przy szerokości 320 i skali tekstu 135% zakończone powodzeniem.
- Flutter analyze: bez uwag.

# AudioKiddo: raport z Etapu 3, część B (Studio)

Data: 2026-09-26.

## Zaimplementowane

- **Studio** (`studio/`, Flutter Web) na lokalnym szkicu katalogu:
  - lista treści z oznaczeniem błędów;
  - edycja pozycji, pakietów i półek (kolejność przeciąganiem);
  - edytor skryptów gier interaktywnych z szablonem;
  - wybór plików audio i PDF z automatycznym rozmiarem i SHA-256;
  - publikacja przez eksport `catalog.json` z podbitą wersją, zablokowana, gdy katalog ma błędy.
- **Walidacja tym samym kodem co aplikacja** (`ak_core`). Komunikaty przetłumaczone na zrozumiałe polskie zdania z nazwą pola lub kroku (np. „Opis dla rodzica: nie może być puste”, „Błąd w kroku „intro”: nieznane nagranie…”). Dodatkowo wykrywa półki wskazujące na nieistniejące pozycje.
- **`ak_core`**: publiczna funkcja `parseGameScript`.

## Przetestowane

| Test | Wynik |
|---|---|
| Studio: 8 testów (import prawdziwego katalogu aplikacji bez błędów, wykrywanie i polskie komunikaty, zmiana ID na półkach, usuwanie, szablon skryptu, eksport z podbiciem wersji i zachowanie szkicu, edycja w interfejsie) | ✅ |
| `flutter analyze` Studio | ✅ |
| Przeglądarka (build release): lista, edytor pozycji, zmiana rodzaju na grę, edytor skryptu z błędami, blokada publikacji przy błędzie | ✅ |

## Ograniczenia

- **Tryb lokalny**: pliki audio nie są nigdzie wysyłane (Studio liczy tylko rozmiar i sumę), a katalog trafia do aplikacji przez podmianę `app/assets/mock/catalog.json`. Wysyłka plików, logowanie administratorów, publikacja i przywracanie wersji wymagają Supabase.
- **Brak odsłuchu** w Studio: dojdzie razem z wysyłką plików.
- **Przestawianie kroków skryptu** jest możliwe tylko przez zmianę „Następny krok”; kolejność kart nie ma znaczenia dla działania.

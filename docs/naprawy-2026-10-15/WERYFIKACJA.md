# Weryfikacja lokalnych napraw — 15.10.2026

Projekt: audiokiddo-glos, baza 193d620. Zmiany pozostają w lokalnych plikach bez commita i bez wdrożenia.

| Sprawdzenie | Wynik |
| --- | --- |
| flutter analyze | Brak problemów |
| Pełne testy standardowe | 312 zaliczonych, 1 pominięty |
| Pełne testy z ustawieniami App Store | 310 zaliczonych, 3 pominięte |
| Ostateczny test ekranów planu i rzeczywistego powrotu na Start | 4 zaliczone |
| Deno: testy funkcji | 90 zaliczonych |
| Deno: sprawdzenie typów wszystkich funkcji | Sukces |
| Wszystkie migracje + schema_test.sql na jednorazowym PostgreSQL 17 | Sukces, w tym nowa regresja rodzinnego Dobranoc |
| git diff --check | Sukces |

Pełny zestaw standardowy uruchomiono przed ostatnią poprawką testu trafiania w przycisk Start; potem ponownie przeszły cztery testy planu oraz cały zestaw App Store. Kod produkcyjny był ten sam, poza doprecyzowaniem komentarza w main.dart.

## Kompilacje lokalne

- iOS release z ustawieniami App Store, bez podpisu: sukces. Wynik w `app/build/ios/iphoneos/Runner.app`.
- Android release APK: sukces. Wynik w `app/build/app/outputs/flutter-apk/app-release.apk`.
- Niczego nie wysłano do sklepu ani na urządzenie. Build iOS wymaga podpisania przed dystrybucją.

Android wypisuje ostrzeżenia zgodności narzędzi Kotlin/Gradle, wersji schematu Android SDK oraz oczekiwanej czcionki CupertinoIcons. Kompilacja kończy się sukcesem; w kodzie aplikacji nie znaleziono bezpośrednich odwołań do CupertinoIcons. Nie aktualizowano zależności platformowych w ramach tych napraw; oględziny natywnych kontrolek pozostają częścią testów urządzeniowych.

## Granice weryfikacji

Testy audio, sieci i sklepów używają atrap. Nie wykonano prawdziwych płatności ani próby na fizycznym telefonie. Podpisywanie i dystrybucja builda oraz migracja produkcyjnej bazy nie były objęte zgodą na ten lokalny etap.

Logi pełnych testów zawierają komunikaty Dart VM „Callbacks into the Dart VM are currently prohibited…” także obecne w historycznym logu sprzed zmian. Testy kończą się powodzeniem. Przyczyny tego komunikatu nie ustalono; wynik nie zastępuje sprawdzenia logów i odtwarzania na urządzeniach.

Lista zmienionych plików kodu z sumami SHA-256: `pliki-zmian.sha256.json`. Logi: `logs/`. Aktualne testy znajdują się w `app/test/`, a stare próby audytowe pozostają wyłącznie dowodem poprzedniego stanu.

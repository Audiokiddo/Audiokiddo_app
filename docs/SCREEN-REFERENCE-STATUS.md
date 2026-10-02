# Przebudowa według screenów — zweryfikowane wdrożenie

## Punkt odniesienia
Dwa arkusze „Zdjęcie 1.jpg” i „Zdjęcie 2.jpg” przesłane przez użytkownika w tej rozmowie. Nowa hierarchia zastępuje poprzedni Start z wielkim hero. Zachowany rzeczywisty katalog AudioKiddo i model dostępu do płatnych materiałów.

## Zapisane w kodzie
| Ekran | Układ i funkcje |
|---|---|
| Start | Logo, wyszukiwanie, profil, 4 kafelki 2×2, kontynuacja z rzeczywistej historii |
| Nawigacja | Start, Biblioteka, Ulubione, Więcej; Plan przeniesiony do Więcej |
| Biblioteka | Typ, serie, przedziały wieku, 6 kategorii 2×3, wyszukiwanie, lista kategorii, czas trwania |
| Ratunku | 10/20/30/45 minut, 5 nastrojów, rzeczywiste wymagania materiałowe, oddzielny wynik; bez propozycji przekraczających limit czasu |
| Szczegóły | Duża ilustracja, metadane, opis, odtwarzanie, pobieranie, materiały i dodawanie nagrań do kolejki |
| Odtwarzacz | Fiolet, ilustracja nagrania, tytuł, serce, postęp, ±15 s, play, tempo/timer/pobierz/kolejka |
| Timer | Po nagraniu, 15/30/45/60 minut, wyłączenie, zatwierdzenie wyboru; zatrzymuje dźwięk, nie zamyka aplikacji |
| Profil | Zmiana dziecka, edycja imienia i wieku, rzeczywiste statystyki i historia |
| Rutyny | Pięć gotowych trybów, lokalny zapis własnych kolejek jako rutyn |
| Kolejka | Dodawanie, usuwanie, przeciąganie, zapis, kolejne odtwarzanie nagrań, błędy dostępu, zatrzymanie po nagraniu z timerem |
| Pobrane | Gotowe i trwające pobrania, postęp, ponowienie, usuwanie, prawdziwe zużycie miejsca |
| Powitanie | Kompozycja „Więcej niż słuchanie” z Szop’enem |

Ilustracje kategorii są autorskimi lekkimi rysunkami w aplikacji, a nie wycięciami z referencyjnych miniaturek. Nazwy i nagrania pozostają z katalogu. Kolejka obsługuje nagrania ciągłe; gry wymagające odpowiedzi uruchamia się osobno.

## Szop’en
Nowa asymetria brwi, bardziej otwarte oczy ze spojrzeniem z ukosa, mały półuśmiech; dla dzieci nadal przyjazna mimika. 16 przeredagowanych wypowiedzi spotkania. Krótki dymek na Starcie po 12 sekundach, najwyżej raz na dzień, zamykany, znika po 10 sekundach. Nie pojawia się przy aktywnym materiale audio. Ustawienie w Więcej pozwala wyłączyć automatyczne żarty; wywołanie ręczne pozostaje dostępne.

## Weryfikacja — 2 października 2026
- Analiza Flutter: bez błędów i ostrzeżeń analizatora.
- Eksport podglądów: poprawny; obejrzano Start, Bibliotekę, Ratunku i wynik, odtwarzacz, timer, profil, rutyny, kolejkę i Szop’ena.
- Po kontroli wizualnej poprawiono kontrast timera oraz ikonę przewijania o 15 sekund.
- Poprawiono nagłówek przy dużym tekście; dymek znika także wtedy, gdy odtwarzanie rozpocznie się już po jego pokazaniu.
- Układ i interakcje: 17 testów ekranów i dostępności przeszło po poprawkach.
- Pełen zestaw: **127 testów zaliczonych** (3 min 16 s), w tym iPad, małe telefony, duży tekst, kolejka, rekomendacje i trwałość rutyn. Końcowe uruchomienie wykonano kolejno, bez kolizji równoległych procesów Flutter.
- Android debug APK zbudowany poprawnie. To wersja do lokalnego sprawdzenia, nie publikacja w sklepie.
- Zaktualizowano grafiki natywnych widgetów i GIF animacji. Widget systemowy ma statyczną ilustrację; animacje działają wewnątrz aplikacji.
- Nie wykonywano w tej rundzie testu na fizycznym telefonie ani budowania iOS.
- Gradle zgłasza przyszłą niezgodność użycia Kotlin Gradle Plugin przez flutter_timezone i home_widget; obecny build kończy się poprawnie.

## Pliki do obejrzenia
- Galeria rzeczywistych ekranów: [redesign-reference/index.html](redesign-reference/index.html).
- Animacja: [szop/wdrozenie/szopen-animacja.gif](szop/wdrozenie/szopen-animacja.gif).
- Aktualny Android APK: [app-debug.apk](../app/build/app/outputs/flutter-apk/app-debug.apk).

Galeria używa katalogu testowego oraz przykładowego dziecka i kolejki. Nie przedstawia prawdziwej historii użytkownika. Ilustracje są uproszczonymi wektorami, a nie identycznymi okładkami z przesłanych screenów.

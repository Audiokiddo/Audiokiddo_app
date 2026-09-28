# Golden von Ekran — pierwsze wdrożenie

## Gotowe

- Oryginalny rysunkowy golden retriever: długie uszy, szeroki pysk, złota sierść, uniesiona brew, apaszka, łapy i ogon.
- Animacja niezależnych elementów: ogon, uszy, machająca łapa, mruganie, oddech i pysk podczas mówienia. Przechylenie głowy przy słuchaniu; zamknięte oczy w trybie snu.
- Trzy stroje: turkusowa koszulka, kamizelka podróżnika, lawendowa piżama.
- Zastępuje poprzednią okrągłą maskotkę przez istniejący komponent `Kiddo`, więc jest widoczny także w powitaniu, trybie dziecka, podróży, sesjach i grach.
- Start: dotknięcie Goldena otwiera spotkanie z rodzicielskimi żartami i przyciskiem kolejnej kwestii. Te nowe kwestie są tekstowe i nie zagłuszają audio. Głos lektorski do nich pozostaje do nagrania.
- Gry interaktywne: przyjazna mina, reakcje na stan gry. Golden słucha podczas nagrania lektora, nie udaje, że mówi jego tekst. Bez zmian zawartości istniejących ciągłych MP3.
- Widżety iOS i Android: grafiki tej samej postaci, dobierane do pory dnia, z zachowaniem istniejących skrótów do aplikacji. Widżety przedstawiają statyczne pozy; pełna animacja działa we Flutterze.
- Ograniczanie ruchu: cała postać nieruchoma przy ustawieniu systemowym, wyłączonym TickerMode oraz nieaktywnej aplikacji.

## Materiały

`golden-animacja.gif` — podgląd merdania, gestu łapy, mrugania i oddechu. `golden_day.png`, `golden_adventure.png`, `golden_pajamas.png` — eksporty stroju. Autorska grafika została narysowana natywnie we Flutterze; nie jest podmienionym obrazem żadnej postaci filmowej ani wygenerowanym modelem 3D. Jest to rysunkowa wersja do oceny przez właściciela marki.

Źródło grafiki i przegubów: `app/lib/core/widgets/golden_painter.dart`. Źródło animacji: `app/lib/core/widgets/kiddo.dart`. Eksport plików obu widżetów można powtórzyć z folderu `app`: `flutter test tool/render_golden_test.dart`. Nie edytować ręcznie samych eksportów, bo przestaną odpowiadać postaci w aplikacji.

## Kolejność dalszej pracy

1. Ocena charakteru i proporcji tej działającej wersji postaci.
2. Nagranie właściwego głosu Goldena i dopasowanie istniejących nagrań interfejsu, które nadal używają roboczego głosu / dawnej nazwy Kiddo.
3. Łapa ratunkowa z bezpiecznym zatrzymaniem sesji, ponowieniem polecenia oraz podpowiedziami napisanymi do konkretnych zadań. Nie została dodana w tym etapie; przycisk nie może udawać funkcji bez gotowej obsługi stanu gry.
4. Dopiero potem ciągłe pakiety MP3: ustalenie granic zdań i zadań, zachowanie oryginałów, eksport segmentów, kontrola klików i muzyki na łączeniach, przypisanie pomocy i przejść.

Cięcie audio można wykonać lokalnie dostępnym FFmpeg. Wymaga zatwierdzonej mapy fragmentów (ustalonej na podstawie treści / transkrypcji / odsłuchu), a nie samego automatycznego wykrywania ciszy. Oryginalne MP3 pozostają nienaruszone. Cięcie nie usuwa lektora ani nie rozdziela automatycznie głosu i muzyki ze zmiksowanego nagrania.

## Zakres weryfikacji

Wyniki testów i kompilacji uzupełnione w końcowej informacji. Podgląd animacji pochodzi z tego samego natywnego rysownika co aplikacja; nie jest nagraniem ekranu telefonu. Interfejs automatyzacji nie udostępnił aplikacji Simulator, więc pełna kontrola wizualna systemowych widżetów na ekranie urządzenia pozostaje do wykonania. Wcześniejsze luki zakupów i dostarczania audio z audytu nie są naprawiane jako część zmiany maskotki.

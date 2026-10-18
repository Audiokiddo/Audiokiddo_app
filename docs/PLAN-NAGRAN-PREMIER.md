# Plan nagrań premier (stan 18.10.2026)

Zakryte karty w Nowościach obiecują datę. Bez nagrań karta po dacie pokaże „Już wkrótce” (zabezpieczone w aplikacji), ale rodzic zobaczy niedotrzymaną obietnicę. Każda premiera potrzebuje więc tego samego rytmu pracy, liczonego od daty premiery (D).

## Rytm jednej premiery

| Kiedy | Co | Kto |
|---|---|---|
| D−10 | Scenariusz: kwestie Szop’ena, pytania, odpowiedzi dziecka, zakończenia | Claude pisze szkic, Nela poprawia |
| D−7 | Akceptacja scenariusza | Nela i Dawid |
| D−5 | Nagranie głosem Szop’ena (ElevenLabs, `tool/game_content.py --voice szop`) i test w telefonie | Claude |
| D−4 | Wgranie plików na serwer (`tool/files_update.sh`, folder `audiokiddo-pliki`) | Dawid albo Claude za zgodą |
| D−2 | Katalog: zdjęcie `"planned": true`, skrypt i rozmiary w `catalog.json`, publikacja w Studiu (Serwer → Opublikuj) | Claude |
| D | Karta odwraca się sama; powiadomienie dla rodziców, którzy je włączyli | aplikacja |

Koszt: zabawa 6–10 minut to około 2000–3500 znaków ElevenLabs.

## Kalendarz

| Premiera | Zabawa | Wiek | Długość | Scenariusz do | Nagranie do | Publikacja do |
|---|---|---|---|---|---|---|
| 24.10 (sob.) | Kasztanowe ludziki | 3–9 | 8 min | 14.10 (już po terminie: pilne) | 19.10 | 22.10 |
| 31.10 (sob.) | Kto zgubił parasol? | 3–9 | 7 min | 21.10 | 26.10 | 29.10 |
| 7.11 (sob.) | Pociąg do Bajkowa | 3–9 | 10 min | 28.10 | 2.11 | 5.11 |
| 14.11 (sob.) | Wielka wyprawa po kapcie | 3–9 | 6 min | 4.11 | 9.11 | 12.11 |
| 21.11 (sob.) | Znikające rękawiczki (detektyw) | 7+ | 12 min | 11.11 | 16.11 | 19.11 |
| 28.11 (sob.) | Poczta do Mikołaja | 3–9 | 8 min | 18.11 | 23.11 | 26.11 |

## Co zrobić, gdy termin nie wyjdzie

Przesunąć datę `released` w `catalog.json` o tydzień i opublikować katalog przed dawną datą. Karta pokaże nową datę, a rodzic nie zobaczy „Już wkrótce”.

## Pomysły na treść (do rozwinięcia w scenariuszu)

- **Kasztanowe ludziki:** dziecko nadaje imiona (rozpoznawanie słów jak w Zgubionej Gwiazdce), wybiera, dokąd jadą („las” albo „park”), na końcu zadanie dla rodzica: zrobić prawdziwego ludzika.
- **Kto zgubił parasol?:** trzy wskazówki, trzech podejrzanych (jeż, kaczka, ślimak), odpowiedź słowem albo klaśnięciem.
- **Pociąg do Bajkowa:** cztery stacje, na każdej wybór „zabieramy” albo „zostawiamy”, liczenie pasażerów.
- **Wielka wyprawa po kapcie:** zagadki strażników spod łóżka, ruch w miejscu (bez wstawania z fotelika w wersji do auta).
- **Znikające rękawiczki:** sprawa z teczką PDF jak inne zagadki detektywa, poszlaki po kolei, wskazanie winnego.
- **Poczta do Mikołaja:** pytania Szop’ena, odpowiedzi dziecka zapisuje rodzic; na końcu rodzic dostaje gotowy list do wydrukowania.

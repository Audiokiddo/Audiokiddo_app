# Lord Von Ekran: jeden pies, dwa wcielenia

Stan: 29.09.2026. Postać narysowana we Flutterze (`app/lib/core/widgets/golden_painter.dart`, strój `GoldenOutfit.official` i stroje dziecięce), kwestie w `app/lib/features/lord/lord_lines.dart`.

| | Dla dziecka | Dla rodzica |
|---|---|---|
| Wygląd | Golden w apaszce: koszulka rano, kamizelka podróżnika w dzień, piżama wieczorem | Funkcjonariusz Biura Spraw Domowych: prochowiec z paskiem, koszula z krawatem, kapelusz, monokl, kamienna twarz (krzywy półuśmiech) |
| Mówi | Na głos, ciepło i ciekawie („Uszy gotowe? Moje są duże. To trochę nie fair.”) | Tylko tekstem na ekranie, maszynopisem, bez wykrzykników i emoji, fakty i godziny („Cisza od 14:07. Wszczęto postępowanie.”) |
| Gdzie | Tryb dziecka, magiczne wejście, gry, W drogę, Dobranoc | Notatka „akta” na Starcie przy każdym uruchomieniu, karta dnia, okienko „poznaj mnie”, dopisek „DLA RODZICA” w grach, podróży, Dobranoc i trybie dziecka, widżet |

Zasada podwójnego kanału: gdy Lord mówi łagodnie do dziecka (audio), rodzic widzi na ekranie jego suchy dopisek. Dopiski nigdy nie mówią na głos i nie zagłuszają nagrań. Zmieniają się najwyżej co 30 sekund, a pula kwestii pamięta, gdzie skończyła, więc nie powtarzają się przy każdym wejściu.

Widżet (iOS i Android): Lord w prochowcu (wieczorem w piżamie) i codziennie inny, lżejszy żart na każdą porę dnia (pula `widget…`), wpisywany przez aplikację do widżetu przy każdym uruchomieniu.

Ton według „Audiokiddo — strategia komunikacji”: żartujemy z rzeczy, sytuacji i systemu, nigdy z dziecka ani z tego, jak rodzic sobie radzi. Test `app/test/lord_test.dart` pilnuje: brak wykrzykników i emoji w kwestiach rodzica, długość, rotacja żartów w widżecie.

## Do zrobienia z Waszej strony

- Nagranie głosu Lorda dla dziecka (teraz głos zastępczy z syntezatora, `tool/ui_voice.py`; teksty w `docs/NAGRANIA-DO-GIER.md`, sekcja „Głos Lorda”).
- Akceptacja wyglądu obu wcieleń (`docs/golden/golden_official.png` i pozostałe stroje).
- Łapa ratunkowa i cięcie ciągłych nagrań pakietów: osobny etap (plan w `docs/golden/WDROZENIE.md`).

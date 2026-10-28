# Prompt dla lokalnej sesji z kodem Care

Wklej to w sesji Claude Code uruchomionej w `/Users/dawidkubiak/Desktop/claude folder/audiokiddo-glos`. Odpowiadaj po polsku, kod i commity po angielsku. Nie wypisuj sekretów. Wdrożenia (Supabase, FileZilla, sklepy) tylko po wyraźnej zgodzie w czacie. Po każdej większej zmianie dopisz ją do `PRZEKAZANIE-SESJI-2026-10-28.md` w Skarbnicy.

```
Pracujemy nad zakładką Care („Uszy w górę”) w AudioKiddo. Najpierw przeczytaj w repo (po `git pull` z gałęzi claude/busy-babbage-aeq1ro albo z plików skopiowanych przez Dawida): docs/care/KONCEPCJA-CARE.md, docs/care/EKRAN-CARE-PROJEKT.md, docs/care/odcinki/tacka-czy-taczka.md oraz docs/care/komplet-promptow-0-5.md. Zrzut ekranu zakładki Care wskazał siedem problemów (tabela w EKRAN-CARE-PROJEKT.md, pkt 1).

Zadania w tej kolejności:
1. Napraw kontrast i kolory (karta gwiazdek, hero) z tokenów motywu; test kontrastu w jasnym i ciemnym trybie.
2. Usuń procenty wyniku (np. „wychodzi 93%”); zastąp paskiem Pon–Nie z gwiazdkami za udział.
3. Usuń duplikat odtwarzacza (karta „Wróćmy do zabawy” i pasek „Pauza”): jedno miejsce nad dolną nawigacją.
4. Przebuduj zakładkę wg EKRAN-CARE-PROJEKT.md, pkt 2: nagłówek „Uszy w górę”, pasek tygodnia, okładki zestawów (Szumiąca Szafa, Koszyk Rymusia, Kot Bąbel), sekcja „Dla rodzica”, pierwsze otwarcie. Dotychczasowe gry głosem przenieś niżej z opisem zgody rodzica.
5. Dodaj ekran po zabawie: „łatwo / w sam raz / trudno” (zapis lokalny), pytania do rozmowy, wskazówka. Karta tygodnia jako PDF z lokalnych zapisów.
6. Połącz ze Startem (pkt 3 w EKRAN-CARE-PROJEKT.md): karta pod „Zabawą dnia”, opcje w „Co teraz?”, propozycja po zabawie, filtr w Bibliotece.
7. Wgraj odcinek próbny jako zabawę w zestawie Szumiąca Szafa, oznaczony „odcinek próbny”.

Odcinek próbny: uruchom `python3 tool/care_episode.py tacka-czy-taczka --dry-run` (policzy znaki), potem bez `--dry-run` (klucz ElevenLabs jest w pęku kluczy Dawida; nie pytaj o niego, nie wypisuj go). Powstanie app/assets/audio/care/tacka-czy-taczka.m4a i .timeline.json. Głosy: „szop” (Szop’en) i „nela” (Szuszu).

Zasady: bez ikon ✨/auto_awesome i emoji-ikon; Care ma wyglądać jak AudioKiddo, nie medycznie; bez ocen wymowy i procentów; mikrofon i rozpoznawanie mowy tylko po zgodzie rodzica, na urządzeniu; bez „leczy”, „diagnozuje”, „terapia”; wiek jako poziom zabawy. Po zmianach uruchom `flutter analyze` i `flutter test` w app/. Instalacja na iPhonie: AK_DEVICE=00008120-001408903463C01E bash tool/phone_build.sh. Na końcu pokaż zrzuty ekranu w jasnym i ciemnym trybie.
```

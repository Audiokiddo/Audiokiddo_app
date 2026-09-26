# AudioKiddo: raport z Etapu 4 (silnik gier i prototypy)

Data: 2026-09-27.

## Zaimplementowane

| Element | Szczegóły | Gdzie |
|---|---|---|
| Silnik skryptów | Wykonuje kroki: odtwórz, czekaj, nasłuchuj, rozgałęź, ustaw, skocz, koniec. Rozgałęzienie po przekroczeniu limitu przejść wychodzi z pętli, a „skocz” po limicie kończy sesję. Twardy limit 500 kroków. Gdy wejście jest niedostępne albo ekran zablokowany, silnik przełącza na wariant awaryjny. Stan można zapisać i wznowić. Zwykły Dart, bez audio | `packages/ak_core/lib/src/script/runner.dart` |
| Detektor dźwięku | Klaśnięcia (energia, przejścia przez zero, gwałtowne narastanie i szybkie wygaszanie, 120 ms przerwy) oraz „dziecko coś mówi”. Wyłącznie lokalnie, bez zapisu | `packages/ak_core/lib/src/audio/detectors.dart` |
| Sesja gry w aplikacji | Polecenia silnika wykonuje ten sam odtwarzacz co zwykłe audio (tło, ekran blokady). Podczas czekania gra w pętli podkład albo cisza, co podtrzymuje aplikację w tle. Pauza z ekranu blokady wstrzymuje też czekanie. Wejście dotykiem tylko przy aktywnym ekranie | `app/lib/features/games/` |
| Ekran gry | Ciemny, bez treści do oglądania. Przy nasłuchu dotyku cały ekran jest przyciskiem; wyjście przez przytrzymanie. Gry są też w trybie dziecka | `game_screen.dart` |
| Prototypy | Zgadnij dźwięk (darmowa), Zamrożony taniec, Zamrożone rączki (wersja do samochodu, bez wstawania), Echo rytmu. Nagrania zastępcze: głos systemowy i syntetyczne dźwięki | `tool/game_content.py` |
| Lista dla lektora | Wszystkie kwestie do nagrania, z nazwami plików | `docs/NAGRANIA-DO-GIER.md` |
| Serwer testowy z Range | Potrzebny do strumieniowania na iOS | `tool/dev_server.py` |

## Macierz możliwości prototypów (stan na teraz, mikrofon wyłączony)

| Prototyp | Pierwszy plan | Tło / zablokowany ekran | Co mierzy | Czego nie deklaruje |
|---|---|---|---|---|
| Zgadnij dźwięk | ✅ czas na odpowiedź, potem rozwiązanie | ✅ przetestowane (Android i iOS) | nic (z mikrofonem: że dziecko coś powiedziało) | poprawności odpowiedzi |
| Zamrożony taniec | ✅ muzyka, „stop”, pauza na posąg | ✅ ten sam mechanizm (cisza w pętli), przetestowane w testach | nic | ruchu dziecka |
| Zamrożone rączki | ✅ jak wyżej, zadania na siedząco | ✅ jak wyżej | nic | ruchu dziecka |
| Echo rytmu | ✅ rytm, czas na powtórzenie, przypomnienie | ✅ jak wyżej | nic (z mikrofonem: liczba klaśnięć) | dokładności rytmu |

## Przetestowane

| Test | Wynik |
|---|---|
| `ak_core`: 46 testów (+18: silnik 9, detektor 9) | ✅ |
| Detektor na prawdziwych nagraniach gry: rytmy 3/4/4 klaśnięcia policzone dokładnie; mowa lektora **0** klaśnięć. Pierwsza wersja liczyła sylaby jako klaśnięcia (11 i 9 błędów), co naprawiły dwa kryteria (przejścia przez zero i gwałtowne narastanie) | ✅ |
| Aplikacja: 60 testów (sesja gry: pełny przebieg bez mikrofonu, cisza w pętli, pauza z ekranu blokady, przerwanie) | ✅ |
| Studio: walidacja nowych skryptów | ✅ |
| **Android (emulator): „Zgadnij dźwięk” przy zablokowanym ekranie**, od wstępu przez 3 pytania, czekania z podkładem i odpowiedzi do zakończenia | ✅ |
| **iOS (symulator): to samo po wyjściu do ekranu głównego i zablokowaniu** | ✅ |

Wykryte i naprawione: strumieniowanie na iOS nie działało z prostym serwerem testowym (błąd -11850, brak obsługi Range). To dotyczy tylko środowiska testowego; Supabase Storage zakresy obsługuje.

## Nie zrobione lub zablokowane

- **Mikrofon nie jest jeszcze podłączony.** Detektor jest gotowy i przetestowany na plikach, ale podłączenie mikrofonu (uprawnienia iOS i Android, prośba o zgodę za bramką rodzicielską, usługa mikrofonu w tle na Androidzie, eliminacja echa) wymaga prób na fizycznym telefonie (ARCHITECTURE §15, pkt 2–3). Nie dodaję uprawnień, których nie da się sprawdzić.
- **Ruch telefonu** (`motion_shake`): nieużywany w prototypach, zgodnie z założeniem, że akcelerometr nie mierzy tańca dziecka.
- **Nagrania**: zastępcze. Brzmienie, tempo i długości (np. czas na posąg) trzeba ocenić z dziećmi i dostroić w Studio.
- **Wznawianie gry po przerwaniu** (np. zamknięcie aplikacji): silnik to umie, ale aplikacja jeszcze nie zapisuje stanu gry, więc gra zaczyna się od nowa.

## Kryteria wydania prototypów (do decyzji Dawida)

Prototyp trafi do wersji sklepowej, gdy:
1. ma prawdziwe nagrania;
2. przejdzie test z dziećmi (zrozumiałość, długość);
3. w wersji z mikrofonem ma skuteczność wykrywania ≥ 90% i fałszywe alarmy ≤ 5% w cichym pokoju na 2 telefonach (inaczej wychodzi bez mikrofonu).

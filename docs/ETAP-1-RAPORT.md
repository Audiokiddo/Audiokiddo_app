# AudioKiddo: raport z Etapu 1 (fundament)

Data: 2026-09-26.

## Zaimplementowane

| Element | Gdzie |
|---|---|
| Wspólny rdzeń w czystym Darcie: parser katalogu (błędne pozycje pomijane, reszta działa), reguły dostępu (`all_content` / `pack:` / `item:`), polityka offline (dzierżawa 30 dni, ochrona przed cofnięciem zegara, pliki 14 dni po wygaśnięciu), model i walidator skryptów zabaw (odwołania, zasoby, limity, pętle bez `max_visits`, ślepe zaułki, obowiązkowe warianty awaryjne) | `packages/ak_core` |
| System designu: tokeny kolorów marki, Poppins wbudowany w aplikację (bez pobierania z Google), motyw jasny i ciemny, skalowanie wysokości półek z rozmiarem tekstu | `app/lib/core/theme` |
| Nawigacja (go_router): Start, Biblioteka z filtrami w adresie (skróty ze Startu), Szczegóły, Odtwarzacz | `app/lib/core/router.dart` |
| Katalog przykładowy: 25 audiozabaw (tytuły i czasy ze strony), 3 przykładowe piosenki, półki redakcyjne | `app/assets/mock/catalog.json` |
| Odtwarzanie w tle: just_audio + audio_service + audio_session; pauza przy połączeniu i odłączeniu słuchawek, **bez samoczynnego wznowienia** | `app/lib/features/player` |
| Konfiguracja platform: iOS `UIBackgroundModes: audio`; Android usługa `mediaPlayback`, usunięte uprawnienie `AD_ID`, wyłączona kopia zapasowa danych aplikacji | `ios/`, `android/` |
| Identyfikator aplikacji `pl.audiokiddo.app` | do potwierdzenia |

## Przetestowane

| Test | Wynik |
|---|---|
| `ak_core`: 28 testów jednostkowych | ✅ |
| Aplikacja: 14 testów (kontrast WCAG AA palet, filtry, ekrany, dostęp po zakupie pakietu, brak przepełnień przy tekście 160%) | ✅ |
| `flutter analyze` i `dart analyze` | ✅ bez uwag |
| Build iOS (symulator) i Android (debug APK) | ✅ |
| Symulator iPhone 18 Pro (iOS 27): ekrany, odtwarzanie, **odtwarzanie trwa po wyjściu do ekranu głównego i zablokowaniu** (0:05 → 0:54) | ✅ |
| Emulator Pixel (Android 16): ekrany, odtwarzanie, usługa pierwszoplanowa `mediaPlayback`, sterowanie z panelu powiadomień (pauza i wznowienie), przy zablokowanym ekranie odtwarza dalej | ✅ |
| Emulator Android: przychodzące połączenie pauzuje, po rozłączeniu **nie wznawia** | ✅ |

Testy wykryły i pomogły naprawić dwa realne problemy: przepełnienie kart na półkach przy powiększonym tekście oraz pamięć podręczną zasobów, która zawieszała drugi test.

## Nie sprawdzone lub zablokowane

- **Fizyczne urządzenia**: symulator iOS nie pokazuje sterowania na ekranie blokady (ograniczenie symulatora), a Bluetooth, słuchawki, mikrofon i czujniki wymagają prawdziwych telefonów. Próby mikrofonu i klaśnięć (ARCHITECTURE §15, pkt 2–3) **nie zostały wykonane**, bo potrzebny jest telefon z Androidem i iPhone podłączony kablem.
- **Prawdziwe nagrania i grafiki**: aplikacja odtwarza dźwięk testowy, a okładki to kolorowe zamienniki.
- **Ikona aplikacji i ikona w powiadomieniu**: na razie domyślne ikony Fluttera (Etap 5, po otrzymaniu logo).
- **Skład darmowej próbki**: przyjąłem tymczasowo „Magiczny sklep”, „Co to za dźwięk?” i „Złodziej naszyjnika” (po jednej z każdego pakietu).

## Decyzje podjęte za Dawida (do potwierdzenia)

| Decyzja | Wartość |
|---|---|
| Subskrypcja miesięczna | 24,99 zł, 7 dni za darmo — **zatwierdzone** |
| Subskrypcja roczna | 239,88 zł (19,99 zł/mies.), 7 dni za darmo — **zatwierdzone 5.10.2026** (wcześniej 149,99 zł) |
| Serwer | darmowy plan Supabase podczas budowy, Pro (~100 zł/mies.) dopiero przed publikacją |
| Identyfikator aplikacji | `pl.audiokiddo.app` |

## Kolejny krok: Etap 2

Odtwarzacz docelowy (timer snu, prędkość, tryb bez patrzenia), pobieranie offline z weryfikacją plików, trwały zapis (ulubione, postęp) i wspólny interfejs uprawnień. Potrzebne od Dawida: pliki audio 25 zabaw i piosenki, a do prób mikrofonu fizyczny telefon z Androidem.

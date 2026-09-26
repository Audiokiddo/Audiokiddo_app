# AudioKiddo: raport z Etapu 2 (audio i offline)

Data: 2026-09-26.

## Zaimplementowane

| Element | Szczegóły | Gdzie |
|---|---|---|
| Odtwarzacz docelowy | Pauza/wznowienie, przewijanie ±15 s, pasek postępu, **timer snu** (5/10/15/30 min lub „do końca zabawy”, łagodne wyciszenie w ostatnich 10 s), **prędkość** 0,75–1,25× (zablokowana dla treści zależnych od czasu) | `features/player/` |
| Tryb bez patrzenia | Ciemny ekran z jednym dużym przyciskiem; ekran może się normalnie zablokować; wyjście przytrzymaniem (dziecko nie wyjdzie przypadkiem) | `no_look_screen.dart` |
| Mini-odtwarzacz | Pasek nad nawigacją z tytułem i pauzą; element pojawia się dopiero po udanym załadowaniu | `mini_player.dart` |
| Zapamiętywanie postępu | Zapis co 5 s i przy pauzie/końcu; „Wznów od 2:31” (3 s wcześniej) albo „Od początku”; ukończone i prawie ukończone zaczynają się od nowa | `playback_controller.dart`, `personal_repository.dart` |
| Pobieranie offline | Pobieranie w tle (background_downloader), postęp, anulowanie, ponawianie, **weryfikacja rozmiaru i SHA-256** przed oznaczeniem „gotowe”, kontrola wolnego miejsca (zapas 50 MB), usuwanie pojedyncze i wszystkich, sprzątanie po awarii przy starcie | `features/downloads/` |
| Pliki poza kopią zapasową | iOS: atrybut wykluczenia z iCloud (kanał natywny w Swift); Android: kopia zapasowa aplikacji wyłączona | `AppDelegate.swift`, `MainActivity.kt` |
| Zapis lokalny | SQLite (drift): ulubione, postęp, pobrania, ustawienia; nic nie trafia na serwer | `core/storage/` |
| Uprawnienia i dzierżawa offline | Wspólny interfejs `EntitlementBackend`; **testowe źródło** z ekranem deweloperskim (brak zakupów / subskrypcja / pakiety); dzierżawa 30 dni; ochrona przed cofnięciem zegara; komunikat „odśwież dostęp” | `features/access/` |
| Zakładka „Moje” | Ostatnio słuchane, ulubione, pobrane z zajętym i wolnym miejscem, „Usuń wszystkie pobrane” z potwierdzeniem | `mine_screen.dart` |
| Nagrania testowe | Skrypt generuje mówione nagrania zastępcze (głos systemowy) i uzupełnia katalog o prawdziwe rozmiary i sumy; lokalny serwer udaje serwer plików | `tool/dev_content.py` |

## Przetestowane

| Test | Wynik |
|---|---|
| Testy automatyczne: `ak_core` 28, aplikacja 40 (menedżer pobrań: poprawny, uszkodzony i ucięty plik, błąd sieci, brak miejsca, usuwanie, sprzątanie po awarii; wznawianie; dostęp i dzierżawa; trwałość stanu po restarcie; kolory etykiet; ekrany) | ✅ |
| `flutter analyze` | ✅ bez uwag |
| Android (emulator): pobranie → plik 295 850 B nazwany sumą SHA-256 → **tryb samolotowy** → odtwarzanie z pliku | ✅ |
| Android: restart aplikacji bez internetu → „Wznów od 0:23” → odtwarza od właściwego miejsca | ✅ |
| Android: zabawa niepobrana bez internetu → czytelny komunikat | ✅ |
| Android: pobieranie zlecone bez internetu czeka i **samo kończy się po powrocie sieci** | ✅ |
| Android: timer snu odlicza, tryb bez patrzenia, „Moje” (wolne miejsce z systemu: 8,0 GB) | ✅ |
| Android: symulowana subskrypcja → dzierżawa 30 dni; wygaśnięcie → płatne zabawy proszą o połączenie | ✅ |
| iOS (symulator): build z kanałem natywnym, pobieranie, **plik oznaczony jako wykluczony z iCloud** | ✅ |

Testy i przeklikanie wyłapały pięć błędów, wszystkie poprawione:
1. Ekran odtwarzacza otwierał się dopiero po pauzie, bo `play()` w just_audio kończy się dopiero ze stopem.
2. Odświeżanie dostępu mogło zapisać stan po zamknięciu kontrolera.
3. Poprawka kontrastu filtrów ukryła napisy na zwykłych etykietach.
4. Ikona wybranej zakładki była blada.
5. Mini-odtwarzacz pokazywał zabawę, której nie udało się uruchomić.

## Nie sprawdzone lub zablokowane

- **Fizyczne urządzenia**: słuchawki przewodowe i Bluetooth, samochód, ekran blokady iPhone'a (symulator go nie pokazuje), zużycie baterii przy długim słuchaniu. Wymaga Twoich telefonów.
- **iOS offline**: symulator korzysta z sieci Maca, więc tryb samolotowy przetestowałem tylko na Androidzie.
- **Timer „do końca zabawy” i wyciszanie**: logika jest w kodzie i widać odliczanie, ale pełnego 5-minutowego wyciszenia nie przesłuchałem do końca.
- **Okładki na ekranie blokady**: brak prawdziwych grafik.
- **Karty PDF Detektywa**: przeniesione do Etapu 3 (strefa rodzica, bo drukowanie i udostępnianie wymagają bramki rodzicielskiej).

## Uwagi do Etapu 6 (przed wydaniem)

- `NSAllowsLocalNetworking` w `Info.plist` i konfiguracja HTTP dla emulatora (tylko w buildach debug na Androidzie) służą lokalnemu serwerowi. Przed wydaniem trzeba je usunąć lub ograniczyć do debug.
- Ikona w powiadomieniu Androida to na razie ikona Fluttera.

## Kolejny krok: Etap 3

Backend Supabase, konto rodzica (opcjonalne), Studio do dodawania treści, weryfikacja zakupów (subskrypcja, pakiety, pojedyncze zabawy), zakupy ze strony (WooCommerce), bramka rodzicielska, usuwanie konta i karty PDF.

Potrzebne od Dawida:
1. **Konto Supabase**: załóż je na e-mail firmowy i dodaj mnie przez klucze w sekretach, nie w czacie. Instrukcję podam.
2. **Konta deweloperskie**: status Apple i Google.
3. **Klucze WooCommerce**: klucz REST tylko do odczytu i sekret webhooka.
4. **Pliki audio**: jeśli są gotowe.

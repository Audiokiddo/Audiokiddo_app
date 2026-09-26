# AudioKiddo: raport z Etapu 5 (część bez kont)

Data: 2026-09-27.

## Zaimplementowane

| Element | Szczegóły |
|---|---|
| Onboarding | 3 ekrany przy pierwszym uruchomieniu: powitanie z przypomnieniem o głośności („Uszy są nam jeszcze potrzebne!”), „Jak to działa” dla rodzica (bez patrzenia, tryb dziecka, offline, bez reklam) z linkami za bramką, opcjonalne pytanie o wiek (tylko w telefonie, staje się domyślnym wiekiem trybu dziecka). „Pomiń” na każdym kroku. Ustawienie czytane przed pierwszą klatką |
| Testy dostępności | Wytyczne Fluttera (cele dotyku 48 dp / 44 pt, etykiety, kontrast) na onboardingu, Starcie, Bibliotece, szczegółach i w trybie dziecka, dodatkowo w trybie ciemnym i przy tekście 200% |
| Manifest prywatności iOS | `PrivacyInfo.xcprivacy`: brak śledzenia; sprawdzone, że trafia do paczki aplikacji |
| Android: mniej usług w tle | Usunięta nieużywana usługa `dataSync` biblioteki pobierania |
| Szkice prawne | `docs/prawne/`: polityka prywatności i regulamin z warunkami subskrypcji, oparte na faktycznym działaniu aplikacji, oznaczone do weryfikacji przez prawnika |
| Materiały do sklepów | `docs/SKLEPY.md`: nazwa, podtytuł, opisy, słowa kluczowe, kategorie i wiek, odpowiedzi do App Privacy i Data safety, notatki dla recenzentów, plan zrzutów ekranu |
| Audyt | `docs/AUDYT-SDK.md`: biblioteki, uprawnienia buildu release (`aapt2`), ustawienia iOS, przepływ danych |

## Przetestowane

| Test | Wynik |
|---|---|
| Aplikacja: 69 testów (+9: onboarding 2, dostępność 7) | ✅ |
| `ak_core` 46, Studio 8, schemat bazy, funkcje serwera 6 | ✅ |
| Onboarding na iPhonie (symulator) i Androidzie (emulator), tryb ciemny na iPhonie | ✅ |
| Uprawnienia buildu release Androida: brak `AD_ID`, lokalizacji, mikrofonu, aparatu i kontaktów | ✅ |
| Pobieranie po usunięciu usługi `dataSync` | ✅ |
| Build iOS z manifestem prywatności | ✅ |

Wykryte i poprawione:
1. Na drugim ekranie onboardingu linki były ucięte przez wskaźnik kroków.
2. Kropki nieaktywnych kroków były prawie niewidoczne.
3. Biblioteka pobierania dokładała niepotrzebną usługę `dataSync`.

## Nie zrobione lub zablokowane

- **Ikona aplikacji, ikona powiadomień, ekran startowy**: potrzebne logo w wektorze od Dawida (nie odtwarzam logo).
- **Test z VoiceOver i TalkBack na prawdziwym telefonie**: testy automatyczne sprawdzają etykiety i cele dotyku, ale nie zastąpią przejścia aplikacji czytnikiem ekranu.
- **Wydajność i bateria**: wymagają pomiaru na fizycznych urządzeniach.
- **Weryfikacja prawna**: szkice wymagają prawnika. Dane administratora, okresy przechowywania i adresy wpisane jako `[TODO]`.
- **Przechwycenie ruchu sieciowego release'u**: do zrobienia po podłączeniu Supabase.

## Uwaga o środowisku

Emulator Androida po kilkunastu godzinach pracy uległ awarii systemu („The system died”). Pomógł zimny restart. To nie był błąd aplikacji.

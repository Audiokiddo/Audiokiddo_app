# AudioKiddo: audyt bibliotek, uprawnień i przepływu danych

Stan: 2026-09-27, build release Androida (`app-release.apk`, 67 MB) i build iOS (symulator). Powtórzyć przed każdym wydaniem i po dodaniu Supabase (Etap 3).

## Biblioteki bezpośrednie aplikacji

| Pakiet | Do czego | Łączy się z siecią | Dane |
|---|---|---|---|
| `flutter_riverpod`, `go_router`, `intl`, `path`, `crypto` | stan, nawigacja, formatowanie, sumy SHA-256 | nie | brak |
| `just_audio`, `audio_service`, `audio_session` | odtwarzanie, ekran blokady, przerwania | tylko adresy nagrań podane przez nas | brak |
| `background_downloader` | pobieranie nagrań w tle | tylko adresy nagrań podane przez nas | brak |
| `drift`, `drift_flutter` (SQLite), `path_provider` | zapis lokalny: ulubione, postęp, pobrania, ustawienia | nie | tylko w telefonie |
| `printing` | podgląd, druk i udostępnianie PDF (za bramką) | nie (systemowe okno druku i udostępniania) | brak |
| `in_app_purchase` (+ `_android`, `_storekit`) | zakupy w App Store i Google Play | tylko ze sklepem | transakcje: sklep, a po Etapie 3 nasz serwer |
| `url_launcher` | otwieranie regulaminu i polityki (za bramką) | przeglądarka systemowa | brak |

**Brak**: SDK reklamowych, analitycznych, raportowania błędów (Crashlytics, Sentry), Facebook i Firebase. Po Etapie 3 dojdzie `supabase_flutter`, który trzeba ocenić tak samo.

## Android: uprawnienia w buildzie release (sprawdzone narzędziem `aapt2`)

| Uprawnienie | Skąd | Uwagi |
|---|---|---|
| `INTERNET` | aplikacja | pobieranie treści |
| `WAKE_LOCK`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK` | aplikacja / audio_service | odtwarzanie w tle; typ usługi **mediaPlayback** do deklaracji w Play Console |
| `ACCESS_NETWORK_STATE`, `RECEIVE_BOOT_COMPLETED` | background_downloader (WorkManager) | wznawianie pobrań po restarcie telefonu |
| `com.android.vending.BILLING` | in_app_purchase | zakupy |
| `…DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` | AndroidX (wewnętrzne) | niewidoczne dla użytkownika |

Czego **nie ma** (zgodnie z Families Policy): `AD_ID` (usunięte), lokalizacji, mikrofonu, aparatu, kontaktów i pamięci zewnętrznej.

Pozostałe ustawienia:
- **Kopia zapasowa:** wyłączona (`allowBackup=false`).
- **Nieszyfrowane HTTP:** dozwolone tylko w buildach debug, dla serwera testowego.
- **Usługa `dataSync` biblioteki pobierania:** usunięta z manifestu (nieużywana, a każdy typ usługi w tle wymaga uzasadnienia w Play Console). Pobieranie sprawdzone po zmianie.

## iOS

- **Tryby w tle:** `audio` (odtwarzanie przy zablokowanym ekranie).
- **Prośby o uprawnienia (`…UsageDescription`):** brak. Mikrofon dojdzie dopiero po próbach na urządzeniu, wtedy z opisem po polsku.
- **`NSAllowsLocalNetworking`:** tylko dla serwera testowego. Przed wydaniem usunąć albo ograniczyć do konfiguracji debug (Etap 6).
- **`PrivacyInfo.xcprivacy`:** brak śledzenia i domen śledzących; typy zbieranych danych uzupełnić po Etapie 3.
- **Pobrane pliki:** wyłączone z kopii iCloud (atrybut sprawdzony w Etapie 2).

## Przepływ danych (docelowo, po Etapie 3)

```
Telefon ──HTTPS──► Supabase (UE): anonimowy ID / e-mail rodzica, uprawnienia, zakupy
Telefon ──HTTPS──► Supabase Storage: pobieranie nagrań (adresy ważne 15 min)
Telefon ──────────► App Store / Google Play: płatności
audiokiddo.pl (WooCommerce) ──webhook──► Supabase: zamówienia ze strony
Mikrofon ──► tylko pamięć telefonu (energia dźwięku), nic nie jest zapisywane ani wysyłane
```

## Do weryfikacji przed wydaniem

- Przechwycenie ruchu sieciowego (proxy, np. mitmproxy) w buildzie release: czy aplikacja łączy się wyłącznie z Supabase, sklepami i adresami nagrań.
- Po dodaniu Supabase: przegląd pakietu `supabase_flutter`.
- Aktualne formularze Data safety i App Privacy w dniu wysyłki.

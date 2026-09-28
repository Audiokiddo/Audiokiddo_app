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
| `supabase_flutter` (+ `app_links`, `shared_preferences`) | konto rodzica, uprawnienia z serwera | tylko nasz projekt Supabase (UE) | e-mail rodzica, identyfikator konta; sesja zapisana w telefonie |
| `sign_in_with_apple` | „Kontynuuj z Apple” (iOS) | Apple (systemowe okno) | token logowania trafia tylko do Supabase |
| `google_sign_in` | „Kontynuuj z Google” | Google (systemowe okno) | token logowania trafia tylko do Supabase. **Do weryfikacji przed wydaniem:** zgodność z programem Families (decyzja D9) |
| `flutter_local_notifications`, `timezone`, `flutter_timezone` | codzienne przypomnienia dla rodzica (lokalne, bez serwera) | nie | godzina przypomnień w telefonie |
| `record` | mikrofon w zabawach (klaśnięcia, głos) oraz „Twój głos” (nagrania rodzica) | nie | w zabawach próbki trafiają do detektora w pamięci i są odrzucane. Nagrania rodzica (do 12 s, AAC) zapisywane są tylko w telefonie, wyłączone z kopii zapasowej, nigdy nie są wysyłane; usuwane z profilem dziecka. Dane nie opuszczają urządzenia, więc w etykietach prywatności sklepów nie są „zbierane” |

**Brak**: SDK reklamowych, analitycznych, raportowania błędów (Crashlytics, Sentry), Facebook i Firebase.

## Android: uprawnienia w buildzie release (sprawdzone narzędziem `aapt2`)

| Uprawnienie | Skąd | Uwagi |
|---|---|---|
| `INTERNET` | aplikacja | pobieranie treści |
| `WAKE_LOCK`, `FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_MEDIA_PLAYBACK` | aplikacja / audio_service | odtwarzanie w tle; typ usługi **mediaPlayback** do deklaracji w Play Console |
| `ACCESS_NETWORK_STATE`, `RECEIVE_BOOT_COMPLETED` | background_downloader (WorkManager) | wznawianie pobrań po restarcie telefonu |
| `com.android.vending.BILLING` | in_app_purchase | zakupy |
| `POST_NOTIFICATIONS` | flutter_local_notifications | przypomnienia; prośba systemowa dopiero po wyborze „Włącz przypomnienia” |
| `RECORD_AUDIO` | aplikacja / record | zabawy z odpowiedzią głosem lub klaśnięciem (prośba po bramce rodzica) oraz nagrania rodzica w strefie rodzica (Postęp → Twój głos w zabawie) |
| `…DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION` | AndroidX (wewnętrzne) | niewidoczne dla użytkownika |

Widżet na ekranie głównym (`DayPartWidget`, niewyeksportowany odbiornik) nie potrzebuje uprawnień: odświeża się niedokładnym alarmem o zmianie pory dnia (bez `SCHEDULE_EXACT_ALARM`).

Czego **nie ma** (zgodnie z Families Policy): `AD_ID` (usunięte), `USE_BIOMETRIC` / `USE_FINGERPRINT` (dokładane przez Google Sign-In, usunięte), lokalizacji, aparatu, kontaktów i pamięci zewnętrznej. Stan sprawdzony `aapt2` 2026-09-27.

Pozostałe ustawienia:
- **Kopia zapasowa:** wyłączona (`allowBackup=false`).
- **Nieszyfrowane HTTP:** dozwolone tylko w buildach debug, dla serwera testowego.
- **Usługa `dataSync` biblioteki pobierania:** usunięta z manifestu (nieużywana, a każdy typ usługi w tle wymaga uzasadnienia w Play Console). Pobieranie sprawdzone po zmianie.

## iOS

- **Tryby w tle:** `audio` (odtwarzanie przy zablokowanym ekranie).
- **Prośby o uprawnienia:** tylko mikrofon (`NSMicrophoneUsageDescription`, po polsku; opis wymienia zabawy i nagrania rodzica), pokazywana po bramce rodzica albo w strefie rodzica przy pierwszym nagraniu.
- **Widżet (`AudioKiddoWidget`, WidgetKit):** bez sieci i bez danych, tylko tekst według pory dnia i link `audiokiddo://open/...` do aplikacji. Osobny identyfikator `pl.audiokiddo.app.widget` (tworzony automatycznie przy podpisywaniu).
- **Schemat adresów `audiokiddo://`:** otwiera tylko ekrany strefy rodzica (`/dobranoc`, `/podroz`); w trybie dziecka przekierowanie i tak zostawia dziecko w jego strefie.
- **Sign in with Apple:** wymaga dodania funkcji w Xcode po założeniu konta Apple (patrz `docs/KROKI-DLA-DAWIDA.md`).
- **`NSAllowsLocalNetworking`:** tylko dla serwera testowego. Przed wydaniem usunąć albo ograniczyć do konfiguracji debug (Etap 6).
- **`PrivacyInfo.xcprivacy`:** brak śledzenia i domen śledzących; typy zbieranych danych uzupełnić po Etapie 3.
- **Pobrane pliki:** wyłączone z kopii iCloud (atrybut sprawdzony w Etapie 2).

## Przepływ danych (docelowo, po Etapie 3)

```
Telefon ──HTTPS──► Supabase (UE): anonimowy ID / e-mail rodzica, uprawnienia, zakupy
Telefon ──HTTPS──► Supabase Storage: pobieranie nagrań (adresy ważne 15 min)
Telefon ──────────► App Store / Google Play: płatności
audiokiddo.pl (WooCommerce) ──webhook──► Supabase: zamówienia ze strony
Mikrofon ──► tylko pamięć telefonu (energia dźwięku), nic nie jest zapisywane ani wysyłane.
            Otwarty tylko w trakcie zabawy, próbki poza oknem odpowiedzi są odrzucane bez analizy.
Logowanie Apple / Google ──► token tylko do Supabase (nie korzystamy z innych danych konta)
```

## Do weryfikacji przed wydaniem

- Przechwycenie ruchu sieciowego (proxy, np. mitmproxy) w buildzie release: czy aplikacja łączy się wyłącznie z Supabase, sklepami i adresami nagrań.
- Po dodaniu Supabase: przegląd pakietu `supabase_flutter`.
- Aktualne formularze Data safety i App Privacy w dniu wysyłki.

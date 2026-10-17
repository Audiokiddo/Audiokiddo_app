# Lokalne poprawki AudioKiddo — przekazanie dla Claude’a

Data: 15.10.2026. Projekt: `/Users/dawidkubiak/Desktop/claude folder/audiokiddo-glos`.
Baza zmian: commit `193d6209db2d541c7b2b1f03d1c1935cc5e81107`, gałąź `build/iphone-2026-10-13`.

## Zakres i stan

Użytkownik wybrał nowszy folder `audiokiddo-glos` i zlecił naprawy wyłącznie lokalne. Zmiany zapisano w plikach tego projektu, bez tworzenia commita. Starszy `audiokiddo-app` posłużył tylko jako źródło wcześniej przygotowanych poprawek; w tym etapie go nie zmieniano.

Nie wykonywano deploy, push, migracji zdalnej bazy, publikacji w sklepie ani wysyłania wiadomości. Wcześniejsze wdrożenie claim-order opisane w historycznym audycie to osobny, poprzedni etap. Obecne zmiany serwerowe są tylko lokalnymi plikami.

Aktualne wyniki i ograniczenia: [docs/naprawy-2026-10-15/WERYFIKACJA.md](docs/naprawy-2026-10-15/WERYFIKACJA.md).
Historyczny audyt `docs/audyt-nowych-funkcji-2026-10-14/` opisuje stan sprzed tych napraw. Jego pliki `proby/` zachowano jako materiał dowodowy; aktualne testy regresji są w `app/test/`.

## Co zmieniono

1. **Pobieranie — `download_manager.dart`.** Przeniesiono wcześniejsze poprawki obsługi wielu wpisów wskazujących ten sam plik, współdzielenia pobrań i bezpiecznego usuwania plików. Lokalny plik musi odpowiadać SHA i rozmiarowi z aktualnego katalogu. Dodano obsługę ponownego pobrania brakującego pliku, kolejkę operacji, ponawianie inicjalizacji po błędzie, ograniczenie czasu oczekiwania na platformę/URL/enqueue, stan błędu po anulowaniu i liczenie wspólnego pliku raz w zajętym miejscu.
2. **Zakupy — `purchase_controller.dart`.** Wyjątki przy przywracaniu i przetwarzaniu zakupu nie pozostawiają ekranu w stanie oczekiwania. Restore ma limit czasu. Obsłużono błąd strumienia sklepu, ciche przywracanie i zakończenie życia providera podczas operacji. Zachowano nową ofertę wyłącznie abonamentową; stare testy ofert nie zastąpiły nowych zasad sprzedaży.
3. **Start — `main.dart`.** Odtwarzanie stanu pobrań odbywa się po pierwszej klatce interfejsu, z raportowaniem błędu. Zachowano czyszczenie kopii nagrań Szop’ena dodane w nowszej wersji oraz wczytywanie stanu konta/trybu dziecka przed pokazaniem aplikacji.
4. **Zamiana w planie — `plan_editor.dart`, `session.dart`, `session_screens.dart`.** Callback zamiany przekazuje teraz ID pierwotnej zabawy zamiast pozycji w zmieniającej się liście. `replacePlay(String itemId, ContentItem)` zwraca bool. Jeśli zabawa już gra lub została usunięta, nie podmienia innej i pokazuje komunikat. Także plany przed startem wyszukują ID w aktualnym planie po zamknięciu wyboru. Zmieniono wywołania i testy.
5. **Dodawanie czasu przy zakończeniu.** SessionController wstawia nowe kroki przed nami, nigdy za aktualnym indeksem pętli. Zabawa dodana podczas pożegnania nie jest pomijana i nie powoduje powtórzenia bieżącego komunikatu.
6. **Błąd odtwarzania sesji.** `SessionState.error` pozwala zakończyć sesję czytelnym komunikatem po błędzie źródła/dostępu zamiast zostawiać pozornie grający ekran i nieobsłużony Future. Ekran daje przycisk wyjścia; nie udaje prawidłowego ukończenia planu.
7. **Animacja powitalna — `launch_greeting.dart`.** Pominięcie konkuruje z odczytem wiadomości. Gdy katalog nie jest gotowy, dotknięcie zamyka kurtynę i rezygnuje z późnego powitania. Dialog ma własny obiekt Route, więc zamykany jest konkretny dialog, a nie przypadkowy ekran otwarty w międzyczasie. Zachowano logo, ograniczenie ruchu, czas podstawowy i limit oczekiwania na katalog.
8. **Czas i uprawnienia — `catalog_providers.dart`, `app.dart`, `shop.dart`.** `currentTimeProvider` odświeża czas co najwyżej co minutę i na granicy dnia; `calendarDayProvider` ogranicza przeliczanie katalogu do zmiany daty. `accessTimeProvider` reaguje dokładnie na termin uprawnienia; lease ma osobny termin. Powrót na pierwszy plan odświeża czas. Dostęp jest oddzielony od zegara katalogu, aby uniknąć cyklu dostęp → usuwanie pobrań → katalog → dostęp.
9. **Kontrola przed audio — `playback_controller.dart`.** Ponowna weryfikacja dostępu przed szukaniem źródła oraz po jego przygotowaniu. Stary wynik canPlay nie wystarcza do uruchomienia nagrania. `PlaybackAccessUnavailable` jest obsługiwane przez dotychczasowe ścieżki błędów i nową obsługę błędu sesji. Nie przerywa się automatycznie nagrania już trwającego.
10. **Biblioteka — `all_plays.dart`.** Wiersze płaskiej biblioteki budowane są przez ListView.builder, a nagłówki liter wyliczane z poprzedniego elementu. Zachowano wyszukiwarkę, filtry, sortowanie i polskie znaki. Nie deklarowano zmierzonego przyspieszenia na urządzeniu.
11. **Jeden odtwarzacz — `open_player.dart`.** Helper znajduje istniejący odtwarzacz/grę także głębiej w stosie. Zdejmuje ekrany ponad nim i używa go ponownie albo zastępuje drugim typem. Zachowano testy podstawowe i dodano test zmiany typu z ekranem pośrednim.
12. **Lokalny claim-order i CI.** Błąd lub niepoprawny wynik ogranicznika prób zwraca 503 i nie odpytuje sklepu. Testuje to `_shared/claim_order_guard_test.ts`. CI sprawdza typy wszystkich funkcji `*/index.ts`.
13. **Rodzinne „Dobranoc” — lokalna migracja `20261024000001_shared_bedtime_grace.sql`.** Połączony drugi opiekun może korzystać z wąskiego okna bedtime grace także po wygaśnięciu abonamentu właściciela. `my_entitlements()` przekazuje tylko właściwy wygasły wpis all_content, bez przywrócenia zwykłego dostępu i bez ujawniania innych zakupów poza dotychczasową zasadą aktywnego udostępniania. Cofnięcie uprawnienia, poprzedni dzień i opuszczenie rodziny nie dają grace. Migracja NIE została wdrożona zdalnie.
14. **Jakość testów.** Usunięto nieużywany import. Test samouczka sprawdza osiągalność przycisków, kolejne tytuły i faktyczne zamknięcie. Testy sesji czekają na zakończenie przejścia; edytor planu jest zamykany przed naciśnięciem końca sesji. Test powrotu na Start naciska widoczną ikonę paska zamiast ukrytej ikony gestu.

## Najważniejsze testy

- `time_refresh_test.dart`: wygaśnięcie, premiera po północy bez ponownego pobierania manifestu, odświeżenie po powrocie.
- `release_regression_test.dart`: wolny katalog i pomijanie kurtyny, dodawanie podczas pożegnania, zmiana aktualnego nagrania podczas wybierania zamiennika.
- `playback_access_regression_test.dart`: nieaktualny cache dostępu nie uruchamia audio; błąd sesji jest widoczny.
- `library_and_cards_persistence_test.dart`: wyszukiwanie po pakiecie, porządki sortowania, trwały zapis kart i przywracanie.
- `download_manager_test.dart`, `gate_and_purchases_test.dart`: przeniesione regresje pobierania i zakupów.
- `open_player_test.dart`, `plan_screens_test.dart`, `session_test.dart`, `small_screens_test.dart`: nawigacja i przebiegi ekranowe.
- `supabase/tests/schema_test.sql`: na końcu nowe przypadki udostępnionego bedtime grace; lokalna jednorazowa baza.

## Co pozostaje poza tym etapem

- Wdrożenie lokalnej migracji i jakiekolwiek operacje w chmurze — poza zgodą użytkownika w tym zadaniu. Bez przyszłego wdrożenia poprawki rodzinnej reguły serwer nadal działa po staremu.
- Testy rzeczywistego StoreKit/Google Play, CarPlay/Android Auto, rozmowy telefonicznej, blokady ekranu, offline i długiej sesji na fizycznych urządzeniach.
- Decyzja produktowa dotycząca liczby opiekunów / komunikatu „Dla dziadków”: nie rozszerzano modelu rodziny.
- Historyczna różnica stref czasowych grace: klient porównuje dzień urządzenia, SQL dzień Europe/Warsaw. Przed testami w innych strefach wymaga ujednolicenia lub jawnej decyzji produktowej.
- Brak zmiany modelu potwierdzania zamówienia (numer + email); przeniesiona poprawka dotyczy awarii ogranicznika, nie przebudowy autoryzacji zakupów.

## Odtworzenie weryfikacji

W katalogu `app`:

```sh
flutter analyze
flutter test
flutter test --dart-define=PARENT_GATE_EVERYWHERE=true --dart-define=REDEEM_CODES=false
flutter build ios --release --no-codesign --dart-define=PARENT_GATE_EVERYWHERE=true --dart-define=REDEEM_CODES=false
flutter build apk --release
```

W katalogu projektu: `tool/test_db.sh` (wyłącznie tymczasowy PostgreSQL). W `supabase/functions`: `deno test --allow-env _shared/` oraz `deno check */index.ts`. Żadna z tych komend nie jest poleceniem wdrożenia.

## Aktualizacja na fizycznym iPhonie — 15.10.2026

Na późniejszą, wyraźną prośbę użytkownika skompilowano bieżącą lokalną wersję (wraz z niezatwierdzonymi poprawkami) i zainstalowano ją na podłączonym `iPhone (Dawid)` poleceniem `bash tool/phone_build.sh`. Kompilacja i instalacja zakończyły się kodem 0. Powstały plik `app/build/ios/phone/Build/Products/Release-iphoneos/Runner.app/Frameworks/App.framework/App` ma znacznik czasu 15.10.2026 12:28:18. Podpis: Personal Team `QN4JABW6TD`, identyfikator `pl.audiokiddo.test.qn4jabw6td`, taki sam jak w poprzedniej instalacji. Telefon potwierdził instalację, a `devicectl device process launch` potwierdził uruchomienie. Numer w `app/pubspec.yaml` pozostał `1.0.0+4`; aktualizacja tego konkretnego telefonu nie wymagała podbicia numeru.

To instalacja testowa z konta osobistego, według komentarza w `tool/phone_build.sh` wymaga ponowienia po 7 dniach. Nie przesyłano kodu na serwer ani do App Store/TestFlight. Obecna aplikacja Flutter nie ma mechanizmu zdalnej wymiany skompilowanego kodu; sama zmiana Supabase nie odświeży aplikacji na iPhonie. Lokalna migracja `20261024000001_shared_bedtime_grace.sql` nadal nie jest wdrożona zdalnie.

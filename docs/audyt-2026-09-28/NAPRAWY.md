# Naprawy po audycie z 28.09.2026

| Punkt raportu | Stan | Jak |
|---|---|---|
| P1-1 stary dowód zakupu przywraca dostęp po zwrocie | ✅ naprawione | Każda zmiana ma czas podpisu dokumentu sklepu (`entitlements.source_signed_at`); starszy dokument nie nadpisuje nowszego stanu. Test regresji w `supabase/functions/_shared/purchases_test.ts` i `supabase/tests/schema_test.sql` (12). |
| P1-2 Sandbox bez rozróżnienia | ✅ naprawione | `APPLE_ENVIRONMENTS` (domyślnie tylko `Production`); `tool/set_store_secrets.sh` ustawia `Production,Sandbox` na czas TestFlight i recenzji Apple, z opisem jak to wyłączyć. Powiadomienia z innego środowiska są pomijane. |
| P1-3 powtórzone powiadomienie zmienia stan | ✅ naprawione | `apply_store_event` w bazie: zapis zdarzenia, kontrola kolejności i zmiana uprawnień w jednej transakcji; błąd cofa też znacznik zdarzenia. |
| P1-4 przeniesienie zakupu na inne konto | ✅ naprawione | Zakup zostaje przy koncie. Przechodzi tylko z anonimowego posiadacza (zakup bez konta, potem logowanie lub reinstalacja) albo na konto wskazane przez sklep (`appAccountToken` / `obfuscatedAccountId`). Inaczej: odmowa `account`. |
| P1-5 webhook WooCommerce gubi aktualizację | ✅ naprawione | Jedno wywołanie `apply_woo_order` (zdarzenie, zamówienie, przypisanie do konta) w jednej transakcji. |
| P1-6 wersja sklepowa nie startuje, płatne pliki publiczne | ✅ naprawione w kodzie; ⏳ wdrożenie na LH.pl | Aplikacja bez `CONTENT_BASE_URL` pobiera podpisane linki z funkcji `download-url` (sprawdza uprawnienia w `can_download`, link ważny 15 min). Na LH.pl `tool/lhpl/get.php` sprawdza podpis i wydaje plik spoza `public_html` (z obsługą zakresów dla iOS). Konfiguracja: `tool/set_files_secrets.sh`. |
| P2-7 katalog i Studio lokalnie | ⏳ | Publikacja ze Studia na serwer to osobny etap (logowanie administratorów, wgrywanie plików, wersje katalogu). |
| P2-8 łączenie konta po zakupie jako gość | ✅ rozwiązane regułą z P1-4 | Po zalogowaniu aplikacja przywraca zakupy, a serwer przenosi je z anonimowego posiadacza na konto rodzica. |
| P2-9 nieaktualny test Studio | ✅ | Test porównuje liczbę pozycji z katalogiem wejściowym. |
| P3-10 ograniczenie ruchu maskotki | ✅ (zmiana ChatGPT) | Cała postać nieruchoma przy ograniczeniu ruchu, w tle i poza ekranem. |

Plik `purchase-audit.test.ts` w tym folderze to historyczna reprodukcja (przed naprawą). Jego scenariusze z odwróconym oczekiwaniem są teraz testami regresji w `supabase/functions/_shared/purchases_test.ts` („audit P1-…”).

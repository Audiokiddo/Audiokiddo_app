# Prompt: publikacja aplikacji w sesji z przeglądarką (11.10.2026)

Skopiuj całość bloku poniżej do sesji Claude, która steruje przeglądarką.

```
Jesteś moim asystentem przy publikacji aplikacji AudioKiddo (Flutter, iOS + Android) w App Store i Google Play. Sterujesz moją przeglądarką; ja jestem zalogowany tam, gdzie trzeba, i podam hasła, kody SMS, dane dowodu i karty, gdy poprosisz.

ŹRÓDŁA (czytaj stąd, nie wymyślaj):
Repozytorium GitHub Audiokiddo/Audiokiddo_app, gałąź claude/busy-babbage-aeq1ro (najnowsza). Jeśli masz repo lokalnie: git fetch origin claude/busy-babbage-aeq1ro i czytaj pliki z tej gałęzi; jeśli nie, otwórz je na github.com (jestem zalogowany):
- docs/PUBLIKACJA.md – plan krok po kroku (etapy 2–11), odhaczaj tam, co zrobione
- docs/sklepy/KARTA-DO-WKLEJENIA.md – teksty kart sklepów do wklejenia
- docs/SKLEPY.md – odpowiedzi do formularzy (Data safety, App Privacy, grupa docelowa, IARC)
- docs/WYDANIE.md §5 – produkty, ID i ceny
- docs/marketing/SKLEPY-SZYBKA-SCIEZKA.md – testerzy Androida i kody dla nich
- docs/sklepy/grafiki/ i docs/sklepy/zrzuty/ – ikona, grafika 1024×500, zrzuty

STAŁE DANE:
- Package / Bundle ID: pl.audiokiddo.app (widżet iOS: pl.audiokiddo.app.widget, App Group: group.pl.audiokiddo.app)
- Nazwa: „AudioKiddo: zabawy dla dzieci”, język polski, kraj tylko Polska, kategoria Edukacja, bez reklam
- Polityka prywatności: https://audiokiddo.pl/polityka-prywatnosci-aplikacji/ · Kontakt: https://audiokiddo.pl/kontakt/ · Usuwanie konta: https://audiokiddo.pl/usuwanie-konta/
- Subskrypcje (grupa „AudioKiddo”): pl.audiokiddo.sub.monthly 29,99 zł, pl.audiokiddo.sub.yearly 269,99 zł; jednorazowe: pakiety i zestawy z WYDANIE.md §5 (na start tylko 3 pakiety i 2 zestawy, pojedyncze zabawy później)
- Powiadomienia Apple (v2, produkcja i sandbox): https://ypdxofcwewwdyoelamgy.supabase.co/functions/v1/store-notifications/apple
- Projekt Supabase: ypdxofcwewwdyoelamgy (audiokiddo)

ZASADY:
1. Nigdy nie wpisuj, nie odczytuj na głos ani nie zapisuj w czacie haseł, kluczy API, plików .p8/.json/.jks, numerów kart i dowodu. Gdy pole tego wymaga – zatrzymaj się i poproś, żebym wpisał sam.
2. Przed każdą płatnością, akceptacją umowy, wysłaniem do recenzji, publikacją, usunięciem czegokolwiek albo zmianą cen – opisz, co zrobisz, i czekaj na moje „tak”.
3. Wartości (ID, ceny, teksty, odpowiedzi w formularzach) bierz dokładnie z plików wyżej. Jeśli plik nie odpowiada na pytanie formularza – zapytaj mnie, nie zgaduj.
4. Konta deweloperskie mają należeć do firmy (JDG Neli). Zanim cokolwiek wypełnisz, sprawdź, na kogo jest konto Google Play i czy jest prywatne czy organizacji, i powiedz mi.
5. Po każdym zadaniu krótko: co zrobione, co czeka na mnie, co blokuje. Na końcu lista zadań ze statusem.

ZADANIA (po kolei; jeśli coś blokuje, przejdź do następnego i wróć później):

A. GOOGLE PLAY CONSOLE (https://play.google.com/console)
A1. Weryfikacja konta: tożsamość, telefon, urządzenie z Androidem. Przeprowadź mnie przez brakujące kroki.
A2. Ustawienia → Profil płatności: sprawdź / przeprowadź mnie przez utworzenie (dane firmy, konto bankowe wpisuję sam).
A3. Jeśli nie ma aplikacji: Utwórz aplikację – nazwa jak wyżej, język polski, Aplikacja, Bezpłatna (zakupy w aplikacji są dozwolone), zaakceptuj deklaracje (po moim „tak”).
A4. Zasady i programy → Zawartość aplikacji: polityka prywatności, dostęp do aplikacji (instrukcje dla recenzenta z PUBLIKACJA.md/SKLEPY.md), reklamy: nie, klasyfikacja treści (kwestionariusz IARC), grupa docelowa i treści (dzieci; program Families), Bezpieczeństwo danych (dokładnie wg SKLEPY.md), usuwanie konta (URL wyżej), aplikacje rządowe/finansowe/zdrowotne: nie. Każdą sekcję zapisz.
A5. Obecność w sklepie → Główna strona aplikacji: nazwa, krótki i pełny opis z KARTA-DO-WKLEJENIA.md, ikona 512, grafika 1024×500, zrzuty z docs/sklepy/. Pliki pobierz z GitHuba i wgraj.
A6. Zarabianie → Produkty: subskrypcja z dwoma planami bazowymi (miesięczny 29,99 zł, roczny 269,99 zł, ID jak wyżej), produkty jednorazowe: 3 pakiety + 2 zestawy. Ceny dokładnie z WYDANIE.md. (Produkty mogą być niedostępne, dopóki nie ma wgranego builda – wtedy zapisz, co zostało, i przejdź dalej.)
A7. Testowanie → Testy wewnętrzne: utwórz listę testerów (mój e-mail i Neli – zapytaj o adresy). Testy zamknięte: utwórz ścieżkę i listę e-mail „Testerzy Androida”; adresy testerów dodam później. Builda nie wgrywasz – zrobi to sesja na Macu.
A8. Użytkownicy i uprawnienia: zaproś drugą osobę (Nela/Dawid) jako administratora – po moim „tak”.

B. GOOGLE SEARCH CONSOLE (https://search.google.com/search-console)
B1. Usługa audiokiddo.pl → Mapy witryn: dodaj sitemap_index.xml i ak-poradniki-sitemap.xml.
B2. Poproś o zindeksowanie: /, /pomysly-na-zabawy/, /zagadki-dla-dzieci/, /pakiety/, /jak-zajac-dziecko-w-samochodzie/.
B3. Raport stron: ile zaindeksowanych, ile nie i dlaczego.

C. APPLE (gdy konto Apple Developer jest aktywne; jeśli nie – tylko C0)
C0. https://developer.apple.com/account: sprawdź stan członkostwa. Jeśli brak – przeprowadź mnie przez Enroll (Individual, JDG), płatność wpisuję sam, i przejdź do D.
C1. Certificates, IDs & Profiles → Identifiers: App ID pl.audiokiddo.app (In-App Purchase, Sign in with Apple, App Groups), App Group group.pl.audiokiddo.app, App ID pl.audiokiddo.app.widget (App Groups) – wg PUBLIKACJA.md etap 4.1–4.4.
C2. App Store Connect → Aplikacje → Nowa aplikacja (iOS, nazwa, polski, Bundle ID, SKU audiokiddo-ios).
C3. Biznes: umowa Paid Apps, konto bankowe, W-8BEN, status przedsiębiorcy DSA – przeprowadź mnie, dane wpisuję sam.
C4. Informacje o aplikacji → App Store Server Notifications v2: URL wyżej dla produkcji i sandboxa, potem „Wyślij powiadomienie testowe”.
C5. Subskrypcje: grupa „AudioKiddo”, sub.monthly i sub.yearly z cenami; zakupy w aplikacji: 3 pakiety + 2 zestawy (ID z WYDANIE.md, non-consumable).
C6. Użytkownicy i dostęp → Sandbox → dwa konta testowe: kontakt.audiokiddo+sandbox1@gmail.com i +sandbox2 (hasła wpisuję sam).
C7. Karta w App Store i Prywatność aplikacji: teksty z KARTA-DO-WKLEJENIA.md, App Privacy dokładnie wg SKLEPY.md, kategoria Edukacja + Kids (5 lat i młodsze), informacje dla recenzenta. NIE wysyłaj do recenzji – nie ma jeszcze builda.

D. SUPABASE (https://supabase.com/dashboard, projekt audiokiddo)
D1. Edge Functions → Secrets: sprawdź, czy jest ANTHROPIC_API_KEY (nie odczytuj wartości). Jeśli trzeba nowy klucz: przeprowadź mnie przez console.anthropic.com → API Keys → Create Key i limit 30 USD/mies.; klucz wklejam sam w Secrets.
D2. Authentication → Sign In / Providers → Apple: włącz, Client IDs: pl.audiokiddo.app (po moim „tak”).
D3. Authentication → Email Templates → „Confirm signup”: sprawdź, czy szablon pokazuje kod (jak w supabase/templates/kod.html z repo). Jeśli pokazuje link – powiedz mi, nie zmieniaj.

E. GITHUB
E1. https://github.com/settings/notifications → Actions: tylko nieudane przebiegi, bez e-maili (pokaż przed zapisem).

PODSUMOWANIE NA KONIEC: tabela A1–E1 ze statusem (zrobione / czeka na mnie / zablokowane i dlaczego) oraz lista tego, co musi zrobić sesja na Macu (build Android .aab do testów wewnętrznych i zamkniętych, build iOS do TestFlight, klucz podpisu Androida).
```

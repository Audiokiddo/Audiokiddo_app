# AudioKiddo: przekazanie projektu (stan na 4.10.2026)

Dokument dla nowej sesji Claude (w chmurze) i dla Dawida. Przeczytaj w całości przed pracą.

## 1. Czego dotyczy projekt

**AudioKiddo** to aplikacja mobilna (Flutter, iOS i Android, interfejs po polsku) z audiozabawami
dla dzieci 3–9 lat, bez ekranu: dziecko słucha i odpowiada głosem, klaśnięciem albo słowem.
Sprzedaż przez pakiety (Detektyw, Słowa i Wiedza, Wyobraźnia), subskrypcję i sklep WooCommerce
na audiokiddo.pl (zakup na stronie daje dostęp w aplikacji po e-mailu, numerze zamówienia lub kodzie).
Właściciel: Dawid (agencja BiznesoweLove); lektorka i współtwórczyni: Nela. Maskotka: szop
**Szop’en** (dla dziecka ciepły, dla rodzica urzędowo-sarkastyczny).

**Zasady pracy (obowiązkowe):**
- Odpowiedzi do Dawida **zawsze po polsku**, na końcu jasna lista „Co teraz zrobić”.
- Kod, komentarze i commity **po angielsku**; styl jak w otaczającym kodzie.
- **Nigdy nie proś o wklejanie haseł, kluczy API ani certyfikatów do rozmowy.** Podawaj bezpieczny
  sposób (pęk kluczy macOS, `supabase secrets set`, zmienne środowiskowe ustawiane przez Dawida).
- Zdalne `supabase db push`, `supabase functions deploy`, `config push` uruchamia Dawid.
- Aplikacja w kategorii „Kids”: zakupy i linki na zewnątrz tylko za bramką rodzica, mikrofon
  i rozpoznawanie mowy wyłącznie po zgodzie rodzica i **tylko w telefonie** (nic nie jest wysyłane).

## 2. Repozytorium i struktura

Repo git: `audiokiddo-app/` (na Macu Dawida: `~/Desktop/claude folder/audiokiddo-app`).
**Brak zdalnego repozytorium** – trzeba je wypchnąć na GitHub (sekcja 6), żeby chmura je widziała.

- `app/` – aplikacja Flutter (Riverpod 3, go_router, just_audio + audio_service, drift, record,
  speech_to_text, swipeable_page_route, printing).
  - `lib/core/router.dart` – trasy; każda strona przez `swipePage()` (cofanie gestem od lewej
    krawędzi); odtwarzacz `/odtwarzacz` wysuwa się od dołu.
  - `lib/features/player/bottom_dock.dart` – pasek dolny (Start, Biblioteka, ▶, Sklep, Więcej),
    karta „Dokończ przygodę / Teraz słuchacie” z Szop’enem i dymkami żartów.
  - `lib/features/player/player_screen.dart` – odtwarzacz (SeekBar, PullDownToClose, „Brawo! Co dalej?”).
  - `lib/features/catalog/home_screen.dart` – Start (HeroShelf, kafle sytuacji, kategorie niżej).
  - `lib/features/family/plan_screen.dart` – plan rozwoju („Dziś dla…”, tydzień, co rozwijamy, etapy).
  - `lib/features/games/` – gry interaktywne: `game_controller.dart`, `speech.dart`
    (rozpoznawanie słów na urządzeniu, tylko iOS), `speech_check_screen.dart` (`/mowa`).
  - `lib/core/widgets/szop.dart` – naklejki Szop’ena (`assets/szop/*.png`), teksty dla rodzica.
  - `lib/features/personal/app_icon_screen.dart` – wybór ikony aplikacji (iOS, `AppIconPlugin` w AppDelegate).
  - `lib/core/theme/appearance.dart` – motyw jasny (domyślny) / ciemny / jak telefon.
  - `assets/mock/catalog.json` – katalog (pakiety, zabawy, ścieżki plików z rozmiarem i sha256).
- `packages/ak_core/` – logika w czystym Dart: silnik skryptów gier (engine 3: wybór słowami,
  `no_speech` fallback), `words.dart` (WordMatcher), detektory dźwięku, plan rozwoju, katalog.
- `supabase/` – migracje SQL i Edge Functions (Deno): download-url (podpisane linki 4 h),
  verify-purchase, woo-webhook, redeem-code, claim-order, sync-web-purchases i in.
- `tool/` – skrypty:
  - `game_content.py` – generuje gry; `--voice nela --games zgubiona-gwiazdka` mówi głosem
    ElevenLabs (klucz z pęku kluczy macOS „elevenlabs-api-key”, kwestie cache’owane w
    `dev_content/tts-cache/`); bez tego głos systemowy macOS „Zosia”.
  - `phone_build.sh` – kompilacja i instalacja na iPhonie Dawida (tylko na Macu).
  - `shrink_pdf.py` – kompresja PDF (PyMuPDF, porównuje strony z oryginałem).
  - `make_icons.py`, `slice_mascot.py`, `import_covers.py`, `import_recordings.py`,
    `files_update.sh`, `verify_server_files.py`, `content_files_sql.py`, `make_codes.py`.
- `dev_content/` (**poza gitem**, 184 MB) – nagrania, pliki gier i PDF wysyłane na serwer.
- `docs/` – raporty etapów, `ZABAWY-ZE-SLOWAMI.md`, `NAGRANIA-DO-GIER.md`, `DOSTEP-Z-SKLEPU.md` itd.

Materiały źródłowe Dawida (poza repo): `~/Desktop/claude folder/AudioKiddo-materialy/`
(mp3 audiozabaw, akta sprawy PDF, przewodniki, okładki, logo).

**Serwer plików:** LH.pl, wtyczka WP „AudioKiddo – pliki aplikacji”, katalog
`/home/platne/serwer335689/public_html/autoinstalator/audiokiddo.pl/wordpress106097/wp-content/plugins/audiokiddo-pliki/nagrania/…`
(wgrywanie przez FileZillę/SFTP, Dawid się loguje). Sprawdzenie: `python3 tool/verify_server_files.py`.

**Testy:** `cd packages/ak_core && dart test` (85 testów), `cd app && flutter analyze && flutter test --timeout 60s`
(162 testy; obecnie 2 do poprawy, patrz niżej).

## 3. Co zostało zrobione ostatnio (skrót)

- Silnik gier engine 3: odpowiedzi słowami (rozpoznawanie mowy offline na iPhonie), przycisk
  „Powtórz polecenie”, słowa „jeszcze raz/powtórz”, słuchanie do końca okna (nie urywa po pauzie),
  krótkie słowa („tak”, „plum”) łapane przez rozpoznawanie mowy. Na Androidzie słowa wyłączone
  (biblioteka mogłaby wysłać dźwięk do Google) – dziecko klaszcze.
- Gra „Zgubiona Gwiazdka” (5 zakończeń) – głos Neli z ElevenLabs v4, pliki na serwerze (51, zgodne).
- Nowy wygląd wg makiety Dawida: pasek z ▶, Szop’en, motyw jasny, Start, karta zabawy (minuty,
  wiek, potrzebne), „Podobne zabawy”, profil, „Mamy coś!”, plan rozwoju, ikony aplikacji z Szop’enem.
- Gesty: cofanie od lewej krawędzi (też w odtwarzaczu), zwijanie odtwarzacza w dół, karta
  nad paskiem zamykana przesunięciem w lewo, przycisk ▶ (gra → odtwarzacz; inaczej szybki wybór
  z „Dokończ: …” i ✕), „Zakończ słuchanie” w odtwarzaczu.
- PDF-y akt Detektywa: stara kompresja wycinała obrazki – skompresowane od nowa (`dev_content/pdf/`),
  katalog zaktualizowany. **Na serwerze wciąż są stare** (patrz zadania).
- ElevenLabs Studio: projekt „Nela - Wyjscie do sklepu” (zabawa „Czas na zakupy”): narracja
  wygenerowana (10:21, głos Nela, v4), efekty: drzwi 0:36, koszyk 1:03, pakowanie, drzwi 10:01;
  muzyka „Tiny Cart Adventures” 30 s od 10:18 (15%). Tekst: `docs/produkcja/czas-na-zakupy/`,
  okładka: `docs/produkcja/czas-na-zakupy/okladka.png`.

## 4. Do zrobienia (priorytety)

1. **Wgrać poprawione PDF-y na serwer** (8 plików z `dev_content/pdf/`: 5 akt `detektyw/*.pdf`
   bez przewodnika + `detektyw/przewodnik.pdf`, `slowa-i-wiedza/przewodnik.pdf`,
   `wyobraznia/przewodnik.pdf`) do `…/audiokiddo-pliki/nagrania/pdf/<pakiet>/`, potem
   `verify_server_files.py`. Wymaga Maca i FileZilli (Dawid).
2. ~~Poprawić 2 testy~~ – zrobione w chmurze (4.10.2026).
3. ~~Interaktywne akta sprawy Detektywa~~ – zrobione w chmurze (4.10.2026): ekran `/akta/:id`
   (`app/lib/features/pdf/case_file_screen.dart`), przycisk „Akta sprawy” w odtwarzaczu
   i „Rozwiązuj w telefonie” na karcie zabawy, dane w `app/assets/case_files.json`.
   Do sprawdzenia przez Dawida na iPhonie (rysowanie stron PDF działa tylko na urządzeniu)
   i w treści nagrań: odpowiedzi odczytane ze stron, nie z nagrań. Labirynt „Znikające dzwonki”
   zad. 2 i zadania słuchowe/rysunkowe są bez oceniania.
4. **Przebudowa Biblioteki** (prośba Dawida): czytelniejsza, z wyraźnym podziałem na pakiety
   (karty pakietów z okładką, liczbą zabaw, co masz / co do odblokowania, potem zabawy w pakiecie;
   osobno piosenki i gry; filtry wieku i czasu). `lib/features/catalog/library_screen.dart`.
5. **„Czas na zakupy” do aplikacji** (wymaga Maca/przeglądarki Dawida):
   ściszyć efekty w ElevenLabs Studio (~30–40%), wyeksportować nagranie (zapytać Dawida o zgodę
   na pobranie), dokleić stałą czołówkę muzyczną (taka sama w pakietach Słowa i Wiedza oraz
   Wyobraźnia, ok. pierwsze sekundy nagrań w `AudioKiddo-materialy/…`; Detektyw ma inną),
   nowy pakiet roboczo „Przygody na co dzień” (Dawid: „Sytuacje”), okładka, wpis w katalogu,
   migracja `content_files`, wgranie na serwer.
6. Pomysły do decyzji Dawida: codzienne powiadomienie z Szop’enem, kolekcja naklejek za serię,
   propozycja pakietu po tygodniu planu, kolejne bajki ze słowami (np. „Nocne zoo”).

## 5. Ograniczenia sesji w chmurze

W chmurze **nie ma**: Maca, Xcode, symulatora iOS, iPhone’a Dawida, polecenia `say`,
pęku kluczy z kluczem ElevenLabs, FileZilli ani folderów `dev_content/` i `AudioKiddo-materialy/`.
Da się tam: zmieniać kod, uruchamiać testy (`flutter`/`dart` trzeba doinstalować), pisać
dokumentację i dane (np. JSON akt sprawy). Kompilację na iPhone (`tool/phone_build.sh`),
wgrywanie na serwer i ElevenLabs robi się na Macu (lokalna sesja Claude Code).

## 6. Jak przenieść projekt do chmury

Dawid na Macu (w Terminalu, w folderze `audiokiddo-app`):
```bash
gh repo create audiokiddo-app --private --source=. --push
```
(albo utworzyć prywatne repo na github.com i `git remote add origin … && git push -u origin main`).
Potem w Claude Code na claude.ai/code wybrać to repozytorium. **Nie wypychać** kluczy ani plików
`.env` (są w `.gitignore`; przed pushem sprawdzić `git status`).

---

## Stan na 6.10.2026 (przekazanie do nowej sesji)

Gałąź robocza: `claude/busy-babbage-aeq1ro` (nie wypychać do `main` bez zgody Dawida). Instalacja na iPhonie: `bash tool/phone_build.sh`. Testy: w `app/` `flutter test` (warto plik po pliku z limitem czasu), baza `bash tool/test_db.sh`, funkcje `cd supabase/functions && deno test`.

### Ostatnio zrobione (commity 0089927 i 7d994d7 oraz niezacommitowane poprawki testów)
- **Samouczek Szop’ena** (`app/lib/features/welcome/szop_tour.dart`): przełącza zakładki, przewija do funkcji (`TourTarget` w home, bibliotece, sklepie, Więcej), żółta ramka, ciemniejsze tło. Dawid zgłosił, że ramki trafiały w złe miejsca: poprawione (pomiar po zakończeniu przewijania), **do sprawdzenia na iPhonie**.
- **Samouczek detektywa** przy pierwszej zabawie z aktami (`app/lib/features/pdf/case_file_tutorial.dart`).
- **Tryb samochodu** (`SessionScreen` w `app/lib/features/session/session_screens.dart`): duże przyciski, układ poziomy z przyciskami po prawej. Stary rysowany szop zastąpiony wszędzie obecnym Szop’enem (widżet `Kiddo` rysuje teraz `SzopSticker`).
- **Abonament pierwszy wszędzie**: wspólny `SubscriptionOffer` (`app/lib/features/purchases/subscription_value.dart`): przekreślona cena miesięczna, 19,99 zł/mies., jedna linia oszczędności, jeden przycisk. Pakiety na zawsze schowane pod „Wolisz kupić pakiet na zawsze?” (Sklep, paywall), na stronie pakietu jako mały link.
- **Okno po darmowej zabawie** (`after_free_play.dart`, wyzwalane w `now_playing_pill.dart`): najpierw kolejna darmowa zabawa, potem oferta.
- **„Co teraz?”** (`app/lib/features/home/quick_pick.dart`): czas 15–60 min, losowana kolejność (najpierw niesłuchane), „Jedziemy autem”, zabawa do dokończenia, „Włącz po kolei”.
- **„Co dziś robimy”**: do 7 zabaw, tylko z naszymi okładkami.
- **Powitanie Szop’ena po otwarciu** (`app/lib/features/home/launch_greeting.dart`).
- **Konto**: rejestracja e-mail + hasło (kod tylko potwierdza adres, `signUp`/`verifySignUp`), kod tylko przy zapomnianym haśle i nie zakłada konta (`shouldCreateUser: false`, błąd `noAccount`), po usunięciu konta czyszczone dane z telefonu.
- **Przypomnienia**: własna godzina, kafelek w Więcej → Powiadomienia.
- **Tryb jasny/ciemny**: domyślnie automat (ciemny 20:00–6:00), pytanie usunięte z powitania.
- **Zakupy**: `PreviewStoreGateway` — bez produktów w App Store pokazuje nasze ceny i komunikat zamiast zawieszenia.
- **CRM w Studio** (zakładka CRM, `studio/lib/crm/`): pulpit, decyzje, zadania, pomysły, kalendarz, reklamy, mailing, użytkownicy, aktualizacje, ustawienia. Agent COO: funkcja `supabase/functions/coo` (Claude API), MailerLite: `supabase/functions/mailerlite`. Opis: `docs/CRM.md`. Migracja `20261008000001_crm.sql` i funkcje **są już wdrożone** przez Dawida.

### Do zrobienia
1. **Dokończyć testy aplikacji** po ostatnich zmianach. Ostatni pełny przebieg miał błędy w: `screens_test` (cena „7 dni za darmo, potem 239,88 zł / rok” — tekst z nowej oferty), `session_test` („DOBRANOC” w wieczornym hero), `small_screens_test` (przepełnienia o 2–16 px na małych ekranach — prawdopodobnie nowy odtwarzacz samochodowy lub `SubscriptionOffer`), `navigation_motion_test` (animacje widżetu `Kiddo`), `account_test` (nowa rejestracja hasłem — test już poprawiony, sprawdzić), test „parent encounter… large text”. `shop_test` już przechodzi.
2. Sprawdzić na iPhonie samouczek (ramki), tryb samochodu w poziomie, rejestrację hasłem i usuwanie konta.
3. Szablon e-maila „Confirm signup” w Supabase musi pokazywać kod (`supabase/templates/kod.html`); jeśli przychodzi link zamiast kodu, Dawid robi `supabase config push`.
4. Dawid: klucz `ANTHROPIC_API_KEY` (`supabase secrets set`), wgrać `studio/build/web` do `public_html/studio` (zbudowane `bash tool/studio_build.sh`), dopisać swój e-mail do tabeli `admins`, później MailerLite (`MAILERLITE_API_KEY`, `MAILERLITE_FROM`).
5. Otwarte z wcześniej: konta Apple Developer i Google Play, logowanie Apple/Google, usunięcie `nagrania/pdf/przewodnik.pdf` z serwera, okładka dla „Prawda czy nie?”.

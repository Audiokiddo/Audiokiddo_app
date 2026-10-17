# AudioKiddo: pełny kontekst projektu (do wgrania do Claude Projects)

Stan na 17.10.2026. Ten plik zbiera wszystko, co trzeba wiedzieć o projekcie AudioKiddo: czym jest, kto go robi, jak działa technicznie, co zostało zrobione, co czeka na decyzje i jakich zasad się trzymać. Pisany po polsku, bo tak pracuje zespół. Kod, komentarze i commity są po angielsku.

Aktualniejsze szczegóły są w repozytorium (`docs/`). Gdzie to ważne, podaję nazwę pliku.

---

## 1. Czym jest AudioKiddo

- **Aplikacja mobilna** (Flutter, iOS i Android, interfejs po polsku) z **audiozabawami dla dzieci 3–9 lat**. Dziecko słucha i odpowiada głosem, klaśnięciem albo słowem, rodzic wybiera zabawę. Telefon może leżeć ekranem w dół.
- **Maskotka: szop Szop’en** (pełne imię „Szop’en von Ekran”). Dla dziecka ciepły, dla rodzica urzędowo-sarkastyczny. Dyskretny, można go wyciszyć, nigdy nie przerywa nagrań żartami.
- **Dane dzieci zostają na telefonie.** Mikrofon i rozpoznawanie mowy tylko po zgodzie rodzica i tylko na urządzeniu (nic nie jest wysyłane). Na Androidzie rozpoznawanie słów jest wyłączone, dziecko klaszcze.
- **Kategoria „Kids”** w sklepach: zakupy i linki na zewnątrz tylko za bramką rodzica (pytanie z liczbą).
- Marka: turkus, lawenda, żółty. Polska rodzinna marka.

### Zespół
- **Dawid** (agencja BiznesoweLove): właściciel, robi stronę, reklamy, serwer, publikację w sklepach.
- **Nela**: lektorka, współtwórczyni, pisze i nagrywa zabawy, konto deweloperskie Apple jest jej firmy (zespół Apple `D83635FL35`, Biznesowelove Nela Mariak).
- W aplikacji i na stronie: „AudioKiddo robią Nela i Dawid, para z Polski. Sami piszą zabawy i podkładają głosy.” (Do potwierdzenia, czy „nagrywają” dotyczy wszystkich głosów, patrz sekcja 12.)

---

## 2. Zasady pracy z Claude (obowiązkowe)

1. **Odpowiedzi do Dawida po polsku**, na końcu jasna lista „Co teraz zrobić”.
2. **Kod, komentarze, commity po angielsku**, styl jak w otaczającym kodzie. Formatter repozytorium ma `page_width: 110`, ale pliki nie są w całości sformatowane. Nie uruchamiać `dart format` na całych plikach (zmienia cudze linie). CI nie sprawdza formatowania.
3. **Nigdy nie wklejać haseł, kluczy API, certyfikatów ani kodów SMS do rozmowy.** Hasła i klucze: zmienne środowiskowe, Network secrets, pęk kluczy macOS, `supabase secrets set`. Hasła, kody SMS, dane karty i dowodu wpisuje wyłącznie Dawid.
4. **Pytać przed:** płatnościami, usuwaniem, publikowaniem, zmianami w śledzeniu i reklamach.
5. **Zdalne komendy uruchamia Dawid:** `supabase db push`, `supabase functions deploy`, `config push`.
6. **Nie pchać na gałęzie innych sesji** bez wyraźnej zgody.
7. **Teksty do rodzica (zasady głosu z badania, sekcja 9):** sucho, konkretnie, bez wykrzykników, bez „bez ekranu” w formie absolutnej (telefon jest ekranem), bez „zasługujesz na chwilę dla siebie”, bez form rodzajowych („podałeś”), bez „pociecha / maluszek / magiczne chwile”, bez żartów z innych rodziców i imion dzieci. Winny jest system albo przedmiot, nigdy rodzic ani dziecko. Teksty słyszane przez dziecko w zabawach zostają żywe.
8. **Nie obiecywać:** efektów rozwojowych, „samodzielnej zabawy przez godzinę”, liczb minut, dopóki nie zmierzono.

---

## 3. Repozytorium i gałęzie

Repo GitHub: `Audiokiddo/Audiokiddo_app`. Na Macu Dawida: `~/Desktop/claude folder/audiokiddo-app`.

Gałęzie:
- `main`.
- `claude/busy-babbage-aeq1ro`: druga sesja Claude (strona audiokiddo.pl w wersji 3.25.1 i część aplikacji).
- `claude/fervent-meitner-jmt63o`: gałąź z pracą z tej sesji (zawiera scalenie gałęzi busy-babbage). **Aktualna, wszystkie zmiany opisane niżej są na niej.** PR nie został założony.

Struktura:
- `app/` aplikacja Flutter 3.47.5 (Riverpod 3, go_router, just_audio 0.10, audio_service 0.18, drift, record, speech_to_text, share_plus, in_app_review, flutter_local_notifications).
- `packages/ak_core/` czysty Dart: katalog, dostęp i licencje (Scopes), silnik skryptów gier, plan rozwoju.
- `supabase/` migracje SQL i funkcje Edge (Deno).
- `studio/` Flutter web: panel administracyjny „Studio” (statystyki, katalog, promocje, CRM).
- `strona/` źródła wtyczki WordPress „AudioKiddo – pliki aplikacji” i skrypty narzędziowe (`strona/tool/*.js`).
- `tool/` skrypty (build, kopie, zawartość): `phone_build.sh`, `release_build.sh`, `test_db.sh`, `game_content.py` itd.
- `filmy/` osobny folder do pracy nad filmikami (szablon, `narzedzia/elevenlabs.py`, README).
- `docs/` raporty etapów, strategie, instrukcje (lista w sekcji 15).
- Poza gitem (u Dawida): `dev_content/` (nagrania, pliki gier, PDF), materiały źródłowe `AudioKiddo-materialy/`.

---

## 4. Treść i katalog

Katalog jest w `app/assets/mock/catalog.json` oraz publikowany na serwerze (`catalog_versions`, `catalog_pointer`). Każda zabawa ma: id, rodzaj, pakiet, wiek (`age_min`, `age_max`), czas, sytuacje (`podroz`, `przed_snem`, `w_domu`, `czekanie`), umiejętności, wymagania (mikrofon, miejsce do ruchu, kartka i ołówek, wydruk PDF), dostęp (`free` albo `paid`), pliki audio, okładkę, datę premiery.

Pakiety:
- **Wyobraźnia** (wiek 3–9), **Słowa i wiedza** (wiek 3–9), **Detektyw** (wiek 7+, z aktami spraw w PDF).
- Zabawy spoza pakietów: m.in. „Zgadnij dźwięk”, „Prawda czy nie?”, „Zgubiona Gwiazdka” (gra z pięcioma zakończeniami, głos Neli z ElevenLabs).

Darmowe zabawy: po jednej z każdego pakietu. Jest to „Magiczny sklep” (Wyobraźnia), „Co to za dźwięk?” (Słowa i wiedza), „Złodziej naszyjnika” (Detektyw, oznaczony 7+), plus „Zgadnij dźwięk”, „Prawda czy nie?”, „Zgubiona Gwiazdka”.

Kategorie w aplikacji: Kreatywne, Ruchowe, Logiczne, Edukacyjne, Fabularne, Piosenki, Spokojne (używane do dobierania, nie kafelek).

Pliki audio leżą na serwerze LH.pl (wtyczka WordPress „AudioKiddo – pliki aplikacji”), aplikacja pobiera je przez funkcję `download-url` (podpisane linki ważne 4 h), a serwer sprawdza dostęp funkcją SQL `can_download`. Sprawdzenie plików na serwerze: `python3 tool/verify_server_files.py`.

---

## 5. Model sprzedaży i ceny

- **Jeden abonament dla całej rodziny** (decyzja z 8–9.10.2026): miesięczny **29,99 zł**, roczny **269,99 zł** (około 22,50 zł miesięcznie). Bez planów po liczbie dzieci, bez limitu profili dzieci. Bez okresu próbnego z kartą (darmowe zabawy jako demonstracja). Abonent może dzielić dostęp z drugim rodzicem (`Więcej → Drugi rodzic`, kod ważny 7 dni).
- **Pakiety na zawsze (jednorazowe):** Wyobraźnia 49,99 zł, Słowa i wiedza 49,99 zł, Detektyw 69,99 zł. **Zestawy:** dwa pakiety 89,99 zł, trzy 159,99 zł.
- **Pojedyncze zabawy:** 9,99 zł (Detektyw: 19,99 zł).
- Deklarowana obietnica abonamentu: wszystkie zabawy teraz i **jeden nowy pakiet co miesiąc**.
- **Źródła zakupu:** App Store, Google Play i sklep WooCommerce na audiokiddo.pl (dostęp w aplikacji po e-mailu, numerze zamówienia lub kodzie). Dokładna tabela identyfikatorów produktów: `docs/WYDANIE.md` §5 i `app/lib/features/purchases/offer_catalog.dart`.
- Identyfikatory aplikacji: iOS i Android `pl.audiokiddo.app`, widżet iOS `pl.audiokiddo.app.widget`, grupa `group.pl.audiokiddo.app`.
- Aplikacja nie jest jeszcze w sklepach (stan strony z 12.10.2026: „aplikacja jeszcze nie w sklepach”). Budowanie i testy trwają, wersje testowe na iPhonie przez `tool/phone_build.sh`.

### Polecenia znajomych (zrobione 12.10.2026)
- Znajomy zakłada konto i wpisuje kod `POLEC-XXXXXX`: **oboje dostają po 30 zł** środków do wykorzystania w aplikacji.
- **Limit: jeden kod nagradza najwyżej 3 osoby w roku kalendarzowym** (czas polski).
- Konto gościa (anonimowe) nie może użyć kodu, aplikacja prosi o założenie konta.
- Środki wydaje się w `Poleć znajomym → Twoje środki` (z bramką rodzica i potwierdzeniem): miesiąc całej biblioteki 29,99 zł (kolejne miesiące dodają się na koniec trwającego), pakiet 49,99 / 69,99 zł, pojedyncza zabawa 9,99 zł. Cennik w tabeli `credit_prices`.
- Serwer: migracja `20261021000001_referral_credit.sql` (tabele `credit_ledger`, `credit_prices`, funkcje `redeem_referral`, `referral_code_for`, `credit_offers`, `spend_credit`), funkcje Edge `redeem-code`, `referral-code`, nowa `credit`. Stara zasada (14 dni dla znajomego, miesiąc dla polecającego po zakupie) usunięta.
- **Ryzyko do pamiętania:** wytyczna Apple 3.1.1 (waluta w aplikacji). Środki nie są do kupienia ani wypłaty. W notatce dla recenzenta dać zdanie: „Referral credit is a free reward (30 PLN for both sides, max 3 per year), cannot be purchased or withdrawn, and only unlocks content inside the app.” Szczegóły: `docs/POLECENIA.md`.

---

## 6. Architektura techniczna

**Aplikacja:**
- Stan i dostęp: `AccessController` (uprawnienia z serwera, dzierżawa offline), `canPlayProvider`, `itemAccessProvider`, `accessPolicyProvider`. Zakres uprawnień: `all_content`, `pack:<id>`, `item:<id>`.
- Odtwarzanie: `AkAudioHandler` (just_audio + audio_service), `PlaybackController`, kolejka (`QueueRunner`), sesje (`SessionController`: trasa i dobranoc).
- Gry: `GameController`, silnik w `ak_core` (engine 3: odpowiedzi słowami, fallback bez rozpoznawania).
- Zdarzenia analityczne: `AppEvent` w `lib/features/insights/events.dart` (m.in. `wants_more`, `cancel_reason`, `paywall_view`, `purchase_*`).
- Trasy w `lib/core/router.dart`. Ważne: `/biblioteka`, `/biblioteka/moje-pakiety`, `/sklep`, `/subskrypcja`, `/polec`, `/dostep`, `/konto`, `/podroz`, `/dobranoc`, `/ratunku`.

**Serwer (Supabase):**
- Baza Postgres z migracjami w `supabase/migrations` (najnowsze: `20261021000001_referral_credit.sql`, `20261022000001_bedtime_grace.sql`). Testy schematu: `supabase/tests/schema_test.sql`, uruchamiane przez `tool/test_db.sh`.
- Tabela `entitlements` (źródło: app_store, google_play, woocommerce, manual; zakres; ważność; unikalność `(source, store_original_tx_id, scope)`).
- Funkcje Edge: `account-status`, `admin`, `ads`, `claim-order`, `coo`, `credit`, `delete-account`, `download-url`, `factory`, `mailer`, `mailerlite`, `redeem-code`, `referral-code`, `reviews`, `store-notifications`, `sync-web-purchases`, `verify-purchase`, `woo-webhook`.
- Konta: logowanie kodem z maila (bez hasła) lub hasłem, Apple, Google. Goście mają konto anonimowe.

**Strona audiokiddo.pl:** WordPress + WP Fastest Cache, Autoptimize, Yoast, WooCommerce. Wtyczka własna w wersji 3.25.1 (druga sesja). Źródła wtyczki w `strona/`, audyt i sekcje w `docs/strona/`.

**CarPlay / Android Auto:** `docs/CARPLAY.md`. Zakładki CarPlay: „Na drogę”, „Ostatnie” (z postępem), „Pakiety”, „Więcej”, przycisk zapętlania. **Kod Swift (`SceneDelegate.swift`) nie był kompilowany lokalnie; GitHub zbudował iOS bez błędów (`flutter build ios --no-codesign`).** Uprawnienie `com.apple.developer.carplay-audio` wymaga wniosku do Apple (dopiero po przyznaniu można je dodać), więc CarPlay nie działa w samochodzie ani w symulatorze do tego czasu.

**CI (GitHub Actions, `.github/workflows/ci.yml`):** ak_core (analiza + testy), aplikacja (analiza `--fatal-infos`, testy zwykłe i „jak build App Store” z `PARENT_GATE_EVERYWHERE=true REDEEM_CODES=false`), Studio (testy + build web), serwer (testy schematu na PostgreSQL 17, `deno test --allow-env`, `deno check`, `deno lint`), build Android i build iOS bez podpisu. Przy czerwonym CI Dawid dostaje maile „Run failed”.

**Testy lokalne:** `PATH=/opt/sdk/flutter/bin:$PATH` w środowisku chmurowym. `flutter analyze --fatal-infos` oraz `flutter test --timeout 60s` (pełny zestaw trwa około 5 minut, 250 testów w zwykłej wersji, 248 w sklepowej).

**Instalacja na iPhonie (na Macu Dawida):**
```
cd ~/Desktop/"claude folder"/audiokiddo-app
git checkout claude/fervent-meitner-jmt63o && git pull
tool/phone_build.sh
```
Skrypt podpisuje aplikację kontem Dawida (darmowe Apple ID, 7 dni) z testowym identyfikatorem `pl.audiokiddo.test.<zespół>`, nie zajmuje `pl.audiokiddo.app` należącego do Neli. Wymaga: zalogowania w Xcode (Settings → Accounts), certyfikatu Apple Development, iPhone’a podłączonego i odblokowanego, trybu dewelopera. Bez tego `flutter run` próbuje podpisać zespołem Neli i kończy się błędem profili.

---

## 7. Co zostało zrobione w tej sesji (12–17.10.2026)

### Aplikacja
- **Zapętlenie zamiast zmiany tempa** w odtwarzaczu (przycisk „Zapętl”, działa z ekranu blokady i CarPlay, każde przejście liczy się jako wysłuchane).
- **CarPlay rozbudowany** (cztery zakładki, postęp, przycisk zapętlania, odświeżanie listy). Patrz sekcja 6.
- **„Co dziś robimy”:** wszystkie dostępne (w tym darmowe, niezależnie od oznaczenia wieku) na początku, zablokowane z ciemną okładką, kłódką, napisem „W abonamencie” i „Dostępne po wykupieniu abonamentu”. Test pilnuje, że darmowy „Złodziej naszyjnika” (7+) jest widoczny dla 4-latka.
- **Moje pakiety** (kafelek na Starcie pod „Co robicie?” i na górze Biblioteki, strona `/biblioteka/moje-pakiety`): kupione pakiety w całości, darmowe zabawy z pozostałych pakietów (z dopiskiem „N z M za darmo”), darmowe zabawy spoza pakietów.
- **Biblioteka w stylu katalogu:** wyszukiwarka, szybkie filtry (w tym „Na leżąco”), „Najnowsze”, kategorie jako lista z liczbami, pakiety jako kolekcje (okładka, opis, liczba zabaw, ile za darmo, cena).
- **Rezygnacja z subskrypcji** (inspiracja nagraniem Dawida): `Konto → Abonament` lub „Zarządzaj subskrypcją” → ekran „Jak możemy pomóc?” (abonament z datą, przywróć zakupy, zmień plan, anuluj) → pytanie „Dlaczego chcesz zrezygnować?” (Za drogo / Dziecko już nie korzysta / Za mało nowych zabaw / Coś nie działało / Kupione przez pomyłkę / Inny powód) → odpowiedź na to, co możemy naprawić → „Potwierdź anulowanie” z datą końca dostępu → strona subskrypcji w sklepie (aplikacja sama nie anuluje). Powody trafiają do statystyk w Studio.
- **Po pierwszym logowaniu:** oś „Teraz: darmowe zabawy → Z abonamentem: wszystkie zabawy → Co miesiąc: nowy pakiet”. Przycisk „Odbieram” przypięty na dole.
- **Tryb samochodowy i dobranoc:** stuknięcie „dalej” przez rodzica uruchamia następną zabawę od razu, bez 5-sekundowego odliczania (odliczanie zostaje, gdy zabawa kończy się sama).
- **Zmiany z badania rodziców (punkty A–G):**
  - A. Po darmowej zabawie „Czy dziecko chce jeszcze?” (Tak, od razu / Nie dziś / Zapytam), odpowiedź zapisywana jako `wants_more`.
  - B. Zielony znaczek „ZA DARMO” (nie dla abonentów), trzy opcje obok siebie na górze Sklepu (za darmo / pakiet na zawsze / abonament z ceną miesięczną i roczną w przeliczeniu).
  - C. Przegląd tekstów według zasad głosu.
  - D. Trasa: przypomnienie w piątek 15:30 (tylko dla rodziców, którzy włączyli przypomnienia), ostrzeżenie ile zabaw nie jest na telefonie, na koniec trasy linijka z prawdziwym czasem.
  - E. „Obiad bez wołania” na Starcie 16:30–19:30: około 25 minut zabaw bez przygotowań w jednym stuknięciu.
  - F. Pierwsza zabawa dopasowana do wieku (4-latek: najkrótsza darmowa).
  - G. „Co usłyszy dziecko” na stronie zabawy.
- **Dalsze usprawnienia:**
  - „Ulubiona: <imię>” z „Jeszcze raz” (zabawa ukończona co najmniej dwa razy).
  - Odliczanie do premiery nowej zabawy na dwa tygodnie przed (z dzwonkiem na dzień premiery).
  - Przełącznik „Słuchamy razem / Dziecko samo” w odtwarzaczu i dwa pytania do rozmowy po zabawie.
  - „Na leżąco” (filtr, od listopada do marca kafelek na Starcie).
  - „Dla dziadków” w Więcej (gotowa wiadomość do wysłania).
  - Prośba o ocenę w sklepie tylko w ciągu 3 dni od dobrego momentu (rodzic: „Tak, dziecko chce jeszcze” albo dziecko ukończyło tę samą zabawę ponownie), nie częściej niż co 60 dni.
  - **Dobranoc zawsze działa:** gdy cała biblioteka wygasła dzisiaj, zabawy „przed snem” grają do północy (aplikacja i serwer, `bedtime_grace`).
- **Polecenia 30 zł:** patrz sekcja 5.

### Stan CI ostatniej wersji
Wersja `726d9ff` (commit „Dobranoc zawsze działa…”) przeszła wszystkie sprawdzenia GitHub Actions, w tym build iOS, build Androida, testy schematu bazy i funkcji.

### Wcześniej (poza aplikacją)
- Strona audiokiddo.pl: wydajność (Lighthouse mobile z 67 do 93, desktop 96), konfiguracja cache, audyt SEO (`docs/strona/AUDYT-STRONY-2026-10-10.md`), sekcja pakietów, prompty dla osobnej sesji z dostępem do przeglądarki (`docs/ZADANIA-PRZEGLADARKA.md`, `docs/PROMPT-PUBLIKACJA-PRZEGLADARKA.md`), lista adresów do indeksacji w Search Console (55 adresów w porządku). Druga sesja naprawiła mapy witryny (wersja 3.25.1).
- Folder `filmy/` z narzędziami i podłączonym Higgsfield oraz ElevenLabs (klucze tylko jako Network secrets).
- Wtyczka 3.7.0 **nie** została wdrożona, bo cofnęłaby wersję 3.25.0 drugiej sesji.

---

## 8. Wyniki badania rodziców dzieci 4–6 lat (12.10.2026)

Badanie desk research (3189 opinii z App Store, Wykop, BabyBoom, Instagram, YouTube, artykuły). Bez rozmów z rodzicami; wiek 4–6 lat potwierdzony tylko w części wypowiedzi, reszta to rodzice przedszkolaków 3–7 lat. Plik źródłowy: `audiokiddo_badanie_rodzicow_dzieci_4-6.pdf` (u Dawida). Najważniejsze wnioski:

1. Rodzice **spierają się o ekran między sobą**, a tablet jest planem awaryjnym. Nie pozycjonować „przeciw ekranom”, mówić „jeszcze jedna rzecz w torbie”.
2. Rozwiązania mierzy się **czasem działania** („do pierwszego skrzyżowania”). Najgorsze są krótkie nagrania do ciągłego przełączania.
3. Najsilniejsze sytuacje: **trasa autem, pora 17–19 po pracy, chore dziecko w domu.** Pierwszy test sprzedażowy: trasa.
4. Zaufanie buduje **przewidywalna treść** („bez strasznych treści”, „nie ma głupot”), nie obietnice rozwojowe (przyjmowane podejrzliwie).
5. Najlepiej dopisywany humor: **format urzędowy i „specyfikacja”**, wymierzony w sytuację lub system, nigdy w innych rodziców („madki” poza granicą).
6. O zakupie decyduje **dziecko, które wraca** („mamo, włącz mi…”). Moment prawdy: koniec pierwszej darmowej zabawy.
7. Jedynki u konkurencji to **błędy aplikacji, niewidoczne kłódki, niejasne płatności i konta na jednym telefonie**.
8. Ojcowie są obecni i mówią krótko, z autoironią. Treści bez płci rodzica.
9. Rodzice chcą też **wspólnego czasu**, nie tylko odciążenia („spokój” bywa odbierany jako zarzut).
10. Logistyka przedszkola („na jutro”, kasztany w niedzielę o 20) to temat do rozpoznawalności marki, nie do sprzedaży.

Segmenty (do testów w tej kolejności): Trasa, Okno 17–19, Ostrożni wobec ekranów; później Dzień w domu i Rytuał razem. Konkurencja: Bajkowe Poddasze (najbliższy emocjonalnie, standard zaufania), Readmio (quizy po bajce, cena), Audioteka Kids i Storytel (bez kolejek, konto na jednym urządzeniu), prawdziwy rywal to darmowy YouTube i bajka w TV. Nikt w Polsce nie mówi „dziecko odpowiada i działa”. Rekomendowane testy: 6–8 rozmów, dwa „Raporty z trasy” (nagranie dźwięku bez twarzy dziecka, za zgodą rodziców), dwutygodniowy test formatów „Komunikat” i „Godzina zero”, test ekranu „Chce jeszcze?”.

---

## 9. Strategia i marketing

- Budżet startowy reklam: **5 000 zł**, cel: zysk (1 mln zł zysku), nie obrót. Plan `docs/STRATEGIA-5000-DO-MILIONA.md`: najpierw diagnoza poprzednich 2 000 zł kampanii (bez rezultatu) i sprawdzenie samego zakupu, potem jeden płatny kanał (Meta), 1 500 zł pierwsza transza, 2 500 zł warunkowo, 1 000 zł rezerwa. Zamówienia i zwroty ze sklepu są źródłem prawdy, nie panel reklamowy.
- Koszt stały około 1 000 zł miesięcznie. Było kilka zamówień na Empiku.
- Dodatkowe dokumenty: `docs/REKLAMY.md`, `docs/SEO-GEO.md`, `docs/marketing/`, `docs/CRM.md`, `docs/ANEKS-ANALITYCZNY.md` (zdarzenia analityczne).

---

## 10. Czeka na decyzje albo działania Dawida

**Serwer (po wdrożeniu do bazy działają nowe funkcje; do tego czasu stara zasada):**
```
supabase db push
supabase functions deploy referral-code
supabase functions deploy redeem-code
supabase functions deploy credit
```
Kolejność: najpierw baza, potem funkcje. Migracje do wdrożenia: `20261021000001_referral_credit.sql`, `20261022000001_bedtime_grace.sql`.

**Decyzje:**
- Czy zdanie „Bez reklam. Zabawy piszą Nela i Dawid, para z Polski.” na stronie zabawy jest w pełni prawdziwe (i czy dopisać „i nagrywają”, jeśli wszystkie głosy nagrywacie sami; część głosów jest z ElevenLabs).
- Jedna darmowa kołysanka „na zawsze” po wygaśnięciu abonamentu (wymaga zmiany w katalogu: która zabawa).
- Napis „NAJLEPIEJ SIĘ OPŁACA” przy planie rocznym: zostaje (opisuje prawdziwą oszczędność) albo do usunięcia.
- Duplikaty śledzenia na stronie (dwa piksele Facebooka, trzy tagi Google) czekają na decyzję.
- Aktualizacje wtyczek WordPress, okładki Maxa i Mili (do wyboru), widoczność strony `/zapis-pakiet-darmowy/`.
- Wniosek o uprawnienie CarPlay do Apple (`docs/CARPLAY.md`).
- Konta deweloperskie, produkty w sklepach, podpisywanie: `docs/WYDANIE.md`, `docs/PUBLIKACJA.md`, `docs/KROKI-DLA-DAWIDA.md`.

**Kolejne pomysły zaproponowane, jeszcze nie zrobione** (Dawid wybierze):
1. Prośba o opinię po zakończonej trasie z prawdziwym czasem.
2. Gotowe przykładowe zdania do opinii (bez nagród za opinie, zakazane przez Apple).
3. Szablony odpowiedzi na opinie w tonie Szop’ena (funkcja `reviews` już jest).
4. „Coś nie gra” zamiast jedynki: formularz z jednym pytaniem i automatycznymi danymi o telefonie.
5. Ekran „Działa bez internetu” z listą pobranych zabaw i „Pobierz wszystko na wyjazd”.
6. Jasna historia płatności (data następnej płatności, przypomnienie 3 dni przed końcem okresu).
7. Próbka 30 s na każdej zablokowanej zabawie.
8. Rytuał na tydzień (dwie stałe pory, jedno przypomnienie).
9. Seria dla rodzeństwa (wspólna zabawa dla dwojga).
10. Kartka „Zrobione” do wydruku z naklejkami po 10 zabawach.
- Odrzucone przez Dawida: „Protokół tygodnia” od Szop’ena.

**Znane drobne problemy:**
- CI: pojedyncze starsze maile „Run failed” dotyczyły testów Deno bez `--allow-env` i lintu; poprawione na gałęzi `claude/fervent-meitner-jmt63o`, nie na `main`.
- Lighthouse: pozostaje CLS 0,10 z `.ak-h5-szop` w hero strony (kod drugiej sesji).

---

## 11. Bezpieczeństwo i dane

- Hasła i klucze (WordPress `WP_USER`/`WP_PASS`, Higgsfield: nagłówek `Authorization: Key ID:SECRET`, ElevenLabs: nagłówek `xi-api-key`) są wyłącznie w zmiennych środowiskowych, Network secrets albo w pęku kluczy macOS. Nigdy w rozmowie, repozytorium ani zrzutach ekranu.
- Dane dzieci: lokalnie w telefonie (profile, wyniki, historia). Serwer zna konto rodzica i uprawnienia, nie zna profili dzieci.
- Analityka zdarzeń: bez danych osobowych, zdarzenia w `app_events` (opisy w `docs/ANEKS-ANALITYCZNY.md`).
- Skasowanie konta: funkcja `delete-account`. Lokalna kopia bazy: `docs/KOPIA-BAZY.md`.

---

## 12. Najważniejsze pliki (gdzie szukać szczegółów)

| Temat | Plik |
|---|---|
| Przekazanie projektu (starsze, 4.10) | `docs/PRZEKAZANIE-PROJEKTU.md` |
| Opis produktu, projekt, architektura | `PRODUCT.md`, `DESIGN.md`, `ARCHITECTURE.md` |
| Wydanie w sklepach, produkty i ceny | `docs/WYDANIE.md`, `docs/PUBLIKACJA.md`, `docs/SKLEPY.md`, `docs/KROKI-DLA-DAWIDA.md` |
| Polecenia 30 zł | `docs/POLECENIA.md` |
| CarPlay | `docs/CARPLAY.md` |
| Strategia i reklamy | `docs/STRATEGIA-5000-DO-MILIONA.md`, `docs/REKLAMY.md` |
| Strona i SEO | `docs/STRONA.md`, `docs/SEO-GEO.md`, `docs/strona/`, `strona/` |
| Zadania dla sesji z przeglądarką | `docs/ZADANIA-PRZEGLADARKA.md`, `docs/PROMPT-PUBLIKACJA-PRZEGLADARKA.md` |
| Analityka i CRM, panel Studio | `docs/ANEKS-ANALITYCZNY.md`, `docs/CRM.md`, `docs/PANEL-I-STATYSTYKI.md` |
| Treść gier i nagrań | `docs/ZABAWY-ZE-SLOWAMI.md`, `docs/NAGRANIA-DO-GIER.md`, `docs/FANTAZJUSZ-ELEVENLABS.md`, `docs/OKLADKI.md` |
| Plan usprawnień | `docs/PLAN-USPRAWNIEN.md` |
| Filmy | `filmy/`, `filmy/narzedzia/README.md` |

---

## 13. Jak zacząć pracę w nowej rozmowie

1. Przeczytaj sekcje 1, 2 i 10 tego pliku.
2. Zapytaj Dawida, na której gałęzi pracujecie (domyślnie `claude/fervent-meitner-jmt63o`) i czy wdrożył migracje z sekcji 10.
3. Przed zmianami w aplikacji: `cd app && flutter analyze --fatal-infos`, po zmianach pełne `flutter test --timeout 60s` oraz wersja sklepowa (`--dart-define=PARENT_GATE_EVERYWHERE=true --dart-define=REDEEM_CODES=false`).
4. Przed zmianami w bazie: test schematu przez `tool/test_db.sh` (potrzebuje PostgreSQL).
5. Teksty do rodzica pisz według zasad z sekcji 2, punkt 7.
6. Na końcu odpowiedzi: po polsku, krótka lista „Co teraz zrobić” dla Dawida.

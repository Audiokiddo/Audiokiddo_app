# AudioKiddo: architektura aplikacji mobilnej

Wersja: Etap 0, 2026-09-26, zaktualizowana po odpowiedziach Dawida tego samego dnia. Status każdej decyzji jest w sekcji 17. Kilka rozwiązań zależy od prób technicznych w Etapie 1 (sekcja 15).

Oznaczenia używane w dokumencie:

- **[F]**: fakt potwierdzony źródłem (rejestr źródeł w `docs/ETAP-0-RAPORT.md`, sekcja 11)
- **[D]**: informacja od Dawida, niezweryfikowana
- **[Z]**: założenie projektowe
- **[DEC]**: decyzja do podjęcia przez Dawida
- **[SPIKE]**: wymaga próby technicznej na urządzeniu przed utrwaleniem

---

## 1. Kontekst i ograniczenia

- Produkt: interaktywne audiozabawy (dziś 25 plików mp3 w 3 pakietach) i piosenki, obsługiwane bez patrzenia w ekran. **[F]**
- Istniejące audiozabawy to **liniowe nagrania z wbudowanymi pauzami na odpowiedź dziecka**. Nie potrzebują silnika. W v1 są odtwarzane jak zwykłe audio. **[Z]** Potwierdzi to odsłuch plików.
- Silnik skryptów (sekcja 10) służy nowym zabawom, które reagują na czas, dotyk lub dźwięk.
- Zespół utrzymujący: 2 osoby, bez dedykowanego backendowca. Kryterium wyboru: najmniej ruchomych części. **[D]**
- Dystrybucja: App Store (kategoria Kids) i Google Play (program Families). Rynki: `TODO(Dawid)`.

## 2. Widok ogólny

```
┌──────────────────────── Aplikacja Flutter (iOS / Android) ────────────────────────┐
│  Strefa rodzica           │  Tryb dziecka            │  Rdzeń (packages/ak_core)  │
│  konto, paywall, pobrania │  duże kafle, odtwarzacz, │  modele, walidator         │
│  ustawienia, PDF          │  silnik zabaw            │  skryptów, reguły dostępu  │
│  ─────────── parental gate ───────────               │                            │
│  Lokalnie: SQLite (drift) z profilami, ulubionymi, postępem i pobraniami;          │
│  pliki audio w katalogu aplikacji; ostatni poprawny katalog w cache                │
└──────────────┬──────────────────────────────────────────────────┬──────────────────┘
               │ HTTPS (katalog publiczny, podpisane URL-e)        │ StoreKit 2 / Play Billing
┌──────────────▼──────────────────────────────┐          ┌────────▼─────────┐
│ Supabase (region UE)                        │◄─────────┤ Apple / Google   │
│ Auth · Postgres (RLS) · Storage · Edge Fn   │ powiadom. │ serwery sklepów  │
│  verify-purchase / store-notifications /    │ serwerowe └──────────────────┘
│  download-url / delete-account / publish    │
└──────────────▲──────────────────────────────┘
               │
┌──────────────┴──────────────┐
│ AudioKiddo Studio (CMS)     │  Flutter Web, tylko dla administratorów
│ korzysta z tego samego      │
│ ak_core                     │
└─────────────────────────────┘
```

## 3. Stos technologiczny (wstępny)

Wersje sprawdzone w pub.dev i na kanale Flutter 2026-09-26. Przypinamy je w Etapie 1. **[F]**

| Obszar | Wybór | Wersja | Uzasadnienie |
|---|---|---|---|
| Framework | Flutter stable | 3.47.5 (Dart 3.13.4) | Decyzja Dawida, jedna baza kodu |
| Stan / DI | flutter_riverpod | 3.4.x | Jeden wzorzec, testowalny, bez generatorów na start |
| Nawigacja | go_router | 18.x | Przekierowania chroniące tryb dziecka i deep linki |
| Odtwarzanie | just_audio + audio_service + audio_session | 0.10.x / 0.18.x / 0.2.x | Standard dla tła i ekranu blokady |
| Mikrofon (gry) | record (strumień PCM) + własna analiza | 7.1.x | Lokalne wykrywanie klaśnięć i aktywności głosowej, bez zapisu [SPIKE] |
| Czujniki | sensors_plus | 7.1.x | Opcjonalny ruch telefonu [SPIKE] |
| Baza lokalna | drift (SQLite) | 2.35.x | Pobrania, postęp, ulubione, cache katalogu |
| Pobieranie | background_downloader | 9.6.x | Wznawianie, praca w tle, postęp |
| Zakupy | in_app_purchase (oficjalny plugin Flutter) | 3.3.x | Bez SDK firm trzecich (sekcja 7) |
| Logowanie | supabase_flutter + sign_in_with_apple (+ google_sign_in [DEC]) | 2.17.x | Sekcja 4 |
| PDF | printing (+ pdfx do podglądu) | 5.15.x | Drukowanie i udostępnianie kart pracy |
| Rozpoznawanie mowy | poza v1 | — | Polski na urządzeniu niepotwierdzony [SPIKE opcjonalny] |

Minimalne systemy (propozycja **[Z]**): iOS 16+, Android 8.0 (API 26)+. Target API zgodny z aktualnym wymogiem Google Play w dniu wydania.

**Czego celowo nie używamy:** Firebase Analytics, Crashlytics, Facebook SDK, RevenueCat, SDK reklamowe i identyfikatory reklamowe (IDFA, AAID; uprawnienie `AD_ID` usunięte z manifestu).

## 4. Backend: porównanie i rekomendacja

| Kryterium | **Supabase** (rekomendacja) | Firebase | Lekka alternatywa (np. Cloudflare Workers + R2 + D1) |
|---|---|---|---|
| Koszt startowy | Plan Pro ok. 25 USD/mies. (plan darmowy usypia nieaktywne projekty, więc nie nadaje się na produkcję) [do weryfikacji cen] | Blaze pay-as-you-go, zwykle niski | Najtańsza |
| Utrzymanie | Jedna konsola: Postgres, Auth, Storage, funkcje | Wiele usług, reguły w osobnym języku | Najwięcej własnego kodu (logowanie!) |
| Lokalizacja danych | Region UE (Frankfurt) do wyboru | Region UE możliwy, część usług globalna | UE możliwa |
| Prywatność SDK w apce dla dzieci | Klient to cienka warstwa HTTP, bez telemetrii zachowań | SDK Google z domyślnymi mechanizmami diagnostycznymi, wymaga audytu | Bez SDK |
| Usuwanie danych | Zwykłe SQL + usunięcie użytkownika Auth | Wiele miejsc (Auth, Firestore, Storage) | Własna implementacja |
| Pliki | Storage z podpisanymi URL-ami | Cloud Storage z regułami | R2 z podpisanymi URL-ami |
| Treści / CMS | Postgres i panel Studio na tym samym modelu | Firestore i własny panel | Własny panel |

**Rekomendacja [DEC]: Supabase, region UE.** Uzasadnienie: jedno miejsce na dane, jawny SQL z Row Level Security, proste usuwanie konta, brak SDK zbierającego telemetrię. Ryzyko: zależność od jednego dostawcy. Łagodzenie: standardowy Postgres i Storage kompatybilny z S3 dają się przenieść.

### Logowanie (wstępnie)

- **Konto jest opcjonalne (zatwierdzone).** Jest wymagane tylko do odblokowania pakietów kupionych na audiokiddo.pl (sekcja 7a). Aplikacja działa bez konta: darmowa próbka, a nawet zakup subskrypcji przez sklep, z przywróceniem przez „Przywróć zakupy”. Konto rodzica daje synchronizację uprawnień między iOS i Androidem oraz odzyskanie dostępu po zmianie telefonu na inny system.
- W momencie zakupu aplikacja tworzy **anonimowego użytkownika Supabase** (losowy UUID, bez danych osobowych), żeby powiązać transakcję z serwerem. Późniejsze założenie konta **łączy** tego użytkownika z e-mailem lub Apple ID, bez migracji danych.
- Metody: e-mail (kod jednorazowy, bez haseł) i **Sign in with Apple** (iOS). Google Sign-In **[DEC]**: dopuszczalność tego SDK w apce z Families i jego transmisję danych trzeba sprawdzić w Etapie 3, a na iOS wymusza zasadę 4.8 (spełnia ją Sign in with Apple). Bez Facebook Login.
- Logowanie jest dostępne tylko w strefie rodzica, za bramką.

## 5. CMS: AudioKiddo Studio

Wymaganie: Dawid bez kodu dodaje audio, okładkę, metadane i skrypt zabawy, podgląda, publikuje i wycofuje treści.

**Rekomendacja [DEC]: własny, prosty panel webowy we Flutter Web („Studio”)**, logowanie tylko dla kont z rolą `admin`.

- Współdzieli `ak_core` z aplikacją, więc **ten sam walidator** sprawdza skrypt w panelu i w telefonie. To najmocniejszy argument za własnym panelem.
- Funkcje: lista treści, formularz z uploadem audio i okładki (automatyczny odczyt długości i rozmiaru, suma SHA-256), edytor kroków zabawy w formie listy formularzy (nie surowy JSON), podgląd odsłuchu w przeglądarce, przyciski „Publikuj” i „Wycofaj”, historia wersji katalogu z przyciskiem „Przywróć”.
- Hosting statyczny (np. Cloudflare Pages, darmowy plan) albo Supabase Storage.

Alternatywa: **Directus** podpięty pod Postgres Supabase. Daje gotowy interfejs, ale walidację skryptów i publikację wersji trzeba by dopisać jako rozszerzenia, do tego dochodzi hosting kontenera. Supabase Studio (panel bazy) nie spełnia wymogu obsługi bez kodu.

## 6. Model danych

### 6.1 Serwer (Postgres, RLS włączone na wszystkich tabelach)

```
content_items          -- edytowane w Studio, NIE czytane bezpośrednio przez aplikację
  id text pk           -- np. 'wyobraznia-magiczny-sklep'
  kind text            -- 'audio_game' | 'song' | 'interactive_game'
  pack_id text null    -- 'wyobraznia' | 'slowa-i-wiedza' | 'detektyw' | null
  title, subtitle, parent_description text
  age_min smallint, age_max smallint null
  duration_sec int, players_min/max smallint null   -- tylko gdy znane
  situations text[]    -- 'podroz','przed-snem','w-domu','czekanie'
  skills text[]        -- cele rozwojowe (tylko uzasadnione)
  requirements text[]  -- 'mikrofon','miejsce-do-ruchu','kartka-i-olowek'
  access text          -- 'free' | 'subscription'
  store_product_id text null        -- produkt „pojedyncza zabawa” w sklepach (sekcja 7)
  -- dostęp: access='free' LUB użytkownik ma scope 'all_content' | 'pack:<pack_id>' | 'item:<id>'
  cover_asset, audio_assets jsonb   -- ścieżki w Storage, rozmiary, sha256
  script jsonb null    -- tylko kind='interactive_game'
  pdf_assets jsonb null
  status text          -- 'draft' | 'published' | 'withdrawn'
  updated_at, updated_by

catalog_versions       -- niezmienne migawki opublikowanego katalogu
  version int pk, created_at, created_by, manifest jsonb, manifest_sha256, note
catalog_pointer        -- jedna linia: aktualna wersja (publikacja / przywrócenie = zmiana wskaźnika)

accounts               -- 1:1 z auth.users; tylko rodzic
  user_id uuid pk, created_at, is_anonymous bool, deleted_at null

entitlements           -- źródło prawdy o dostępie
  id uuid pk, user_id uuid fk
  source text          -- 'app_store' | 'google_play' | 'woocommerce' | 'manual'
  scope text           -- 'all_content' | 'pack:<id>' | 'item:<content_id>'
  status text          -- 'active' | 'grace' | 'billing_retry' | 'expired' | 'revoked' | 'refunded'
  valid_until timestamptz null
  store_original_tx_id text unique null   -- iOS originalTransactionId / Android purchaseToken
  updated_at

store_events           -- idempotencja powiadomień serwerowych
  event_id text pk     -- notificationUUID (Apple) / messageId (Google) / webhook id (Woo)
  received_at, payload_hash, processed_at

store_products         -- mapowanie produktu (sklep lub WooCommerce) na zakresy dostępu
  product_ref text pk  -- 'ios:pl.audiokiddo.pack.detektyw' | 'android:…' | 'woo:1234'
  scopes text[]        -- np. zestaw 3 pakietów: {'pack:wyobraznia','pack:slowa-i-wiedza','pack:detektyw'}

web_purchases_pending  -- zakupy ze strony, których e-mail nie ma jeszcze konta w aplikacji
  email_normalized text, woo_order_id bigint, product_ref text, status text, created_at
  -- unikalne (woo_order_id, product_ref); przypisywane po zalogowaniu na ten e-mail
```

Na serwerze **nie ma żadnych danych dziecka**: profile, pseudonimy, postęp i ulubione są wyłącznie lokalne w v1 **[DEC]**.

### 6.2 Telefon (SQLite przez drift)

`child_profiles` (lokalne: pseudonim opcjonalny, przedział wieku, awatar z gotowej listy), `favorites`, `recent_plays`, `playback_progress`, `downloads` (id treści, wersja, ścieżka, rozmiar, sha256, stan: `queued | running | verifying | ready | failed`), `catalog_cache` (ostatni **poprawnie zwalidowany** manifest i jego wersja), `entitlement_lease` (sekcja 8).

### 6.3 Manifest katalogu (to, co pobiera aplikacja)

Publiczny plik `catalog/v{N}.json` plus mały wskaźnik `catalog/current.json` (`{"version": N, "sha256": "..."}`). Zawiera metadane, półki redakcyjne („zabawa dnia”, półki tematyczne) i odnośniki do zasobów. Pliki darmowe leżą w publicznym buckecie, płatne w prywatnym i są pobierane przez podpisany URL.

Zasady aktualizacji:

1. Aplikacja pobiera wskaźnik i manifest, sprawdza sumę kontrolną, `schema_version` i waliduje każdą pozycję. Pozycje z `min_engine_version` wyższym niż silnik aplikacji są **ukrywane**, reszta działa.
2. Błąd całego manifestu oznacza, że aplikacja zostaje przy ostatnim poprawnym katalogu z cache. Biblioteka nie znika.
3. Nowy katalog nigdy nie podmienia danych trwającej sesji. Sesja trzyma migawkę skryptu z chwili startu.
4. Pobrane pliki są adresowane parą (id, wersja zasobu). Stara wersja zostaje, dopóki nowa nie jest `ready`.

## 7. Płatności i weryfikacja

**Decyzja (zatwierdzona 2026-09-26): natywne zakupy przez `in_app_purchase` i własna weryfikacja w Edge Functions Supabase. Bez RevenueCat.**

Uzasadnienie: publicznie opisane przypadki odrzuceń aplikacji w Apple Kids Category z powodu przekazywania historii zakupów stronie trzeciej (RevenueCat Community, 2023) i zgłoszenia problemów z identyfikatorami w Google Families. **[F, źródła 2023–2024, mogą być nieaktualne]** Własna weryfikacja eliminuje stronę trzecią z przepływu danych. Koszt: więcej kodu serwerowego, ok. 3–5 dni.

Przepływ:

1. Paywall (strefa rodzica) pokazuje produkty z `queryProductDetails`: cenę, okres i ofertę wstępną **z danych sklepu**, nigdy z własnej konfiguracji.
2. Przed zakupem aplikacja tworzy lub odczytuje anonimowego użytkownika i przekazuje jego UUID jako `appAccountToken` (iOS) i `obfuscatedAccountId` (Android).
3. Po zakupie klient wysyła transakcję (JWS na iOS, `purchaseToken` na Androidzie) do `verify-purchase`. Serwer weryfikuje ją przez App Store Server API i Google Play Developer API, zapisuje `entitlements` i dopiero wtedy aplikacja **potwierdza transakcję** (`completePurchase` i acknowledge). Błąd sieci zostawia transakcję niepotwierdzoną i ponawia próbę. Aplikacja **nigdy** nie nadaje dostępu na podstawie samego odpowiedzi klienta.
4. `store-notifications`: App Store Server Notifications V2 (weryfikacja podpisu JWS i łańcucha certyfikatów Apple) oraz Google RTDN przez Pub/Sub push (weryfikacja tokenu OIDC). Każde zdarzenie jest zapisywane w `store_events`, a duplikat jest ignorowany (idempotencja). Obsługiwane: odnowienie, wygaśnięcie, okres łaski, ponawianie płatności, zwrot i odwołanie, zmiana planu, zakup oczekujący (Ask to Buy / płatność odroczona).
5. „Przywróć zakupy” odtwarza transakcje sklepu i weryfikuje je ponownie. Zakup przypisany do innego konta AudioKiddo: **[DEC]** proponuję przepięcie do bieżącego konta z komunikatem dla rodzica.

### Oferta w aplikacji (zatwierdzona struktura, ceny częściowo do ustalenia)

| Produkt | Typ w sklepie | Zakres | Cena |
|---|---|---|---|
| Subskrypcja miesięczna | auto-odnawialna | `all_content` | 29,99 zł (od 9.10.2026; roczna 269,99 zł), bez planów wg liczby dzieci |
| Subskrypcja roczna | auto-odnawialna | `all_content` | 149,99 zł, 7 dni za darmo |
| Pakiet Wyobraźnia | jednorazowy (non-consumable) | `pack:wyobraznia` | 49,99 zł (jak na stronie) |
| Pakiet Słowa i Wiedza | jednorazowy | `pack:slowa-i-wiedza` | 49,99 zł |
| Pakiet Detektyw | jednorazowy | `pack:detektyw` | 69,99 zł |
| Zestaw 2 pakietów | jednorazowy | 2 × `pack:` | 89,99 zł |
| Zestaw 3 pakietów | jednorazowy | 3 × `pack:` | 159,99 zł |
| Pojedyncza zabawa: Wyobraźnia, Słowa i Wiedza | jednorazowy | `item:<id>` | propozycja **9,99 zł** (pakiet wychodzi o 50% taniej) [DEC] |
| Pojedyncza zabawa: Detektyw | jednorazowy | `item:<id>` | propozycja **19,99 zł** (pakiet o 30% taniej) [DEC] |

- Ceny w sklepach wybiera się z siatki cen Apple i Google. Aplikacja zawsze pokazuje cenę zwróconą przez sklep.
- Trial 7 dni na obu planach (zatwierdzone 2026-09-26), skonfigurowany w obu sklepach jako oferta wstępna. Sklepy dają go raz na użytkownika w grupie subskrypcji, więc aplikacja pokazuje go **tylko wtedy, gdy sklep go zwraca** dla danego użytkownika.
- Rodzic, który ma już pojedyncze zabawy, widzi pełną cenę pakietu. Sklepy nie obsługują dopłat do pakietu, więc przy zakupie pojedynczej zabawy pokazujemy uczciwą podpowiedź: „Pakiet 10 zabaw kosztuje 49,99 zł”.
- Każda pojedyncza zabawa to osobny produkt, ręcznie zakładany w App Store Connect i Play Console (~30 produktów na start, każdy z nazwą, opisem i dla Apple ze zrzutem do review). W Studio pole `store_product_id` łączy treść z produktem. Automatyzacja przez API sklepów jest możliwa później.
- Bez przekreślonych cen „promocyjnych” w aplikacji: zasady sklepów i przepisy o obniżkach (Omnibus) utrudniają to bez wyraźnej potrzeby.

## 7a. Zakupy ze strony audiokiddo.pl (WooCommerce), zakres v1

Wymaganie Dawida: klienci strony mają w aplikacji dostęp do pakietów kupionych na stronie.

**Zgodność ze sklepami:**
- Apple 3.1.3(b) *Multiplatform Services* pozwala na dostęp do treści kupionych na stronie, **o ile te same treści można kupić w aplikacji** (spełnione: pakiety są też produktami w aplikacji). [F]
- Aplikacja nie może zachęcać do kupowania poza aplikacją: w aplikacji **nie ma** żadnej wzmianki o sklepie internetowym, jego cenach ani linku. [F]
- Google: FAQ Payments potwierdza dostęp do treści opłaconych gdzie indziej dla aplikacji bez zakupów (*consumption-only*). Dla aplikacji z zakupami w Google Play i jednocześnie dostępem do zakupów ze strony nie znalazłem wprost zapisu. Zakaz dotyczy kierowania do innych metod płatności, a tego nie robimy. **Ryzyko niskie, do ponownej weryfikacji w Etapie 5.** [F/Z]

**Przepływ:**
1. Rodzic (za bramką) loguje się w aplikacji e-mailem użytym przy zakupie. Kod jednorazowy potwierdza, że e-mail należy do niego.
2. Funkcja `sync-web-purchases` pyta API WooCommerce (klucz tylko do odczytu, w sekretach Supabase) o zamówienia ze statusem „zrealizowane” dla tego adresu rozliczeniowego. Pozycje zamówień są mapowane przez `store_products` na zakresy `pack:*`, a wynik trafia do `entitlements` z `source='woocommerce'` i `store_original_tx_id='woo:<order>:<product>'` (idempotencja).
3. Webhook WooCommerce (`order.updated`, podpis HMAC weryfikowany na serwerze):
   - zamówienie zrealizowane: przyznanie dostępu albo wpis do `web_purchases_pending`, jeśli konta jeszcze nie ma;
   - zwrot lub anulowanie: status `revoked`.
4. Klient kupił na inny e-mail: w Studio jest przycisk „Przyznaj dostęp” (źródło `manual`, z notatką). Tekst pomocy w aplikacji: „Nie widzisz zakupionego pakietu? Napisz do nas”, bez linku do sklepu.

**Po stronie WordPressa (Dawid):** klucze REST API WooCommerce tylko do odczytu, webhook `order.updated` z sekretem, lista ID produktów (5 produktów). Bez zmian w motywie i wtyczkach.

**Koszt:** ok. 3–5 dni w Etapie 3.

## 8. Polityka dostępu offline (propozycja do zatwierdzenia) [DEC]

| Sytuacja | Zachowanie |
|---|---|
| Darmowa próbka | Po pobraniu działa offline bez limitu, bez konta i bez serwera |
| Aktywna subskrypcja | Aplikacja trzyma **lokalną dzierżawę** (`lease`) podpisaną przez serwer: `valid_until` = min(koniec okresu + 3 dni, teraz + **30 dni**). Pobrane treści płatne grają offline do jej końca |
| Odświeżanie | Przy każdym starcie z internetem, w tle, bez blokowania odtwarzania |
| Długa podróż | 30 dni offline bez przerwy wystarcza na typowe wyjazdy. Przed wyjazdem rodzic może w ustawieniach „odświeżyć dostęp”, co daje pełne 30 dni |
| Wygaśnięcie (wykryte online) | Treści płatne zablokowane z kłódką i komunikatem dla rodzica. Pliki zostają **14 dni** (powrót bez ponownego pobierania), potem są usuwane automatycznie |
| Dzierżawa wygasła offline | Blokada z prośbą o połączenie, pokazywana tylko w strefie rodzica. Dziecko widzi neutralny komunikat głosowy „Poproś rodzica” |
| Zwrot lub odwołanie | Wykryte przy następnym połączeniu. **Kompromis:** na urządzeniu stale offline dostęp trwa najwyżej do końca dzierżawy (maks. 30 dni) |
| Zmiana zegara | Ochrona przed cofnięciem zegara: zapamiętany „najpóźniej widziany czas”. Cofnięcie zegara o więcej niż 24 h wymusza odświeżenie online |
| Wylogowanie | Treści płatne pozostają na dysku, ale zablokowane do ponownego zalogowania na konto z dostępem. Próbka działa |
| Zmiana konta | Uprawnienia przeliczane dla nowego konta, pobrania bez uprawnień zablokowane |
| Usunięcie konta | Usuwane wszystkie pobrane treści płatne i dane lokalne (poza próbką, jeśli rodzic chce jej używać dalej jako gość) |

Pliki nie są szyfrowane (DRM) **[Z]**: te same mp3 są sprzedawane na stronie, więc koszt DRM przewyższa korzyść. Pliki leżą w katalogu aplikacji wykluczonym z kopii iCloud i Google.

## 9. Audio: odtwarzanie, sesja, przerwania

- **Zwykłe audio** (audiozabawy, piosenki): `just_audio` + `audio_service`. iOS: `UIBackgroundModes: audio`, kategoria `playback`. Android: usługa pierwszoplanowa typu `mediaPlayback` (deklaracja w Play Console dla targetu 14+). **[F]** Sterowanie z ekranu blokady, słuchawek i Bluetooth przez `audio_service`.
- **Przerwania** (`audio_session`): połączenie telefoniczne pauzuje, po zakończeniu odtwarzanie **nie wznawia się samo** (dziecko mogło odejść). Odłączenie słuchawek pauzuje. Zmiana wyjścia audio kontynuuje odtwarzanie.
- **Prędkość**: 0,75–1,25× dla audiozabaw i piosenek. **Wyłączona** w grach rytmicznych i wszystkich zabawach z `timing_sensitive: true`.
- **Timer snu**: 5 / 10 / 15 / 30 min lub „do końca zabawy”, z łagodnym wyciszeniem. Brak autoodtwarzania kolejnych treści w trybie dziecka.
- **Sesja gry z mikrofonem [SPIKE]**: iOS wymaga kategorii `playAndRecord` z `defaultToSpeaker`, `allowBluetoothA2DP` i przetwarzaniem głosu (AEC). Uwaga: gdy wejściem jest mikrofon słuchawek Bluetooth, system przełącza je na profil HFP (mono, niższa jakość). Plan: wejście z mikrofonu telefonu, wyjście A2DP. Android: `AcousticEchoCanceler` tam, gdzie dostępny. Mikrofon aktywny **tylko w oknach nasłuchu** po zakończeniu instrukcji.

## 10. Silnik interaktywnych zabaw

Skrypt to **dane** interpretowane przez silnik wbudowany w aplikację. Żadnego pobieranego kodu. Nowe scenariusze mogą korzystać z istniejących typów kroków; nowy typ kroku wymaga aktualizacji aplikacji i podniesienia `engine_version`.

### 10.1 Typy kroków (engine_version 1)

| Typ | Opis |
|---|---|
| `play` | Odtwórz segment audio |
| `wait` | Cisza lub pętla podkładu przez `duration_ms` (czas na odpowiedź dziecka) |
| `input` | Okno nasłuchu lub dotyku z limitem czasu i wynikami `on_*` |
| `branch` | Wybór następnego kroku na podstawie zmiennej lub wyniku |
| `set` | Ustaw lub zwiększ zmienną (np. licznik rund) |
| `goto` | Skok (pętle ograniczone przez `max_visits`) |
| `end` | Zakończenie z opcjonalnym segmentem pożegnania |

Wejścia w v1: `tap_anywhere`, `clap` (liczba klaśnięć), `voice_activity` (dziecko coś powiedziało, **nie** co), `motion_shake` (opcjonalnie). `speech_keywords` jest zarezerwowane, a walidator odrzuca je w v1.

### 10.2 Przykład: „Zgadnij dźwięk” (runda z pętlą)

```json
{
  "schema_version": 1,
  "id": "zgadnij-dzwiek-zwierzeta-1",
  "version": 3,
  "min_engine_version": 1,
  "title": "Zgadnij dźwięk: zwierzęta",
  "age_min": 3,
  "duration_sec_estimate": 360,
  "situations": ["podroz", "w-domu"],
  "timing_sensitive": false,
  "capabilities": { "optional": ["voice_activity"], "required": [] },
  "assets": {
    "intro":      { "path": "games/zd1/intro.m4a",      "bytes": 412331, "sha256": "…" },
    "q_krowa":    { "path": "games/zd1/q_krowa.m4a",    "bytes": 98211,  "sha256": "…" },
    "a_krowa":    { "path": "games/zd1/a_krowa.m4a",    "bytes": 120044, "sha256": "…" },
    "heard_you":  { "path": "games/zd1/heard_you.m4a",  "bytes": 30112,  "sha256": "…" },
    "thinking":   { "path": "games/zd1/thinking_loop.m4a", "bytes": 60551, "sha256": "…" },
    "outro":      { "path": "games/zd1/outro.m4a",      "bytes": 301222, "sha256": "…" }
  },
  "variables": { "round": 0 },
  "start": "intro",
  "steps": {
    "intro":   { "type": "play", "asset": "intro", "next": "q1" },
    "q1":      { "type": "play", "asset": "q_krowa", "next": "listen1" },
    "listen1": {
      "type": "input",
      "input": "voice_activity",
      "window_ms": 6000,
      "on_detected": "ack1",
      "on_timeout": "answer1",
      "fallback": {
        "no_microphone":  { "type": "wait", "duration_ms": 6000, "loop_asset": "thinking", "next": "answer1" },
        "screen_locked":  "same_as_no_microphone",
        "input_error":    "same_as_no_microphone"
      }
    },
    "ack1":    { "type": "play", "asset": "heard_you", "next": "answer1" },
    "answer1": { "type": "play", "asset": "a_krowa", "next": "count" },
    "count":   { "type": "set", "var": "round", "op": "inc", "next": "more" },
    "more":    { "type": "branch", "if": { "var": "round", "lt": 5 }, "then": "q1", "else": "end", "max_visits": 6 },
    "end":     { "type": "end", "asset": "outro" }
  }
}
```

Ważne: segment `heard_you` mówi „Słyszę, że masz pomysł!”, a **nie** „Brawo, dobrze!”, bo aplikacja nie wie, co dziecko powiedziało. Odpowiedź zawsze pada z nagrania.

### 10.3 Walidacja (w Studio przed publikacją i w telefonie przed startem)

- Schemat JSON, wszystkie odwołania `next`, `then`, `else`, `on_*` i `asset` istnieją, `start` istnieje.
- Każdy krok jest osiągalny (ostrzeżenie), z każdego kroku da się dojść do `end`.
- Pętle: każdy cykl w grafie zawiera `branch` z `max_visits`. Twarde limity silnika: 500 wykonanych kroków na sesję, `window_ms` ≤ 30 000, `duration_ms` ≤ 120 000, łączny czas sesji ≤ 60 min.
- Każdy krok `input` ma pełny `fallback` dla `no_microphone`, `screen_locked` i `input_error`.
- `timing_sensitive: true` blokuje zmianę prędkości.
- Wadliwy skrypt oznacza, że zabawa nie startuje („Tej zabawy nie da się teraz uruchomić”), błąd trafia do lokalnego logu. Reszta biblioteki działa.

### 10.4 Stan sesji i przerwania

Sesja zapisuje `(script_id, script_version, step_id, variables)` przy każdym kroku. Przerwanie (telefon, wyjście, zabicie aplikacji) prowadzi do wznowienia od **początku bieżącego kroku `play`** albo od powtórzenia instrukcji przed `input`. Zmiana wersji skryptu w katalogu przy niedokończonej sesji: sesja startuje od nowa z nową wersją.

### 10.5 Trzy prototypy (Etap 4)

| Prototyp | Wariant bazowy (działa zawsze) | Wariant rozszerzony | Czego NIE deklarujemy |
|---|---|---|---|
| Zgadnij dźwięk | `wait` z podkładem, potem rozwiązanie | `voice_activity` skraca czekanie | Oceny poprawności odpowiedzi |
| Zamrożony taniec | Muzyka i nagrane „STOP!” w losowych odstępach z listy. Telefon leży. Zadania ruchowe bezpieczne (bez skakania z mebli). **W trybie „podróż” zamiana na taniec rąk i min** | brak | Wykrywania ruchu dziecka |
| Echo rytmu | Demonstracja, `wait`, „a teraz posłuchaj, jak to brzmiało” | `clap` liczy klaśnięcia i porównuje **liczbę**, z tolerancją [SPIKE] | Precyzyjnej oceny rytmu, dopóki spike tego nie potwierdzi |

## 11. Macierz możliwości (stan aplikacji × platforma)

Legenda: ✅ standardowe API, do potwierdzenia testem na urządzeniu · ⚠️ możliwe warunkowo [SPIKE] · ❌ niemożliwe lub nie planujemy.

| Funkcja | iOS: pierwszy plan | iOS: tło | iOS: blokada | Android: pierwszy plan | Android: tło | Android: blokada |
|---|---|---|---|---|---|---|
| Zwykłe audio | ✅ | ✅ | ✅ | ✅ | ✅ (FGS mediaPlayback) | ✅ |
| Sterowanie ze słuchawek / ekranu blokady | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Gra: kroki `play`/`wait`/`branch` | ✅ | ⚠️ (sesja audio musi trwać nieprzerwanie) | ⚠️ jw. | ✅ | ⚠️ (FGS) | ⚠️ (FGS) |
| Wejście: dotyk ekranu | ✅ | ❌ | ❌ | ✅ | ❌ | ❌ |
| Wejście: klaśnięcie / VAD (mikrofon) | ✅ | ⚠️ tylko jeśli nagrywanie wystartowało na pierwszym planie i sesja trwa | ⚠️ jw. | ✅ | ⚠️ FGS `microphone` musi wystartować, gdy apka jest widoczna [F] | ⚠️ jw. |
| Wejście: ruch telefonu | ✅ | ⚠️ niepotwierdzone | ⚠️ niepotwierdzone | ✅ | ⚠️ tylko w FGS (bez FGS brak zdarzeń od Androida 9) [F] | ⚠️ jw. |
| Rozpoznawanie słów po polsku lokalnie | ⚠️ polski na urządzeniu niepotwierdzony | ❌ (v1) | ❌ (v1) | ⚠️ zależne od urządzenia i pakietu języka | ❌ (v1) | ❌ (v1) |

Wniosek projektowy: **każda zabawa musi mieć wariant bazowy oparty wyłącznie na `play`/`wait`**, a wejścia są dodatkiem. Po wykryciu blokady ekranu silnik przełącza bieżący `input` na `fallback.screen_locked`, zanim upłynie okno nasłuchu.

## 12. Tryb dziecka i parental gate

- **Wejście do trybu dziecka**: rodzic wybiera profil i zabawy (albo „wszystko dostępne dla wieku”). Tryb pamięta się po restarcie aplikacji.
- **W trybie dziecka nie ma**: zakupów, paywalla, linków zewnętrznych, udostępniania, ustawień konta ani próśb o uprawnienia systemowe. Treści zablokowane są **ukryte**, a nie pokazane z kłódką (brak presji zakupowej).
- **Wyjście**: ikona rodzica w rogu otwiera bramkę. Nawigacja wstecz (Android), deep link i przywrócenie ekranu po restarcie przechodzą przez `go_router` `redirect`, który sprawdza flagę trybu. Test widżetowy dla każdej trasy.
- **Bramka [Z]**: zadanie wymagające czytania i liczenia, generowane losowo, np. „Dotknij liczby **czterdzieści siedem**”, a do wyboru 4 liczby zapisane cyframi. Bez podpowiedzi głosowej z odpowiedzią. Po 3 błędach blokada na 30 s. Komunikat głosowy „Zawołaj rodzica” dla dzieci, które nie czytają (zgodnie z sugestią Apple). Bramka **nie jest** zgodą rodzica na przetwarzanie danych ani weryfikacją wieku.
- **Bramka chroni**: wyjście z trybu dziecka, paywall i zakupy, logowanie i konto, linki (polityka, regulamin, zarządzanie subskrypcją, kontakt), prośbę o mikrofon, udostępnianie i drukowanie PDF, ustawienia.

## 13. Bezpieczeństwo

- Klucze Apple (App Store Server API, `.p8`), konto serwisowe Google i klucz `service_role` Supabase trzymamy **wyłącznie** w sekretach Edge Functions. Nigdy w aplikacji, repozytorium ani rozmowie. W aplikacji jest tylko publiczny klucz `anon`.
- RLS: użytkownik czyta tylko swoje `entitlements`. Zapisy do `entitlements` i `store_events` robią wyłącznie funkcje serwerowe. Tabele treści czyta i zapisuje tylko rola `admin` (Studio).
- Podpisane URL-e do plików płatnych: ważne 15 min, wydawane po sprawdzeniu uprawnień. Sam URL nie reguluje dostępu do lokalnej kopii (sekcja 8).
- Integralność pobrań: po pobraniu sprawdzana jest suma SHA-256. Niezgodna suma oznacza, że plik nie jest `ready`, zostaje usunięty i pobranie jest ponawiane.
- Studio: logowanie e-mail z kodem, rola `admin` nadawana ręcznie w bazie, 2 konta.
- CI: sekrety podpisu (certyfikaty, keystore) w sekretach CI albo lokalnie w pęku kluczy macOS, nigdy w repo. `.gitignore` z `key.properties`, `*.jks`, `*.p8`, `.env`.

## 14. Prywatność i zgodność: plan

Szczegóły źródeł z datą sprawdzenia: `docs/ETAP-0-RAPORT.md`, sekcja 11.

| Wymaganie | Źródło | Realizacja w projekcie | Dowód weryfikacji (Etap 5) |
|---|---|---|---|
| Kids Category: brak linków, zakupów i rozpraszaczy poza strefą za bramką | Apple 1.3 [F] | Sekcja 12 | Testy widżetowe tras, nagranie przejścia |
| Kids: brak analityki i reklam firm trzecich, brak przekazywania danych urządzenia stronom trzecim | Apple 1.3, 5.1.4 [F] | Brak SDK analityki; Supabase jako podmiot przetwarzający; własna weryfikacja zakupów | Lista zależności, przechwycony ruch sieciowy (proxy) |
| Metadane „dla dzieci” tylko w Kids Category | Apple 5.1.4 / 2.3.8 [F] | Implikuje wybór Kids Category **[DEC]** | Checklista metadanych |
| Logowanie przez stronę trzecią wymaga równoważnej opcji | Apple 4.8 [F] | E-mail + Sign in with Apple | Test ekranu logowania |
| Usunięcie konta w aplikacji | Apple 5.1.1(v), Google [F] | `delete-account` (Edge Function) + informacja, że subskrypcję anuluje się w sklepie | Test E2E: rekordy znikają |
| Usunięcie konta także przez stronę WWW | Google Play [F] | Formularz lub strona na audiokiddo.pl z instrukcją (e-mail z kodem) | Link w Data safety |
| Zakupy treści cyfrowych przez IAP | Apple 3.1.1 / Google Payments [F] | `in_app_purchase` | Sandbox / licencjonowani testerzy |
| Dostęp do zakupów ze strony bez zachęcania do nich | Apple 3.1.3(b), Google Payments FAQ [F] | Sekcja 7a: te same pakiety w IAP, brak wzmianek o sklepie www | Przegląd tekstów i ekranów |
| Informacje o subskrypcji przed zakupem | Apple 3.1.2 [F] | Paywall: cena, okres, odnowienie, trial, linki | Zrzuty ekranu paywalla |
| Families: zakaz transmisji AAID i innych identyfikatorów sprzętowych | Google Families [F] | Brak SDK, `AD_ID` usunięte z manifestu | Merged manifest + ruch sieciowy |
| Families: ujawnienie danych z mikrofonu | Google Families [F] | Mikrofon lokalnie, bez zapisu; deklaracja w Data safety | Kod + test ruchu |
| FGS: deklaracja typów usług | Android / Play Console [F] | `mediaPlayback` (+ `microphone` tylko jeśli spike się uda) | Wpis w Play Console |
| RODO / COPPA / prawo konsumenckie | Przepisy | Minimum danych, brak danych dziecka na serwerze, podstawa prawna do konsultacji | **Wymaga konsultacji prawnej** |
| Oznaczenie przedsiębiorcy (DSA) w UE | App Store / Play [Z, do weryfikacji] | Dane przedsiębiorcy publicznie w sklepach (adres, e-mail, telefon) | Konsola sklepu |

## 15. Próby techniczne (Etap 1, przed rozbudową)

1. **Audio w tle i przy blokadzie** na fizycznym iPhonie i Androidzie: odtwarzanie, ekran blokady, połączenie przychodzące, odłączenie słuchawek, samochód przez Bluetooth.
2. **Sesja gry z mikrofonem przy blokadzie**: iOS `playAndRecord` + AEC; Android FGS `mediaPlayback|microphone` uruchomiona na pierwszym planie. Kryterium: po zablokowaniu ekranu okno nasłuchu nadal otrzymuje próbki, a dźwięk z głośnika nie wyzwala detekcji w ≥ 95% prób w cichym pokoju.
3. **Detektor klaśnięć**: skuteczność na 3 urządzeniach, w cichym pokoju i w aucie (odrzuty i fałszywe trafienia).
4. **(Opcjonalnie) Rozpoznawanie mowy po polsku offline**: iOS `SFSpeechRecognizer.supportsOnDeviceRecognition` i `SpeechTranscriber.supportedLocales`; Android `createOnDeviceSpeechRecognizer`. Tylko do decyzji na przyszłość.

Wyniki mogą zmienić sekcje 9–11.

## 16. Struktura repozytorium (planowana)

```
audiokiddo-app/
  app/                    # aplikacja Flutter
    lib/
      core/               # motyw, router, DI, błędy, lokalizacja
      features/
        catalog/  player/  downloads/  games/  kids_mode/
        parental_gate/  paywall/  account/  onboarding/  settings/
      l10n/app_pl.arb
    test/  integration_test/
  packages/ak_core/       # modele, schemat i walidator skryptów, reguły dostępu (czysty Dart)
  studio/                 # CMS (Flutter Web), Etap 3
  supabase/
    migrations/  functions/{verify-purchase,store-notifications,sync-web-purchases,woo-webhook,download-url,delete-account,publish-catalog}/
  docs/
  ARCHITECTURE.md  README.md
```

## 17. Decyzje

| # | Decyzja | Stan |
|---|---|---|
| D1 | Backend: Supabase, region UE | wstępna (brak sprzeciwu); budżet ~100–150 zł/mies. czeka na potwierdzenie |
| D2 | CMS: własne Studio (Flutter Web); użytkownicy: Dawid i Nela | **zatwierdzona** |
| D3 | Weryfikacja zakupów: własna, bez RevenueCat | **zatwierdzona** |
| D4 | Konto: opcjonalne; anonimowy użytkownik przy zakupie | **zatwierdzona** |
| D5 | Profile dzieci tylko lokalne | wstępna (brak sprzeciwu) |
| D6 | Polityka offline: sekcja 8 | wstępna (brak sprzeciwu) |
| D7 | Rozpoznawanie słów poza v1 | wstępna (brak sprzeciwu) |
| D8 | Apple Kids Category (przedział „5 i młodsze”) + Google tylko dzieci | **zatwierdzona** |
| D9 | Google Sign-In: decyzja w Etapie 3 po audycie SDK | otwarta |
| D10 | CarPlay / Android Auto poza v1 | wstępna (brak sprzeciwu) |
| D11 | Zakupy ze strony (WooCommerce) w v1, sekcja 7a | **zatwierdzona** |
| D12 | Oferta: subskrypcja + pakiety + zestawy + pojedyncze zabawy, sekcja 7 | **zatwierdzona** z cenami (24,99 zł / 149,99 zł, trial 7 dni na obu planach; pojedyncze zabawy 9,99 / 19,99 zł) |
| D13 | Wiek: jak na stronie głównej (Wyobraźnia i Słowa i Wiedza 3+, Detektyw 6+) | **zatwierdzona** |
| D14 | Rynek: Polska na start, docelowo cały świat; interfejs od początku w plikach lokalizacji | **zatwierdzona** |
| D15 | Piosenki: autorskie AudioKiddo | **potwierdzone** przez Dawida (dotyczy też praw wykonawczych do nagrań) |

## Dodatki 2026-09-28: rodzina, plan, przypomnienia, Kiddo

- **D16. Profile dzieci tylko w telefonie.** Imię (opcjonalne), wiek, cele, sytuacje, minuty dziennie. Kilkoro dzieci, jedno aktywne. Wyniki zabaw (ukończenia, odpowiedzi, poprawne odpowiedzi ze zmiennej `score` skryptu) zapisywane lokalnie, maks. 2000 wpisów. Nic o dzieciach nie trafia na serwer.
- **D17. Plan rozwoju w `ak_core` (`development.dart`).** 30 dni, 4 poziomy (1: krótkie nagrania i piosenki; 2: zabawy z odpowiedziami; 3+: dłuższe przygody), jedna porcja dziennie w limicie minut, bez powtórek dzień po dniu, skrzynka co 7 dni, porady funkcji po jednej. Nowy dzień otwiera się najwcześniej następnego dnia kalendarzowego. Zablokowane treści tylko, gdy nie ma nic dostępnego; dzień zaliczają dostępne zabawy; rozpoczęte dni są „zamrażane”.
- **D18. Przypomnienia lokalne** (`flutter_local_notifications`) o godzinie wybranej przez rodzica, na 7 dni naprzód, odnawiane przy każdym otwarciu; dzisiejsze pomijane po wykonaniu porcji. Teksty z lekkim humorem dla rodziców.
- **D19. Kiddo i magiczne wejście.** Maskotka rysowana w kodzie; wstęp z lektorem (podgłośnij → powitanie → „Abrakadabra!” → dostęp przyznany). Głos Kiddo wbudowany (`assets/audio/kiddo`), nagrania zastępcze do podmiany przez Nelę.
- **D20. Głos rodzica tylko w telefonie.** Trzy nagrania na dziecko (przywitanie, pochwała, dobranoc; do 12 s, AAC 64 kbps) w `Documents/parent_voice`, wyłączone z kopii zapasowej, usuwane razem z profilem dziecka. Nie ma synchronizacji: imię dziecka głosem rodzica to dane osobowe, a bez wysyłki nie ma ich w etykietach prywatności. Brak nagrania = głos Kiddo.
- **D21. Sesje prowadzone (W drogę, Dobranoc).** Lista kroków (`ItemStep` z katalogu, `LineStep` Kiddo z pauzą, `ParentStep` z zastępczym głosem Kiddo) grana przez `SessionController`, a dźwięk przez odtwarzacz aplikacji (ekran blokady, słuchawki). W podróży bez zabaw interaktywnych: nikt nie sięga po telefon w czasie jazdy.
- **D22. Widżet bez danych aplikacji.** iOS WidgetKit (`ios/AudioKiddoWidget`, linia czasu na godziny 5/11/15/19) i Android `AppWidgetProvider` (`DayPartWidget.kt`, niedokładny alarm o zmianie pory). Pokazują tylko tekst według pory dnia i otwierają `audiokiddo://open/{,podroz,dobranoc}`. Bez App Group i bez wspólnych danych; postęp dziecka w widżecie to osobna decyzja.
- **D23. Skróty i asystenci.** iOS: szybkie akcje na ikonie (Dobranoc, W drogę) i App Shortcuts (Spotlight, aplikacja Skróty, przycisk czynności; Siri nie mówi po polsku, więc głosowo tylko frazy angielskie). Po zimnym starcie trasa czeka w `AppRoutes.pending` i Dart odbiera ją kanałem `pl.audiokiddo/launch`. Android: statyczne skróty z `shortcuts.xml` i capability `OPEN_APP_FEATURE` dla Asystenta Google (po polsku).
- **D24. Widżet z postępem.** Aplikacja zapisuje dla widżetu tylko gotowy tekst („Zosia · dzień 3 · 2 z 7 nut”) i liczbę nut tygodnia (`home_widget`: iOS App Group `group.pl.audiokiddo.app`, Android SharedPreferences). Imię dziecka zostaje w telefonie.
- **D25. Karta dla dziadków.** Obrazek PNG rysowany w telefonie i przekazywany do systemowego udostępniania; nic nie przechodzi przez nasz serwer.
- **D26. Android Auto.** Katalog w samochodzie (Na drogę, Pobrane, Piosenki, Na dobranoc): tylko słuchanie, bez zabaw interaktywnych, tylko to, co rodzina może odtworzyć. CarPlay wymaga osobnej zgody Apple (entitlement dla aplikacji audio) i konta dewelopera.
- **D27. Weryfikacja zakupów bez klucza Apple.** iOS wysyła podpisaną transakcję StoreKit 2; serwer sprawdza łańcuch certyfikatów do przypiętego Apple Root CA G3, OID-y App Store, bundle id i podpis. Stan subskrypcji aktualizują powiadomienia V2. Google: konto usługi i Play Developer API; RTDN przez Pub/Sub push z tokenem OIDC. Zakup trzyma użytkownik anonimowy (D4); po zalogowaniu aplikacja przywraca zakupy i serwer przepina je na konto rodzica.
- **D28. Start odpowiada na „co teraz?”.** Karta dnia, cztery tryby (Mam chwilę, W drogę, Dobranoc, Tryb dziecka; kolejność według pory dnia), pierwsze kroki (same się odhaczają, znikają po wykonaniu), pytanie do rozmowy, nowość. Przeglądanie (pakiety, filtry) jest w Bibliotece; wiek, pakiet i sytuacja siedzą pod jednym przyciskiem „Filtry”. „Mam chwilę” dobiera zabawę ze znanych danych (miejsce, czas, nastrój, wiek, dostęp, co było dziś), bez serwera. Czas bez ekranu liczymy z własnych wyników rodziny (ostatnie 7 dni).
- **D29. Lord Von Ekran.** Maskotka: golden retriever narysowany w kodzie, w dwóch wcieleniach. Dla dziecka ciepły (głos, stroje według pory dnia), dla rodzica „funkcjonariusz Biura Spraw Domowych” (prochowiec, monokl, tekst maszynopisem bez wykrzykników). Rodzic dostaje dopiski tylko na ekranie, nigdy głosem, najwyżej co 30 s; pule kwestii w `lord_lines.dart`, testowane pod kątem zasad ze strategii komunikacji. Widżet pokazuje Lorda i codzienny żart przekazywany z aplikacji.

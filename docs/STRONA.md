# Nowa strona audiokiddo.pl (wtyczka „AudioKiddo – strona”)

Stan: 6 października 2026 (wersja 2: slajdy i Szop’en). Wtyczka rysuje trzy widoki we własnym stylu: stronę główną, blog i każdy wpis. Koszyk, zamówienie i strony produktów zostają w WooCommerce i obecnym motywie, więc płatności działają tak jak dziś.

## Co jest na stronie

- **Start, podzielony na slajdy** (każdy na pełny ekran). Treści i zdjęcia ze starej strony, po nowemu:
  - hero „Nie wiesz, jak zająć dziecko… w samochodzie? / bez ekranów? / …” (słowa same się piszą), Max i Mila;
  - „Poznaj interaktywne audiozabawy”: zdanie zapala się słowo po słowie przy przewijaniu, cztery kółka (słucha, odpowiada, rozwiązuje, zdobywa wiedzę);
  - „Posłuchaj fragmentu”: nasze trzy próbki MP3 z biblioteki mediów;
  - „Audiozabawy w akcji”: trzy filmy z dziećmi, włączają się z dźwiękiem po kliknięciu;
  - „Poznaj nasze produkty” (ciemny slajd): pakiety według wieku (od 4 lat, od 7 lat), lista zabaw, zestawy z wyliczoną oszczędnością;
  - „Dlaczego rodzice wybierają AudioKiddo” (sześć ikon);
  - specjalistki: Julia Kasielska i Maria Lewandowska-Nawrocka;
  - opinie rodziców (Laura, Agata, Ewelina, Agata, Pam) do przesuwania;
  - darmowy pakiet 3 zabaw za zapis (formularz MailerLite XQ2HmS);
  - aplikacja z abonamentem: pokaże się sama, gdy w ustawieniach będzie link do App Store albo Google Play;
  - Kim jesteśmy (Nela i Dawid, Dawid = głos Profesora Fantazjusza);
  - 14 pytań i odpowiedzi, „AudioKiddo w sześciu zdaniach”, blog, nocne pożegnanie.
- **Szop’en oprowadza:** przy przewijaniu w rogu ekranu Szop’en zmienia pozę, z przymrużeniem oka mówi, co jest na slajdzie, i podświetla po kolei najważniejsze rzeczy (resztę strony lekko przyciemnia). „Dalej” przechodzi do następnej rzeczy albo slajdu, „Ucisz mnie” chowa dymek (strona to zapamiętuje), kliknięcie w Szop’ena opowiada slajd od nowa. Z boku kropki slajdów. Kwestie Szop’ena: `ak_tour()` w `inc/data.php`. Wyłączenie: Ustawienia → AudioKiddo strona → „Szop’en oprowadza”.
- **Animacje:** wejścia przy przewijaniu, żółty marker pod słowem w nagłówkach, przesuwający się pasek „w samochodzie • przed snem • …”, uniesienia kart po najechaniu, okładki pochylające się za myszką, korektor dźwięku przy odtwarzaniu, nagłówek chowający się przy czytaniu w dół, pasek postępu. Kto ma w systemie „ogranicz ruch”, dostaje stronę bez animacji.
- **Sklep na żywo:** ceny, promocje i dostępność pobierane z WooCommerce. Przycisk „Do koszyka” dodaje bez przeładowania, licznik koszyka w nagłówku odświeża się sam, także przy włączonym cache.
- **Blog:**
  - wyszukiwarka;
  - tematy (kategorie);
  - wyróżniony najnowszy wpis;
  - karty z rysunkiem Szop’ena, gdy wpis nie ma zdjęcia;
  - zapis na darmowy pakiet w środku listy.
- **Wpis:**
  - ramka „Najważniejsze w skrócie”;
  - spis treści, który podświetla czytany rozdział;
  - karta aplikacji przed trzecim rozdziałem;
  - pytania jako rozwijane odpowiedzi;
  - autor (Nela, Dawid albo oboje);
  - „Czytaj dalej”.
- **SEO:**
  - tytuły, opisy, canonical, karty dla Facebooka;
  - dane strukturalne: organizacja z założycielami, aplikacja, pakiety z ceną z WooCommerce, artykuł z autorem, okruszki i FAQ.

  Na tych stronach Yoast albo Rank Math milkną, żeby nic się nie dublowało.
- **GEO (asystenci AI):**
  - adres `audiokiddo.pl/llms.txt` ze streszczeniem firmy, cenami, pytaniami i listą artykułów;
  - na stronie zdania-fakty, które ChatGPT, Perplexity i Gemini mogą zacytować wprost.
- **Fabryka:** artykuł zatwierdzony w Studio → Fabryka trafia na blog z FAQ i autorem. Wtyczka czyta je z wpisu.

## Krok 1. Wgranie wtyczki (5 min)

1. Plik: `strona/audiokiddo-strona.zip`. Po zmianach odśwież go poleceniem:

   ```bash
   tool/strona_zip.sh
   ```

2. WordPress → **Wtyczki → Dodaj nową → Wyślij wtyczkę na serwer** → wybierz zip → **Zainstaluj** → **Włącz**.
3. Przy kolejnej wersji WordPress zapyta, czy zastąpić obecną. Wybierz **Zastąp**.

## Krok 2. Ustawienia (10 min)

WordPress → **Ustawienia → AudioKiddo strona**:

| Pole | Co wpisać |
|---|---|
| Link do App Store / Google Play | Po publikacji aplikacji. Wtedy na stronie pojawi się slajd aplikacji z abonamentem. |
| Numery produktów | Domyślnie: 372 Wyobraźnia, 373 Słowa i Wiedza, 7339 Detektyw, 371 zestaw 2, 6235 zestaw 3. Sprawdź w Produkty (najedź na produkt, pokaże się „ID”). |
| Kod formularza MailerLite | Domyślnie formularz ze starej strony (`XQ2HmS`, darmowy pakiet). Skrypt MailerLite ładuje się z tagów strony (GTM); jeśli formularz się nie pokaże, po 7 s pojawia się przycisk „Poproś o pakiet mailem”. |
| Adres opinii | Zostaw puste. Wypełnimy, gdy ruszą opinie z aplikacji (punkt 12). |
| Zdjęcia Neli i Dawida | Puste: zdjęcia ze starej strony (już we wtyczce). |
| Strona kontaktu, polityka, regulamin | Domyślnie `/kontakt/`, `/polityka-prywatnosci/`, `/regulamin-sklepu/`. |
| Instagram, Facebook… | Profile marki (trafiają też do danych dla Google). |

## Krok 3. Strona główna i blog (5 min)

1. **Strony → Dodaj nową**:
   - tytuł „Start”, treść pusta;
   - po prawej Szablon: **AudioKiddo: Start**;
   - Opublikuj.
2. Druga strona „Blog”, bez szablonu (pusta).
3. **Ustawienia → Czytanie**:
   - „Strona główna wyświetla: Statyczną stronę”;
   - Strona główna: **Start**;
   - Strona z wpisami: **Blog**.

   Zapisz.
4. Ustawienia → Bezpośrednie odnośniki: wpisy jako **Nazwa wpisu** (adres `audiokiddo.pl/zabawy-w-aucie/`). Jeśli dziś jest inaczej i wpisy już są w Google, nie zmieniaj.

Starej strony głównej nie usuwaj od razu. Zostaw ją jako szkic na tydzień, gdyby trzeba było wrócić.

## Krok 4. Hasło aplikacji dla Fabryki (5 min)

Fabryka publikuje artykuły przez REST WordPressa. Potrzebuje osobnego hasła aplikacji (nie Twojego hasła do logowania).

1. Użytkownicy → Twój profil → na dole **Hasła aplikacji** → nazwa „Fabryka AudioKiddo” → **Dodaj**.
2. WordPress pokaże hasło raz. Nie wklejaj go do rozmowy ani do pliku. Od razu przejdź do Supabase → Edge Functions → **Secrets** i dodaj:
   - `WP_URL` = `https://audiokiddo.pl`
   - `WP_USER` = Twoja nazwa użytkownika w WordPressie
   - `WP_APP_PASSWORD` = skopiowane hasło (ze spacjami, tak jak pokazał WordPress)
3. Hasło możesz w każdej chwili unieważnić w profilu („Unieważnij”). Fabryka straci wtedy dostęp.

Jeśli wtyczka bezpieczeństwa (np. Wordfence) blokuje REST albo hasła aplikacji, w jej ustawieniach zezwól na „Application Passwords”.

## Krok 5. Sprawdzenie (15 min)

- [ ] Strona główna:
  - ceny pakietów zgadzają się z WooCommerce;
  - „Do koszyka” dodaje produkt, pojawia się dymek „Dodano…”, licznik w nagłówku rośnie.
- [ ] Koszyk → zamówienie testowe przelewem → przychodzi mail. W Studio → Zamówienia widać zamówienie (webhook).
- [ ] Odsłuch: przycisk przy pakiecie gra próbkę, drugi klik zatrzymuje. Filmy z dziećmi grają po kliknięciu.
- [ ] Szop’en: przewiń stronę, przy każdym slajdzie mówi i podświetla. „Ucisz mnie” działa, klik w Szop’ena wraca.
- [ ] Formularz darmowego pakietu się pokazuje i zapis przychodzi w MailerLite.
- [ ] Telefon:
  - menu otwiera się z ikonki;
  - nic nie wystaje w bok;
  - przyciski łatwo trafić palcem.
- [ ] Blog i wpis:
  - jest ramka „Najważniejsze w skrócie”;
  - spis treści;
  - pytania rozwijają się.
- [ ] Wejdź na `audiokiddo.pl/llms.txt`: widać tekst z cenami.
- [ ] Google **Rich Results Test** (search.google.com/test/rich-results) dla strony głównej i jednego wpisu: FAQ, Product i Article bez błędów.
- [ ] Jeśli działa LiteSpeed Cache albo inny cache: po zmianie cen kliknij „Wyczyść cache”. Licznik koszyka i tak jest aktualny.
- [ ] Google Search Console:
  - Mapy witryn → dodaj `wp-sitemap.xml` (albo mapę z Yoast / Rank Math);
  - Sprawdzenie adresu URL → strona główna → „Poproś o zindeksowanie”.

## Podgląd bez WordPressa (dla nas)

```bash
php tool/strona_render.php
```

Powstają `strona/podglad/start.html`, `blog.html`, `wpis.html` i `llms.txt`, na przykładowych cenach i wpisach. Skrypt sprawdza też poprawność danych strukturalnych. Podgląd w przeglądarce: serwer „strona-podglad” (port 8765), adres `/podglad/start.html`.

## Co zmieniać w treściach

Teksty pakietów, opinie, specjaliści, kwestie Szop’ena, cennik abonamentu, pytania i „fakty” są w jednym pliku: `strona/audiokiddo-strona/inc/data.php`. Po zmianie cen w App Store i Google Play popraw też `ak_plans()`.

Nowe okładki aplikacji i Szop’en: `python3 tool/site_assets.py`. Zdjęcia ze starej strony (`strona/stare-zasoby`, nasze zdjęcia, specjalistki, okładki, ikony, kadry filmów, awatary z opinii): `python3 tool/site_old_assets.py`. Potem `tool/strona_zip.sh`.

Wiek pakietów jest w `ak_packs()` (`age_from`), jak na stronach produktów: Wyobraźnia i Słowa i Wiedza od 4 lat, Detektyw od 7. Stara strona główna miała 3+ i 6+.

## Czego wtyczka nie robi (świadomie)

- Nie zmienia wyglądu koszyka, zamówienia i stron produktów. To motyw i WooCommerce. Jeśli zechcecie je w tym samym stylu, to osobny krok.
- Nie ładuje niczego z Google Fonts ani zewnętrznych skryptów (RODO). Poppins jest we wtyczce.
- Nie dodaje gwiazdek z opinii do danych dla Google: Google nie pokazuje gwiazdek opinii o własnej firmie, a za próby grozi kara.

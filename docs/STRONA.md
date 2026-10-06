# Nowa strona audiokiddo.pl (wtyczka „AudioKiddo – strona”)

Stan: 6 października 2026. Wtyczka rysuje trzy widoki we własnym stylu: stronę główną, blog i każdy wpis. Koszyk, zamówienie i strony produktów zostają w WooCommerce i obecnym motywie, więc płatności działają tak jak dziś.

## Co jest na stronie

- **Start:**
  - hero „telefon leży ekranem w dół”;
  - „Jeden dzień z AudioKiddo”;
  - jak to działa;
  - trzy pakiety jako „tył płyty” z listą zabaw i odsłuchem próbki;
  - zestawy;
  - cennik abonamentu (miesięcznie / rocznie);
  - przewodnik PDF;
  - O nas (Nela i Dawid);
  - opinie rodziców;
  - wpisy z bloga;
  - pytania rodziców;
  - „AudioKiddo w sześciu zdaniach”.
- **Sklep na żywo:** ceny, promocje i dostępność pobierane z WooCommerce. Przycisk „Do koszyka” dodaje bez przeładowania, licznik koszyka w nagłówku odświeża się sam, także przy włączonym cache.
- **Blog:**
  - wyszukiwarka;
  - tematy (kategorie);
  - wyróżniony najnowszy wpis;
  - karty z rysunkiem Szop’ena, gdy wpis nie ma zdjęcia;
  - zapis na przewodnik w środku listy.
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
| Link do App Store / Google Play | Po publikacji aplikacji. Do tego czasu przyciski „Wkrótce w…” prowadzą do zapisu na przewodnik. |
| Numery produktów | Domyślnie: 372 Wyobraźnia, 373 Słowa i Wiedza, 7339 Detektyw, 371 zestaw 2, 6235 zestaw 3. Sprawdź w Produkty (najedź na produkt, pokaże się „ID”). |
| Kod formularza MailerLite | Z `docs/marketing/NEWSLETTER.md`, krok 3. |
| Adres opinii | Zostaw puste. Wypełnimy, gdy ruszą opinie z aplikacji (punkt 12). |
| Zdjęcia Neli i Dawida | Media → Dodaj → skopiuj adres. Kwadrat 600×600. Bez zdjęć są duże inicjały. |
| Polityka prywatności, regulamin | Adresy istniejących stron. |
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
- [ ] Odsłuch: przycisk na okładce gra próbkę, drugi klik zatrzymuje.
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

Teksty pakietów, cennik abonamentu, pytania i „fakty” są w jednym pliku: `strona/audiokiddo-strona/inc/data.php`. Po zmianie cen w App Store i Google Play popraw też `ak_plans()`.

Nowe okładki: `python3 tool/site_assets.py`, potem `tool/strona_zip.sh`.

## Czego wtyczka nie robi (świadomie)

- Nie zmienia wyglądu koszyka, zamówienia i stron produktów. To motyw i WooCommerce. Jeśli zechcecie je w tym samym stylu, to osobny krok.
- Nie ładuje niczego z Google Fonts ani zewnętrznych skryptów (RODO). Poppins jest we wtyczce.
- Nie dodaje gwiazdek z opinii do danych dla Google: Google nie pokazuje gwiazdek opinii o własnej firmie, a za próby grozi kara.

# Prezent na Mikołajki i Święta: jak uruchomić

Stan: 7 października 2026. Kupujący (np. babcia) płaci na audiokiddo.pl, a sklep od razu wysyła mu mailem **kod prezentowy**. Rodzice dziecka wpisują kod w aplikacji (Sklep › „Masz już dostęp z audiokiddo.pl?” › „Mam kod”). Kod działa na jednym koncie. Zwrot zamówienia wyłącza kod i dostęp.

| Plik | Co to jest |
|---|---|
| `docs/marketing/strona/prezent.html` | Strona „Prezent” do wklejenia w WordPress (blok „Własny HTML”) |
| `docs/marketing/prezent/kartka-prezentowa.pdf` | Pusta kartka do wydruku (kod i imię wpisuje się ręcznie) |
| `tool/gift_card.py` | Kartka od razu z kodem i imieniem: `python3 tool/gift_card.py --code AK-XXXX-XXXX --to "Zosi" --from "Babci i Dziadka" -o ~/Desktop/kartka.pdf` |
| `supabase/migrations/20261010000001_gift_codes.sql` | Tabele i funkcje prezentów |
| `supabase/functions/woo-webhook` | Po opłaceniu zamówienia z produktem prezentowym tworzy kod i dopisuje go do zamówienia jako notatkę dla klienta (WooCommerce wysyła ją mailem) |

## Uruchomienie (Dawid, raz)

1. **WooCommerce: produkty prezentowe.** Zrób kopię „Zestaw 3 pakietów” i pakietów jako osobne produkty, np. „Prezent: zestaw 3 pakietów”. Ta sama cena. Zanotuj ich ID (widać w adresie edycji produktu: `post=123`).
   - Produkty prezentowe **nie mogą** być w tabeli `store_products`. Inaczej kupujący dostałby dostęp na swoje konto zamiast kodu.
2. **Klucz REST do zapisu:** WooCommerce › Ustawienia › Zaawansowane › REST API › Dodaj klucz, uprawnienia „Odczyt/Zapis”, opis „AudioKiddo prezenty”.
3. **Sekrety w Supabase** (wpisujesz sam w Terminalu, nie wklejaj ich do rozmowy):
   ```bash
   supabase secrets set WOO_WRITE_KEY=ck_... WOO_WRITE_SECRET=cs_...
   supabase secrets set GIFT_CODE_SECRET="$(openssl rand -hex 32)"
   ```
   `GIFT_CODE_SECRET` ustaw raz i nie zmieniaj (z niego powstają kody).
4. **Wdrożenie:**
   ```bash
   supabase db push
   supabase functions deploy woo-webhook
   ```
5. **Które produkty są prezentami.** Supabase › SQL Editor, wpisz swoje ID produktów:
   ```sql
   insert into public.gift_products (product_ref, scopes, label) values
     ('woo:ID_ZESTAWU', '{pack:detektyw,pack:slowa-i-wiedza,pack:wyobraznia}', 'Zestaw 3 pakietów'),
     ('woo:ID_DETEKTYW', '{pack:detektyw}', 'Pakiet Detektyw'),
     ('woo:ID_SLOWA', '{pack:slowa-i-wiedza}', 'Pakiet Słowa i Wiedza'),
     ('woo:ID_WYOBRAZNIA', '{pack:wyobraznia}', 'Pakiet Wyobraźnia');
   ```
6. **Strona:** nowa strona `audiokiddo.pl/prezent`, blok „Własny HTML”, wklej `prezent.html`. Podmień linki `#prezent-zestaw`, `#prezent-pakiet`, `#probka`, `#kartka` (wgraj PDF kartki do Mediów).
7. **Test:** kup prezent sam (np. kuponem 100%). W ciągu minuty powinien przyjść mail z notatką „Kod prezentowy: AK-…”. Wpisz kod w aplikacji na drugim koncie. Potem zwróć zamówienie: kod przestaje działać.

Gdy notatka nie przyjdzie: WooCommerce › Ustawienia › Zaawansowane › Webhooki › dziennik dostaw (błąd 500 = sklep ponawia sam). Logi: Supabase › Edge Functions › woo-webhook.

## Kiedy promować

- Od 10 listopada strona „Prezent” w menu i na stronie głównej, rolki „prezent bez ekranu”.
- 1–6 grudnia: Mikołajki. 7–23 grudnia: Święta, w ostatnich dniach komunikat „kod przychodzi mailem w kilka minut”.
- Grupa reklamowa: dorośli 45–70 lat (dziadkowie) oraz rodzice 28–42 lat. Osobne kreacje dla obu grup.

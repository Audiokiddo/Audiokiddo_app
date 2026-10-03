# Dostęp do pakietów kupionych w sklepie audiokiddo.pl, prezenty i kody

Stan: 3 października 2026. Kod: `app/lib/features/account/access_screen.dart` (ekran „Dostęp do pakietów”, trasa `/dostep`), funkcje `supabase/functions/{sync-web-purchases,claim-order,redeem-code}`, baza `supabase/migrations/20261003000002_access_codes.sql`, narzędzie `tool/make_codes.py`.

## Trzy drogi do tego samego celu

| Droga | Dla kogo | Jak działa |
|---|---|---|
| **1. E-mail** (od początku) | Klient kupił w sklepie i loguje się w aplikacji tym samym adresem | Logowanie kodem z maila. Aplikacja sama pobiera zamówienia z tego adresu (`sync-web-purchases`). Dodatkowo każde nowe zamówienie trafia do aplikacji od razu (webhook sklepu). Nic nie trzeba wpisywać. |
| **2. Numer zamówienia + e-mail z zamówienia** (nowe) | Klient podał w sklepie inny adres, kupował bez konta albo nie pamięta, jakiego adresu użył | Aplikacja → Sklep → „Masz już dostęp z audiokiddo.pl?” → numer zamówienia i adres z zamówienia. Serwer sprawdza parę w sklepie (klucz tylko do odczytu) i dodaje pakiety do konta. Zła para zawsze daje tę samą odpowiedź „nie znaleźliśmy”, więc nikt nie sprawdzi cudzych zamówień. |
| **3. Kod dostępu** (nowe) | Prezenty (np. dla babci), testerzy, recenzenci, promocje, konkursy | Kod w formacie `AK-7K3M-9QXD` (bez 0, O, 1, I, żeby się nie myliły). Aplikacja → ten sam ekran → „Mam kod”. Kod generujesz sam (poniżej). |

Wszystko działa też bez konta: aplikacja tworzy wtedy konto gościa (bez danych osobowych) i podpowiada, żeby zalogować się e-mailem, bo inaczej dostęp zginie przy zmianie telefonu.

### Zasady bezpieczeństwa
- **Zamówienie ma jednego właściciela.** Jeśli konto A ma już pakiety z zamówienia, konto B nie przejmie go numerem i adresem. Odpowiedź: „przypisane do innego konta”. (Właściciel adresu z zamówienia zawsze ma pierwszeństwo przy logowaniu e-mailem.)
- **Zgadywanie jest ograniczone:** 10 błędnych prób na godzinę na konto, potem „za dużo prób”.
- **Kody w bazie są zaszyfrowane jak hasła** (tylko SHA-256). Z bazy nie da się ich odczytać, tylko sprawdzić. Dlatego plik z kodami z `AudioKiddo-kody/` jest jedynym miejscem, gdzie je widać. Traktuj go jak karty podarunkowe.
- **Jedno użycie na konto.** Kod na 5 użyć dostanie 5 różnych kont, a to samo konto drugi raz usłyszy „masz już ten dostęp”.
- Zwrócone lub anulowane zamówienie nie da dostępu.

## Kody: jak je robić
Terminal (kody trafiają do bazy dopiero z `--apply`, bez niego tylko je zobaczysz):

```bash
cd ~/Desktop/"claude folder"/audiokiddo-app
python3 tool/make_codes.py detektyw -n 5 --note "Recenzenci" --apply          # 5 kodów, każdy dla 1 konta, na stałe
python3 tool/make_codes.py wszystko --uses 10 --days 90 --expires 2026-12-31 --note "Testerzy Google Play" --apply
python3 tool/make_codes.py wyobraznia slowa-i-wiedza -n 1 --note "Prezent dla babci Zosi" --apply   # jeden kod, dwa pakiety
python3 tool/make_codes.py --list                       # co jest w bazie i ile użyto
python3 tool/make_codes.py --revoke "Recenzenci"        # kończy kody z tą notatką i odbiera przyznany dostęp
```

- Pakiety: `detektyw`, `wyobraznia`, `slowa-i-wiedza`, `wszystko`, albo pojedyncza zabawa `item:mikstura`.
- `--uses` ile kont może użyć jednego kodu, `--days` na ile dni dostęp po wpisaniu (domyślnie na stałe), `--expires` do kiedy kod jest ważny.
- Kody lądują w `Desktop/claude folder/AudioKiddo-kody/` (plik CSV do wysłania komuś i plik SQL).

### Typowe zastosowania
- **Google Play:** testerzy zamkniętego testu dostają kod na wszystko na 90 dni.
- **Recenzenci i influencerzy:** kod na jeden pakiet, notatka z nazwą.
- **Prezent ze sklepu:** po zakupie prezentu wystawiasz kod na ten pakiet i wysyłasz mailem.
- **Konkurs:** jeden kod na 1 użycie na zwycięzcę.

## Co zrobić po stronie sklepu (WordPress)
1. **Strona „Dziękujemy za zamówienie” i mail z potwierdzeniem** (WooCommerce → Ustawienia → E-maile → Zamówienie zrealizowane, pole „Dodatkowa treść”):

   > Pakiet jest od razu dostępny także w aplikacji AudioKiddo. Zaloguj się w niej tym samym adresem e-mail, którego użyłeś w sklepie. Jeśli podałeś inny adres, w aplikacji wejdź w Sklep → „Masz już dostęp z audiokiddo.pl?” i wpisz numer tego zamówienia: **{order_number}**.

   (`{order_number}` WooCommerce podstawia samo w tym polu.)
2. **Zamówienia gości** (bez konta w sklepie) działają tak samo: wystarczy e-mail z zamówienia.

## Zasady sklepów (ważne przy zgłoszeniu do App Store)
- **E-mail i numer zamówienia** to dostęp do treści kupionych gdzie indziej przez konto użytkownika. Apple pozwala na to w aplikacjach działających na wielu platformach (3.1.3(b)), pod warunkiem że te same pakiety są też do kupienia w aplikacji (są). W aplikacji nie wolno linkować ani zachęcać do zakupu na stronie, i tego nie robimy (ekran mówi o dostępie, który ktoś już ma).
- **Kody** mogą budzić zastrzeżenia recenzenta Apple (3.1.1: własne mechanizmy odblokowywania, np. klucze licencyjne). Dlatego pole kodu ma wyłącznik: wersję do App Store można zbudować z `--dart-define=REDEEM_CODES=false`, a kody zostają na Androidzie (Google nie ma takiej zasady) i w wersjach testowych. Do rozstrzygnięcia przed zgłoszeniem iOS. Dwie pozostałe drogi działają zawsze.

## Wdrożenie (robi Dawid, bo automat blokuje mi bazę produkcyjną)
```bash
cd ~/Desktop/"claude folder"/audiokiddo-app
supabase db push
supabase functions deploy redeem-code claim-order sync-web-purchases
```
Sekrety sklepu (`WOO_URL`, klucze tylko do odczytu) już są w Supabase.

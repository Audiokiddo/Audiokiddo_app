# Polecenia: 30 zł dla polecającego i dla znajomego

Stan: 12 października 2026. Zastępuje zasadę z 5 października („znajomy 14 dni, polecający miesiąc po zakupie znajomego”).

## Jak to działa

1. Rodzic otwiera w aplikacji „Poleć znajomym” (Start albo Więcej). Widzi swój kod, na przykład `POLEC-7K3M9Q`, i wysyła go przez „Wyślij znajomym” albo kopiuje.
2. Znajomy pobiera aplikację, **zakłada konto** i wpisuje kod: Sklep → „Masz zakup z audiokiddo.pl albo kod?” → „Mam kod”.
3. Od razu **oboje dostają po 30 zł** do wykorzystania w aplikacji: znajomy i rodzic, który polecił.
4. Jeden kod nagradza **najwyżej 3 znajomych w roku kalendarzowym** (czas polski). Czwarty znajomy w tym samym roku usłyszy, że kod w tym roku już się wyczerpał. Od stycznia kod znów działa.
5. Środki wydaje się w „Poleć znajomym” → „Twoje środki” (z bramką rodzica i potwierdzeniem):
   - miesiąc całej biblioteki: 29,99 zł (kolejne miesiące dodają się na koniec trwającego),
   - pakiet Wyobraźnia albo Słowa i wiedza: 49,99 zł, pakiet Detektyw: 69,99 zł,
   - pojedyncza zabawa: 9,99 zł.

   Cennik jest w tabeli `credit_prices`. Zmiana ceny to zmiana wiersza, bez nowej wersji aplikacji.

Ochrona przed nadużyciami:
- Własnego kodu nie da się wpisać.
- Kod działa tylko na założonym koncie. Konto gościa dostaje „Załóż konto, a potem wpisz kod jeszcze raz”.
- Jedno konto może użyć tylko jednego kodu polecającego.
- Limit 3 nagród w roku jest pilnowany w bazie, także gdy dwie osoby wpisują kod jednocześnie.
- Środków nie da się kupić ani wypłacić. Służą tylko do odblokowania treści w aplikacji.
- Obowiązuje ten sam limit błędnych prób co przy kodach prezentowych.

## Co jest w kodzie

- Baza:
  - `supabase/migrations/20261005000001_referrals.sql`: kody i polecenia.
  - `supabase/migrations/20261021000001_referral_credit.sql`: tabele `credit_ledger` (każda zmiana salda, raz na powód) i `credit_prices`, funkcje `redeem_referral` (nowa zasada), `referral_code_for` (z `left_this_year` i `balance`), `credit_offers` i `spend_credit`. Usuwa wyzwalacz `reward_referrer`.
- Funkcje Edge:
  - `referral-code`: kod rodzica, liczniki, saldo.
  - `redeem-code`: kody `POLEC-…` dają środki (odpowiedź z `referral: true`).
  - nowa `credit`: `{action: "offers"}` i `{action: "spend", scope}`.
- Aplikacja: `app/lib/features/referral/referral_screen.dart` (trasa `/polec`, sekcja „Twoje środki”), komunikaty w `app/lib/features/account/access_screen.dart`.
- Testy: `supabase/tests/schema_test.sql` (`tool/test_db.sh`) i `app/test/referral_credit_test.dart`.

## Wdrożenie (robi Dawid, w Terminalu w folderze `audiokiddo-app`)

```bash
supabase db push
```

```bash
supabase functions deploy referral-code
```

```bash
supabase functions deploy redeem-code
```

```bash
supabase functions deploy credit
```

Kolejność ma znaczenie: najpierw baza, potem funkcje. Do czasu wdrożenia działa stara zasada (14 dni dla znajomego), a sekcja „Twoje środki” się nie pokazuje.

## App Store

Środki są nagrodą za polecenie i nie da się ich kupić, więc nie są walutą sprzedawaną poza App Store. Apple (wytyczna 3.1.1) pozwala na takie nagrody, ale recenzent może o nie zapytać. W notatce do recenzji warto napisać jednym zdaniem: „Referral credit is a free reward (30 PLN for both sides, max 3 per year), cannot be purchased or withdrawn, and only unlocks content inside the app.”

# Polecenia: znajomy 14 dni za darmo, polecający miesiąc gratis

Stan: 5 października 2026.

## Jak to działa

1. Rodzic otwiera w aplikacji „Poleć znajomym” (Start albo Więcej). Widzi swój kod, na przykład `POLEC-7K3M9Q`, i wysyła go przez „Wyślij znajomym” albo kopiuje.
2. Znajomy wpisuje kod w aplikacji: Sklep → „Masz zakup z audiokiddo.pl albo kod?” → „Mam kod”. Dostaje **14 dni całej biblioteki**.
3. Gdy znajomy **kupi cokolwiek** (abonament lub pakiet w App Store, Google Play albo na audiokiddo.pl), polecający dostaje **30 dni całej biblioteki**. Kolejne nagrody dodają się na koniec trwającej. Najwięcej 12 nagród na rodzica.

Ochrona przed nadużyciami:
- Własnego kodu nie da się wpisać.
- Jedno konto może użyć tylko jednego kodu polecającego.
- Nagroda przychodzi dopiero po prawdziwym zakupie, nie po samym wpisaniu kodu.
- Obowiązuje ten sam limit błędnych prób co przy kodach prezentowych.

## Co jest w kodzie

- Baza: `supabase/migrations/20261005000001_referrals.sql`. Tabele `referral_codes` i `referral_redemptions`, funkcje `referral_code_for` i `redeem_referral`, wyzwalacz `reward_referrer` na `entitlements`.
- Funkcje Edge:
  - nowa `referral-code`: kod rodzica i liczniki;
  - `redeem-code` rozpoznaje teraz kody `POLEC-…`.
- Aplikacja: `app/lib/features/referral/referral_screen.dart` (trasa `/polec`) oraz karta na Starcie.
- Testy: `supabase/tests/schema_test.sql` (`tool/test_db.sh`) i `supabase/functions/_shared/codes_test.ts`.

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

Do czasu wdrożenia ekran „Poleć znajomym” pokazuje „Polecenia ruszą lada dzień”, a kody `POLEC-…` nie działają.

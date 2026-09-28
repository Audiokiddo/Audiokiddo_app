# AudioKiddo: serwer (Supabase)

Schemat bazy, zasady dostępu (RLS) i funkcje serwerowe. Architektura: `../ARCHITECTURE.md` §4–§7a.

## Zawartość

| Ścieżka | Co robi | Stan |
|---|---|---|
| `migrations/…_init.sql` | Tabele: konta, uprawnienia, produkty, zdarzenia sklepów, zakupy ze strony, treści Studio, wersje katalogu; RLS; funkcje `upsert_entitlement`, `record_store_event`, `claim_web_purchases` | ✅ przetestowane lokalnie |
| `migrations/…_email_lookup.sql` | Dopasowanie kupującego ze strony tylko do **potwierdzonego** e-maila | ✅ przetestowane lokalnie |
| `functions/woo-webhook` | Webhook WooCommerce: podpis HMAC, idempotencja, zapis zamówienia, przyznanie lub odebranie dostępu | ✅ typy i logika; ⏳ nieuruchomione na Supabase |
| `functions/sync-web-purchases` | Po zalogowaniu e-mailem pobiera zamówienia z audiokiddo.pl i przypisuje pakiety | ✅ typy; ⏳ wymaga kluczy WooCommerce |
| `functions/delete-account` | Usunięcie konta rodzica wraz z uprawnieniami | ✅ typy; ⏳ wymaga projektu |
| `functions/_shared/store_status.ts` | Status subskrypcji z danych Apple i Google | ✅ testy jednostkowe; ⏳ do sprawdzenia na danych z sandboxa |
| `migrations/…_store_products.sql` | Produkty App Store i Google Play (subskrypcje, pakiety, zestawy, 25 zabaw) → zakresy dostępu | ✅ przetestowane lokalnie |
| `functions/verify-purchase` | Aplikacja przysyła zakup (iOS: podpisana transakcja JWS, Android: token); serwer sprawdza go u sklepu i zapisuje dostęp. Zakup z innego konta przechodzi na bieżące („Przywróć zakupy”) | ✅ testy logiki i podpisów; ⏳ wdrożenie po `set_store_secrets.sh` |
| `functions/store-notifications` | `/apple`: App Store Server Notifications V2 (podpis i łańcuch do Apple Root CA G3). `/google`: RTDN przez Pub/Sub push (token OIDC). Odnowienia, okres łaski, zwroty, zmiana planu, idempotencja | ✅ testy; ⏳ adresy do wpisania w sklepach (krok 7) |
| `functions/_shared/apple_jws.ts`, `google_play.ts`, `purchases.ts` | Weryfikacja JWS Apple z przypiętym certyfikatem głównym, klient Google Play (konto usługi), reguły zakupów | ✅ 23 testy Deno |
| `download-url`, `publish-catalog` | Podpisane adresy plików (LH.pl), publikacja katalogu ze Studia | ⏳ czeka na decyzję o hostingu plików |

## Testy lokalne (bez konta Supabase)

```bash
tool/test_db.sh
```

```bash
cd supabase/functions && deno test _shared/ && deno check */index.ts
```

`tool/test_db.sh` uruchamia jednorazowy PostgreSQL 17 z imitacją modułu `auth` Supabase i sprawdza scenariusze (dostęp tylko do własnych zakupów, brak możliwości dopisania sobie zakupu, idempotencja, zakupy ze strony, usuwanie konta).

## Wdrożenie: kroki dla Dawida

1. Załóż konto na supabase.com (e-mail firmowy) i projekt **w regionie UE (Frankfurt)**. Na czas budowy wystarczy plan darmowy.
2. Zainstaluj CLI (`brew install supabase/tap/supabase`) i zaloguj się **w swoim terminalu**:

```bash
supabase login
```

```bash
supabase link --project-ref TWOJ_PROJECT_REF
```

3. Wgraj schemat i funkcje:

```bash
supabase db push
```

```bash
supabase functions deploy woo-webhook --no-verify-jwt
```

```bash
supabase functions deploy sync-web-purchases
```

```bash
supabase functions deploy delete-account
```

4. **Sekrety wpisuj tylko w swoim terminalu, nigdy w czacie.** Supabase sam ustawia `SUPABASE_URL` i `SUPABASE_SERVICE_ROLE_KEY`:

```bash
supabase secrets set WOO_URL=https://audiokiddo.pl WOO_CONSUMER_KEY=ck_... WOO_CONSUMER_SECRET=cs_... WOO_WEBHOOK_SECRET=...
```

## WooCommerce: klucze i webhook

- **Klucz REST, tylko do odczytu:** WordPress → WooCommerce → Ustawienia → Zaawansowane → REST API → „Dodaj klucz”, uprawnienia **Odczyt**. Skopiuj `ck_…` i `cs_…` prosto do komendy `supabase secrets set`.
- **Webhook:** WooCommerce → Ustawienia → Zaawansowane → Webhooki → „Dodaj webhook”:
  - temat: **Zamówienie zaktualizowane**;
  - adres dostarczenia: `https://TWOJ_PROJECT_REF.functions.supabase.co/woo-webhook`;
  - sekret: długi losowy ciąg, ten sam co w `WOO_WEBHOOK_SECRET`.
- **ID produktów:** potrzebne do tabeli `store_products` (np. `woo:1234` → `{pack:wyobraznia}`, zestaw 3 → trzy pakiety). Wpisz je w Studio albo podaj mi same ID, to przygotuję plik z danymi.

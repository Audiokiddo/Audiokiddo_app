#!/usr/bin/env bash
# Unlocks all content for a test account on the live server (a "manual" entitlement), so
# paid packs can be tried on a phone before the stores exist. Run it yourself:
#   tool/grant_test_access.sh kontakt.biznesowelove@gmail.com        unlock until 2027-06-30
#   tool/grant_test_access.sh kontakt.biznesowelove@gmail.com --off  lock again
# The account must exist: sign in once in the app with the e-mail code first.
set -euo pipefail
cd "$(dirname "$0")/.."

email=${1:-}
[[ $email == *@*.* ]] || { echo "Podaj adres e-mail konta testowego, np. tool/grant_test_access.sh ja@example.com"; exit 1; }
[[ $email =~ ^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+$ ]] || { echo "Nieprawidłowy adres."; exit 1; }
status=active
[[ ${2:-} == --off ]] && status=revoked

sql=$(cat <<SQL
with u as (select id from auth.users where lower(email) = lower('$email'))
insert into public.entitlements (user_id, source, scope, status, valid_until, product_ref, store_original_tx_id)
select id, 'manual', 'all_content', '$status', '2027-06-30', 'test', 'manual:test:' || id from u
on conflict (source, store_original_tx_id, scope)
  do update set status = excluded.status, valid_until = excluded.valid_until, updated_at = now();
select u.email, e.scope, e.status, e.valid_until
from auth.users u left join public.entitlements e on e.user_id = u.id and e.source = 'manual'
where lower(u.email) = lower('$email');
SQL
)
supabase db query --linked "$sql"
echo
echo "Pusta lista = brak takiego konta: zaloguj się najpierw w aplikacji kodem z maila."
echo "W aplikacji: Moje → konto → odśwież (albo wyloguj i zaloguj), żeby pobrała dostęp."

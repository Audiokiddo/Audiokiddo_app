#!/usr/bin/env bash
# Stores the WooCommerce secrets in Supabase. Run it yourself in your own terminal:
#   tool/set_woo_secrets.sh
# The REST key is pasted at hidden prompts; the webhook secret is generated here and
# copied to the clipboard (never printed), ready to paste into the WooCommerce webhook form.
# Running it again creates a NEW webhook secret: update the webhook in WooCommerce too.
set -euo pipefail
cd "$(dirname "$0")/.."

read -rsp "Wklej Consumer key (zaczyna się od ck_) i Enter: " ck; echo
read -rsp "Wklej Consumer secret (zaczyna się od cs_) i Enter: " cs; echo
[[ $ck == ck_* ]] || { echo "To nie wygląda na Consumer key (ck_...). Nic nie zapisano."; exit 1; }
[[ $cs == cs_* ]] || { echo "To nie wygląda na Consumer secret (cs_...). Nic nie zapisano."; exit 1; }
webhook=$(openssl rand -hex 32)

env_file=$(mktemp)
chmod 600 "$env_file"
trap 'rm -f "$env_file"' EXIT
printf 'WOO_URL=https://audiokiddo.pl\nWOO_CONSUMER_KEY=%s\nWOO_CONSUMER_SECRET=%s\nWOO_WEBHOOK_SECRET=%s\n' \
  "$ck" "$cs" "$webhook" > "$env_file"
supabase secrets set --env-file "$env_file"

printf '%s' "$webhook" | pbcopy
echo
echo "Gotowe. Sekret webhooka jest w schowku (nie jest nigdzie wyświetlany)."
echo "1. Wklej go teraz w WooCommerce, w pole „Sekret” nowego webhooka."
echo "2. Zapisz go też w aplikacji Hasła jako „WooCommerce – sekret webhooka”."

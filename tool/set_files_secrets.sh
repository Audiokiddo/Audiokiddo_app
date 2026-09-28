#!/usr/bin/env bash
# Sets up signed download links for recordings on the LH.pl hosting. Run it yourself:
#   tool/set_files_secrets.sh https://pliki.audiokiddo.pl
# A new signing key is generated here and copied to the clipboard (never printed):
# paste it into config.php on the server (tool/lhpl/config.example.php) right after.
# Running it again creates a NEW key: update config.php too, or links stop working.
set -euo pipefail
cd "$(dirname "$0")/.."

base=${1:-}
[[ $base == https://* ]] || { echo "Podaj adres folderu z get.php, np. tool/set_files_secrets.sh https://pliki.audiokiddo.pl"; exit 1; }
key=$(openssl rand -hex 32)

env_file=$(mktemp)
chmod 600 "$env_file"
trap 'rm -f "$env_file"' EXIT
printf 'FILES_BASE_URL=%s\nDOWNLOAD_SIGNING_KEY=%s\n' "${base%/}" "$key" > "$env_file"
supabase secrets set --env-file "$env_file"

printf '%s' "$key" | pbcopy
echo
echo "Gotowe. Klucz podpisu jest w schowku (nie jest nigdzie wyświetlany)."
echo "1. Na serwerze LH.pl skopiuj tool/lhpl/get.php i config.example.php (jako config.php) do $base."
echo "2. Wklej klucz w config.php jako DOWNLOAD_SIGNING_KEY i wpisz FILES_ROOT (folder z nagraniami poza public_html)."
echo "3. Zapisz klucz w aplikacji Hasła jako „AudioKiddo – klucz linków do plików”."

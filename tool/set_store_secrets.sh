#!/usr/bin/env bash
# Stores the App Store / Google Play settings for verify-purchase and store-notifications.
# Run it yourself in your own terminal, after the store accounts exist:
#   tool/set_store_secrets.sh ~/Downloads/klucz-konta-uslugi.json
# The Google service-account key is read from the file you downloaded from Google Cloud
# (it is never printed); delete that file afterwards, the copy lives only in Supabase.
set -euo pipefail
cd "$(dirname "$0")/.."

key_file=${1:-}
[[ -f $key_file ]] || { echo "Podaj ścieżkę do pliku JSON konta usługi Google, np. tool/set_store_secrets.sh ~/Downloads/klucz.json"; exit 1; }
python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); assert d["type"]=="service_account" and d["private_key"] and d["client_email"]' "$key_file" \
  || { echo "To nie jest plik klucza konta usługi Google. Nic nie zapisano."; exit 1; }
ref=$(cat supabase/.temp/project-ref 2>/dev/null || echo ypdxofcwewwdyoelamgy)

read -rp "E-mail konta usługi, którego używa subskrypcja push Pub/Sub (Enter = ten sam co w pliku): " pubsub_email
[[ -n $pubsub_email ]] || pubsub_email=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["client_email"])' "$key_file")

env_file=$(mktemp)
chmod 600 "$env_file"
trap 'rm -f "$env_file"' EXIT
python3 - "$key_file" "$env_file" "$ref" "$pubsub_email" <<'PY'
import json, sys
key, out, ref, email = sys.argv[1:]
compact = json.dumps(json.load(open(key)), separators=(",", ":"))
with open(out, "w") as f:
    f.write("APPLE_BUNDLE_ID=pl.audiokiddo.app\n")
    # App Review and TestFlight buy in Sandbox. Remove ",Sandbox" once the app is live
    # if testers should no longer unlock anything (audit 2026-09-28, P1-2).
    f.write("APPLE_ENVIRONMENTS=Production,Sandbox\n")
    f.write("GOOGLE_PACKAGE_NAME=pl.audiokiddo.app\n")
    f.write(f"GOOGLE_SERVICE_ACCOUNT_JSON='{compact}'\n")
    f.write(f"GOOGLE_PUBSUB_AUDIENCE=https://{ref}.supabase.co/functions/v1/store-notifications/google\n")
    f.write(f"GOOGLE_PUBSUB_EMAIL={email}\n")
PY
supabase secrets set --env-file "$env_file"
echo
echo "Gotowe. Usuń teraz pobrany plik klucza: rm \"$key_file\""
echo "Adresy do wpisania w sklepach:"
echo "  App Store Connect → App Information → App Store Server Notifications (V2, produkcja i sandbox):"
echo "    https://$ref.supabase.co/functions/v1/store-notifications/apple"
echo "  Google Cloud → Pub/Sub → subskrypcja push tematu z Play Console (z uwierzytelnianiem OIDC,"
echo "  odbiorca = adres poniżej, konto usługi = $pubsub_email):"
echo "    https://$ref.supabase.co/functions/v1/store-notifications/google"

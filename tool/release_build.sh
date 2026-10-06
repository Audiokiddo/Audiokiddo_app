#!/usr/bin/env bash
# Builds AudioKiddo for the stores with the right switches, so nothing has to be remembered:
#   tool/release_build.sh ios       → app/build/ios/ipa/*.ipa       (send with Transporter)
#   tool/release_build.sh android   → app/build/app/outputs/bundle/release/app-release.aab
# Public settings (not secrets) come from tool/release.env if it exists, e.g.:
#   GOOGLE_WEB_CLIENT_ID=1234-abc.apps.googleusercontent.com
#   GOOGLE_IOS_CLIENT_ID=1234-def.apps.googleusercontent.com
# iOS (Kids Category, guideline 1.3): the number question also before purchases and links,
# and no access-code field (guideline 3.1.1). Android keeps both as in the app today.
set -euo pipefail
cd "$(dirname "$0")/.."
platform=${1:-}
[[ $platform == ios || $platform == android ]] || { echo "Użycie: tool/release_build.sh ios|android"; exit 1; }

defines=()
if [[ -f tool/release.env ]]; then
  while IFS='=' read -r key value; do
    [[ -z $key || $key == \#* ]] && continue
    defines+=("--dart-define=$key=$value")
  done < tool/release.env
fi

cd app
flutter pub get >/dev/null
if [[ $platform == ios ]]; then
  flutter build ipa --release "${defines[@]}" \
    --dart-define=PARENT_GATE_EVERYWHERE=true --dart-define=REDEEM_CODES=false
  echo
  echo "Gotowe: $(ls build/ios/ipa/*.ipa). Wyślij go aplikacją Transporter."
else
  [[ -f android/key.properties ]] || { echo "Brak app/android/key.properties (klucz przesyłania, docs/PUBLIKACJA.md krok 5.2)."; exit 1; }
  flutter build appbundle --release "${defines[@]}"
  echo
  echo "Gotowe: build/app/outputs/bundle/release/app-release.aab. Wgraj go w Play Console."
fi

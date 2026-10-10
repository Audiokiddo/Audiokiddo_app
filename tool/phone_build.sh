#!/usr/bin/env bash
# Builds AudioKiddo for your own iPhone with a free Apple ID (Xcode "Personal Team") and
# installs it over the cable. Needs: the iPhone connected and trusted, Developer Mode on,
# your Apple ID in Xcode → Settings → Accounts and an "Apple Development" certificate
# (Accounts → Manage Certificates → +). Such builds run for 7 days; run this again after.
#   tool/phone_build.sh
# It uses a test identifier of its own (pl.audiokiddo.test.<team>), so the store identifier
# pl.audiokiddo.app stays free for Nela's developer account.
set -euo pipefail
cd "$(dirname "$0")/../app"

cert=$(security find-certificate -a -c "Apple Development" -p 2>/dev/null | awk '/BEGIN/{c=""} {c=c $0 "\n"} /END/{print c; exit}')
[[ -n $cert ]] || { echo "Brak certyfikatu Apple Development. Xcode → Settings → Accounts → Twoje Apple ID → Manage Certificates → + → Apple Development."; exit 1; }
team=$(printf '%s' "$cert" | openssl x509 -noout -subject -nameopt multiline | awk -F' = ' '/organizationalUnitName/{print $2; exit}')
[[ $team =~ ^[A-Z0-9]{10}$ ]] || { echo "Nie udało się odczytać zespołu z certyfikatu."; exit 1; }

# A phone that is reachable now ("unavailable" also contains "available", hence the exclusion).
device=$(xcrun devicectl list devices 2>/dev/null | awk '/physical/ && !/unavailable/ && (/connected/ || /available/) {for (i=1;i<=NF;i++) if ($i ~ /^[0-9A-F]{8}-[0-9A-F]{16}$/) print $i}' | head -1)
[[ -n $device ]] || { echo "Nie widzę podłączonego iPhone'a. Podłącz go kablem, odblokuj i stuknij Zaufaj."; exit 1; }

app_id="pl.audiokiddo.test.$(printf '%s' "$team" | tr 'A-Z' 'a-z')"
cat > ios/Flutter/Local.xcconfig <<EOF
// Written by tool/phone_build.sh for a personal test build. Not in git.
DEVELOPMENT_TEAM = $team
CODE_SIGN_STYLE = Automatic
AK_APP_ID = $app_id
EOF
echo "Zespół $team, identyfikator testowy $app_id, telefon $device"

cleanup() { rm -f ios/Flutter/Local.xcconfig; }
trap cleanup EXIT
# Flutter writes the release settings, xcodebuild signs for this very iPhone: a free team
# needs the phone registered, which only a build aimed at the connected device does.
flutter build ios --release --config-only --dart-define=AK_APP_GROUP="group.$app_id"
xcodebuild -workspace ios/Runner.xcworkspace -scheme Runner -configuration Release \
  -destination "id=$device" -derivedDataPath build/ios/phone \
  -allowProvisioningUpdates -allowProvisioningDeviceRegistration build -quiet
xcrun devicectl device install app --device "$device" build/ios/phone/Build/Products/Release-iphoneos/Runner.app
echo
echo "Zainstalowane. Przy pierwszym uruchomieniu: Ustawienia → Ogólne → VPN i zarządzanie urządzeniem → Zaufaj."

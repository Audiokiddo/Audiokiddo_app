#!/usr/bin/env bash
# Builds AudioKiddo Studio (content panel and CRM) for https://audiokiddo.pl/studio/.
# Upload the contents of studio/build/web to the server folder public_html/studio.
set -euo pipefail
cd "$(dirname "$0")/../studio"
# Studio starts from the catalog the app ships with.
cp ../app/assets/mock/catalog.json assets/app_catalog.json
flutter build web --release --base-href /studio/
echo
echo "Gotowe: studio/build/web. Wgraj zawartość tego folderu do public_html/studio na serwerze."

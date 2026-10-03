#!/usr/bin/env bash
# Builds a ZIP with only the recordings, covers of the content and previews, for updating the files
# already on the server WITHOUT touching the signing key (set_files_secrets.sh creates a new key
# every time; use this one after new recordings or previews):
#   tool/files_update.sh
# Upload nagrania-aktualizacja.zip with the LH.pl file manager (Serwery → Menedżer plików) into
#   public_html/wp-content/plugins/audiokiddo-pliki/
# and extract it there, overwriting. The catalog in the app and the files must go together:
# build and install a new app version as well (app/assets/mock/catalog.json holds sizes and
# checksums of every recording).
set -euo pipefail
cd "$(dirname "$0")/.."

[[ -d dev_content/audio ]] || { echo "Brak folderu dev_content z nagraniami."; exit 1; }
out="../AudioKiddo-na-serwer"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
mkdir -p "$work/nagrania" "$out"
cp -R dev_content/audio dev_content/games dev_content/pdf "$work/nagrania/"
[[ -d dev_content/previews ]] && cp -R dev_content/previews "$work/nagrania/"
rm -f "$out/nagrania-aktualizacja.zip"
(cd "$work" && zip -qr -X "$(cd "$out" && pwd)/nagrania-aktualizacja.zip" nagrania -x '*.DS_Store')

zip_path="$(cd "$out" && pwd)/nagrania-aktualizacja.zip"
size=$(du -h "$zip_path" | cut -f1)
echo "Gotowe: $zip_path ($size). Klucz bez zmian."
echo "1. LH.pl → Serwery → Menedżer plików → public_html/wp-content/plugins/audiokiddo-pliki/"
echo "2. Wgraj ZIP, rozpakuj z nadpisaniem, usuń ZIP z serwera."
echo "3. Zbuduj i zainstaluj nową wersję aplikacji (katalog z sumami kontrolnymi): tool/phone_build.sh"

#!/usr/bin/env bash
# Builds a ZIP with only recordings, PDFs and previews, for updating the files already on the
# server WITHOUT touching the signing key (set_files_secrets.sh creates a new key every time;
# use this one after new recordings or previews):
#   tool/files_update.sh                 everything in one ZIP (large)
#   tool/files_update.sh detektyw        one pack: audio, PDFs and previews of that pack
#   tool/files_update.sh detektyw wyobraznia slowa-i-wiedza   one ZIP per pack
# Upload each ZIP with the LH.pl file manager (Serwery → Menedżer plików) into
#   public_html/wp-content/plugins/audiokiddo-pliki/
# and extract it there, overwriting. The catalog in the app and the files must go together:
# build and install a new app version as well (app/assets/mock/catalog.json holds sizes and
# checksums of every recording).
set -euo pipefail
cd "$(dirname "$0")/.."

[[ -d dev_content/audio ]] || { echo "Brak folderu dev_content z nagraniami."; exit 1; }
out="$(cd .. && pwd)/AudioKiddo-na-serwer"
mkdir -p "$out"
# The same files unpacked, for FTP (FileZilla): drag the "nagrania" folder into the plugin folder.
ftp="$out/do-wgrania"
rm -rf "$ftp"
mkdir -p "$ftp"

build() { # build <zip name> <pack or "">
  local name=$1 pack=$2 work
  work=$(mktemp -d)
  mkdir -p "$work/nagrania"
  if [[ -z $pack ]]; then
    cp -R dev_content/audio dev_content/games dev_content/pdf "$work/nagrania/"
    [[ -d dev_content/previews ]] && cp -R dev_content/previews "$work/nagrania/"
  else
    for kind in audio pdf previews; do
      [[ -d dev_content/$kind/$pack ]] || continue
      mkdir -p "$work/nagrania/$kind"
      cp -R "dev_content/$kind/$pack" "$work/nagrania/$kind/"
    done
  fi
  find "$work" -name .DS_Store -delete
  cp -R "$work/nagrania" "$ftp/"
  rm -f "$out/$name"
  (cd "$work" && zip -qr -X "$out/$name" nagrania -x '*.DS_Store')
  rm -rf "$work"
  echo "  $name  ($(du -h "$out/$name" | cut -f1))"
}

echo "Gotowe (klucz bez zmian), w folderze $out:"
if [[ $# -eq 0 ]]; then
  build nagrania-aktualizacja.zip ""
else
  for pack in "$@"; do build "nagrania-$pack.zip" "$pack"; done
fi
echo "Rozpakowane do FTP: $ftp/nagrania (przeciągnij do wp-content/plugins/audiokiddo-pliki/ w FileZilli)."
echo "Albo: Menedżer plików LH.pl → wgraj ZIP-y, rozpakuj z nadpisaniem, usuń ZIP-y z serwera."
echo "3. Nową wersję aplikacji (katalog z sumami kontrolnymi) instaluje tool/phone_build.sh."

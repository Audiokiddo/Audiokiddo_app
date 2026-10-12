#!/bin/bash
# Packs the website plugin for WordPress → Wtyczki → Dodaj nową → Wyślij wtyczkę na serwer.
# Output: strona/audiokiddo-strona.zip
set -euo pipefail
cd "$(dirname "$0")/../strona"
for f in $(find audiokiddo-strona -name "*.php"); do php -l "$f" >/dev/null; done
rm -f audiokiddo-strona.zip
zip -qr audiokiddo-strona.zip audiokiddo-strona -x "*.DS_Store"
echo "Gotowe: strona/audiokiddo-strona.zip ($(du -h audiokiddo-strona.zip | cut -f1))"

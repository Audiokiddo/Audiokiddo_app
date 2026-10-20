#!/bin/bash
# Packs the website plugin for WordPress → Wtyczki → Dodaj nową → Wyślij wtyczkę na serwer.
# Output: strona/audiokiddo-strona.zip
set -euo pipefail
cd "$(dirname "$0")/../strona"
for f in $(find audiokiddo-strona -name "*.php"); do php -l "$f" >/dev/null; done
# The script gets the version in its name: the server caches scripts for a year and drops query
# strings, so only a new name makes visitors load the new script.
version=$(sed -n "s/.*define('AK_VERSION', '\\([^']*\\)').*/\\1/p" audiokiddo-strona/audiokiddo-strona.php)
[ -n "$version" ] || { echo "Brak AK_VERSION"; exit 1; }
rm -f audiokiddo-strona/assets/js/strona-[0-9]*.js audiokiddo-strona/assets/js/v2-[0-9]*.js audiokiddo-strona/assets/css/strona-[0-9]*.css audiokiddo-strona/assets/css/v2-[0-9]*.css audiokiddo-strona/assets/js/v2-demos-[0-9]*.js audiokiddo-strona/assets/css/v2-demos-[0-9]*.css
cp audiokiddo-strona/assets/js/strona.js "audiokiddo-strona/assets/js/strona-$version.js"
cp audiokiddo-strona/assets/js/v2.js "audiokiddo-strona/assets/js/v2-$version.js"
cp audiokiddo-strona/assets/css/strona.css "audiokiddo-strona/assets/css/strona-$version.css"
cp audiokiddo-strona/assets/css/v2.css "audiokiddo-strona/assets/css/v2-$version.css"
cp audiokiddo-strona/assets/js/v2-demos.js "audiokiddo-strona/assets/js/v2-demos-$version.js"
cp audiokiddo-strona/assets/css/v2-demos.css "audiokiddo-strona/assets/css/v2-demos-$version.css"
rm -f audiokiddo-strona.zip
zip -qr audiokiddo-strona.zip audiokiddo-strona -x "*.DS_Store" -x "*/.impeccable/*"
echo "Gotowe: strona/audiokiddo-strona.zip ($(du -h audiokiddo-strona.zip | cut -f1))"

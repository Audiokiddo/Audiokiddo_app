# Wdrożenie strony z sesji Claude

Skrypty logują się do audiokiddo.pl/wp-admin danymi z **zmiennych środowiska** `WP_USER` i `WP_PASS`
(ustawionych w Edit cloud environment), nigdy z kodu ani z czatu.

```bash
cd strona && zip -q -r -X /tmp/audiokiddo-strona.zip audiokiddo-strona
cd tool && NODE_PATH=$(npm root -g) OUT=/tmp node deploy-plugin.js /tmp/audiokiddo-strona.zip
NODE_PATH=$(npm root -g) OUT=/tmp node setup-cache.js
NODE_PATH=$(npm root -g) node clear-cache.js    # po każdym wdrożeniu wtyczki
```

WP Fastest Cache nie zapisze ustawień, dopóki w Elementorze (Ustawienia → Wydajność) jest włączone
„Element Caching”. Wyłączone 10.10.2026; przy cache całych stron jest zbędne.

Po wdrożeniu: sprawdzić stronę i koszyk, zmierzyć Lighthouse, usunąć konto `claude-tymczasowy`
i zmienne `WP_USER` / `WP_PASS` z ustawień środowiska.

# Wdrożenie strony z sesji Claude

> **Najpierw sprawdź wersję na stronie** (`node check-plugins.js`). Stronę rozwija też druga
> sesja (gałąź `claude/busy-babbage-aeq1ro`, 11.10.2026: wersja 3.25.0). Nie wgrywaj zipa
> zbudowanego ze starszego kodu: cofnąłby jej zmiany. Wtyczka 3.7.0 z tej gałęzi jest nieaktualna.

Skrypty logują się do audiokiddo.pl/wp-admin danymi z **zmiennych środowiska** `WP_USER` i `WP_PASS`
(ustawionych w Edit cloud environment), nigdy z kodu ani z czatu.

```bash
cd strona && zip -q -r -X /tmp/audiokiddo-strona.zip audiokiddo-strona
cd tool && NODE_PATH=$(npm root -g) OUT=/tmp node deploy-plugin.js /tmp/audiokiddo-strona.zip
NODE_PATH=$(npm root -g) OUT=/tmp node setup-cache.js
```

Po wdrożeniu: sprawdzić stronę i koszyk, zmierzyć Lighthouse, usunąć konto `claude-tymczasowy`
i zmienne `WP_USER` / `WP_PASS` z ustawień środowiska.

Inne skrypty: `check-plugins.js` (lista wtyczek i wersji), `tune-site.js` (wyłącza leniwe
ładowanie Autoptimize i Cache Enabler), `clear-cache.js` (czyści WP Fastest Cache).

## Zmiany 11.10.2026

- Autoptimize → Obrazki: wyłączone „Lazy-loading obrazków” (lazysizes: 600 ms na telefonie;
  wtyczka strony używa natywnego `loading="lazy"`).
- Cache Enabler wyłączony (stronę cache'uje WP Fastest Cache; dwie wtyczki cache naraz).
- Lighthouse na żywej stronie: telefon 67 → 93, komputer 96 (CLS 0,10 od grafiki Szop'ena
  w pierwszym ekranie: przeskakuje po podmianie czcionki).

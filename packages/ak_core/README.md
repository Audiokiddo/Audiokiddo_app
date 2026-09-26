# ak_core

Wspólna logika domenowa AudioKiddo w czystym Darcie (bez Fluttera), używana przez aplikację i panel Studio:

- `catalog` — model i parser manifestu katalogu (błędne pozycje są pomijane, reszta działa),
- `access` — reguły dostępu do treści na podstawie uprawnień (`all_content`, `pack:<id>`, `item:<id>`),
- `lease` — ocena lokalnej dzierżawy dostępu offline (ARCHITECTURE §8),
- `script` — model i walidator skryptów interaktywnych zabaw (ARCHITECTURE §10).

Testy: `dart test`.

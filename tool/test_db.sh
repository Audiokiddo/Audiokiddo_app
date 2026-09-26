#!/usr/bin/env bash
# Applies supabase/migrations to a throwaway local PostgreSQL 17 with a stubbed auth
# schema and runs supabase/tests/schema_test.sql. Needs: brew install postgresql@17
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PG=/opt/homebrew/opt/postgresql@17/bin
DATA="$(mktemp -d)"
PORT=55432
trap '"$PG/pg_ctl" -D "$DATA" stop -m immediate >/dev/null 2>&1 || true; rm -rf "$DATA"' EXIT

LC_ALL=C "$PG/initdb" -D "$DATA" -U postgres -A trust -E UTF8 --no-locale >/dev/null
LC_ALL=C "$PG/pg_ctl" -D "$DATA" -o "-p $PORT -k $DATA" -l "$DATA/log" -w start >/dev/null
PSQL=("$PG/psql" -h "$DATA" -p "$PORT" -U postgres -v ON_ERROR_STOP=1 -q)

"${PSQL[@]}" -c 'create database audiokiddo_test'
"${PSQL[@]}" -d audiokiddo_test -f "$ROOT/supabase/tests/stub_auth.sql"
for migration in "$ROOT"/supabase/migrations/*.sql; do
  "${PSQL[@]}" -d audiokiddo_test -f "$migration"
done
"${PSQL[@]}" -d audiokiddo_test -f "$ROOT/supabase/tests/schema_test.sql"

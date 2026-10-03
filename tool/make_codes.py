#!/usr/bin/env python3
"""Makes access codes for gifts, testers, reviewers and promotions.

    python3 tool/make_codes.py detektyw -n 5 --note "Recenzenci" --apply
    python3 tool/make_codes.py wszystko -n 1 --uses 10 --days 90 --expires 2026-12-31 --note "Testerzy Google Play" --apply
    python3 tool/make_codes.py wyobraznia slowa-i-wiedza -n 3 --note "Prezent dla babci"
    python3 tool/make_codes.py --list                     # what exists and how much is used
    python3 tool/make_codes.py --revoke "Recenzenci"      # stops the codes of that note and takes their access back

Scopes: a pack id (detektyw, wyobraznia, slowa-i-wiedza), "wszystko" (all content) or item:<id>;
several scopes go into one code. Each code works for --uses accounts (default 1), until
--expires (YYYY-MM-DD, default: no end) and gives access for --days days after redeeming
(default: for good).

The codes are printed and saved to ../AudioKiddo-kody/ (a code is like a gift card: keep the
file private). The server keeps only their SHA-256. Without --apply the SQL is only written to
the same folder; --apply sends it to the live database through the Supabase CLI.
"""
import argparse
import csv
import datetime
import hashlib
import json
import pathlib
import secrets
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CATALOG = ROOT / "app/assets/mock/catalog.json"
OUT = ROOT.parent / "AudioKiddo-kody"
ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"  # same as supabase/functions/_shared/codes.ts


def generate() -> str:
    return "AK" + "".join(secrets.choice(ALPHABET) for _ in range(8))


def fmt(code: str) -> str:
    return f"AK-{code[2:6]}-{code[6:]}"


def code_hash(code: str) -> str:
    return hashlib.sha256(code.encode()).hexdigest()


def scope_of(word: str, packs: set, items: set) -> str:
    if word in ("wszystko", "all", "all_content"):
        return "all_content"
    if word.startswith("item:") and word[5:] in items:
        return word
    if word.startswith("pack:") and word[5:] in packs:
        return word
    if word in packs:
        return f"pack:{word}"
    raise SystemExit(f"Nieznany pakiet lub zabawa: {word}. Pakiety: {', '.join(sorted(packs))}, albo 'wszystko'.")


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("scopes", nargs="*")
    ap.add_argument("-n", type=int, default=1, help="how many codes (default 1)")
    ap.add_argument("--uses", type=int, default=1, help="accounts one code works for (default 1)")
    ap.add_argument("--days", type=int, help="access lasts this many days after redeeming")
    ap.add_argument("--expires", help="the code stops working after this day, YYYY-MM-DD")
    ap.add_argument("--note", default="", help="who or what the codes are for")
    ap.add_argument("--apply", action="store_true", help="write them to the live database")
    ap.add_argument("--list", action="store_true", help="show the codes in the live database")
    ap.add_argument("--revoke", metavar="NOTE", help="stop the codes with this note and take their access back")
    args = ap.parse_args()
    if args.list:
        sql = (
            "select coalesce(nullif(note, ''), '(bez notatki)') as notatka, scopes as zakres, count(*) as kodow, "
            "sum(uses) as uzyc, sum(max_uses) as limit_uzyc, min(expires_at)::date as wazne_do, "
            "min(created_at)::date as utworzone from public.access_codes group by note, scopes order by min(created_at) desc"
        )
        subprocess.run(["supabase", "db", "query", "--linked", sql], check=True, cwd=ROOT)
        return 0
    if args.revoke:
        note = args.revoke.replace("'", "''")
        sql = (
            "update public.entitlements set status = 'revoked', updated_at = now() where product_ref = 'code' "
            "and split_part(store_original_tx_id, ':', 2) in (select left(code_hash, 16) from public.access_codes "
            f"where note = '{note}'); "
            f"update public.access_codes set expires_at = now() where note = '{note}' "
            "returning note, uses, max_uses"
        )
        subprocess.run(["supabase", "db", "query", "--linked", sql], check=True, cwd=ROOT)
        return 0
    if not args.scopes:
        raise SystemExit("Podaj pakiet(y) albo użyj --list / --revoke. Pomoc: python3 tool/make_codes.py -h")
    if not 1 <= args.n <= 500 or not 1 <= args.uses <= 1000:
        raise SystemExit("-n 1..500, --uses 1..1000")
    if args.expires:
        datetime.date.fromisoformat(args.expires)

    catalog = json.loads(CATALOG.read_text())
    scopes = sorted({scope_of(w, {p["id"] for p in catalog["packs"]}, {i["id"] for i in catalog["items"]}) for w in args.scopes})
    codes = [generate() for _ in range(args.n)]

    def q(text: str) -> str:
        return "'" + text.replace("'", "''") + "'"

    rows = ",\n".join(
        f"  ({q(code_hash(c))}, {q('{' + ','.join(scopes) + '}')}, {q(args.note)}, {args.uses}, "
        f"{q(args.expires + 'T23:59:59+02:00') if args.expires else 'null'}, {args.days or 'null'})"
        for c in codes
    )
    sql = (
        "insert into public.access_codes (code_hash, scopes, note, max_uses, expires_at, access_days) values\n"
        f"{rows};\n"
    )

    OUT.mkdir(exist_ok=True)
    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S")
    name = "-".join(s.replace(":", "_") for s in scopes)
    with open(OUT / f"kody-{name}-{stamp}.csv", "w", newline="") as f:
        writer = csv.writer(f)
        writer.writerow(["kod", "zakres", "uzycia", "wazny_do", "dni_dostepu", "notatka"])
        for c in codes:
            writer.writerow([fmt(c), " ".join(scopes), args.uses, args.expires or "", args.days or "", args.note])
    (OUT / f"kody-{name}-{stamp}.sql").write_text(sql)

    if args.apply:
        subprocess.run(["supabase", "db", "query", "--linked", sql], check=True, cwd=ROOT)
    print(("Zapisano w bazie. " if args.apply else "NIE zapisano w bazie (dodaj --apply). ") + f"Zakres: {', '.join(scopes)}")
    for c in codes:
        print(f"  {fmt(c)}")
    print(f"Plik z kodami: {OUT}/kody-{name}-{stamp}.csv")
    return 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""Checks that the files on the server match the catalog (size and SHA-256), the way the app
downloads them: through the download-url function, anonymously.

Free plays, previews and pack guides can be fetched without an account, so they are fully
checked; paid files answer 403 without a purchase and are only reported as "skipped" (they
come from the same ZIP, so a matching free file shows the upload worked).
    python3 tool/verify_server_files.py
"""
import hashlib
import json
import pathlib
import sys
import urllib.error
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parent.parent
CATALOG = ROOT / "app/assets/mock/catalog.json"
FUNCTION = "https://ypdxofcwewwdyoelamgy.functions.supabase.co/download-url"


def signed_url(path: str):
    request = urllib.request.Request(
        FUNCTION, data=json.dumps({"path": path}).encode(), headers={"Content-Type": "application/json"}
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            return json.load(response)["url"], None
    except urllib.error.HTTPError as e:
        return None, e.code


def fetch(url: str):
    with urllib.request.urlopen(url, timeout=120) as response:
        return response.read()


def assets(catalog: dict):
    for pack in catalog["packs"]:
        if pack.get("guide"):
            yield f"przewodnik {pack['id']}", pack["guide"]
    for item in catalog["items"]:
        for key in ("audio", "pdf"):
            for asset in item.get(key) or []:
                yield f"{item['id']} ({key})", asset
        if item.get("preview"):
            yield f"{item['id']} (fragment)", item["preview"]


def main() -> int:
    catalog = json.loads(CATALOG.read_text())
    ok = bad = skipped = 0
    for label, asset in assets(catalog):
        url, code = signed_url(asset["path"])
        if url is None:
            skipped += 1 if code == 403 else 0
            if code != 403:
                bad += 1
                print(f"BŁĄD  {label}: serwer odpowiada {code}")
            continue
        try:
            data = fetch(url)
        except (urllib.error.URLError, OSError) as e:
            bad += 1
            print(f"BŁĄD  {label}: nie da się pobrać ({e})")
            continue
        if len(data) == asset["bytes"] and hashlib.sha256(data).hexdigest() == asset["sha256"]:
            ok += 1
        else:
            bad += 1
            print(f"ZŁY PLIK  {label}: na serwerze {len(data)} B, w katalogu {asset['bytes']} B ({asset['path']})")
    print(f"Zgodne: {ok}, niezgodne lub błędy: {bad}, płatne (nie sprawdzane bez zakupu): {skipped}")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())

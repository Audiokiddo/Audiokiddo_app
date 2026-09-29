#!/usr/bin/env bash
# Pushes supabase/config.toml WITHOUT the email templates. The Free plan refuses template
# changes until a custom SMTP is set (KROKI-DLA-DAWIDA, krok 14), and it refuses the whole
# auth push with them, so anonymous sign-ins and the site URL would never reach the server.
# Run it yourself; it shows the diff and asks before writing, like `supabase config push`.
# After SMTP is set, run the plain `supabase config push` to send the Polish email too.
set -euo pipefail
cd "$(dirname "$0")/.."

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/supabase"
cp -R supabase/.temp "$tmp/supabase/.temp"
# Drop the [auth.email.template.*] sections (undeclared properties stay as they are remotely).
python3 - supabase/config.toml "$tmp/supabase/config.toml" <<'PY'
import re, sys
src, out = sys.argv[1:]
lines, skip = [], False
for line in open(src):
    if re.match(r"\s*\[", line):
        skip = line.strip().startswith("[auth.email.template.")
    if not skip:
        lines.append(line)
open(out, "w").write("".join(lines))
PY
supabase config push --workdir "$tmp"

#!/usr/bin/env bash
# Download + unpack Chrome extensions as untrusted data (Phase 2).
# - Raw .crx -> crx/downloads/<name>_<id>.crx  (gitignored)
# - Inner zip unpacked -> crx/unpacked/<name>/ (gitignored, treated as untrusted)
# - SHA-256 of each .crx printed for crx/HASHES.md
# We never execute anything from inside crx/; unzip only extracts.
set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DL="$REPO_ROOT/crx/downloads"
OUT="$REPO_ROOT/crx/unpacked"
PRODVERSION="${PRODVERSION:-139.0.0.0}"
mkdir -p "$DL" "$OUT"

# name|chrome-extension-id|prodversion-override(optional)
EXTS=(
  "sider|difoiogjjojoaoomphldepapgpbgkhkb|"
  "monica|ofpnmcalabcbjgholdjcjblkibolbppb|"
  "merlin|camppjleccjaphfdbohjdohecfnoikec|"
  "ubo_lite|ddkjiahejlhfcafbddmgiahcphecmpfh|"
  "ubo_classic|cjpalhdlnbpafiamejdnhcphjbkeiagm|"
  "privacy_badger|pkehgijcmpdhfbdbbnkijodmdjhbjlgp|"
  "mb_browserguard|ihcjicgdanjaechkgeegckofjjedodee|"
)

for row in "${EXTS[@]}"; do
  IFS='|' read -r name id pv <<<"$row"
  pv="${pv:-$PRODVERSION}"
  crx="$DL/${name}_${id}.crx"
  url="https://clients2.google.com/service/update2/crx?response=redirect&acceptformat=crx2,crx3&prodversion=${pv}&x=id%3D${id}%26installsource%3Dondemand%26uc"
  echo "=============================================================="
  echo "[$name] id=$id prodversion=$pv"
  http=$(curl -sL -A "Mozilla/5.0 (X11; Linux x86_64) Chrome/${pv}" -w '%{http_code}' -o "$crx" "$url")
  sz=$(stat -c%s "$crx" 2>/dev/null || echo 0)
  echo "  http=$http bytes=$sz"
  if [ "$http" != "200" ] || [ "$sz" -lt 1000 ]; then
    echo "  !! download failed or too small — skipping unpack (reported below)"
    continue
  fi
  echo "  sha256: $(sha256sum "$crx" | cut -d' ' -f1)"
  zip="$DL/${name}.zip"
  python3 -I "$REPO_ROOT/src/strip_crx.py" "$crx" "$zip" || { echo "  !! strip failed"; continue; }
  rm -rf "$OUT/$name"
  mkdir -p "$OUT/$name"
  unzip -o -q "$zip" -d "$OUT/$name" 2>&1 | tail -2
  mv=$(python3 -I -c "import json,sys;print(json.load(open(sys.argv[1]))['manifest_version'])" "$OUT/$name/manifest.json" 2>/dev/null || echo '?')
  ver=$(python3 -I -c "import json,sys;print(json.load(open(sys.argv[1]))['version'])" "$OUT/$name/manifest.json" 2>/dev/null || echo '?')
  echo "  unpacked -> crx/unpacked/$name  (manifest_version=$mv ext_version=$ver)"
done
echo "=============================================================="
echo "DONE"

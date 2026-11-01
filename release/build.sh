#!/usr/bin/env bash
# build.sh - makes icm-shakedown.zip, the file members download. Not shipped in the zip.
#
# Usage:  bash release/build.sh [output folder, default release/out]
#
# Stages the skill into a clean folder named icm-shakedown, leaving out what a member does not
# need (git files, this folder, the unused original report look). Then, on the staged copy:
#   1. a leak scan for the author's names, paths and accounts; any hit stops the build
#   2. the self-test; anything but every line held stops the build
# Only then writes the zip, with icm-shakedown/ as its one top folder.
#
# Exit 0 = zip written. Exit 1 = leak or self-test failure, no zip. Exit 2 = setup problem.

set -u
HERE="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$HERE/release/out}"
mkdir -p "$OUT" || exit 2
OUT="$(cd "$OUT" && pwd)"
STAGE="$(mktemp -d)"; trap 'rm -rf "$STAGE"' EXIT
S="$STAGE/icm-shakedown"

# What ships: everything git tracks, minus the release tooling and the unused original look
(cd "$HERE" && git ls-files) \
  | grep -vE '^(release/|\.gitattributes$|\.gitignore$|templates/report-rymac\.html\.orig$)' > "$STAGE/list" || exit 2
mkdir -p "$S" && (cd "$HERE" && tar -cf - -T "$STAGE/list") | (cd "$S" && tar -xf -) || exit 2
echo "STAGED  $(find "$S" -type f | wc -l | tr -d ' ') files"

# 1. Leak scan. The public GitHub handle in the install lines is allowed; nothing else of the
# author's machine, employer, email or the people named in private notes. The README's
# fill-in example path (Users\YOUR-NAME) is allowed. A scan that cannot run stops the build:
# a broken scan must never read as a clean one.
LEAKS='JeffvanLeenen|Jeff-HQ|OneDrive|fifthave|Fifth Ave|5AP|jdvanleenen@|Jordan|C:\\Users\\[A-Za-z]|/c/Users/[A-Za-z]|AppData|\.claude/hooks|block-send-without-approval'
grep -rnIE "$LEAKS" "$S" > "$STAGE/hits"; rc=$?
[ "$rc" -le 1 ] || { echo "LEAK    the scan itself failed (grep exit $rc); the build stops"; exit 2; }
hits="$(grep -vF 'Users\YOUR-NAME\' "$STAGE/hits")"
hits="${hits//$S\//}"
if [ -n "$hits" ]; then
  echo "LEAK    the build stops; these lines name something private:"
  printf '%s\n' "$hits" | head -20
  exit 1
fi
echo "LEAKS   0 hits"

# 2. The self-test, run from the staged copy so it tests exactly what ships
st="$(bash "$S/scripts/selftest.sh" 2>&1 | tail -1)"
echo "TEST    $st"
case "$st" in *"held. Every script"*) ;; *) echo "        the build stops: the self-test did not hold"; exit 1 ;; esac

# 3. The zip, written by python so it works the same on Windows, macOS and Linux
command -v python >/dev/null 2>&1 && PY=python || PY=python3
"$PY" -I - "$STAGE" "$OUT/icm-shakedown.zip" <<'EOF' || exit 2
import os, sys, zipfile
stage, dest = sys.argv[1], sys.argv[2]
with zipfile.ZipFile(dest, "w", zipfile.ZIP_DEFLATED) as z:
    root = os.path.join(stage, "icm-shakedown")
    for folder, _, files in os.walk(root):
        for name in sorted(files):
            full = os.path.join(folder, name)
            z.write(full, os.path.relpath(full, stage).replace(os.sep, "/"))
print("ZIP     " + dest + " (" + str(os.path.getsize(dest) // 1024) + " KB)")
EOF
exit 0

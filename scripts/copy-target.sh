#!/usr/bin/env bash
# copy-target.sh - shakedown setup. Makes the throwaway copy that layers 2 and 3 work in.
#
# Usage:  bash copy-target.sh <target folder> <scratch folder> [max KB per file, default 1024]
#         bash copy-target.sh --check <target folder> <scratch folder> [max KB]
#
# In a git repo, copies the files saved in the history (what the owner means by "the
# workspace"). Anywhere else, copies every file except .git and node_modules. Files over
# the size limit are skipped and counted, so a folder of videos does not fill the disk.
# The target's own .claude settings come along so its hooks can be tested.
#
# Refuses a scratch folder inside the target: the audit never writes into what it measures.
# Checks that every listed file landed in the copy, and names any that did not.
# Saves a checksum of every copied file beside the copy (<scratch>.manifest, never inside it).
#
# With --check, compares the target now against that manifest and names every file changed,
# new or gone since the copy was made. Run it before the report: an owner, or another chat,
# can edit the workspace while the audit runs, and a report on a stale copy blames the owner
# for things already fixed.
#
# Exit 0 = copied in full (--check: target unchanged). Exit 1 = incomplete copy (--check: the
# target changed). Exit 2 = bad arguments.

set -u
CHECK=0; [ "${1:-}" = "--check" ] && { CHECK=1; shift; }
T="${1:?usage: bash copy-target.sh [--check] <target> <scratch> [max KB]}"
D="${2:?usage: bash copy-target.sh [--check] <target> <scratch> [max KB]}"
MAXKB="${3:-1024}"
[ -d "$T" ] || { echo "copy-target: no folder at $T"; exit 2; }
T="$(cd "$T" && pwd)"

# The files the audit copies, 1 relative path per line, small enough to copy, into $1
list_files() {
  if git -C "$T" rev-parse --show-toplevel >/dev/null 2>&1; then
    (cd "$T" && git ls-files) > "$1.all"
    src="saved files (git)"
  else
    (cd "$T" && find . \( -name .git -o -name node_modules \) -prune -o -type f -print | sed 's#^\./##') > "$1.all"
    src="all files"
  fi
  for extra in .claude/settings.json .claude/settings.local.json; do [ -f "$T/$extra" ] && echo "$extra" >> "$1.all"; done
  # 1 pass of du over every listed file (portable on Linux, macOS and Git Bash), then keep the small ones
  (cd "$T" && tr '\n' '\0' < "$1.all" | xargs -0 du -k 2>/dev/null) \
    | awk -F'\t' -v max="$MAXKB" '$1 <= max { sub(/^[^\t]*\t/, ""); print }' > "$1"
  big=$(( $(sort -u "$1.all" | wc -l) - $(wc -l < "$1") ))
  rm -f "$1.all"
}

# path TAB checksum TAB size for every file in list $1, sorted by path
checksums() {
  (cd "$T" && tr '\n' '\0' < "$1" | xargs -0 cksum 2>/dev/null) \
    | sed -E 's/^([0-9]+) ([0-9]+) (.*)$/\3\t\1\t\2/' | LC_ALL=C sort
}

list="$(mktemp)"

if [ "$CHECK" -eq 1 ]; then
  [ -d "$D" ] || { echo "copy-target: no copy at $D"; exit 2; }
  D="$(cd "$D" && pwd)"
  [ -f "$D.manifest" ] || { echo "copy-target: no manifest at $D.manifest, so this copy cannot be checked"; exit 2; }
  list_files "$list"
  now="$(mktemp)"; checksums "$list" > "$now"
  report="$(LC_ALL=C join -t "$(printf '\t')" -a 1 -a 2 -e GONE -o 0,1.2,2.2 "$D.manifest" "$now" \
    | awk -F'\t' '$2 == "GONE" { print "  new     " $1; next }
                  $3 == "GONE" { print "  gone    " $1; next }
                  $2 != $3     { print "  changed " $1 }')"
  compared=$(wc -l < "$now" | tr -d ' ')
  rm -f "$list" "$now"
  if [ -z "$report" ]; then
    echo "FRESH   the target has not changed since the copy was made ($compared files compared)"
    exit 0
  fi
  echo "STALE   $(printf '%s\n' "$report" | wc -l | tr -d ' ') files changed in the target since the copy was made:"
  printf '%s\n' "$report" | head -40
  echo "        Say so in the report. If a job's own files changed, copy again and rerun that job."
  exit 1
fi

mkdir -p "$D" || exit 2
D="$(cd "$D" && pwd)"
case "$D/" in "$T/"*) echo "copy-target: refusing, $D is inside the target $T"; rmdir "$D" 2>/dev/null; exit 2 ;; esac

list_files "$list"
checksums "$list" > "$D.manifest"
(cd "$T" && tar -cf - -T "$list" 2>/dev/null) | (cd "$D" && tar -xf - 2>/dev/null)
copied=$(find "$D" -type f | wc -l | tr -d ' ')
wanted=$(wc -l < "$list" | tr -d ' ')
# Every listed file must have landed. A copy can lose files with no error shown (a path too long
# for the system, a name it refuses, a clash in the scratch folder), and an audit of an incomplete
# copy blames the owner for files that were never copied.
missing=0
while IFS= read -r f; do
  [ -n "$f" ] || continue
  if [ ! -f "$D/$f" ]; then
    missing=$((missing + 1))
    [ "$missing" -le 20 ] && echo "MISSING $f"
  fi
done < "$list"
rm -f "$list"
echo "COPY    $copied files copied from the target's $src into $D"
echo "        $big files over ${MAXKB} KB left out"
if [ "$missing" -gt 0 ]; then
  echo "        INCOMPLETE: $missing of $wanted listed files did not land. Fix the copy before any layer runs."
  exit 1
fi
echo "        all $wanted listed files landed"
exit 0

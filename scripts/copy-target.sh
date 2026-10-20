#!/usr/bin/env bash
# copy-target.sh - shakedown setup. Makes the throwaway copy that layers 2 and 3 work in.
#
# Usage:  bash copy-target.sh <target folder> <scratch folder> [max KB per file, default 1024]
#
# In a git repo, copies the files saved in the history (what the owner means by "the
# workspace"). Anywhere else, copies every file except .git and node_modules. Files over
# the size limit are skipped and counted, so a folder of videos does not fill the disk.
# The target's own .claude settings come along so its hooks can be tested.
#
# Refuses a scratch folder inside the target: the audit never writes into what it measures.
# Checks that every listed file landed in the copy, and names any that did not.
# Exit 0 = copied in full. Exit 1 = incomplete copy. Exit 2 = bad arguments.

set -u
T="${1:?usage: bash copy-target.sh <target> <scratch> [max KB]}"
D="${2:?usage: bash copy-target.sh <target> <scratch> [max KB]}"
MAXKB="${3:-1024}"
[ -d "$T" ] || { echo "copy-target: no folder at $T"; exit 2; }
T="$(cd "$T" && pwd)"
mkdir -p "$D" || exit 2
D="$(cd "$D" && pwd)"
case "$D/" in "$T/"*) echo "copy-target: refusing, $D is inside the target $T"; rmdir "$D" 2>/dev/null; exit 2 ;; esac

list="$(mktemp)"
if git -C "$T" rev-parse --show-toplevel >/dev/null 2>&1; then
  (cd "$T" && git ls-files) > "$list.all"
  src="saved files (git)"
else
  (cd "$T" && find . \( -name .git -o -name node_modules \) -prune -o -type f -print | sed 's#^\./##') > "$list.all"
  src="all files"
fi
for extra in .claude/settings.json .claude/settings.local.json; do [ -f "$T/$extra" ] && echo "$extra" >> "$list.all"; done

# 1 pass of du over every listed file (portable on Linux, macOS and Git Bash), then keep the small ones
(cd "$T" && tr '\n' '\0' < "$list.all" | xargs -0 du -k 2>/dev/null) \
  | awk -F'\t' -v max="$MAXKB" '$1 <= max { sub(/^[^\t]*\t/, ""); print }' > "$list"
big=$(( $(sort -u "$list.all" | wc -l) - $(wc -l < "$list") ))
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
rm -f "$list" "$list.all"
echo "COPY    $copied files copied from the target's $src into $D"
echo "        $big files over ${MAXKB} KB left out"
if [ "$missing" -gt 0 ]; then
  echo "        INCOMPLETE: $missing of $wanted listed files did not land. Fix the copy before any layer runs."
  exit 1
fi
echo "        all $wanted listed files landed"
exit 0

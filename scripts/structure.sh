#!/usr/bin/env bash
# structure.sh - shakedown layer 1, question 9. Checks the shape rules from the ICM method itself
# (Van Clief and McDermott, as restated in the icm-architect skill's invariants):
#   ENTRY      the root entry file (CLAUDE.md / AGENTS.md) only routes, so it stays short
#   TWINS      CLAUDE.md and AGENTS.md at the root say the same thing, or one points to the other
#   CASE       no 2 paths differ only by capital letters (Windows and macOS treat them as 1 file)
#   CONTRACT   every stage CONTEXT.md below the root names what it reads, what it writes, and
#              what a person checks
#
# Usage:  bash structure.sh <target folder> [entry line limit, default 80]
# Exit 0 = shape holds. Exit 1 = at least 1 finding. Exit 2 = bad arguments.

set -u
T="${1:?usage: bash structure.sh <target> [entry line limit]}"
LIMIT="${2:-80}"
[ -d "$T" ] || { echo "structure: no folder at $T"; exit 2; }
T="$(cd "$T" && pwd)"
n=0
say() { n=$((n + 1)); echo "$1"; }
# A folder below the root with its own CLAUDE.md or AGENTS.md is a child workspace (an umbrella
# ICM). Its CONTEXT.md files are its own map and stages; audit it on its own (umbrella.sh does).
in_child() { local d="${1%/*}"
  while [ "${#d}" -gt "${#T}" ]; do { [ -f "$d/CLAUDE.md" ] || [ -f "$d/AGENTS.md" ]; } && return 0; d="${d%/*}"; done
  return 1; }
kids=0; rooms=0
# A stage contract, as opposed to a room map: the file's own front matter `type:` decides when it
# has one (a stage when it says stage); otherwise a folder named with a stage number (01_draft,
# "02 read") is a stage and any other folder is a room.
is_stage() { local t f; f="${1%/*}"; f="${f##*/}"
  t="$(awk 'NR==1 && $0!="---" {exit} NR>1 && $0=="---" {exit} /^type:/ {sub(/^type:[ \t]*/, ""); print tolower($0); exit}' "$1")"
  if [ -n "$t" ]; then case "$t" in *stage*) return 0 ;; *) return 1 ;; esac; fi
  case "$f" in [0-9]*) return 0 ;; esac; return 1; }

# ENTRY
for e in CLAUDE.md AGENTS.md; do
  [ -f "$T/$e" ] || continue
  lines=$(wc -l < "$T/$e" | tr -d ' ')
  [ "$lines" -gt "$LIMIT" ] && say "ENTRY    $e is $lines lines (limit $LIMIT). An entry file routes; move content to a shelf and leave a pointer."
done
[ -f "$T/CLAUDE.md" ] || [ -f "$T/AGENTS.md" ] || say "ENTRY    no CLAUDE.md or AGENTS.md at the root. A cold agent has no front door."

# TWINS
if [ -f "$T/CLAUDE.md" ] && [ -f "$T/AGENTS.md" ]; then
  if ! cmp -s "$T/CLAUDE.md" "$T/AGENTS.md"; then
    small_c=$(wc -l < "$T/CLAUDE.md"); small_a=$(wc -l < "$T/AGENTS.md")
    if ! { [ "$small_a" -le 5 ] && grep -q 'CLAUDE.md' "$T/AGENTS.md"; } && \
       ! { [ "$small_c" -le 5 ] && grep -q 'AGENTS.md' "$T/CLAUDE.md"; }; then
      say "TWINS    CLAUDE.md and AGENTS.md differ and neither just points to the other. One of them is out of date."
    fi
  fi
fi

# CASE
dups="$(cd "$T" && find . \( -name .git -o -name node_modules \) -prune -o -print | sed 's#^\./##' \
  | awk '{ k = tolower($0); if (k in seen && seen[k] != $0) print seen[k] "  and  " $0; else seen[k] = $0 }')"
if [ -n "$dups" ]; then
  while IFS= read -r d; do say "CASE     $d differ only by capitals; on Windows or macOS one overwrites the other"; done <<< "$dups"
fi

# CONTRACT
while IFS= read -r c; do
  rel="${c#$T/}"
  [ "$rel" = "CONTEXT.md" ] && continue
  in_child "$c" && { kids=$((kids + 1)); continue; }
  is_stage "$c" || { rooms=$((rooms + 1)); continue; }
  low="$(tr 'A-Z' 'a-z' < "$c")"
  miss=""
  printf '%s' "$low" | grep -qE 'input|reads|what comes in|comes in' || miss="$miss inputs,"
  printf '%s' "$low" | grep -qE 'output|writes|what goes out|goes out' || miss="$miss outputs,"
  printf '%s' "$low" | grep -qE 'human check|approv|confirm|review|sign[- ]off|checks? (it|the)|ask(s)? (the )?[a-z]+' || miss="$miss a human check,"
  [ -n "$miss" ] && say "CONTRACT $rel does not name:${miss%,}"
done < <(find "$T" \( -name .git -o -name node_modules -o -name runs -o -name output -o -name _archive \) -prune -o -type f -name CONTEXT.md -print)

echo "SHAPE    $n finding(s)"
[ "$kids" -gt 0 ] && echo "         $kids CONTEXT.md files sit inside child workspaces (own CLAUDE.md) and were left out; run umbrella.sh"
[ "$rooms" -gt 0 ] && echo "         $rooms CONTEXT.md files are room maps, not stages (no stage number, or type: says so), so not judged as contracts"
[ "$n" -eq 0 ] && exit 0 || exit 1

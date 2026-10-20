#!/usr/bin/env bash
# load.sh - shakedown layer 1, question 10. How much an agent reads before it can do one stage's job.
#
# For each stage contract (a CONTEXT.md below the root), adds up the root entry file, the root
# CONTEXT.md, the contract itself, and every file the contract tells the agent to read, named in
# backticks in its intro or input section (paths read from the root or from the contract's
# folder). Files it writes, or says not to load, do not count. Only text an agent reads counts
# (md, txt, csv, json, yaml, html); a PDF or image it attaches does not. Tokens are bytes / 4.
# The ICM range is about 2,000 to 8,000 tokens per stage; past the limit, the agent is reading
# what the step does not need.
#
# Usage:  bash load.sh <target folder> [token limit, default 8000]
# Exit 0 = every stage under the limit. Exit 1 = at least 1 stage over. Exit 2 = bad arguments.

set -u
T="${1:?usage: bash load.sh <target> [token limit]}"
LIMIT="${2:-8000}"
[ -d "$T" ] || { echo "load: no folder at $T"; exit 2; }
T="$(cd "$T" && pwd)"
size() { [ -f "$1" ] && wc -c < "$1" | tr -d ' ' || echo 0; }
# A folder below the root with its own CLAUDE.md or AGENTS.md is a child workspace, read through
# its own entry file, not this one. It is left out here and measured on its own (umbrella.sh).
in_child() { local d="${1%/*}"
  while [ "${#d}" -gt "${#T}" ]; do { [ -f "$d/CLAUDE.md" ] || [ -f "$d/AGENTS.md" ]; } && return 0; d="${d%/*}"; done
  return 1; }
kids=0; rooms=0
# Same test as structure.sh: front matter `type:` decides, else a stage-numbered folder is a stage.
is_stage() { local t f; f="${1%/*}"; f="${f##*/}"
  t="$(awk 'NR==1 && $0!="---" {exit} NR>1 && $0=="---" {exit} /^type:/ {sub(/^type:[ \t]*/, ""); print tolower($0); exit}' "$1")"
  if [ -n "$t" ]; then case "$t" in *stage*) return 0 ;; *) return 1 ;; esac; fi
  case "$f" in [0-9]*) return 0 ;; esac; return 1; }

base=0
for f in CLAUDE.md AGENTS.md; do [ -f "$T/$f" ] && { base=$(size "$T/$f"); break; }; done
base=$((base + $(size "$T/CONTEXT.md")))

over=0; stages=0
while IFS= read -r c; do
  rel="${c#$T/}"; [ "$rel" = "CONTEXT.md" ] && continue
  in_child "$c" && { kids=$((kids + 1)); continue; }
  is_stage "$c" || { rooms=$((rooms + 1)); continue; }
  dir="$(dirname "$c")"
  total=$((base + $(size "$c")))
  # Count what the stage READS: files named before the first section heading or under an input
  # heading (inputs, what comes in, read, reference, sources). A file named only under outputs,
  # process or the human check is written, not read, and a line that says "do not load" is skipped.
  named="$(awk '
    /^#/ { h = tolower($0); sec = (h ~ /^# / || h ~ /input|comes in|read|reference|load|source|needs/); next }
    { l = tolower($0); if (l ~ /(do not|don.t|never) (load|read|open|edit)/) next }
    sec { s = $0; while (match(s, /`[^`]*`/)) { print substr(s, RSTART + 1, RLENGTH - 2); s = substr(s, RSTART + RLENGTH) } }
    BEGIN { sec = 1 }' "$c" | sort -u)"
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    for cand in "$T/$p" "$dir/$p"; do
      if [ -f "$cand" ]; then
        case "$cand" in *.md|*.txt|*.csv|*.json|*.yaml|*.yml|*.html|*.htm) total=$((total + $(size "$cand"))) ;; esac
        break
      fi
    done
  done <<< "$named"
  tok=$((total / 4)); stages=$((stages + 1))
  if [ "$tok" -gt "$LIMIT" ]; then over=$((over + 1)); flag="OVER"; else flag="ok  "; fi
  printf '%s %6d tokens  %s\n' "$flag" "$tok" "$rel"
done < <(find "$T" \( -name .git -o -name node_modules -o -name runs -o -name output -o -name _archive \) -prune -o -type f -name CONTEXT.md -print | sort)

echo "LOAD     $stages stage contracts measured; $over over $LIMIT tokens (entry + contract + named files)"
[ "$kids" -gt 0 ] && echo "         $kids CONTEXT.md files sit inside child workspaces (own CLAUDE.md) and were left out; run umbrella.sh"
[ "$rooms" -gt 0 ] && echo "         $rooms CONTEXT.md files are room maps, not stages, so not measured as a stage"
[ "$over" -eq 0 ] && exit 0 || exit 1

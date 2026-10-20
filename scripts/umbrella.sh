#!/usr/bin/env bash
# umbrella.sh - shakedown layer 1 for an umbrella ICM: a root that routes to child workspaces, each with
# its own CLAUDE.md or AGENTS.md. Read only.
#
# The per-workspace checks (routes, structure, load) judge a workspace by ITS entry file, so they
# run once at the root and once inside every child workspace, each with that workspace as the
# root. The whole-tree checks (status-drift, repeats, claims, secrets, nested-repos, placeholders)
# already read every folder; run them once at the root as usual. Repeats is most useful there:
# it finds a rule pasted into 3 child workspaces.
#
# A child workspace is any folder below the root holding CLAUDE.md or AGENTS.md, outside .git,
# node_modules, runs, output, archives, templates (a blank form) and build output (dist, build,
# .next: a packaged copy, not a workspace).
#
# Usage:  bash umbrella.sh <umbrella root>
# Exit 0 = every workspace clean on all 3 checks. Exit 1 = at least 1 finding. Exit 2 = bad arguments.

set -u
T="${1:?usage: bash umbrella.sh <umbrella root>}"
[ -d "$T" ] || { echo "umbrella: no folder at $T"; exit 2; }
T="$(cd "$T" && pwd)"
HERE="$(cd "$(dirname "$0")" && pwd)"

list="$(mktemp)"; trap 'rm -f "$list"' EXIT
echo "." > "$list"
(cd "$T" && find . \( -name .git -o -name node_modules -o -name runs -o -name output -o -name _archive \
    -o -name archive -o -name templates -o -name _templates -o -name dist -o -name build -o -name .next \
    -o -name '_backup*' -o -name 'backup*' \) -prune -o -type f \( -name CLAUDE.md -o -name AGENTS.md \) -print) \
  | sed 's#^\./##' | xargs -r -d '\n' -n1 dirname | grep -vx '\.' | sort -u >> "$list"

kids=$(($(grep -c . "$list") - 1))
echo "UMBRELLA $kids child workspace(s) below the root, each audited with itself as the root"
echo
printf '%-44s %-14s %-7s %-16s\n' "Workspace" "Routes" "Shape" "Stages over / max"
bad=0; details=""
while IFS= read -r w; do
  dir="$T"; [ "$w" = "." ] || dir="$T/$w"
  r="$(bash "$HERE/routes.sh" "$dir" 2>&1)"; rr=$?
  s="$(bash "$HERE/structure.sh" "$dir" 2>&1)"; sr=$?
  l="$(bash "$HERE/load.sh" "$dir" 2>&1)"; lr=$?
  routes="$(printf '%s\n' "$r" | sed -nE 's/^ROUTES +([0-9]+ of [0-9]+).*/\1/p')"
  [ -n "$routes" ] || routes="no entry"
  orphans="$(printf '%s\n' "$r" | grep -c '^  orphan' || true)"
  [ "$orphans" -gt 0 ] && routes="$routes +${orphans}orph"
  shape="$(printf '%s\n' "$s" | sed -nE 's/^SHAPE +([0-9]+).*/\1/p')"
  over="$(printf '%s\n' "$l" | sed -nE 's/^LOAD +[0-9]+ stage contracts measured; ([0-9]+) over.*/\1/p')"
  max="$(printf '%s\n' "$l" | awk '/^(ok|OVER) /{ if ($2 + 0 > m) m = $2 + 0 } END { print m + 0 }')"
  name="$w"; [ "$w" = "." ] && name="(root)"
  printf '%-44s %-14s %-7s %-16s\n' "${name:0:44}" "$routes" "${shape:-?}" "${over:-?} / $max"
  if [ "$rr" -ne 0 ] || [ "$sr" -ne 0 ] || [ "$lr" -ne 0 ]; then
    bad=$((bad + 1))
    details="$details
== $name
$(printf '%s\n' "$r" | grep -E '^  (dead|orphan)' | head -8)
$(printf '%s\n' "$s" | grep -E '^(ENTRY|TWINS|CASE|CONTRACT)' | head -8)
$(printf '%s\n' "$l" | grep '^OVER' | head -5)"
  fi
done < "$list"

[ -n "$details" ] && printf '%s\n' "$details" | sed '/^$/d'
echo
echo "UMBRELLA $bad of $((kids + 1)) workspaces have at least 1 finding. Whole-tree checks: run them once at the root."
[ "$bad" -eq 0 ] && exit 0 || exit 1

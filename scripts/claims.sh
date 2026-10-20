#!/usr/bin/env bash
# claims.sh - shakedown layer 3, part B by script. Finds files that SAY done (status: approved,
# verdict: accepted) while their own body says otherwise:
#   CONTRADICT  a finding in the file reads `drifted:` or `fail:` on a list line, yet the file says
#               approved or accepted. Either the rule allows accepting known drift (then the file
#               should name it and the reason) or the approval is wrong.
#   EMPTY       the file says approved or accepted, but its approval block is still blank: an empty
#               `verdict:`, an empty Answer / Name / Date line, or the words "verdict blank".
# Templates are skipped: a blank form is meant to be blank.
#
# Usage:  bash claims.sh <target folder>
# Exit 0 = every done-claim is consistent. Exit 1 = at least 1 finding. Exit 2 = bad arguments.

set -u
T="${1:?usage: bash claims.sh <target>}"
[ -d "$T" ] || { echo "claims: no folder at $T"; exit 2; }
T="$(cd "$T" && pwd)"
out="$(mktemp)"; trap 'rm -f "$out"' EXIT

(cd "$T" && grep -rlE --include='*.md' --exclude-dir=.git --exclude-dir=node_modules \
   --exclude-dir=templates --exclude-dir=_templates '^(status: *approved|verdict: *accepted)' . 2>/dev/null) \
| sed 's#^\./##' | while IFS= read -r f; do
    awk -v F="$f" '
      NR == 1 && $0 == "---" { fm = 1; next }
      fm && $0 == "---" { fm = 0; next }
      fm && /^status: *approved/ { approved = 1 }
      fm && /^verdict:/ { hasv = 1 }
      fm && /^verdict: *accepted/ { accepted = 1 }
      fm && /^verdict: *$/ { emptyv = 1 }
      fm { next }
      /^[ \t]*([-*]|[0-9]+\.)/ && /(drifted|fail):/ { bad++; if (!first) first = NR }
      /^[ \t]*- (Answer|Name|Date): *$/ { blank++ }
      tolower($0) ~ /verdict blank/ { blank++ }
      END {
        # A verdict, when the file has one, is the claim; status alone counts only without one.
        # status: approved with verdict: drifted is an honest record of drift, not a done-claim.
        done = hasv ? accepted : approved
        if (hasv && approved && emptyv) done = 1
        if (!done) exit
        if (bad)   printf "CONTRADICT %s says done but lists %d drifted or failed finding(s), first at line %d; each must be named and accepted in its notes, or the verdict is wrong\n", F, bad, first
        if (emptyv || blank) printf "EMPTY      %s says done but its approval is blank (%s)\n", F, (emptyv ? "empty verdict" : "empty approval lines")
      }' "$T/$f"
  done > "$out"

n=$(grep -c . "$out" || true)
head -40 "$out"
echo "CLAIMS   $n done-claim(s) contradicted by their own file"
[ "$n" -eq 0 ] && exit 0 || exit 1

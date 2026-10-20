#!/usr/bin/env bash
# repeats.sh - shakedown layer 1, question 11. One home per fact: finds the same instruction written in
# several files. A rule copied into 3 places drifts the day 1 copy is edited.
#
# Reads only the files that instruct an agent: CLAUDE.md, AGENTS.md, CONTEXT.md and README.md
# anywhere, plus Markdown under a folder named reference, _reference, rules or standards (not
# "references", which usually holds per-image or per-source records). Run records, outputs,
# templates and archives are left out: they quote rules on purpose. An AGENTS.md that is a byte
# copy of the CLAUDE.md beside it is a deliberate twin, so only 1 of the 2 is read.
# Compares runs of 8 words in a row (case and punctuation ignored), so a rule copied with small
# edits still matches. Overlapping runs shared by the same files are reported once.
#
# Usage:  bash repeats.sh <target folder> [min files, default 3]
# Exit 0 = nothing shared that widely. Exit 1 = at least 1 shared passage. Exit 2 = bad arguments.

set -u
T="${1:?usage: bash repeats.sh <target> [min files]}"
MIN="${2:-3}"
[ -d "$T" ] || { echo "repeats: no folder at $T"; exit 2; }
T="$(cd "$T" && pwd)"
out="$(mktemp)"; trap 'rm -f "$out"' EXIT

(cd "$T" && find . \( -name .git -o -name node_modules -o -name runs -o -name output -o -name _archive \
    -o -name archive -o -name templates -o -name _templates -o -name drafts \) -prune -o -type f -name '*.md' -print) \
| sed 's#^\./##' | awk '
    { n = split($0, seg, "/"); base = seg[n] }
    base ~ /^(CLAUDE|AGENTS|CONTEXT|README)\.md$/ { print; next }
    tolower($0) ~ /(^|\/)_?(reference|rules|standards)\// { print }' \
| while IFS= read -r f; do
    case "$f" in *AGENTS.md) twin="$(dirname "$T/$f")/CLAUDE.md"; [ -f "$twin" ] && cmp -s "$T/$f" "$twin" && continue ;; esac
    awk -v F="$f" '
      NR==1 && /^---$/ { fm=1; next } fm && /^---$/ { fm=0; next } fm { next }
      /^[ \t]*#/ { next }   # a shared heading is a shared form, not a copied rule
      # A pointer to 1 shared file is how a rule keeps 1 home, so links and paths are not text:
      # drop a list line that is only a link, link targets, and backticked paths.
      /^[ \t]*([-*]|[0-9]+\.)[ \t]*\[[^]]*\]\([^)]*\)[ \t]*$/ { next }
      { s = $0; gsub(/\]\([^)]*\)/, "]", s); gsub(/`[^`]*`/, " ", s)
        s = tolower(s); gsub(/[^a-z0-9 ]/, " ", s); buf = buf " " s }
      END {
        n = split(buf, w, " ")
        for (i = 1; i + 7 <= n; i++) {
          g = w[i]; for (j = 1; j < 8; j++) g = g " " w[i + j]
          print g "\t" F
        }
      }' "$T/$f"
  done | sort -u | awk -F'\t' -v min="$MIN" '
      { c[$1]++; files[$1] = files[$1] (c[$1] > 1 ? ", " : "") $2 }
      END { for (g in c) if (c[g] >= min) printf "%d\t%s\t%s\n", c[g], files[g], g }' \
  | sort -t$'\t' -k1,1nr -k2,2 \
  | awk -F'\t' '$2 != last { print; last = $2 }' > "$out"

found=$(grep -c . "$out" || true)
head -15 "$out" | awk -F'\t' '{ printf "REPEAT   in %d files: \"... %s ...\"\n         %s\n", $1, $3, $2 }'
echo "ONEHOME  $found passage(s) of 8+ words written in $MIN or more instruction files"
[ "$found" -eq 0 ] && exit 0 || exit 1

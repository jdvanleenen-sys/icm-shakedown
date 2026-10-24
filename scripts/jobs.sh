#!/usr/bin/env bash
# jobs.sh - shakedown, layer 2, part A. Read only.
#
# Usage:  bash jobs.sh <target folder> [outside file ...]
#         bash jobs.sh <target folder> --check <walk file> [outside file ...]
#
# Lists every job a stranger could be sent to do in the target, with the place the
# workspace says that job lives:
#   entry    a row of a table in the top entry files (CLAUDE.md, AGENTS.md, CONTEXT.md)
#   room     a row of a table in a top folder's own CLAUDE.md or CONTEXT.md
#   outside  a path into the target named by a file outside it: the owner's global
#            ~/.claude/CLAUDE.md, every ~/.claude/skills/*/SKILL.md, and any file given.
#            These are the jobs other agents will try, whether or not a routing table
#            names them. The job's words are the heading above the path.
# Each place is listed once; the first source that names it wins. A job whose place does
# not exist is marked "missing": the map sends work to nothing.
#
# With --check, reads the walker's answers, 1 per line:  <job number> TAB <path> TAB <reads>
# (<path> relative to the target, as the walker landed; "none" if stuck). Each job gets 1 word:
#   pass   landed on the place, in 3 reads or fewer (the entry file plus 2)
#   slow   landed on the place in 4 or 5 reads
#   lost   landed on the place in more than 5 reads
#   wrong  landed somewhere else
#   stuck  did not land, or no answer
# Landing on the place, inside it, or on the folder that holds it counts as the place.
#
# Exit 0 = every place exists (and with --check, every job is a pass). Exit 1 = at least 1
# missing place (or 1 job that is not a pass). Exit 2 = bad arguments.

set -u
T="${1:-}"
{ [ -n "$T" ] && [ -d "$T" ]; } || { echo "usage: bash jobs.sh <target folder> [--check <walk file>] [outside file ...]"; exit 2; }
shift
T="$(cd "$T" && pwd)"
WALK=""
if [ "${1:-}" = "--check" ]; then
  WALK="${2:-}"; [ -f "$WALK" ] || { echo "jobs: no walk file at ${2:-}"; exit 2; }; shift 2
fi
BASE="$(basename "$T")"

outside=()
[ -f "$HOME/.claude/CLAUDE.md" ] && outside+=("$HOME/.claude/CLAUDE.md")
for s in "$HOME"/.claude/skills/*/SKILL.md; do [ -f "$s" ] && outside+=("$s"); done
for f in "$@"; do [ -f "$f" ] && outside+=("$f"); done

tops="$(cd "$T" && for d in */; do [ -d "$d" ] && printf '%s\n' "${d%/}"; done)"
RAW="$(mktemp)"; LIST="$(mktemp)"; ALT="$(mktemp)"; trap 'rm -f "$RAW" "$LIST" "$ALT"' EXIT

# Table rows, header rows left out:  source TAB file:line TAB words TAB folder TAB path
table_rows() {  # $1 = file relative to the target, $2 = source word, $3 = the file's folder
  awk -v src="$2" -v dir="$3" -v file="$1" '
    function emit(row, ln,    c, words, n, parts, i, p, path) {
      split(row, c, "|"); words = c[2]
      # A first cell that is only paths (| `finance/` | what it holds |) names the answer, not
      # the job: the job words are the next cell.
      first = c[2]; gsub(/`[^`]*`|[[:space:]·,]|\*/, "", first)
      if (first == "" && c[3] != "") words = c[3]
      gsub(/\*|`/, "", words); gsub(/^[[:space:]]+|[[:space:]]+$/, "", words)
      if (words == "") return
      n = split(row, parts, "`"); path = ""
      for (i = 2; i <= n; i += 2) {
        p = parts[i]
        if (p ~ /[<{*$|=]/ || p ~ /^(https?:|www\.|~|\/|[A-Za-z]:)/) continue
        if (p ~ /\// || p ~ /\.(md|txt|html|json|csv|py|sh|mjs|js|pdf)$/) { path = p; break }
      }
      if (path == "") return
      sub(/#.*/, "", path)
      printf "%s\t%s:%d\t%s\t%s\t%s\n", src, file, ln, words, dir, path
    }
    /^[[:space:]]*\|/ {
      if ($0 ~ /^[[:space:]]*\|[[:space:]:|-]+$/) { pending = ""; next }   # separator: the row above was a header
      if (pending != "") emit(pending, pline)
      pending = $0; pline = NR; next
    }
    { if (pending != "") emit(pending, pline); pending = "" }
    END { if (pending != "") emit(pending, pline) }' "$T/$1"
}

{
  for f in CLAUDE.md AGENTS.md CONTEXT.md; do [ -f "$T/$f" ] && table_rows "$f" entry "-"; done
  while IFS= read -r d; do
    [ -n "$d" ] || continue
    case "$d" in .*|node_modules|_archive) continue ;; esac
    for f in CLAUDE.md CONTEXT.md; do [ -f "$T/$d/$f" ] && table_rows "$d/$f" room "$d/"; done
  done <<< "$tops"
  for o in "${outside[@]+"${outside[@]}"}"; do
    awk -v base="$BASE" -v tops="$tops" -v file="$o" '
      BEGIN { n = split(tops, t, "\n"); for (i = 1; i <= n; i++) if (t[i] != "") top[t[i]] = 1 }
      BEGIN { name = file; sub(/\/SKILL\.md$/, "", name); sub(/.*\//, "", name)
              GENERIC = "^(inputs|outputs|steps|files|process|usage|rules|notes|check|references|overview|setup|workflow|output|input)$" }
      /^#+ / { head = $0; sub(/^#+ +/, "", head)
               # a bare section word ("Inputs", "Steps") is not a job: name the file it sits in
               if (tolower(head) ~ GENERIC) head = name ": " head }
      {
        line = $0; gsub(/\\/, "/", line)
        while (match(line, /`[^`]+`/)) {
          tok = substr(line, RSTART + 1, RLENGTH - 2); line = substr(line, RSTART + RLENGTH)
          p = ""; how = "-"
          k = index(tok, "/" base "/")
          if (k) p = substr(tok, k + length(base) + 2)
          else if (index(tok, base "/") == 1) p = substr(tok, length(base) + 2)
          else { split(tok, seg, "/"); if ((seg[1] in top) && index(tok, "/")) { p = tok; how = "+" } }
          if (p == "" || p ~ /[<{*$|]/) continue
          sub(/[).,;:]+$/, "", p)
          printf "outside\t%s:%d\t%s\t%s\t%s\n", file, NR, (head == "" ? "(no heading)" : head), how, p
        }
      }' "$o"
  done
} > "$RAW"

# Resolve each place: from its own folder first, then from the top. A path with a space that
# resolves nowhere and does not start at a top folder is prose, not a place: dropped. An
# outside path that only starts with a top folder's name ("+", like `_templates/x`) and does
# not exist may be the outside file's own folder, so it is dropped too; one that names the
# target itself ("-") and does not exist is a missing place.
missing=0; seen="|"; n=0
while IFS=$'\t' read -r src where words dir path; do
  guess=0; [ "$dir" = "+" ] && guess=1
  case "$dir" in -|+) dir="" ;; esac
  path="${path%/}"; [ -n "$path" ] || continue
  [ "$guess" -eq 1 ] && [ ! -e "$T/$path" ] && continue
  if [ -n "$dir" ] && [ -e "$T/$dir$path" ]; then place="$dir$path"
  elif [ -e "$T/$path" ]; then place="$path"
  else
    case "$path" in *' '*) first="${path%%/*}"; printf '%s\n' "$tops" | grep -qxF "$first" || continue ;; esac
    place="$dir$path"
  fi
  # "30 Work/../40 Factory" is "40 Factory": fold each folder/.. away
  case "$place" in *..*) place="$(printf '%s' "$place" | sed -E ':a
s#(^|/)[^/]+/\.\.(/|$)#\1#
ta
s#/$##')" ;; esac
  [ -n "$place" ] || continue
  # every place a job's words point at is a right answer for that job, even when the place
  # itself is listed under an earlier job
  printf '%s\t%s\n' "$words" "$place" >> "$ALT"
  case "$seen" in *"|$place|"*) continue ;; esac
  seen="$seen$place|"
  n=$((n + 1))
  state="ok"; [ -e "$T/$place" ] || { state="missing"; missing=$((missing + 1)); }
  printf '%s\t%s\t%s\t%s\t%s\n' "$n" "$state" "$src" "$place" "$words" >> "$LIST"
done < "$RAW"

if [ -z "$WALK" ]; then
  echo "JOBS    $n jobs, $missing whose place does not exist"
  echo "        by source: entry $(awk -F'\t' '$3=="entry"' "$LIST" | wc -l | tr -d ' '), room $(awk -F'\t' '$3=="room"' "$LIST" | wc -l | tr -d ' '), outside $(awk -F'\t' '$3=="outside"' "$LIST" | wc -l | tr -d ' ')"
  awk -F'\t' '{ printf "  %-4s %-7s %-7s %s  <-  %s\n", $1, $2, $3, $4, $5 }' "$LIST"
  [ "$missing" -eq 0 ] && exit 0
  exit 1
fi

# --check: compare each landing with the job's place
tr -d '\r' < "$WALK" | awk -F'\t' -v list="$LIST" -v alt="$ALT" '
  BEGIN { while ((getline l < list) > 0) { split(l, a, "\t"); place[a[1]] = a[4]; words[a[1]] = a[5]; order[++m] = a[1] }
          while ((getline l < alt) > 0) { split(l, a, "\t"); alts[a[1]] = alts[a[1]] "\n" a[2] } }
  $1 ~ /^[0-9]+$/ { land[$1] = $2; reads[$1] = $3 }
  function norm(p) { gsub(/\\/, "/", p); sub(/^\.\//, "", p); sub(/\/$/, "", p); return tolower(p) }
  function lands(l, p,    parent) { p = norm(p); parent = p; sub(/\/[^\/]*$/, "", parent)
    return (l == p || index(l, p "/") == 1 || (l == parent && parent != p)) }
  END {
    for (i = 1; i <= m; i++) {
      j = order[i]; l = (j in land) ? norm(land[j]) : "none"
      hit = lands(l, place[j])
      if (!hit) { k = split(alts[words[j]], al, "\n"); for (x = 2; x <= k; x++) if (lands(l, al[x])) { hit = 1; break } }
      if (l == "none" || l == "") w = "stuck"
      else if (!hit) w = "wrong"
      else if (reads[j] + 0 <= 3) w = "pass"
      else if (reads[j] + 0 <= 5) w = "slow"
      else w = "lost"
      count[w]++
      if (w != "pass") printf "  %-5s job %s  %s  (landed: %s, %s reads; place: %s)\n", w, j, words[j], (j in land ? land[j] : "none"), (j in reads ? reads[j] : "-"), place[j]
    }
    printf "WALK    %d of %d jobs pass; slow %d, lost %d, wrong %d, stuck %d\n", count["pass"], m, count["slow"], count["lost"], count["wrong"], count["stuck"]
    exit (count["pass"] == m ? 0 : 1)
  }'

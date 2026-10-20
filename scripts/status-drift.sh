#!/usr/bin/env bash
# status-drift.sh - shakedown layer 1, question 8 (one truth). Finds an index that disagrees with the
# files it lists.
#
# Usage:  bash status-drift.sh <target folder>
#
# Reads only the files whose job is to route an agent: CLAUDE.md, AGENTS.md, CONTEXT.md, README.md,
# and any file whose front matter `kind:` says index or router. For every line there that names
# another Markdown file (in backticks) AND calls it approved, draft, unresolved or "do not use",
# compare that word with the named file's own `status:` line. Run records and history are not
# read (they describe a past state on purpose), and templates are skipped (blank forms stay draft).
# An index that says "do not use" for a file marked approved makes an agent refuse good work;
# one that says "approved" for a draft lets it use unchecked work. Status should live in one place.
#
# Exit 0 = every such line agrees with its file. Exit 1 = at least 1 disagreement. Exit 2 = bad args.

set -u
T="${1:?usage: bash status-drift.sh <target>}"
[ -d "$T" ] || { echo "status-drift: no folder at $T"; exit 2; }
T="$(cd "$T" && pwd)"
tmp="$(mktemp)"; out="$(mktemp)"
trap 'rm -f "$tmp" "$out"' EXIT

# 1 search for candidate lines: a backticked .md path and a status word on the same line.
(cd "$T" && grep -rniE --include='*.md' --exclude-dir=.git --exclude-dir=node_modules \
  '`[^`]*\.md`.*(approved|draft|unresolved|do not use)|(approved|draft|unresolved|do not use).*`[^`]*\.md`' . 2>/dev/null) > "$tmp"

is_router() {  # 0 when a file routes: a router by name, or front matter kind: index / router
  case "$(basename "$1")" in CLAUDE.md|AGENTS.md|CONTEXT.md|README.md) return 0 ;; esac
  awk 'NR==1 && $0!="---" {exit 1} NR>1 && $0=="---" {exit 1} /^kind:.*(index|router)/ {found=1; exit 0} END {exit !found}' "$1" 2>/dev/null
}

while IFS= read -r hit; do
  src="${hit%%:*}"; rest="${hit#*:}"; lineno="${rest%%:*}"; line="${rest#*:}"
  src="${src#./}"; dir="$(dirname "$src")"
  is_router "$T/$src" || continue
  low="$(printf '%s' "$line" | tr 'A-Z' 'a-z')"
  case "$low" in
    *"do not use"*|*unresolved*|*draft*|*"not approved"*|*unapproved*) want=draft ;;
    *approved*) want=approved ;;
    *) continue ;;
  esac
  # A line that states the rule for how status changes ("it starts as draft", "if it is not
  # approved, stop") is not a claim about the file today. Counted apart, never silently dropped.
  if printf '%s' "$low" | grep -qE '(starts? (as|in|out)|becomes?|makes it|from `?(status: )?draft`? to|until|unless|(^|[^a-z])(if|once)([^a-z]|$))'; then
    echo "RULE    $src:$lineno"; continue
  fi
  printf '%s\n' "$line" | grep -o '`[^`]*\.md`' | tr -d '`' | while IFS= read -r p; do
    for cand in "$p" "$dir/$p"; do
      [ -f "$T/$cand" ] || continue
      case "$cand" in *template*|*_templates/*) break ;; esac
      have="$(awk 'NR==1 && $0!="---" {exit} NR>1 && $0=="---" {exit} /^status:[ ]*/ {sub(/^status:[ ]*/,""); print; exit}' "$T/$cand")"
      [ -n "$have" ] || break
      case "$have" in approved) h=approved ;; *) h=draft ;; esac
      if [ "$h" = "$want" ]; then echo "AGREE"
      else echo "DRIFT   $src line $lineno says $cand is $want; $cand says status: $have"; fi
      break
    done
  done
done < "$tmp" > "$out"

sort -u "$out" -o "$out"
rules=$(grep -c '^RULE' "$out" || true)
checked=$(grep -vc '^RULE' "$out" || true)
drift=$(grep -c '^DRIFT' "$out" || true)
grep '^DRIFT' "$out" | head -40
echo "STATUS  $checked lines name a file and its status; $drift disagree with the file itself"
echo "        $rules more lines describe how a status changes (starts as, if, until), so they were not compared"
[ "$drift" -eq 0 ] && exit 0 || exit 1

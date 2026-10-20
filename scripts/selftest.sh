#!/usr/bin/env bash
# selftest.sh - proves every shakedown script on planted mistakes before anybody trusts it.
# The audit's own layer 3, turned on the audit.
#
# Usage:  bash selftest.sh          (from anywhere)
#
# Builds 2 throwaway workspaces in a temp folder:
#   BAD    a dead route, an unnamed folder, an unfilled slot, a key shaped string,
#          a settings file, a nested repo with unsaved work, a check script
#   CLEAN  the same shape with none of the mistakes
# Every script must fire on BAD and stay quiet on CLEAN. The fake key is built while
# the test runs, so no key shaped text is ever saved in this repo.
#
# Exit 0 = every assertion held. Exit 1 = a script is blind or jumpy.

set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
W="$(mktemp -d 2>/dev/null || mktemp -d -t shake)"
trap 'rm -rf "$W"' EXIT
fails=0; n=0
ok()   { n=$((n + 1)); echo "ok    $1"; }
bad()  { n=$((n + 1)); fails=$((fails + 1)); echo "WRONG $1"; }
expect_exit() { [ "$2" = "$3" ] && ok "$1 (exit $3)" || bad "$1 (wanted exit $3, got $2)"; }
expect_has()  { printf '%s' "$2" | grep -qF -- "$3" && ok "$1" || bad "$1 (missing: $3)"; }
expect_not()  { printf '%s' "$2" | grep -qF -- "$3" && bad "$1 (should not print: $3)" || ok "$1"; }

# ---------- BAD ----------
B="$W/bad"; mkdir -p "$B/docs" "$B/orphan" "$B/scripts" "$B/inner"
printf '# Bad\n\nRead `docs/a.md` first, then `docs/missing.md`. Checks live in `scripts/`.\n' > "$B/CLAUDE.md"
printf 'Notes are in `notes.md`. Name files like `[brand]-[slug].md`. The site is `example.com/page`.\n' >> "$B/CLAUDE.md"
printf 'Hello {{client name}}.\n' > "$B/docs/a.md"
printf 'Owner: {{your name}}\n' >> "$B/CLAUDE.md"
printf 'Hi {{name}}\n' > "$B/docs/page-template.html"
FAKE="sk-ant-$(printf 'A%.0s' $(seq 1 30))"
printf 'key = %s\n' "$FAKE" > "$B/docs/notes.md"
printf 'API_KEY=x\n' > "$B/.env"
printf 'x\n' > "$B/orphan/x.md"
printf '#!/usr/bin/env bash\nexit 0\n' > "$B/scripts/check-thing.sh"
(cd "$B/inner" && git init -q . && printf 'x\n' > draft.md)

out="$(bash "$HERE/routes.sh" "$B" 2>&1)"; rc=$?
expect_exit "routes fires on a dead route" "$rc" 1
expect_has  "routes counts 3 of 4 resolving" "$out" "3 of 4 named paths resolve"
expect_has  "routes names the dead route with its line" "$out" "dead    CLAUDE.md:3"
expect_has  "routes names the unnamed folder" "$out" "orphan  orphan/"
expect_has  "routes finds a short name where the short name lives" "$out" '`notes.md` is at docs/notes.md'
expect_not  "routes skips a naming example in brackets" "$out" "[brand]"
expect_not  "routes skips a web address" "$out" "example.com"

out="$(bash "$HERE/placeholders.sh" "$B" 2>&1)"; rc=$?
expect_exit "placeholders fires on a slot" "$rc" 1
expect_has  "placeholders names the entry file" "$out" "entry      1  CLAUDE.md"
expect_has  "placeholders counts a page draft as background" "$out" "docs/a.md"
expect_not  "placeholders leaves a file named template alone" "$out" "page-template.html"
mkdir -p "$W/doc"; printf '# Doc\n\nThe page fills `{{HEADLINE}}` for you.\n\n```\n{{EXAMPLE}}\n```\n' > "$W/doc/SKILL.md"
out="$(bash "$HERE/placeholders.sh" "$W/doc" 2>&1)"; rc=$?
expect_exit "placeholders leaves slots shown as code alone" "$rc" 0
mkdir -p "$W/sp"; printf '# Sp\n\nOwner: {{your name}}\n' > "$W/sp/README.md"; mkdir -p "$W/sp/my notes"; printf 'Hi {{x}}\n' > "$W/sp/my notes/draft page.md"
out="$(bash "$HERE/placeholders.sh" "$W/sp" 2>&1)"
expect_has  "placeholders reads a file with spaces in its name" "$out" "my notes/draft page.md"

out="$(bash "$HERE/secrets.sh" "$B" 2>&1)"; rc=$?
expect_exit "secrets fires on a key" "$rc" 1
expect_has  "secrets names the kind" "$out" "AI key (Anthropic)"
expect_has  "secrets lists the settings file" "$out" "ENVS    1 settings"
expect_not  "secrets never prints the full key" "$out" "$FAKE"

out="$(bash "$HERE/nested-repos.sh" "$B" 2>&1)"; rc=$?
expect_exit "nested-repos fires on unsaved work" "$rc" 1
expect_has  "nested-repos names the folder" "$out" "inner/"
expect_has  "nested-repos sees no online copy" "$out" "NO ONLINE COPY"

out="$(bash "$HERE/guards.sh" "$B" 2>&1)"; rc=$?
expect_exit "guards always lists" "$rc" 0
expect_has  "guards finds the check script" "$out" "check-thing.sh"
mkdir -p "$B/.claude"
printf '{"hooks":{"PreToolUse":[{"matcher":"Write","hooks":[{"type":"command","command":"bash scripts/check-thing.sh"}]}]}}' > "$B/.claude/settings.json"
out="$(HOME="$W/nohome" bash "$HERE/guards.sh" "$B" 2>&1)"
expect_has  "guards reads a hook out of the target's settings" "$out" "HOOKS   1 commands"

D="$W/scratch"
out="$(bash "$HERE/copy-target.sh" "$B" "$D" 2>&1)"; rc=$?
expect_exit "copy-target copies" "$rc" 0
[ -f "$D/docs/a.md" ] && ok "copy-target copied a nested file" || bad "copy-target lost docs/a.md"
out="$(bash "$HERE/copy-target.sh" "$B" "$B/inside" 2>&1)"; rc=$?
expect_exit "copy-target refuses a scratch inside the target" "$rc" 2
[ -d "$B/inside" ] && bad "copy-target left a folder inside the target" || ok "copy-target left the target untouched"

# ---------- FOLDER NAMES WITH SPACES (local change, see JEFF-CHANGES.md) ----------
S="$W/spaced"; mkdir -p "$S/20 Brain/learning"
printf '# Sp\n\nNotes live in `20 Brain/learning/`. Old notes in `20 Brain/gone/`. Run `node --test` first. Each trip gets `20 Brain/trips/{trip}/`.\n' > "$S/CLAUDE.md"
out="$(bash "$HERE/routes.sh" "$S" 2>&1)"; rc=$?
expect_exit "routes fires on a dead route with a space in it" "$rc" 1
expect_has  "routes counts a spaced path that resolves" "$out" "1 of 2 named paths resolve"
expect_has  "routes names the dead spaced route" "$out" '`20 Brain/gone/`'
expect_not  "routes still skips a command with a space" "$out" "node --test"
expect_not  "routes skips a {single-brace} placeholder" "$out" "{trip}"

# ---------- A KEY SAVED IN THE HISTORY ----------
K="$W/saved"; mkdir -p "$K"
printf 'key = %s\n' "$FAKE" > "$K/config.md"
(cd "$K" && git init -q . && git add config.md && git -c user.name=t -c user.email=t@t commit -q -m t)
out="$(bash "$HERE/secrets.sh" "$K" 2>&1)"; rc=$?
expect_exit "secrets fires on a saved key" "$rc" 1
expect_has  "secrets says the key is saved in the history" "$out" "1 of them SAVED IN THE HISTORY"

# status-drift: an index that calls an approved file "do not use"
mkdir -p "$B/places"
printf -- '---
kind: place-index
status: approved
---
# Places
- `places/harbour.md` - unresolved; do not use yet.
' > "$B/places/index.md"
printf -- '---
status: approved
---
# Harbour
' > "$B/places/harbour.md"
out="$(bash "$HERE/status-drift.sh" "$B" 2>&1)"; rc=$?
expect_exit "status-drift fires on an index that disagrees with its file" "$rc" 1
expect_has  "status-drift names the file and both statuses" "$out" "places/harbour.md is draft; places/harbour.md says status: approved"
printf -- '---
status: approved
---
# Log
At the time, `places/harbour.md` was still draft.
' > "$B/places/history-log.md"
out="$(bash "$HERE/status-drift.sh" "$B" 2>&1)"
expect_not  "status-drift ignores history in a non-router file" "$out" "history-log.md line"

# copy-target: a file that cannot land in the copy must stop the audit
CT="$W/ct-target"; CD="$W/ct-scratch"; mkdir -p "$CT/docs" "$CD/docs/b.md"; echo x > "$CD/docs/b.md/blocker"
printf 'a
' > "$CT/docs/a.md"; printf 'b
' > "$CT/docs/b.md"
out="$(bash "$HERE/copy-target.sh" "$CT" "$CD" 2>&1)"; rc=$?
expect_exit "copy-target fires when a file does not land" "$rc" 1
expect_has  "copy-target names the missing file" "$out" "MISSING docs/b.md"

# structure: an entry file that holds content, twins that drifted, a case clash, a thin contract
SB="$W/shape-bad"; mkdir -p "$SB/01_draft"
for i in $(seq 1 90); do echo "Rule line $i holds content that belongs on a shelf."; done > "$SB/CLAUDE.md"
echo "# Old entry" > "$SB/AGENTS.md"
echo "a" > "$SB/Notes.md"; echo "b" > "$SB/notes.md"
printf '# 01_draft\nWrite the draft.\n' > "$SB/01_draft/CONTEXT.md"
out="$(bash "$HERE/structure.sh" "$SB" 2>&1)"; rc=$?
expect_exit "structure fires on a broken shape" "$rc" 1
expect_has  "structure flags a long entry file" "$out" "ENTRY    CLAUDE.md is 90 lines"
expect_has  "structure flags drifted twins" "$out" "TWINS"
expect_has  "structure flags a thin contract" "$out" "CONTRACT 01_draft/CONTEXT.md does not name: inputs, outputs, a human check"
if [ -f "$SB/Notes.md" ] && [ -f "$SB/notes.md" ] && ! [ "$SB/Notes.md" -ef "$SB/notes.md" ]; then
  expect_has "structure flags names that differ only by capitals" "$out" "CASE"
else
  ok "structure case check skipped: this file system cannot hold 2 names that differ only by capitals"
fi

# load: a stage whose contract names 40 KB of text
LB="$W/load-bad"; mkdir -p "$LB/01_step" "$LB/ref"
echo "# Entry" > "$LB/CLAUDE.md"
head -c 40000 /dev/zero | tr '\0' 'x' > "$LB/ref/big.md"
printf '# 01_step\nRead `ref/big.md` first.\n' > "$LB/01_step/CONTEXT.md"
out="$(bash "$HERE/load.sh" "$LB" 2>&1)"; rc=$?
expect_exit "load fires on a stage over the limit" "$rc" 1
expect_has  "load names the heavy stage" "$out" "01_step/CONTEXT.md"

# structure: a file that calls itself a stage is judged as 1 even without a stage number
TS="$W/typed-stage"; mkdir -p "$TS/launch" "$TS/library"
printf '# Entry\nGo to `launch/` or `library/`.\n' > "$TS/CLAUDE.md"
printf -- '---\ntype: stage-contract\n---\n# Launch\nShip it.\n' > "$TS/launch/CONTEXT.md"
printf '# Library\nOne folder per year.\n' > "$TS/library/CONTEXT.md"
out="$(bash "$HERE/structure.sh" "$TS" 2>&1)"; rc=$?
expect_exit "structure judges a typed stage with no stage number" "$rc" 1
expect_has  "structure flags the thin typed stage" "$out" "CONTRACT launch/CONTEXT.md does not name"
expect_not  "structure leaves a room map alone" "$out" "CONTRACT library/CONTEXT.md"
expect_has  "structure counts the room map it did not judge" "$out" "1 CONTEXT.md files are room maps"

# load: a stage that READS a 40 KB rules file under its inputs
LI="$W/load-input"; mkdir -p "$LI/01_step" "$LI/ref"
echo "# Entry" > "$LI/CLAUDE.md"; head -c 40000 /dev/zero | tr '\0' 'x' > "$LI/ref/rules.md"
printf '# 01_step\n## Inputs\n- Every run: `ref/rules.md`\n## Outputs\n- A draft.\n' > "$LI/01_step/CONTEXT.md"
out="$(bash "$HERE/load.sh" "$LI" 2>&1)"; rc=$?
expect_exit "load counts a big file named under inputs" "$rc" 1

# repeats: 1 rule pasted into 3 contracts
RB="$W/repeat-bad"; mkdir -p "$RB/01_a" "$RB/02_b" "$RB/03_c"
for d in 01_a 02_b 03_c; do printf '# %s\nNever send anything to the builder without the owner reading it first.\n' "$d" > "$RB/$d/CONTEXT.md"; done
out="$(bash "$HERE/repeats.sh" "$RB" 2>&1)"; rc=$?
expect_exit "repeats fires on a rule written in 3 files" "$rc" 1
expect_has  "repeats names the files" "$out" "01_a/CONTEXT.md, 02_b/CONTEXT.md, 03_c/CONTEXT.md"

# umbrella: a root routing to 2 child workspaces; 1 child has a thin contract and a long entry file
UB="$W/umbrella-bad"; mkdir -p "$UB/alpha/01_step" "$UB/beta/01_step" "$UB/templates/kit"
printf '# Umbrella\nGo to `alpha/` or `beta/`. Blank kits are in `templates/`.\n' > "$UB/CLAUDE.md"
printf '# Alpha\nStart at `01_step/`.\n' > "$UB/alpha/CLAUDE.md"
printf '# Alpha map\nThis room map only routes to `01_step/`.\n' > "$UB/alpha/CONTEXT.md"
printf '# 01_step\n## Inputs\nThe brief.\n## Outputs\nA draft.\n## Human check\nThe owner reads it.\n' > "$UB/alpha/01_step/CONTEXT.md"
for i in $(seq 1 90); do echo "Beta rule line $i that belongs on a shelf."; done > "$UB/beta/CLAUDE.md"
printf '# 01_step\nDo the step.\n' > "$UB/beta/01_step/CONTEXT.md"
printf '# {{name}}\n' > "$UB/templates/kit/CLAUDE.md"
out="$(bash "$HERE/structure.sh" "$UB" 2>&1)"; rc=$?
expect_exit "structure at an umbrella root leaves child workspaces to their own run" "$rc" 0
expect_has  "structure says how many child files it left out" "$out" "sit inside child workspaces"
out="$(bash "$HERE/umbrella.sh" "$UB" 2>&1)"; rc=$?
expect_exit "umbrella fires when a child workspace has findings" "$rc" 1
expect_has  "umbrella finds 2 child workspaces, not the template" "$out" "UMBRELLA 2 child workspace(s)"
expect_has  "umbrella flags the long entry file inside the child" "$out" "ENTRY    CLAUDE.md is 90 lines"
expect_has  "umbrella flags the thin contract inside the child" "$out" "CONTRACT 01_step/CONTEXT.md does not name"
expect_not  "umbrella does not call a child's room map a thin contract" "$out" "CONTRACT alpha/CONTEXT.md"
printf '# Beta\nStart at `01_step/`.\n' > "$UB/beta/CLAUDE.md"
printf '# 01_step\n## Inputs\nThe brief.\n## Outputs\nA draft.\n## Human check\nThe owner reads it.\n' > "$UB/beta/01_step/CONTEXT.md"
out="$(bash "$HERE/umbrella.sh" "$UB" 2>&1)"; rc=$?
expect_exit "umbrella quiet once every child workspace is sound" "$rc" 0

# claims: an accepted record that lists a drift, and an approved file with a blank approval
CB="$W/claims-bad"; mkdir -p "$CB/runs/s1" "$CB/templates"
printf -- '---\nstatus: approved\nverdict: accepted\n---\n# Render\n1. Hair: `drifted: dark brown; expected: chestnut`\n2. Wings: holds\n' > "$CB/runs/s1/render.md"
printf -- '---\nstatus: approved\n---\n# Review\n## Yes\n- Answer:\n- Name:\n- Date:\n' > "$CB/runs/s1/review.md"
printf -- '---\nstatus: approved\nverdict: drifted\n---\n# Render 2\n1. Hair: `drifted: dark`\n' > "$CB/runs/s1/render2.md"
printf -- '---\nstatus: approved\n---\n- Answer:\n- Name:\n' > "$CB/templates/form.md"
out="$(bash "$HERE/claims.sh" "$CB" 2>&1)"; rc=$?
expect_exit "claims fires on done-claims the file contradicts" "$rc" 1
expect_has  "claims flags an accepted record with a drift" "$out" "CONTRADICT runs/s1/render.md"
expect_has  "claims flags an approval left blank" "$out" "EMPTY      runs/s1/review.md"
expect_not  "claims leaves an honest drifted verdict alone" "$out" "render2.md"
expect_not  "claims skips templates" "$out" "templates/form.md"

# ---------- CLEAN ----------
C="$W/clean"; mkdir -p "$C/docs"
printf '# Clean\n\nRead `docs/a.md` first. Everything lives in `docs/`.\n' > "$C/CLAUDE.md"
printf 'Hello Dana.\n' > "$C/docs/a.md"

out="$(bash "$HERE/routes.sh" "$C" 2>&1)"; rc=$?
expect_exit "routes quiet on a clean map" "$rc" 0
expect_has  "routes counts 2 of 2" "$out" "2 of 2 named paths resolve"
out="$(bash "$HERE/placeholders.sh" "$C" 2>&1)"; rc=$?
expect_exit "placeholders quiet on filled files" "$rc" 0
out="$(bash "$HERE/secrets.sh" "$C" 2>&1)"; rc=$?
expect_exit "secrets quiet with no keys" "$rc" 0
out="$(bash "$HERE/nested-repos.sh" "$C" 2>&1)"; rc=$?
expect_exit "nested-repos quiet with no nested repo" "$rc" 0

out="$(bash "$HERE/status-drift.sh" "$C" 2>&1)"; rc=$?
expect_exit "status-drift quiet when nothing disagrees" "$rc" 0
mkdir -p "$C/places"
printf -- '# Places
- `places/harbour.md` - approved.
' > "$C/places/README.md"
printf -- '---
status: approved
---
# Harbour
' > "$C/places/harbour.md"
out="$(bash "$HERE/status-drift.sh" "$C" 2>&1)"; rc=$?
expect_exit "status-drift quiet when the index agrees" "$rc" 0
printf -- '# Places
- `places/harbour.md` starts as `status: draft`. Only the owner'"'"'s yes makes it approved.
- If `places/harbour.md` is not approved, stop and ask.
' >> "$C/places/README.md"
out="$(bash "$HERE/status-drift.sh" "$C" 2>&1)"; rc=$?
expect_exit "status-drift quiet on lines that state the status rule" "$rc" 0
expect_has  "status-drift counts the rule lines it did not compare" "$out" "2 more lines describe how a status changes"
printf '# Clean\n\nRead `docs/a.md` first. Everything lives in `docs/`. Each run writes `docs/run-N.md`. Places live in `places/`.\nLessons go in `courses/NN-name/lesson.md`. Fonts come from `@remotion/google-fonts`; the old copy is at `C:/GitHub/other/`; reruns add `-round-2.md`; outputs sit in `…/output/`.\n' > "$C/CLAUDE.md"
out="$(bash "$HERE/routes.sh" "$C" 2>&1)"; rc=$?
expect_exit "routes quiet on patterns, packages, drive paths, fragments and ellipses" "$rc" 0
expect_has  "routes counts the patterns it skipped" "$out" "2 naming patterns"
out="$(bash "$HERE/copy-target.sh" "$C" "$W/clean-copy" 2>&1)"; rc=$?
expect_exit "copy-target quiet on a full copy" "$rc" 0
expect_has  "copy-target confirms every file landed" "$out" "listed files landed"

SC="$W/shape-clean"; mkdir -p "$SC/01_draft"
printf '# Entry\nGo to `01_draft/` for drafting.\n' > "$SC/CLAUDE.md"; cp "$SC/CLAUDE.md" "$SC/AGENTS.md"
printf '# 01_draft\n## Inputs\nThe brief.\n## Outputs\nA draft.\n## Human check\nThe owner reads it.\n' > "$SC/01_draft/CONTEXT.md"
out="$(bash "$HERE/structure.sh" "$SC" 2>&1)"; rc=$?
expect_exit "structure quiet on a sound shape" "$rc" 0
out="$(bash "$HERE/load.sh" "$SC" 2>&1)"; rc=$?
expect_exit "load quiet on a light stage" "$rc" 0
for d in 01_a 02_b; do mkdir -p "$SC/$d"; printf '# %s\nSee the rules in the entry file.\n' "$d" > "$SC/$d/CONTEXT.md"; done
out="$(bash "$HERE/repeats.sh" "$SC" 2>&1)"; rc=$?
expect_exit "repeats quiet when each rule has 1 home (twins ignored)" "$rc" 0
LO="$W/load-output"; mkdir -p "$LO/01_step"
echo "# Entry" > "$LO/CLAUDE.md"; head -c 40000 /dev/zero | tr '\0' 'x' > "$LO/01_step/map.html"
printf '# 01_step\nDo NOT load `map.html` to change it.\n## Inputs\n- The brief.\n## Outputs\n- `map.html`, rebuilt.\n' > "$LO/01_step/CONTEXT.md"
out="$(bash "$HERE/load.sh" "$LO" 2>&1)"; rc=$?
expect_exit "load quiet on a big file the stage writes or must not load" "$rc" 0
RH="$W/repeat-heading"; mkdir -p "$RH/01_a" "$RH/02_b" "$RH/03_c"
printf '# 01_a\n## What must never happen here at any stage of the work\nThe AI never guesses a number.\n' > "$RH/01_a/CONTEXT.md"
printf '# 02_b\n## What must never happen here at any stage of the work\nThe AI never makes a call for the owner.\n' > "$RH/02_b/CONTEXT.md"
printf '# 03_c\n## What must never happen here at any stage of the work\nThe AI never contacts the builder.\n' > "$RH/03_c/CONTEXT.md"
out="$(bash "$HERE/repeats.sh" "$RH" 2>&1)"; rc=$?
expect_exit "repeats quiet when 3 files share only a heading" "$rc" 0

mkdir -p "$C/runs/s1"
printf -- '---\nstatus: approved\nverdict: accepted\n---\n# Render\n1. Hair: holds\n## Yes\n- Answer: yes\n- Name: Dana\n- Date: 2026-10-19\n' > "$C/runs/s1/render.md"
out="$(bash "$HERE/claims.sh" "$C" 2>&1)"; rc=$?
expect_exit "claims quiet when done-claims match their files" "$rc" 0

echo
if [ "$fails" -eq 0 ]; then echo "selftest: $n of $n held. Every script fires on the mistake and stays quiet on the clean case."; exit 0; fi
echo "selftest: $fails of $n WRONG. Do not trust the audit until this passes."; exit 1

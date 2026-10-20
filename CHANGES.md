# Changes from the original

Built on RyMac's 4R audit (github.com/oathdriven/rymac-4r-icm-audit, MIT, see LICENSE), and
renamed the ICM Shakedown (`icm-shakedown`) so it is not mistaken for RyMac's own product.
Credit to RyMac is kept in SKILL.md, the README and the footer of every report.

## Layer 1 grew from 8 questions to 11, each backed by a script
- `status-drift.sh` (question 8): an index or router line that calls a file draft, approved or
  "do not use" while the file's own `status:` says otherwise. Lines that state the status rule
  ("starts as draft", "if it is not approved") are counted apart, not compared.
- `structure.sh` (question 9): entry file over 80 lines, CLAUDE.md and AGENTS.md that disagree,
  file names that differ only by capitals, and stage contracts missing inputs, outputs or a
  human check.
- `load.sh` (question 10): rough tokens each stage makes the agent read (entry + contract + named
  text files); flags any stage over 8,000.
- `repeats.sh` (question 11): the same 8-word passage in 3 or more instruction files (headings
  ignored, and links or paths to a shared file ignored: a pointer is how a rule keeps 1
  home), so each rule has 1 home.

## Layer 3
- `claims.sh`: files that say done (`status: approved`, `verdict: accepted`) while their own body
  lists a drift or failure, or leaves the approval blank.

## Safer setup
- `copy-target.sh` now confirms every file landed in the scratch copy and stops the audit if any
  did not (Windows unzip and long paths can drop files silently).
- `routes.sh` skips naming patterns like `read-back-N.md` instead of calling them dead.

## Umbrella ICMs
- `umbrella.sh`: for a root that routes to child workspaces (each with its own CLAUDE.md or
  AGENTS.md), runs routes, structure and load once per workspace, each judged by its own entry
  file, and prints 1 table. Templates are not counted as workspaces.
- `structure.sh` and `load.sh` leave a child workspace's files to its own run and say how many
  they left out, so a child's room map is never called a thin stage contract.
- Stage or room: a CONTEXT.md is judged as a stage contract when its front matter `type:` says
  stage, or, with no `type:`, when its folder carries a stage number (`01_draft`, `02 read`).
  Other CONTEXT.md files are room maps: counted, not judged.
- `load.sh` counts what a stage READS: files named in its intro or input section. Files it
  writes, or says not to load, no longer inflate the count (a 6 MB generated map had made 1 stage
  read "3.3 million tokens").
- `dist`, `build`, `.next` and backup folders are copies, not workspaces.
- About 4 times faster on Windows: the per-path checks use bash's own matching instead of
  starting a helper program for every path.

## Proof
`bash scripts/selftest.sh` plants a mistake and a clean case for every script: 86 of 86 hold.
Every new check was also run on 3 real ICM workspaces before release (including an umbrella with
about 70 child workspaces); each finding was read by hand and the false alarms were fixed.

The report page uses the AI the vL Way look; the original look is kept as
`templates/report-rymac.html.orig`.

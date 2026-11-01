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

## Layer 2: route every job, run 2
- `jobs.sh`: lists every job a stranger could be sent on (each routing row of the entry file and
  of every top folder's router, plus every path into the workspace that the owner's global
  instructions and skills name), and marks any whose place does not exist. With `--check`, it
  scores a walker's landings: pass, slow, lost, wrong or stuck.
- Layer 2 now walks the route of every job with 1 cheap agent, then runs 2 jobs end to end: the
  most used and the next in a rotation kept in the record. 1 full run per audit missed every
  job it never touched; a job named only in the owner's global instructions had no route at all.

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

## Release 1: one zip a stranger can install (2026-11-01)
- `START-HERE.md`: install, a first run, and how to check the report, in plain words.
- `demo/summit-coat/`: a made-up painting company with 8 planted problems, and
  `demo/ANSWERS.md` beside it (outside the audit's reach) to check the report against.
- `copy-target.sh --check`: the copy saves a checksum list beside itself; before the report,
  the check names every file changed, new or gone in the target since the copy. Found on a
  real audit, where the owner's other chat edited 15 files mid-run and a full run worked from
  the old versions.
- `jobs.sh`: a route that leaves the workspace on purpose (`../../other-venture/`) is marked
  `outside`, not `missing`; the `../` fold no longer treats `..` as a folder name. A table
  keyed by a number (`| 7 | Build Anything |`) words the job as "7 Build Anything", not "7".
  A skill that only names a common folder (`templates/`) is no longer read as a job in the
  workspace being audited.
- `placeholders.sh`: `[YOUR ...]` slots were never counted, because `awk -v` stripped the
  backslashes in the pattern. Found by the demo.
- Removed the paths that only resolved on the author's machine.

## Proof
`bash scripts/selftest.sh` plants a mistake and a clean case for every script: 117 of 117 hold.
Every new check was also run on 3 real ICM workspaces before release (including an umbrella with
about 70 child workspaces); each finding was read by hand and the false alarms were fixed.

The report page uses the AI the vL Way look. The original RyMac look stays in the GitHub repo
as `templates/report-rymac.html.orig`; the zip leaves it out.

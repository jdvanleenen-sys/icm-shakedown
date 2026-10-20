# ICM Shakedown: Read, Run, Reality, Report

**Find out if your ICM folder system actually works, not just if the folders look right.**

Most audits read your files and tell you what the files say.

The shakedown does that, then has a fresh AI with no memory do 1 real job in a copy of your
workspace.

Then the shakedown plants real mistakes to see if your guards catch them.

Then you get a plain English report with the 3 fixes that matter most, each 1 with the file
and the line.

Your workspace is never changed. Not 1 byte. Everything runs in a throwaway copy.

---

## The 4 layers

1. **Read.** 11 questions about the structure. Do your routes go anywhere? Is every folder
   on the map? Is anything unsaved? Are there keys sitting in files? 10 of the 11 are
   answered by a script, not an opinion. The newest 4 check the ICM shape itself: one
   status per file, a short entry file, a light read per stage, each rule in 1 place.
2. **Run.** A fresh AI that has never seen your workspace does 1 real job, cold. The AI
   reports every place it got stuck, with the file and line that caused it.
3. **Reality.** Your 3 biggest promises get tested. The audit plants a mistake each guard
   should catch and a clean case each guard should pass. Then the audit checks 3 lines
   that say "done" against the thing each 1 describes.
4. **Report.** The verdict in 1 sentence, the counts, the 3 fixes ranked by what each would
   cost you, and what the audit could not see.

No made up score out of 100. Only numbers that were counted.

---

## Install the ICM Shakedown

1. Put this repo in your Claude Code skills folder as a folder named `icm-shakedown`:
   - Mac or Linux: `git clone https://github.com/jdvanleenen-sys/icm-shakedown ~/.claude/skills/icm-shakedown`
   - Windows (Git Bash): `git clone https://github.com/jdvanleenen-sys/icm-shakedown ~/.claude/skills/icm-shakedown`
   - No git: use **Code, Download ZIP** on GitHub, unzip, and rename the folder to `icm-shakedown`
     inside `skills` (`C:\Users\YOUR-NAME\.claude\skills\` on Windows).
3. Restart Claude Code.
4. Open Claude Code in the folder you want audited and type:

**"shake down my ICM"**

That's the trigger. **"shakedown"** and **"audit my ICM"** work too.

**If the audit doesn't start:** check that the folder sits directly inside `skills`, not in a
second folder inside `skills`.

## What you need

- Claude Code
- bash, which Mac and Linux already have. On Windows, bash comes with Git for Windows.
- git and python make 2 of the checks sharper. The audit still runs without them.

## Check the audit itself first

The shakedown tests your guards, so the audit tests its own scripts too. Run this once after
you install:

**"bash ~/.claude/skills/icm-shakedown/scripts/selftest.sh"**

The self-test builds a workspace full of planted mistakes and a clean workspace, then checks
that every script catches the mistakes and stays quiet on the clean 1. You want to see
every line held (`86 of 86 held` on this version).

## Umbrella ICMs

If your workspace is a root that routes to several child workspaces, each with its own
`CLAUDE.md`, the audit sees that and runs `scripts/umbrella.sh`: routes, shape and read load are
checked once at the root and once inside every child, each judged by its own entry file. The
checks that read the whole tree (status drift, rules copied into 3 places, keys, done-claims) run
once at the root, so a rule pasted into 3 child workspaces still shows up.

---

## Where the results go

Every audit writes a record, so the next audit can show you what changed.

- If your `CLAUDE.md` or `CONTEXT.md` names a home for shakedowns, the record goes there.
- If not, the record goes in a folder called `shakedowns` next to your workspace, never
  inside your workspace.

Run a shakedown every week and the report tells you if you're getting better or drifting.

---

## Credit

ICM, Interpretable Context Methodology, is Jake Van Clief and David McDermott's method:
https://arxiv.org/abs/2603.16021

The ICM Shakedown is built by Jeff Van Leenen (AI the vL Way) on RyMac's 4R audit: the 4 layers
(Read, Run, Reality, Report) and the 3 promises are RyMac's, from
[filesnfolders.com](https://filesnfolders.com), original at
https://github.com/oathdriven/rymac-4r-icm-audit (MIT). 2 ideas in the Read layer come from
Jake's own ICM audit, written fresh here: a rule that lives only in a sentence, and an example
that breaks the rule printed beside the example.

Added in this version: 3 more Read questions on the ICM shape, done-claim and copy checks,
umbrella mode, and the vL report look. See `CHANGES.md`.

MIT license: free to use, share and change.

# ICM Shakedown: start here

## What you will finish

A plain English report on your folder system: what works, where a new AI gets stuck, which of
your rules nothing actually enforces, and the 3 fixes worth making first, each with the file and
the line. Your folders are never changed. The audit works on a copy.

Your first run is on Summit Coat, a made-up painting company that comes in this zip with 8
problems planted in it. Then you run it on your own folders.

## What you need

- **Claude Code.** It comes with every paid Claude plan (Pro and up). The free plan does not
  include it. Get it at https://claude.com/download
- **On a Windows PC: Git for Windows**, from https://git-scm.com/download/win. It brings
  the "bash" the audit's checks run in. A Mac already has it. Not sure you have it? Ask Claude
  Code "is git installed?" and it will check.
- **A folder system to audit**, with a `CLAUDE.md` file at the top. If you built your business
  folder in the course, that is the one.
- About 15 minutes for the demo, longer for a big workspace.

## Before you start

- **What it reads:** the folder you point it at, plus your Claude Code settings and skills, to
  find the jobs your AI gets sent on.
- **What it writes:** a throwaway copy in a temporary folder, and the report, in a folder
  named `shakedowns` next to the folder you audit, never inside it.
- **What leaves your computer:** what Claude reads goes to Claude, the same as any Claude Code
  session. The audit sends nothing to anyone else and posts nothing.
- **What it uses from your plan:** the audit starts 3 fresh AIs that read your files cold (up
  to 5 on a big workspace), and that uses up your plan's limit faster than a normal chat. On a
  1,500-file workspace the fresh AIs used more than 550,000 tokens; on the demo, about 260,000.
  On the Pro plan, run a big audit when you have nothing else urgent to do in Claude that day.

## Do it now

1. **Unzip** this file. You get a folder named `icm-shakedown`.
2. **Install it.** Open Claude Code in the folder that holds `icm-shakedown`. In the Claude
   desktop app, open Code and choose that folder. In a terminal, go to that folder and type
   `claude`. Then type:
   `install the icm-shakedown skill from this folder into my skills folder, then check it`
   Claude copies it to your skills folder (`.claude/skills/` in your home folder) and runs its
   self-test. You want to see `117 of 117 held`.
3. **Close Claude Code and open it again**, so it sees the new skill.
4. **Run the demo.** Type: `shake down the Summit Coat demo`
   Claude copies the demo into your Documents folder, audits that copy, and tells you the full
   path of the report.
5. **Run it on your own folders.** Open Claude Code in your own workspace and type:
   `shake down my ICM`

Before it saves the report, the audit tells you where the `shakedowns` folder will go and asks.
Say yes.

## Check it

1. Open `icm-shakedown/demo/ANSWERS.md`, after the demo run, not before. It lists the 8
   problems planted in Summit Coat. Your report should name all 8.
2. For every finding in a report on your own folders, open the file it names, at the line it
   names. If the line does not say what the report says, the finding is wrong. Tell us in the
   community.

## If it goes wrong

- **The audit does not start:** the `icm-shakedown` folder must sit directly inside `skills`,
  not inside a second folder. Close Claude Code and open it again.
- **"bash: command not found" on Windows:** install Git for Windows, then open Claude Code again.
- **The self-test says WRONG, and "Filename too long" shows above it:** your folders are nested
  too deep for Windows, not a fault in the audit. Unzip to a short folder, such as `C:\shake`,
  and install from there.
- **The self-test says WRONG for any other reason:** do not trust the audit yet. Post the WRONG
  lines in the community.
- **"INCOMPLETE" during the copy:** a path was too long for Windows. Ask Claude to use a shorter
  scratch folder, such as `C:\shake`.

## Who made it

Built by Jeff Van Leenen (AI the vL Way) on RyMac's 4R audit (filesnfolders.com, MIT licence).
ICM, the folder method it checks, is Jake Van Clief and David McDermott's:
https://arxiv.org/abs/2603.16021. Free to use, share and change; see `LICENSE`.

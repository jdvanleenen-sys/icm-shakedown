# Layer 2, RUN: route every job, run 2

Layer 1 says what the workspace claims. Layer 2 finds out whether a stranger can use the
workspace. The stranger is a fresh agent with no memory of the owner, the auditor, or the
work. Layer 2 has 2 parts: every job gets a route walk, and 2 jobs get run end to end.

Why both: running 1 job end to end misses every job the run never touched, and a workspace
breaks most often on the job nobody tried this month. Running every job end to end costs
dozens of agents and needs a made-up input for each. Finding the route is cheap, and a
wrong route is where most stuck points start.

## Part A: route every job

### List the jobs

`bash scripts/jobs.sh <target> > <scratch>/jobs.txt`

The list holds every row of the entry file's tables, every row of each top folder's own
router, and every path into the workspace that the owner's global instructions and skills
name. That last kind matters most: those are the jobs other agents will be sent on, and no
routing table may name them. A job marked `missing` is already a finding: the map sends work
to nothing.

Run it on the target itself: it only reads. On the scratch copy it would lose the jobs whose
outside paths name the target by its folder name, and call empty folders missing (the copy
holds files, not empty folders). The outside files (global instructions, skills) are read
where they live; nothing is changed. The walker still walks the scratch copy.

### Hand the walk over

Give 1 fresh agent the prompt below, with the job words only, numbered as in the list. Never
the places: the walker must find them. Over 40 jobs, split the list across up to 3 agents,
each with the same prompt and its own part of the list.

```
You are walking a folder system cold. You have never seen it. Everything you need
must come from its own files.

The folder: <scratch copy path>

For each job below, find the 1 file or folder where that work starts. Do not do the
work. Start every job again from the entry file (CLAUDE.md or AGENTS.md), and count
every file you open for that job, the entry file included. Listing a folder is not
a read. Stop a job after 8 reads and answer none.

Rules:
- Work ONLY inside that folder. Write nothing anywhere.
- Never fix the folder system itself.

Answer with 1 line per job, tab separated, nothing else on the line:
<job number> TAB <path you landed on, relative to the folder, or none> TAB <reads>

Then, under the lines, every place you had to guess, with the file and line.

The jobs:
<numbered job words from jobs.txt>
```

### Check the walk

Save the walker's lines to `<scratch>/walk.tsv`, then:
`bash scripts/jobs.sh <target> --check <scratch>/walk.tsv`

Each job gets 1 word: `pass` (the place, in 3 reads or fewer), `slow` (4 or 5), `lost` (more
than 5), `wrong` (landed elsewhere), `stuck` (no answer). Every job that is not a pass is a
finding. Before it goes in the report, open the router line the walker should have followed
and say which it is: the map is wrong (a dead or missing row), the map is thin (no row for
this job), or the walker misread (the row was there and plain). Only the first 2 are the
owner's findings; count the third apart.

## Part B: run 2 jobs end to end

### Pick the 2 jobs

1. **The job the owner does most**, from the entry file. Prefer a job that ends in a file,
   because a file can be checked.
2. **The next job in the rotation:** the first job in `jobs.txt` that no earlier record
   names under "Jobs run end to end". Skip a job that only works by touching something live
   (sending email, posting, paying); write it under "could not see" and take the next.

Write both in the record under "Jobs run end to end", so the next audit takes the next 1.
Over enough audits, every job gets a full run.

If a job needs input (a transcript, a brief, a customer), write a small made-up 1 and say
in the report that it was made up.

### Hand each job over

1 fresh agent per job (a subagent with no shared context, or a new session), each with the
prompt below and nothing else. No hints about where things live.

```
You are walking a folder system cold. You have never seen it. Everything you need
must come from its own files.

The folder: <scratch copy path>

The job: <1 sentence, the way the owner would say it>
The input, if the job needs 1: <the made up input>

Rules:
- Work ONLY inside that folder. Write nothing anywhere else.
- Do not use online tools, connectors, email or the web.
- Never fix the folder system itself. If something is broken or unclear, write it
  down as a finding and carry on the way a new person would.
- Start at the entry file (CLAUDE.md or AGENTS.md) and follow what the files say.

Report, evidence only, no advice:
1. Did the job get done? Yes, partly, or no. If a file came out, give its path.
2. How many files you read before you knew where to go.
3. Every place you got stuck or had to guess, each with the file and line that caused it.
4. Every rule you found that you could not follow, and why.
```

### Read what comes back

- **Done, with a file:** open the file. Check the file against the rules the workspace
  states for that kind of output. A job done wrong is worse than a job not done.
- **Files read before knowing where to go:** the entry file plus 2 more is a workspace that
  routes well. Past 5, the map is not doing its job.
- **Each stuck point** becomes a finding with the file and line the agent gave. Check the
  line yourself before it goes in the report. An agent can misread. Say whether the folders
  caused it or the made-up input did; count only the first as the owner's.

## If the target is too big to copy

Copy the entry files and the homes the jobs route to, and say in the report that the walk
ran on a slice.

# Shakedown: {{target name}}, {{YYYY-MM-DD}}

Target: `{{target path}}` · Scratch copy: {{files copied}} files, {{files left out}} left out
Results home: `{{results home}}` (left out of every layer) · Last audit: {{date or "none, this is the baseline"}}

## The verdict
{{1 sentence, plain words: what works and what does not}}

## The counts (each 1 counted, never estimated)
| Count | Now | Last time |
|---|---|---|
| Routes that resolve | {{n of m}} | {{or -}} |
| Top folders named in the entry files | {{n of m}} | |
| Lines with an unfilled slot, outside templates | {{n}} | |
| Folders with their own save history at risk | {{n}} | |
| Key shaped strings / settings files with keys | {{n}} / {{n}} | |
| Promises tested / guards proven | {{n}} / {{n}} | |
| Jobs routed: pass / slow / lost / wrong / stuck, of all | {{n}} / {{n}} / {{n}} / {{n}} / {{n}}, of {{n}} | |
| Jobs whose place does not exist | {{n}} | |
| Full runs done (of 2) | {{n}} | |
| Files read before knowing where to go, each full run | {{n}}, {{n}} | |
| Places the full runs got stuck (caused by the folders) | {{n}} | |
| Claims that say done, still true | {{n of 3}} | |
| Index lines that disagree with their file | {{n}} | |
| Shape findings (entry, twins, case, contracts) | {{n}} | |
| Stages over the read budget / heaviest stage in tokens | {{n}} / {{n}} | |
| Rules written in 3 or more files | {{n}} | |
| Files that say done but contradict themselves | {{n}} | |

## The 3 fixes, ranked by what each would cost if left alone
1. **{{fix}}** · `{{file}}:{{line}}` · {{why, in business words}}
2. **{{fix}}** · `{{file}}:{{line}}` · {{why}}
3. **{{fix}}** · `{{file}}:{{line}}` · {{why}}

## Layer 1, READ
{{1 line per question, 1 to 11, each with its evidence}}

## Layer 2, RUN
Route walk: {{n}} jobs from `jobs.sh` ({{n}} entry, {{n}} room, {{n}} outside), {{n}} walker(s).
{{every job that is not a pass: its word, the job, where the walker landed, and whether the map is wrong, the map is thin, or the walker misread}}

Jobs run end to end (the rotation reads this line):
1. Most used: {{the job, in the owner's words}} · Input: {{real or made up}}
2. Rotation: {{the job}} · Input: {{real or made up}}
{{each stranger's report, stuck points quoted with file and line}}

## Layer 3, REALITY
| Promise | Guard | Planted mistake | Clean case | Word |
|---|---|---|---|---|
| {{promise}} | {{guard or none}} | {{fired / quiet}} | {{passed / fired}} | {{proven, blind, jumpy, missing}} |

Claims checked:
{{claim, where the claim sits, what was checked, still true or not}}

## The old audit you were doing, next to the shakedown
| Today's finding | The old audit (reads files only) | The shakedown |
|---|---|---|
| {{finding}} | {{finds this / sees the check exists / cannot see / not checked}} | {{how the shakedown found it}} |

## What the audit could not see
{{always at least 1 line}}

## Since last time
{{better, worse, or same per count, or "first audit, the baseline is set"}}

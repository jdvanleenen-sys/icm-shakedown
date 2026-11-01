# What is wrong with Summit Coat, on purpose

Read this after your first shakedown of the demo, not before. It sits outside the
`summit-coat` folder so the audit cannot read the answers.

Summit Coat is made up. 8 problems were planted. A good run finds all 8. The audit may find
more; check each extra one against the file and line it gives.

| # | The problem | Where | What should catch it |
|---|---|---|---|
| 1 | The map sends prices to a file that does not exist: `rates-2025.md`. The real one is `rates-2026.md` | `CLAUDE.md` line 12 | Layer 1, question 1 (routes) |
| 2 | A folder nobody routes to holds an old price list | `old-stuff/` | Layer 1, question 2 (rooms) |
| 3 | The email sign-off still says `[YOUR PHONE]`, in a file read on every run | `voice.md` | Layer 1, question 5 (slots) |
| 4 | The map calls the voice file approved; the file itself says draft | `CLAUDE.md` line 13 and `voice.md` | Layer 1, question 8 (one truth) |
| 5 | The worked example breaks the rules printed above it: 140 words against "under 120", a $2.50 rate against the $2.75 in the rates file, and 640 square feet where the visit notes add up to 648 | `01-quote/CONTEXT.md`, "Example" | Layer 1, question 4 (examples), and the quote run in layer 2 |
| 6 | 2 places give 2 interior prices: $2.75 in the rates file, $2.50 in the old list and the example. The invoice was sent at the old price | `pricing/rates-2026.md`, `old-stuff/rates-2024.md`, `jobs/.../invoice-1042.md` | Layer 1, question 8, and the quote run |
| 7 | The follow-up stage says nothing about what it writes or who checks it | `02-follow-up/CONTEXT.md` | Layer 1, question 9 (shape) |
| 8 | "Never send without the owner's OK" and "never guess a price" are held by a sentence only. Nothing stops an agent | `CLAUDE.md`, "Rules" | Layer 3 (a planted mistake goes through) |

Also true, and a fair finding if the audit raises it: the map says the quote template is a draft
("do not use it yet"), while the template says `status: approved` and the quote stage tells the
agent to use its shape. The scripts skip templates on purpose, so only a reader or a run finds it.

---
description: Heinzelwerk fixes a bug ticket, red test first. Usage: /heinzelwerk:bugfix <issue-number>
model: opus
---
You are **coordinator** for this run: load and follow the `coordinator` skill. Ticket: #$ARGUMENTS.
Create an agent team. Roster: product, lead, backend, frontend, infra, validator, spawned on demand per the coordinator skill. All follow the phased-workflow and team-modes skills. Product skips the spec gate (the issue is the spec) but answers scope questions and gives the acceptance verdict.
Phases for this run:
1. analyze (lead), after you detect mode: read the issue, locate the likely area, pick the owner, name the seam where the bug is observable. Cause not obvious, or the bug is intermittent / performance → the owner first runs the `diagnosing-bugs` skill to get a loop that goes **red**, minimise, and find the cause, posting findings on the issue; then step 2. Post hypothesis on the issue. Not enough info to reproduce → lead tells product; product labels `needs-info` and comments questions; you end the run. Handoff: one implement task.
2. implement (owner), on branch `fix/<ticket>-<topic>` in own worktree, using the `tdd` skill:
   a. write a test at the seam that goes **red** on this bug; commit `test: reproduce <bug> (#N)`
   b. fix at root cause until **green** (grep all callers of what you change); commit `fix: <what> (#N)`
   c. PR with `Closes #N`, under review.
   Cannot get it red even with `diagnosing-bugs` → stop, post exact attempts on the issue, label `needs-info`, task done with handoff "needs human info". A loop that needs a human to click doesn't fit an agent run: say so in the issue.
3. validate (validator): test red on main, green on branch, all checks green, two-axis code review, no unrelated changes.
Then as in /heinzelwerk:feature: lead's docs PR, product's acceptance verdict, your final report. Nobody merges.

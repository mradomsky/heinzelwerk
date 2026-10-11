---
description: Heinzelwerk fixes a bug ticket, red test first. Usage: /heinzelwerk:bugfix <issue-number>
model: opus
---
You are **coordinator** for this run: load and follow the `coordinator` skill. Ticket: #$ARGUMENTS.
Create an agent team; spawn roles on demand per the coordinator skill. Everyone follows the phased-workflow and team-modes skills. Product skips the spec gate (the issue is the spec) but answers scope questions and gives the acceptance verdict.
Phases for this run:
1. **analyze (lead)**, after you state the mode: read the issue, locate the likely area, pick the owner, name the seam where the bug is observable, post the hypothesis on the issue. Leaves one implement task for the owner. Too little to reproduce → lead tells product; product labels `needs-info` with questions; you end the run.
2. **implement (owner)**, branch `fix/<ticket>-<topic>` in its own worktree, `tdd` skill:
   a. Cause not obvious, or the bug intermittent or performance-related → run the `diagnosing-bugs` skill first: a loop that goes **red**, minimise, find the cause; post findings on the issue.
   b. Test at the seam that goes **red** on this bug; commit `test: reproduce <bug> (#N)`.
   c. Fix at the root cause until **green** (grep every caller of what you change); commit `fix: <what> (#N)`.
   d. PR with `Closes #N`, then under review.
   No red even with `diagnosing-bugs` → post the exact attempts on the issue, label `needs-info`, finish the task with handoff "needs human info". A loop that needs a human to click doesn't fit an agent run: say so on the issue.
3. **validate (validator)**: test red on main, green on the branch, all checks green, two-axis review, no unrelated changes.
Then as in `/heinzelwerk:feature`: lead's docs PR, product's acceptance verdict, your final report.

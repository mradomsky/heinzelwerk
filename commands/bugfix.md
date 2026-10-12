---
description: Heinzelwerk fixes a bug ticket, red test first. Start the session with --model opus. Usage: /heinzelwerk:bugfix <issue-number>
model: opus
---
You are **coordinator** for this run: load and follow the `heinzelwerk:coordinator` skill. Ticket: #$ARGUMENTS.
Precondition: the issue is labelled `ready-for-agent`. Label missing → ask the user before starting.
Create an agent team; spawn roles on demand per the `heinzelwerk:coordinator` skill. Product skips the spec gate (the issue is the spec) but answers scope questions and gives the acceptance verdict. Your spawn prompts for tech-lead, the owner, and validator carry the phase list below verbatim.
Phases for this run:
1. **analyze (tech-lead)**, after you state the mode: read the issue, locate the likely area, pick the owner, name the seam where the bug is observable, post the hypothesis on the issue. Leaves one task `#N <role> implement: <bug>` with the seam in its details. Too little to reproduce → tech-lead tells product; product labels `needs-info` with questions; you end the run.
2. **implement (owner)**, branch `fix/<ticket>-<topic>` in its own worktree, `heinzelwerk:tdd` skill:
   a. Cause not obvious, or the bug intermittent or performance-related → run the `heinzelwerk:diagnosing-bugs` skill first: a loop that goes **red**, minimise, find the cause; post findings on the issue.
   b. Test at the seam that goes **red** on this bug; commit `test: reproduce <bug> (#N)`.
   c. Fix at the root cause until **green** (grep every caller of what you change); commit `fix: <what> (#N)`.
   d. PR with `Closes #N`; done note, complete the task, create `#N validate <role>: <bug>`.
   No red even with `heinzelwerk:diagnosing-bugs` → post the exact attempts on the issue, tell tech-lead; product labels `needs-info`; the task is abandoned (phased-workflow). A loop that needs a human to click doesn't fit an agent run: say so on the issue.
3. **validate (validator)**: the `test:` commit is red on `origin/main` (detached worktree, cherry-pick; see your prompt), green on the branch, all checks green, two-axis review, no unrelated changes.
Then as in `/heinzelwerk:feature`: tech-lead's docs PR, product's acceptance verdict, your final report.

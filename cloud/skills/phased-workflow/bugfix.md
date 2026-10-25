# Bugfix phases (cloud)

Read by tech-lead, the owner, and validator in a `/heinzelwerk-cloud:bugfix` run. `#N` is the bug issue.

1. **analyze (tech-lead)**, after coordinator states the mode: read the issue, locate the likely area, pick the owner,
   name the seam where the bug is observable, post the hypothesis on the issue (the design block from your §1 only when
   the fix changes an interface or touches a risk area). Report one task block `#N <role> implement: <bug>` with the seam
   in it and `spawn: <role>: …`. Too little to reproduce → report `question: product: needs-info` with the questions;
   product labels `needs-info`; coordinator ends the run.
2. **implement (owner)**, branch `fix/<ticket>-<topic>` in its own worktree, `heinzelwerk-cloud:tdd` skill:
   a. Cause not obvious, or the bug intermittent or performance-related → run the `heinzelwerk-cloud:diagnosing-bugs`
      skill first: a loop that goes **red**, minimise, find the cause; post findings on the issue.
   b. Test at the seam that goes **red** on this bug; commit `test: reproduce <bug> (#N)`.
   c. Fix at the root cause until **green** (grep every caller of what you change); commit `fix: <what> (#N)`.
   d. PR with `Closes #N`; done note and `spawn: validator: #N validate <role>: <bug>` in your report (phased-workflow
      **Implementers**).
   No red even with `heinzelwerk-cloud:diagnosing-bugs` → post the exact attempts on the issue, report
   `abandoned: no red` and `question: product: needs-info`; product labels `needs-info`. A loop that needs a human to
   click doesn't fit an agent run: say so on the issue.
3. **validate (validator)**: the `test:` commit (its own commit, or fail) is red on `origin/main` (detached worktree,
   cherry-pick; see your prompt), green on the branch, all checks green, two-axis review, no unrelated changes.

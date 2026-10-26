# Bugfix phases

Read by tech-lead, the owner, and validator in a `/heinzelwerk:bugfix` run. `#N` is the bug issue.

1. **analyze (tech-lead)**, after coordinator states the mode:
   - Read the issue, locate the likely area, pick the owner, and name the seam where the bug is observable.
   - Post the hypothesis on the issue. Add the design block from your §1 only when the fix changes an interface or touches a risk area.
   - Leave one task `#N <role> implement: <bug>` with the seam in its details.
   - Then message coordinator: `[tech-lead] plan posted: spawn <role>`.
   - Too little to reproduce → tech-lead tells product; product labels `needs-info` with questions; coordinator ends the run.
2. **implement (owner)**, on branch `fix/<ticket>-<topic>` in its own worktree, with the `heinzelwerk:tdd` skill:
   a. Cause not obvious, or the bug intermittent or performance-related → run the `heinzelwerk:diagnosing-bugs` skill first: a loop that goes **red**, minimise, find the cause. Post findings on the issue.
   b. Test at the seam that goes **red** on this bug; commit `test: reproduce <bug> (#N)`.
   c. Fix at the root cause until **green** (grep every caller of what you change); commit `fix: <what> (#N)`.
   d. PR with `Closes #N`. Then done note, create `#N validate <role>: <bug>`, complete the task, message coordinator (phased-workflow **Implementers**).

   No red even with `heinzelwerk:diagnosing-bugs`:
   - Post the exact attempts on the issue and tell tech-lead.
   - Product labels `needs-info`.
   - The task is abandoned (phased-workflow).

   A loop that needs a human to click doesn't fit an agent run: say so on the issue.
3. **validate (validator)**:
   - The `test:` commit is its own commit, or fail.
   - It is red on `origin/main` (detached worktree, cherry-pick; see your prompt) and green on the branch.
   - All checks green.
   - Two-axis review.
   - No unrelated changes.

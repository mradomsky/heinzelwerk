# heinzelwerk plugin review, 2026-10-13

Review at v0.27.0 (after PR #17). Read every file; walked a single-PR feature run, a multi-PR run with slice acceptance, and a bugfix run; ran `hooks/guard.sh` against 165 commands. Findings from the 2026-10-11 and 2026-10-12 reviews are not repeated.

Status: sections 1, 2, 3, and 5 applied in v0.28.0 (merge runs after diagnose through a `validate: merge` task; acceptance re-runs after a fix; validator spawn and release rules; next task before completing the current one; run state edited by id, resume = run state without a final report after it; merge-gate waits for CI inside the caller's timeout, checks `mergeable`, reports a failed merge as a skip; tf-gate self-check; guard anchored on the command with the new bypasses closed, `hooks/guard-test.sh` with 203 cases). Section 4 (redundancy and token cost) deferred.

## 1. Logic gaps

1. **Auto-merge runs before diagnose and before the acceptance verdict.** `validator.md:26` (single PR) and `:36` (slice acceptance) run the merge gate on pass. Only then does coordinator (`coordinator:44`) trigger tech-lead's diagnose (`tech-lead.md` §4), which may open fix tasks "on the same branch" (`phased-workflow:33`). After a squash merge that branch is stale: a new PR from it re-shows the merged diff. Product's verdict (`product.md:37`) also lands after the merge. Fix: tech-lead's diagnose with no gap creates `#N validate: merge`; validator claims it and runs the gate per PR in plan order. One extra task, and "validated sha = merged sha" stays meaningful. Alternative (keep merge-first): define the post-merge fix path as a fresh branch from `origin/main`, new PR, own validate task.
2. **A failed slice acceptance is never re-run.** `validator.md:33-36`: fail → tech-lead opens a fix task, then "complete the acceptance task". No rule creates a second acceptance task, so the slice is never proven whole after the fix and the gate (multi-PR) never runs. Fix: tech-lead §3, on an acceptance failure: open the fix task **and** `#N validate: slice acceptance <k>` blocked by it.
3. **Validator can be released mid-loop.** `coordinator:18` spawns validator on the *first* `validate task created`; `coordinator:21` releases a role when no pending or in-progress task names it. After a fail verdict only a `<role> fix` task is pending, so validator qualifies for release; the next validate task then has no claimant and no spawn rule covers it (the list has "first" and tech-lead-accepted tasks only). Fix: spawn validator on *any* `validate task created` while it isn't running; release it only when no implement or fix task is pending or in progress either.
4. **Task hand-over leaves a window.** `phased-workflow:32-33,43`: complete the implement or fix task, *then* create the validate task. In between, no task names the implementer (release rule fires) and no validate or fix task is pending (validator may claim slice acceptance, `validator.md:30`). Fix: create the next task first, then complete yours.
5. **Resume detection is underspecified.** `coordinator:51-53`: one run-state comment per ticket, edited in place, created before the final report. "Newer than the last final report" is undefined (creation vs edit time), and a second run on the same ticket either reuses or duplicates it. Also all roles share one `gh` identity, so `gh issue comment --edit-last` can hit product's or validator's comment. Fix: one run-state comment per run, edited by id (`gh api -X PATCH repos/{owner}/{repo}/issues/comments/<id>`); resume when the newest run-state comment has no final report after it.
6. **Single-mode cwd contradiction.** `coordinator:13` allows "the repo or its parent"; `team-modes:9-11` says cwd must be the repo, anything else stops; README says the repo. Leftover from #11 before #15. Fix `coordinator:13`.
7. **Validate-task titles break the `<role> <kind>` grammar.** `phased-workflow:11`: `#19 validate backend: …` puts the kind first and names an implementer; "the role in the title is the owner" then reads as backend. The parenthetical for validator exists, but implementers get no "never a `validate` task" line. Add it to `phased-workflow:31`.

## 2. Gate scripts

1. **`merge-gate:21` `gh pr checks --watch` meets the Bash tool timeout.** Default 2 minutes; CI rarely finishes inside it. The gate dies with a timeout, not a `MERGE SKIP`, and the validator's "stop at the first MERGE SKIP" never fires. Fix: `timeout 540 gh pr checks "$pr" --watch` → on expiry `MERGE SKIP: CI still running`, and tell validator to pass a 10-minute timeout.
2. **No `mergeable` check.** After PR 1 squash-merges, PR 2 may conflict; `gh pr merge` then fails under `set -e` with a non-zero exit instead of a skip line. Fix: `pv mergeable .mergeable` must be `MERGEABLE` (reason: "needs rebase"); wrap `gh pr merge` so a failure prints `MERGE SKIP: merge failed: <stderr>`.
3. **The `validated` marker is a protocol token, not an authorization.** Every role runs under the same `gh` login; an implementer (or injected repo content) can post `heinzelwerk: validated <sha>` on its own PR and the gate merges. Nothing cheap fixes this with one identity. State it in README and setup G as the accepted trade-off, next to "recommended off when main deploys".
4. **"PR review comment" (`validator.md:26`) is ambiguous.** `gh pr review --comment -b` lands in `.reviews[]`, `gh pr comment` in `.comments[]`, an inline review comment through the API in neither. Name the command.
5. **tf-gate has no self-check.** merge-gate verifies itself against main; tf-gate trusts tech-lead to type `bash <(git show origin/main:scripts/tf-gate)` (`tech-lead.md:30`). Add the same comparison to tf-gate; tech-lead §5 then runs `scripts/tf-gate` plainly.
6. **`gh pr view --json files` returns at most 100 files.** A larger PR gets a partial allowlist check. Add `files | length >= 100` → skip. Low.
7. `main` is hardcoded in both gates while the guard also protects `master`. Fine as an assumption; say so once in README.

## 3. Guard hook (165 commands)

All cases from the earlier reviews behave. New:

- **Bypasses**: `git commit -nm "x"` (combined short flags); `git -c core.hooksPath=/dev/null commit`, `git config core.hooksPath …`, `HUSKY=0 git commit` (skip the gitleaks pre-commit hook README calls the real secret defence); `gh api graphql … mergePullRequest`; `git switch -c main` / `--create main`; `git stage .env`, `git update-index --add .env`; `git add plan.bin` / `*.tfplan` (saved plans carry sensitive values; `infra.md:19` says they stay out of commits).
- **False positives** (regexes are not anchored to command position, so quoted text matches): `grep -rn "git push origin main" docs/`, `echo "gh pr merge …"`, `gh issue comment --body "… gh pr merge …"`, `cat team.md | grep "terraform apply"`, `git commit -m "… -auto-approve …"`, `gh pr create --body "$(cat <<EOF … gh pr merge … EOF)"`, `git checkout main -- file`. Validator and tech-lead quote these rules in ticket and PR comments, so this will fire in real runs. Fix: anchor `git`, `gh`, `terraform` at segment start (allowing `VAR=x` prefixes), and run the merge and `-auto-approve` checks on `msgfree` after also stripping `--body`/`-b` arguments.
- Message `agents never merge; humans merge` is stale since v0.26 → "merge only through scripts/merge-gate".

## 4. Redundancy and token cost

1. `skills/handoff` duplicates `coordinator:50-53`; its upstream body (temp dir, suggested skills, arguments) is a no-op here. Delete the skill, keep the field list in coordinator.
2. `model-selection` description fires on "launching subagents": 728 words auto-loaded in every teammate that spawns one, although role prompts and `phased-workflow:42` already carry the triggers (2026-10-11 L4). Scope the description to shape, retro, setup, adopt-docs.
3. Description scoping is inconsistent: tdd, code-review, codebase-design, domain-modeling, grilling, prototype, diagnosing-bugs, writing-for-agents say "heinzelwerk copy … use inside …"; `to-spec`, `to-tickets`, `improve-codebase-architecture`, `adopt-docs`, `handoff`, `ponytail-debt` do not, so they collide with mattpocock-skills in the user's own sessions (decision in #13).
4. `setup/domain.md` (read by every agent before exploring code) repeats domain-modeling's directory diagrams. Trim to the consumer rules, about ten lines.
5. Opus triggers live in three places: role prompts, `phased-workflow:42`, `model-selection:50-54`. Keep the first two; the Heinzelwerk section of model-selection shrinks to two lines.
6. `ponytail-debt`: CLI leftovers (`/ponytail-debt`, "stop ponytail-debt / normal mode to revert", ask-to-persist) are no-ops when retro drives it.
7. team-modes **Contract changes** (~400 words) loads in every teammate every run but matters only when `team.md` lists contracts. Disclose into `contracts.md` with a pointer "when your task or team.md names a contract".
8. DESIGN-IT-TWICE trigger "a new or changed module interface" (`tech-lead.md:12`) fires on most slices: three Sonnet subagents plus Opus critique plus pre-mortem per plan. Tighten to "a new module, or an interface with more than one caller".
9. `adopt-docs:22` one Haiku subagent per doc contradicts `model-selection:38` (batch small jobs). Batch 5–10 docs per subagent.
10. `commands/feature.md:6` "too big for one run → stop" duplicates product's spec-gate check 1 and makes coordinator judge scope. Drop it from the command.

## 5. Smaller

1. `retro:65` hardcodes `-R mradomsky/heinzelwerk`: any other installer's retro files issues into this repo. Present team actions and ask once where to file them.
2. `team-modes:25` team-dir discovery via `ls ~/.claude/teams/` is ambiguous after several runs. Coordinator passes the team name in every spawn prompt (`coordinator:20` lists ticket and mode already).
3. `coordinator:14` leftover cleanup: `gh pr view <branch>` errors when no PR exists; detached `val-`, `red-`, `accept-` worktrees have no branch and are never cleaned if validator crashed. `coordinator:58` `rev-list @{u}..HEAD` fails on them too. Add: detached or no PR → remove when clean.
4. `bugfix.md:5` "you" means tech-lead, then coordinator, in one paragraph read by three roles.
5. Fix-task numbering `k` after an acceptance failure (`tech-lead.md:23`): say it continues validator's count for that PR.
6. Bugfix validator: no separate `test:` commit (implementer squashed) → red proof impossible → name it as a fail reason.
7. `validator.md:7` "remove it after the verdict" vs merge gate "from your worktree": order is gate, then remove.
8. UI validation (`validator.md:17`) reads screenshots from the `heinzelwerk-screenshots` branch; say how (`gh api … --jq` or `curl` to a temp file), the model otherwise guesses.
9. `tech-lead.md:5` "Never merges" is still true but `README:16` and the guard message should both point at the gate.

## 6. Solid, keep

Spawn-on-demand and release rules (once 1.3 is fixed), contract-change rules, deterministic gates with policy read from main, the self-check in merge-gate, done note + metrics block, the guard's per-argument `git add` check, product.md as the prompt shape.

## 7. Fix order

1. 1.1, 1.2, 1.3, 1.4 (run flow).
2. 2.1, 2.2, 3 (gate and guard behaviour in a real run).
3. 1.5, 1.6, 1.7, 2.3–2.5.
4. Section 4, then 5.

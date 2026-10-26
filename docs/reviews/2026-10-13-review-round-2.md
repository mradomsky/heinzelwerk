# heinzelwerk review round 2, 2026-10-13

At v0.29.1 (main `a98d007` + PR #21). Independent fresh-context reviewer (read-only, with the brief from `prompts/review-plugin.md` widened to the v0.28–0.29 changes), then every "wrong" and "gap" claim re-checked by hand: code.claude.com tools and hooks references fetched, `gh pr view --json statusCheckRollup` on a stagehopper PR, guard probes through `hooks/guard.sh`. Findings from the three earlier rounds are not repeated.

Follow-up (v0.31.0, after the #106 run on stagehopper): gates and `ui-shots` moved into the plugin's `bin/`, so target repos carry only policy and updates arrive with the plugin; the gate retargets a PR stacked on a merged PR, keeps going past a skip for unstacked PRs, and always leaves policy files, `.claude/settings*.json`, and workflows to a human; the docs PR is validated and gated like any other; a re-landed PR gets a new validate task; coordinator runs the gate itself when the user asks for a merge.

Status: all sections applied in v0.30.0 (same PR as the merge-gate size cap): hook matcher `Bash|PowerShell` and `CLAUDE_CODE_USE_POWERSHELL_TOOL=0` for runs; merge-gate branches on a check run's `status`, waits 450 s, ends every error in a `MERGE SKIP` line (ERR trap); tf-gate validates its mode; guard reads text-free commands in both loops, closes the `-q main`, `-fu`, `export HUSKY=0`, `commit -i` holes (hooks/guard-test.sh 219 cases); tech-lead announces every task it creates with `tasks created: <ids>, spawn <roles>`, handles a `mergeable`/CI skip with one rebase round, ends the docs PR with a message; bugfix seeding sends `plan posted`; coordinator's diagnose trigger, respawn naming `<role>-N`, cleanup rule once; validator completes a conflicted acceptance task, fetches screenshots through `gh api`, reruns a verdict-less gate once; setup ignores plan files; token items 5.1–5.8.

## 1. Will it run?

Confirmed by the reviewer against the docs: task tools and their three states, team `config.json` with `members`, spawn by plugin agent type, shutdown request and revive-on-message, `disable-model-invocation` on commands, `user-invocable: false`, `onFailure` (v2.1.295+), every `gh` field and subcommand the scripts use. Unverifiable: exact `TaskUpdate` parameter names; `gh issue create --parent` (absent in gh 2.93, the API fallback is in the doc); whether a respawn under a released role's name gets fresh context.

1. **The guard is bypassed on Windows.** `hooks/hooks.json:5` matches `Bash` only. Tools reference: on Windows with Git Bash "the tool is on by default for claude.ai and Console accounts" and "Claude treats PowerShell as the primary shell"; hooks reference: "Match `Bash|PowerShell` in hooks that inspect shell commands". Every guard rule is dead for commands an agent sends through the PowerShell tool, on the author's own platform. The PowerShell hook input carries the same `tool_input.command`. Fix: matcher `Bash|PowerShell`; README: set `CLAUDE_CODE_USE_POWERSHELL_TOOL=0` in the run environment (the guard's rules and the setup scripts are bash-shaped), state v2.1.295 as the minimum.
2. **merge-gate's CI wait never waits for GitHub Actions.** `merge-gate:13` `(.conclusion // .state // "PENDING")`: gh exports a check run's `conclusion` as a string, `""` while it is queued or running (verified: a completed run shows `"status":"COMPLETED","conclusion":"SUCCESS"`), and jq's `//` treats `""` as present. The poll at `:23` sees no `PENDING`, and `:59` counts the empty line as a failed check. Introduced in v0.28 when `--watch` was replaced. Fix: `if .__typename == "CheckRun" then (if .status == "COMPLETED" then .conclusion else "PENDING" end) else .state end`.
3. **The gate can outlive its Bash timeout.** 540 s CI wait + up to 30 s `mergeable` loop + a dozen `gh` calls can exceed the 600 s cap: tool timeout, no verdict line. Fix: `MERGE_GATE_WAIT` default 450.

## 2. Contradictions and gaps

Every pointer resolves (team-modes §0/§3/§4, **Contract changes**, **Routing**, **Messaging**, `proposals.md`, `contracts.md`, `bugfix.md`, "§4 of its prompt", "step 6", `DESIGN-IT-TWICE.md`, **Implementers**).

1. **Nobody spawns validator for the merge task.** `coordinator:21` releases validator after its last validate task, which is before diagnose; `tech-lead.md:28-29` then creates `validate: merge` (and diagnose tasks) with no message to coordinator, whose only validator trigger is an implementer's `validate task created`. The run stalls. Fix: every §4 branch ends with `[tech-lead] tasks created: <ids>, spawn <roles>`; coordinator's spawn rule names that message.
2. **"Every validate task passed" with slice acceptance still pending** (`coordinator:44`) reads as "every completed one passed": diagnose and the merge task start before acceptance, and `validator.md:31` then cannot claim acceptance because a validate task is pending. Fix: "no validate task pending or in progress, every verdict a pass".
3. **Acceptance conflict ends in "Stop."** (`validator.md:32`) without completing the task; left in progress it blocks the happy-path end (`coordinator:56`) and the next claim. Fix: "Stop: remove the worktree, complete the task."
4. **Bugfix seeding never says `plan posted`.** `bugfix.md:5` "leaves one task", no message; `coordinator:17` spawns implementers only after `plan posted`. Also unclear whether §1's design block applies to a bugfix. Fix: step 1 ends with `[tech-lead] plan posted: spawn <role>`; the design block only when the fix changes an interface.
5. **`phased-workflow:33,43` "a fix task from validator → same loop"**: the acceptance fix task comes from tech-lead (`tech-lead.md:23`); an owner may skip the new validate task, and the gate then has no `validated <new head>`. Fix: "a fix task, validator's or tech-lead's".
6. **`coordinator:38`** "its in-progress task: done note `abandoned…`, completed" names no actor, and coordinator does no tasks (`:9`). Name tech-lead.
7. **The docs PR has no end message** (`tech-lead.md:38`); `coordinator:48` ("docs PR open") and §4.1 have no trigger. Fix: §6 ends with `[tech-lead] docs PR: <url | none>`.
8. **Respawn naming.** `coordinator:15` respawns a released role as `<role>`, `team-modes:24` reserves `<role>-2` for crashes; whether a same-name spawn is a fresh session is unverified. Fix: every respawn is `<role>-N`, next free number.
9. **`product.md:17`** "Spec gate passed" goes to tech-lead only; `coordinator:48` needs it for the status line. Add coordinator.
10. **`README:109`** lists six mattpocock copies; prototype, diagnosing-bugs, improve-codebase-architecture, to-spec, to-tickets also carry "heinzelwerk copy". List all.

## 3. Failure paths

1. **Gate skips PR 2 of 3** (`mergeable` or CI reason): validator stops (`validator.md:40`), `tech-lead.md:29` goes straight to the docs PR, the slice stays half-merged, the final report lists the skip. Conflicts after a squash are unlikely when the integration merge was clean, but CI on PR 2 ran against the old `main`. Fix: on a `mergeable` or CI skip tech-lead opens `<role> fix k: rebase` for that PR, the owner re-validates, and `validate: merge 2` covers the rest; one round, then the human.
2. **Gate crash**: a `gh` or network error under `set -e` (`merge-gate:29,40`) exits with no verdict line; `validator.md:40` handles skips only. Fix: `trap 'echo "MERGE SKIP: gate error (line $LINENO)"; exit 0' ERR` in the script; validator reruns once.
3. **Screenshots on a private repo**: `validator.md:17` downloading the blob's `?raw=true` URL returns the login page. Fix: `gh api repos/{owner}/{repo}/contents/<path>?ref=heinzelwerk-screenshots -H 'Accept: application/vnd.github.raw+json' > <file>`.
4. **`plan.bin` is never ignored** (`infra.md:17`, setup C2); `git add -A` passes the guard by design, so a plan with sensitive values lands in the PR. Fix: setup C2 adds `plan.bin` and `*.tfplan` to `.gitignore`.
5. Crash, compaction, flaky check, no answer, usage cap: covered.

## 4. Scripts

**guard.sh**, reproduced by probe:
- False positives: the first loop reads `text`, not `msgfree`, and segments split on `|`, `&&`, `;` inside quoted bodies, so `gh pr review 12 --comment -b "checks: pass | gh pr merge not run"` and `gh issue comment 5 --body "ran checks && gh pr merge was refused"` block. Validator verdicts are exactly this shape. Fix: both loops read `msgfree`; strip `-f/-F body=…` too.
- Bypasses: `git checkout -q main`, `--force main`, `git switch --quiet main` (`:36` allows only `-b/-B/-c/-C/--create`); `git push -fu origin x` (`:46` wants `-f\b`); `export HUSKY=0; git commit` (`:48` checks one segment); `git commit -i .env` (`:51` checks `add` only). Fixes: `(checkout|switch)( +-[a-zA-Z]+| +--[a-z-]+)* +(main|master)`; ` -[a-zA-Z]*f[a-zA-Z]*\b` on push; hook-skipping variables anywhere in the text when any segment commits; `commit … -i|--include <paths>` through the secret-file check.
- By design, worth a README line: `git push` and `git push origin HEAD` from the main checkout push main.

**merge-gate**: 1.2, 1.3, 3.2; `:29` and `:40` abort under `set -e` on a `gh` error or a non-numeric policy value (the ERR trap covers both).
**tf-gate**: `mode` unvalidated (`tf-gate foo …` behaves as `check`, exit 0); `git fetch` failure exits with git's message only. Minor.
**ui-shots**: fine. CRLF: `.gitattributes` covers `*.sh` and `skills/setup/scripts/*`; all four scripts are 100755.

## 5. Token cost (always loaded)

1. `phased-workflow:18-26` Phases table (~130 words) restates Task lifecycle `:28-36`; `analyze` exists only in `bugfix.md`. Keep the lifecycle.
2. `team-modes:63-66` §4 validator checklist and `single.md:13` Validator row duplicate `validator.md` §1–3 for every teammate. Drop both; `workspace.md`'s Integration row suffices.
3. `single.md:10` Contract row (~60 words) restates `contracts.md`. Pointer.
4. `coordinator:14` and `:58` state the same worktree cleanup twice. Define it once in §4.2; §1 says "run §4.2, keep branches without a PR".
5. `phased-workflow:13-16` and `team-modes:27` both carry "anything durable goes on GitHub".
6. `validator.md:41` restates the criteria the gate decides. Keep "Never merge any other way; a skip is not a failure."
7. `setup/team.md:26` template line repeats team-modes §1 into every target repo.
8. No-ops: `phased-workflow:41` "Interfaces: deep modules, small interfaces"; `tech-lead:22` "Coordinator observes, you decide".

## 6. Fix order

1. 1.1, 1.2, 1.3 (guard and gate dead on the common path), then the guard items in §4.
2. 2.1, 2.2, 2.4 (run stalls), 2.3, 2.5–2.9.
3. 3.1–3.4.
4. §5 and the rest.

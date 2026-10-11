# heinzelwerk setup review, 2026-10-11

Status: all findings below were applied the same day, except D2 (merge lead into the main session), which waits for Run 1 measurements.

## Round 2 (independent re-review, same day)

Applied, blocking or wrong-flow only: `TaskUpdate` cannot rename a task, so the title-tag lifecycle became **one validate task per PR** and **one fix task per round** (native states only); command `model:` covers one turn, so sessions start with `--model opus`; `effort`/`disallowedTools` apply in-process only; hook `onFailure: block` and a Git Bash prerequisite; roster protocol replaced by reading the team `config.json`; MCP note corrected (teammates load servers from project/user config); lead signals `plan posted`; coordinator triggers lead's diagnose and docs PR; validator messages lead on infra pass, acceptance conflicts, and third fix rounds; bugfix phases travel in spawn prompts, red-on-main uses a detached worktree plus cherry-pick, `needs-info` is product's alone, abandoned tasks defined, bugfix requires `ready-for-agent`; frontend scope questions go to product; unanswered escalation, teammate failure, flaky check, and compaction counts have rules; guard normalises quoting and whitespace, allows any `git -c/-C/--opt` prefix, blocks `+main`, `--mirror`, `--all`, `-n` on commit, `gh api …/merge`, worktrees on main, `checkout -B main`, judges `git add` arguments one by one, and no longer flags `main-*` branches or `.tfvars`.

Also applied later the same day: shared implementer rules moved into phased-workflow `## Implementers`; `codebase-design` and model-selection pointers dropped from implementer prompts; skill descriptions trimmed to about 30 words; no-op sentences removed (command-level "everyone follows", voice role list, `argument-hint` on the hidden handoff skill).

Also: team-modes §2/§3 disclosed as `single.md` / `workspace.md` behind one pointer; Apache change notice added inside `skills/caveman/SKILL.md`.

Deferred: clarify the provenance of `skills/model-selection` (original or copied; needs the author).

Scope: every file in the plugin. Method: read all, walked one `/feature` and one `/bugfix` run end to end, checked every cross-reference (skill names, doc paths, labels, section refs), tested `hooks/guard.sh` against 28 realistic commands, and verified the Claude Code features the plugin assumes against code.claude.com (fetched 2026-10-11). Upstream skills (tdd, code-review, codebase-design, domain-modeling, grilling, prototype, writing-for-agents, caveman, ponytail) are reviewed only where heinzelwerk adapts or depends on them.

Severity: **P** = will not run as written · **C** = contradiction or gap · **D** = design and responsibility split · **K** = communication framework · **L** = language, prompting, token cost.

## 1. Platform facts (P)

- **P1. Custom task statuses do not exist.** `skills/phased-workflow/SKILL.md:28` defines proposed / open / in progress / under review / needs work / done. Claude Code's shared task list has exactly three states: pending, in progress, completed. Every status-driven rule (validator "pick up any task under review", coordinator release rule, lead triage "proposed to open") has no mechanism. Fix: define the lifecycle once on the three native states plus a title tag (`[proposed]`, `[review]`, `[needs-work]`), which is already your own fallback in `docs/test-run-plan.md`.
- **P2. Task tools are off by default on current models.** Without `CLAUDE_CODE_ENABLE_TODO_TOOLS=1` (or `--allowedTools TaskCreate,...`) there is no shared task list at all. README's install block sets only `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS`. Fix: add the second env var to the same snippet and to `docs/test-run-plan.md` Phase 0.
- **P3. `skills:` in agent frontmatter is ignored for teammates.** Docs: "Claude Code doesn't apply the definition's `skills` to a teammate." `agents/backend.md:4`, `frontend.md:4`, `infra.md:5`, `lead.md:5` rely on it and the prompts say "(preloaded `caveman` skill)". Teammates will run without caveman or ponytail. Fix: inline a four-line voice rule and the ponytail core in the prompt, or instruct "load the `ponytail` skill first" and drop "(preloaded)".
- **P4. Headless runs cannot spawn teammates.** `-p` mode runs named agents as ordinary subagents. `skills/coordinator/SKILL.md:34` "No user present (headless)" is a dead branch. Fix: delete it, state "runs are interactive" in README.
- **P5. Hook command path unquoted; Windows caveat.** `hooks/hooks.json:6` uses `${CLAUDE_PLUGIN_ROOT}/hooks/guard.sh` unquoted: breaks on paths with spaces. Shell-form hooks run under Git Bash on Windows and fall back to PowerShell when it is absent, where a `.sh` will not execute. Fix: quote the path; verify once on this machine.
- **P6. `guard.sh` fails open.** Tested on this machine, which lacks `jq`: every command passed with exit 0 (stderr: `jq: command not found`). Fix: `command -v jq >/dev/null || block "jq missing"` as the first line.
- **P7. `.claude-plugin/marketplace.json:7`** `"source": "./"` passes the "must start with ./" rule, but the docs' root form is `"."`. Align.
- **P8. `effort` is a real agent frontmatter field.** `skills/model-selection/SKILL.md:55-63` has an Effort column that nothing enforces. Fix: `effort: high` in `agents/lead.md` and `agents/validator.md`, `medium` elsewhere; delete the column.
- **P9. `user-invocable: false` exists.** Answers the open question in `docs/test-run-plan.md` (hide building blocks). Apply to `to-spec`, `to-tickets`, `handoff`, `coordinator`, `phased-workflow`, `team-modes`, `model-selection`.
- **P10. Cross-skill bare names** ("use the `grilling` skill") are undocumented inside plugins. Keep the Phase 1 check; fall back to `heinzelwerk:grilling` if it fails.
- P11. `license:` in `skills/ponytail/SKILL.md` is accepted but inert. Harmless.

## 2. Contradictions and gaps (C)

- **C1. Spec issues get the slice label.** `skills/to-spec/SKILL.md:20` applies `ready-for-agent` to the spec issue. `phased-workflow:13` "Spec issues are never run directly"; `commands/feature.md:6` refuses spec issues. Every `/shape` run therefore produces a spec that invites `/feature` and gets refused. Fix: to-spec applies no label (or `needs-triage`); only to-tickets labels slices.
- **C2. Spec-issue handling is defined twice with different outcomes.** `commands/feature.md:6`: coordinator stops, suggests `/shape`. `agents/product.md:16`: relabel `needs-info`, end run. `commands/shape.md`'s `needs-info` path then assumes "a run stopped on it, put its questions to the user", but a spec has no questions. Fix: delete product's spec-issue branch; the coordinator precondition owns it.
- **C3. Refactoring has no owner.** `skills/tdd/SKILL.md:38` "refactoring belongs to review". `agents/backend.md:15` refactors only on needs-work. `agents/validator.md:14` smells "never block alone". So on a passing PR, smell findings go nowhere. Fix (pick one): validator may return needs-work when N or more smells sit in changed code; or implementer does one refactor pass after green and before under review, and tdd's rule is adapted.
- **C4. Mandatory seam round-trip.** `skills/tdd/SKILL.md:22` heinzelwerk note: "confirm seams with lead by message". Lead already named them in the task (`agents/lead.md:9`, `backend.md:10`). Every task now blocks on a lead reply. Fix: "the seams are the ones in your task; message lead only when they don't fit".
- **C5. Message-prefix rule excludes half the team.** `skills/team-modes/SKILL.md:40`: every message starts with `[<repo>@<branch>]`; coordinator and lead ignore messages without it. Product, validator during acceptance, and coordinator have no branch. Read literally, lead ignores coordinator's nudges and product's scope answers. Fix: implementers prefix `[repo@branch]`, everyone else `[role]`.
- **C6. Worktree listing is promised and never produced.** `team-modes:43` "lead lists them in the final report". `agents/lead.md:19` technical report has no such item; the metrics block in `coordinator:59+` has no field. Fix: add `worktrees:` to both, or drop the sentence.
- **C7. `left:` discoveries die with the task.** `phased-workflow:67` sends over-cap discoveries to the done note; `:74` `left:`; but `:16` says anything durable goes to GitHub and tasks are disposable. Lead's docs PR (`lead.md:17`) harvests only term/adr/learning/risk. Fix: lead's technical report collects every `left:` line; product files `needs-triage` issues for the real ones at run end.
- **C8. "Phase" is half-applied.** `phased-workflow:20` "every task has exactly one phase", yet validation of an implement task is a status, not a task; validate tasks exist only for slice acceptance (`lead.md:9`). Fix: say it plainly ("validate work rides on the implement task's status; the only validate task is slice acceptance") or drop the phase column from the table.
- **C9. Bugfix diagnose has no runnable owner.** `commands/bugfix.md:8`: "the owner first runs diagnosing-bugs" inside lead's analyze step, before the implement task exists; spawn-on-demand means the owner is not running yet, and lead cannot write a test (no Write). Fix: lead's analyze handoff is one implement task whose first step is the diagnosing loop; coordinator spawns the owner then.
- **C10. Early ends post no report, so retro cannot see them.** `coordinator:59` §4 covers the happy path only. Spec-gate fail, needs-info and stopped runs have no instruction to post the final report, yet `skills/retro/SKILL.md:17` finds runs by the `heinzelwerk-metrics` comment. Fix: "every end, including spec-gate fail and handoff, posts the final report with `outcome:` set".
- **C11. `heinzelwerk-survey` label never created.** `retro:63` uses it; `setup:63` creates only the five triage labels. `gh issue create --label` fails. Fix: add to setup or `gh label create` in retro.
- **C12. HITL script path is wrong in target repos.** `skills/diagnosing-bugs/SKILL.md:35,64` reference `scripts/hitl-loop.template.sh`; it lives in the plugin, never copied by setup. `commands/bugfix.md:13` already says HITL loops don't fit agent runs. Fix: drop the HITL branch for heinzelwerk, or point at `${CLAUDE_PLUGIN_ROOT}/skills/diagnosing-bugs/scripts/`.
- **C13. model-selection contradicts its own role table.** `:39` anti-pattern "same model generating and grading"; `:55-62` Sonnet builds, Sonnet validates non-risk diffs. Either state the accepted trade-off (human PR review is the real last line) next to the table, or make both review axes Opus by default.
- **C14. Human-edit heuristic has false negatives.** `retro:19` and `team-modes:39`: commits without `Co-Authored-By` are human fixes. A human fixing with Claude Code also carries the trailer. Fix: mark the heuristic approximate; prefer "commits after the agent's last push on that branch" and confirm with the user.
- **C15. Gate-fail escalation has no sanctioned outcome.** Lead "never retries around the gate", raw apply is blocked, so the user can only apply by hand or widen `infra-policy.json`. Say so in `lead.md:13-15` and the coordinator routing row.
- **C16. Revert-drift task (`lead.md:16`)** has no ticket of its own, violating `phased-workflow:11`. Say: filed under the current ticket with `Refs`, and why.
- **C17. Dangling upstream text.** `skills/caveman/SKILL.md:19` (`ultracave`, `megacave`, hook `Caveman mode`, `/caveman-compress`); `skills/setup/issue-tracker-github.md:19` (`/triage`, no such command here); `skills/to-tickets/SKILL.md:63` (`.scratch/` local tracker setup never offers); ponytail level switches; `wontfix` and `ready-for-human` labels no flow applies except retro. Trim or mark.

## 3. Responsibility split and workflow (D)

- **D1. Lead cannot write, so backend types lead's docs.** `agents/lead.md:17`: lead dictates "exact file contents" into an implement task. The constraint (`disallowedTools: Edit, Write`) is wider than the principle ("never edits code"). Recommend: lead writes the docs PR in its own worktree; "no code" stays a prompt rule. Saves a teammate round-trip and transcription errors.
- **D2. Two Opus sessions always on.** Coordinator "routes, doesn't decide" and relays "verbatim" both ways (`coordinator:32`): a pipe plus an observer. Every user-to-lead exchange costs two extra hops. The case for the split is lead's context filling with triage. Recommend: measure in Run 1; if lead's context stays small, merge lead into the main session and keep "coordinator" as that role's process section.
- **D3. Lead is the serial bottleneck**: triage, questions, flags, diagnose, apply, docs, report, plus the seam confirmation (C4). Keep lead for decisions only: fix C4, keep validator-to-implementer and implementer-to-product direct (already allowed).
- **D4. Unmerged infra applied to dev** (`lead.md:13`) before human review; revert only when the next run starts (`lead.md:16`), an unbounded window. Recommend: retro also checks for applied-but-closed PRs; or move post-merge apply to CI and keep lead's apply strictly for `auto_apply_dirs`.
- **D5. Spec gate re-reviews what `/shape` just gated with a human.** `product.md` Spec gate re-checks the same four properties. When the ticket came from `/shape`, make the gate a read-and-confirm comment, not a review.
- **D6. The 0–10 rating** (`coordinator:39`): four criteria, one number, threshold ≤4. Models do not produce calibrated scores; the threshold yields noise nudges the retro then counts. Replace with the four typed conditions as yes/no triggers (stuck, confused, wrong-direction, constraint), which already exist.
- **D7. "You route, you don't decide"** (`coordinator:9`) is false: coordinator spawns, releases, flags duplicates, ends the run. Say "you decide process, never scope or design".

## 4. Communication framework (K)

- **K1. Routing stated four times**: `coordinator` §2 table, `team-modes` Routing, `phased-workflow` Triage path, README. Single source: team-modes (every teammate loads it). Coordinator keeps only its own escalation rules.
- **K2. Run sequence stated four times**: README Workflow, `commands/feature.md:8` (558-char arrow chain), coordinator §1-4, lead steps. The feature.md chain is unreadable and duplicates the skill it tells you to load. Cut it to precondition plus "load coordinator".
- **K3. Repeated rules**: "Follow the phased-workflow and team-modes skills" in 8 files; "main checkout" in 5; "never merge" in 7. A repeat as a one-token pointer is fine; a re-explanation is duplication. Keep the rule in team-modes, pointers elsewhere.
- **K4. Overloaded words.** "handoff" = phase handoff column, the `handoff` skill, bugfix "Handoff: one implement task", done-note field. "acceptance" = criteria, command, slice-acceptance task, acceptance verdict. "spec" = spec issue, spec gate, Spec review axis, "the issue is the spec". Rename at least: the handoff skill's output to `## Heinzelwerk run state`; acceptance command to "e2e command".
- **K5. Roster protocol** (`coordinator:15-21`, `team-modes:16-18`) is sound. Validator and product never receive roster updates, and that works only because the release rule keeps their targets alive. Say so in one line so a future edit doesn't break it.
- **K6. Done note** is good. Add `worktree:` (C6) and make `left:` durable (C7).

## 5. Language, prompting, token cost (L)

- **L1. Agent prompts are walls.** `agents/validator.md:10` is a 1057-char line with four bold sub-cases and nested parentheses; `lead.md:9` 771 chars; `feature.md:8` 558. `agents/product.md` is the model: headed sections, one rule per line. Reshape lead, validator, backend, frontend the same way.
- **L2. Negation-heavy against your own `writing-for-agents` rule** ("prompt the positive"): coordinator 20 negations in 960 words, team-modes 20, phased-workflow 19, lead 11 in 654. Keep the hard guardrails; rewrite the rest: "Never decide scope yourself" becomes "Scope decisions go to product"; "Never touch frontend scope" becomes "Your scope is backend paths".
- **L3. Arrows**: 29 in coordinator, 21 in team-modes, 18 in lead. Fine for a mapping (`stuck → ask lead`), poor for narrative. One arrow per line.
- **L4. Context load per implementer ≈ 6,500 words of instructions** (agent prompt + caveman + ponytail + phased-workflow + team-modes + tdd + codebase-design + model-selection) before reading code. `model-selection` (1,077 words) is loaded to read one table row: inline the role's row in its prompt, keep the skill for subagent decisions. `codebase-design` (851) for implementers reduces to one line; keep the skill for lead and the survey.
- **L5. caveman (744 words) and ponytail (592)** are mostly CLI-user behaviour (status, aliases, hooks, level switches, reply language). A four-line heinzelwerk voice rule and a six-line ponytail core replace them for teammates (and P3 forces this anyway).
- **L6. No-op sentences.** `backend.md:10` "a pushback on the request itself becomes a proposal" handles ponytail *ultra*; you set *full*. `setup:71` "Never create one when the other exists" is implied by the if/else before it.
- **L7. `to-spec`'s "LONG… extremely extensive" user stories** (upstream shouting) sits oddly beside the tracer-bullet ethos. Keep the stories, drop the intensifiers.
- **L8. README `## Roles` table splits the numbered Workflow list** (items 4-6 continue after it, `README.md:43-55`). Move the table below Workflow.
- **L9. Small leaks.** `skills/README.md:1` "Auto-loaded in every repo" (only descriptions load). `skills/setup/design.md:14` "LCARS" is a stagehopper leak in a generic template. `retro:64` "`repository` in its `plugin.json`" is unreachable at run time in a target repo; write `mradomsky/heinzelwerk`.
- L10. Section refs (`team-modes §4`, `**Contract changes**`, "Heinzelwerk section") all resolve. Good.

## 6. Guard hook test (`hooks/guard.sh`)

Tested 28 commands through a shim (the real hook fails open without `jq`, P6).

| Result | Commands |
|---|---|
| Blocked, correct | `git push origin main`, `HEAD:main`, `--force`, `-f`, `--no-verify`, `terraform apply` (also `-chdir=`, `cd x && terraform apply`), `git add .env` |
| **Bypassed** | `git -C ../repo push origin main` (team-modes:33 teaches the `-C` form), `git checkout main && git merge feat/1`, `git switch main && git merge`, `gh pr merge 12`, `git add -A` |
| **False positive** | `git push origin feat/22-main-page`, `git merge origin/main` (rebase is the rule, but merge is common), `git add .env.example` |

Fixes: match `git(\s+-C\s+\S+)?\s+(push|merge)`; test `main|master` as a ref token after a space, `:` or `/` at argument position, not as a substring; add `gh pr merge` and `git (checkout|switch) (main|master)`; `.env(\.|$)` minus `.example|.sample`; fail closed on missing `jq`. Keep README honest: the real secret defence is the gitleaks pre-commit hook from setup section C, the guard is a tripwire.

## 7. Protect these

- Deterministic `tf-gate` plus the credential-scope boundary (`README:17`): the right design, stated correctly.
- Spawn-on-demand, release rules, roster.
- Contract-change rules (`team-modes:20-28`): the most precise part of the plugin.
- Done note plus metrics block: the retro loop closes.
- `agents/product.md` as the prompt shape to copy.
- model-selection's "cheap verifier downstream" test.
- `docs/test-run-plan.md` is honest about unknowns; `prompts/review-plugin.md` asks the right questions.

## 8. Fix order

1. P1, P2, P3, P4, P6 (will not run as written).
2. C1, C2 (spec label and spec-issue path).
3. C3, C4, C5 (refactor owner, seam round-trip, prefix rule).
4. D1 (lead writes the docs PR), D6 (drop the 0–10 score).
5. K1, K2 dedupe; L1 reshape lead and validator.
6. Guard regexes (§6).
7. Everything else, then re-run `prompts/review-plugin.md`.

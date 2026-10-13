# heinzelwerk

_Named after the Heinzelmännchen of Cologne, the house gnomes who finished the town's work overnight while everyone slept._

Claude Code plugin: a lean autonomous dev team (coordinator / product / tech-lead / backend / frontend / infra / validator) on top of Claude Code agent teams, plus the skills to shape work before the team touches it.

## Principles

- **Align before building.** A human grills the idea into a spec and slices it into tracer-bullet tickets. The team only runs `ready-for-agent` slices.
- **Shared language.** `GLOSSARY.md` and ADRs keep agents concise and naming consistent. Agents propose terms; humans confirm them.
- **Feedback loops.** Red → green at agreed seams; validator runs real checks and a two-axis review (standards, spec).
- **Deep modules.** Small interfaces, lots of behaviour behind them; tests through the interface.
- **Phases, not pipelines.** Work is typed analyze / implement / validate; any agent may create work in any phase, every task leaves a handoff.
- **Tickets are durable, tasks are disposable.** Everything the next run needs lives on GitHub.
- **Pointers, not imports.** `CLAUDE.md` holds a short `## Agent skills (heinzelwerk)` block; agents read `docs/agents/heinzelwerk/*` when the pointer fires.
- **Humans merge, unless a deterministic gate allows it.** Agents open PRs and never push main. `merge-gate` (in the plugin's `bin/`, so no PR can change it) merges a PR only when `merge-policy.json` on main allows it: the validator's `heinzelwerk: validated <sha>` names the PR's current head, every changed file is allowed, CI green, mergeable, no unchecked manual check left (the validator does the ones it can). Policy files, `.claude/settings*.json`, and workflows always wait for a human. It runs after tech-lead's diagnose finds no gap, docs PR included; a PR stacked on a merged PR is retargeted to main first. Setup section G turns it on (policy, a PR CI workflow, and the `Bash(merge-gate *)` permission auto mode needs); recommended off when `main` deploys to production, also because the `validated` line is a protocol marker, not an authorization: every role shares one `gh` login, so a teammate, or text it reads in the repo, could post it.
- **Infra auto-applies only through a deterministic gate.** `tf-gate` (plugin `bin/`) checks the saved plan against `infra-policy.json` on main (environment allowlist, no destroys, protected types, change limit). Tech-lead applies on pass and escalates on fail or doubt. Credential scope is the real boundary: agents never hold prod write credentials.

## Install

```sh
claude --plugin-dir /path/to/heinzelwerk         # try locally
/plugin marketplace add mradomsky/heinzelwerk     # or from GitHub
/plugin install heinzelwerk
```

Needs Claude Code 2.1.295 or later (hook `onFailure`). Enable agent teams and the shared task list in `~/.claude/settings.json`; on Windows also keep runs on the Bash tool, the guard's rules and the setup scripts are bash-shaped (the hook matches the PowerShell tool too, as a backstop):

```json
{ "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1", "CLAUDE_CODE_ENABLE_TODO_TOOLS": "1", "CLAUDE_CODE_USE_POWERSHELL_TOOL": "0" } }
```

Runs are interactive: a headless `-p` session cannot spawn teammates. Keep the default in-process teammate mode: split panes ignore the agents' `effort` and `disallowedTools`. The guard hook has no dependencies beyond bash (Git Bash on Windows); `tf-gate` needs `jq` on infra repos; the tracker and `merge-gate` need `gh`. The plugin's `bin/` (`merge-gate`, `tf-gate`, `ui-shots`) is on the Bash tool's PATH while the plugin is enabled, so target repos carry no copies and every plugin update reaches every repo at once. The default branch must be `main`: both gates read their policy from it and every worktree starts from `origin/main`.

Start every shaping or run session with `--model opus`: a command's `model:` covers only its first turn, and shape, feature, bugfix, and retro span many.

Start team runs **without MCP servers**: every teammate otherwise loads every connected server's tool definitions on every turn. `--strict-mcp-config` empties the main session's set; teammates load MCP servers from project and user config regardless, so remove or disable servers there for the run (`claude mcp list` / `claude mcp remove`) and check `/mcp` inside a teammate once.

Start runs from the repo (single mode) or from the folder that contains the repos (workspace mode). Task worktrees live inside each repo at `.claude/worktrees/heinzelwerk/<branch>` (git-ignored through `.git/info/exclude`, next to Claude Code's own worktrees), so they are always inside the folder Claude Code was started from and edits don't prompt.

```sh
cd ~/work/stagehopper    # or ~/work for a workspace run
claude --model opus --strict-mcp-config   # coordinator on Opus; no MCP servers in the main session
```

Need one for a run (e.g. an issue tracker without `gh`)? Pass only that one: `claude --strict-mcp-config --mcp-config ./mcp-run.json`.

## Workflow

1. **Once per repo or workspace**: `/heinzelwerk:setup` → interview → one PR per repo with `docs/agents/heinzelwerk/*`, optional seeded `GLOSSARY.md`/ADRs, and the `## Agent skills (heinzelwerk)` block. Review, merge. In a multi-repo folder, run it from the parent folder; it also writes the workspace docs into the tickets repo.
2. **Shape (you + product)**: `/heinzelwerk:shape [issue | idea]`. Product grills you, writes the spec, slices it into `ready-for-agent` tickets with blocking edges, and lists the frontier. Also the way back in after a run stops on `needs-info`. Want only the interview? Stop after the grill. `/heinzelwerk:to-spec` and `/heinzelwerk:to-tickets` stay typeable for odd cases (e.g. slicing a spec written elsewhere).
3. **Build (you + coordinator)**: `/heinzelwerk:feature <slice>` or `/heinzelwerk:bugfix <issue>`. Your session becomes coordinator: your single point of contact, routes scope questions to product and technical ones to tech-lead, watches the team, posts the final report.
4. **Review** what the gate skipped, or everything when the gate is off. With the gate on, the docs PR merges too; keep `GLOSSARY.md`, `docs/adr/`, or `learnings.md` in `deny_paths` if you want to approve those by hand, otherwise read them at the retro.
5. **Weekly**: `/heinzelwerk:retro` over the week's runs, including an architecture survey (deepening candidates filed as `needs-triage`) → retro record + doc PR for the project, issues in this repo for the team. Good use of leftover tokens.
6. **New docs appeared?** `/heinzelwerk:adopt-docs` absorbs only new or changed docs (ledger in `docs/agents/heinzelwerk/adopted.md`).

## Roles

| Role | Owns | Where | Model |
|---|---|---|---|
| coordinator | process: your channel, lifecycle, observation, final report | main session of a run (`skills/coordinator`) | Opus |
| product | what: shaping, spec gate, scope answers, acceptance verdict | main session of `/shape`; teammate in runs | Opus in `/shape`, Sonnet in runs |
| tech-lead | how: tasks, seams, technical triage, diagnose, infra apply through the gate, docs PR | teammate | Opus |
| backend / frontend | building, test-first | teammates | Sonnet |
| infra | Terraform: plan, never apply | teammate | Sonnet |
| validator | checks, two-axis review, slice acceptance, merge gate | teammate | Sonnet; Opus review on the project's risk areas |

Main-session roles (coordinator, product in `/shape`) run on the session model: start it with `--model opus`. Escalation and degradation happen through subagents (Opus for depth, Haiku for breadth and mechanical work). Each role's triggers are in its prompt; the reasoning is in `skills/model-selection`.

## What gets written into a target repo

```
CLAUDE.md                 ## Agent skills (heinzelwerk) pointer block (existing file is reused; AGENTS.md-only repos get one that imports it)
GLOSSARY.md               lazily, resolved terms only
docs/adr/                 lazily, decisions meeting all three ADR criteria
docs/agents/heinzelwerk/  heinzelwerk's own files; other files in docs/agents/ are left alone
  issue-tracker.md  triage-labels.md  domain.md  team.md  repo-map.md  learnings.md
  design.md               UI repos: design system
  infra-policy.json       infra repos: tf-gate policy
  merge-policy.json       merge-gate policy (setup section G)
  adopted.md              ledger of adopted docs
  retros/                 retro records
  workspace.md            tickets repo only, workspace mode
.claude/settings.json     Bash(merge-gate *) permission (section G)
GLOSSARY-MAP.md           tickets repo only, workspace mode
CLAUDE.workspace.md       tickets repo only; parent folder CLAUDE.md = one @import line
```

## Layout

User-invoked (you type them; they orchestrate and never call each other):
- `commands/shape.md` — shaping session with product
- `commands/feature.md`, `commands/bugfix.md` — team runs, main session as coordinator
- `skills/setup` — agentic docs setup (calls `adopt-docs`)
- `skills/retro` — weekly retrospective + architecture survey

Model-invoked (reusable discipline, agents reach for them):
- `skills/coordinator` — main-session role in runs
- `skills/to-spec`, `skills/to-tickets` — driven by `/shape`, also runnable directly
- `skills/phased-workflow` — phases, task lifecycle, handoffs, tickets, done notes, docs candidates
- `skills/team-modes` — routing, messaging, voice, single-repo vs workspace cooperation rules
- `skills/adopt-docs` — existing docs → ADRs, glossary, repo map, issues; also runnable directly
- `skills/diagnosing-bugs` — red loop → minimise → hypothesise → instrument → fix, used by `/bugfix`
- `skills/improve-codebase-architecture` — deepening opportunities; run weekly by retro, or directly for an ad-hoc survey
- `skills/prototype` — throwaway UI variations / logic walkthroughs, used by `/shape`
- `skills/model-selection` — which tier for which work, and why; the roles' triggers live in `agents/*`
- `skills/ponytail-debt` — `shortcut:` ledger, used by retro
- `skills/tdd`, `skills/code-review`, `skills/codebase-design`, `skills/domain-modeling`, `skills/grilling`, `skills/writing-for-agents`, `skills/prototype`, `skills/diagnosing-bugs`, `skills/improve-codebase-architecture`, `skills/to-spec`, `skills/to-tickets`: adapted copies of mattpocock/skills. Their descriptions say "heinzelwerk copy … Use inside heinzelwerk …", so if you also have the mattpocock plugin installed, your own sessions pick the upstream skill and runs pick ours. Both are namespaced (`heinzelwerk:tdd` vs `mattpocock-skills:tdd`); no rename needed.

Other:
- `bin/` — `merge-gate`, `tf-gate`, `ui-shots`: on the Bash tool's PATH while the plugin is enabled; policy stays in the target repo, the code stays here
- `agents/` — roles, usable as subagents or teammates
- `hooks/` — `guard.sh` blocks pushing, checking out, or moving main, `gh pr merge` (also through the API), plain `--force`, `--no-verify` and hook-skipping (`core.hooksPath`, `HUSKY=0`), adding secret, state, or plan files, raw `terraform apply/destroy/import/state`, `-auto-approve`. Rules anchor on the command and ignore quoted text, so a verdict quoting a rule never trips it. By design it does not block a bare `git push` or `git push origin HEAD`, which push main from the main checkout: agents work in worktrees. `guard-test.sh` runs the regression cases (needs node). A tripwire: the secret defence is the gitleaks pre-commit hook setup recommends
- `docs/test-run-plan.md` — staged plan for the first runs; `docs/reviews/` — review records
- `prompts/` — loose prompts, staging area before `skills/` or `commands/` (e.g. `review-plugin.md`: independent review of this plugin)

## License

heinzelwerk is MIT (`LICENSE`). Skills copied from mattpocock/skills (MIT) and dietrichgebert/ponytail (MIT) keep their own licenses; which files, what was adapted, and the full texts are in `THIRD_PARTY_NOTICES.md`. Some ideas come from Hephaestus (AGPL-3.0); no code or text copied.

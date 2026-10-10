# heinzelwerk

_Named after the Heinzelmännchen of Cologne, the house gnomes who finished the town's work overnight while everyone slept._

Claude Code plugin: a lean autonomous dev team (coordinator / product / lead / backend / frontend / infra / validator) on top of Claude Code agent teams, plus the skills to shape work before the team touches it.

## Principles

- **Align before building.** A human grills the idea into a spec and slices it into tracer-bullet tickets. The team only runs `ready-for-agent` slices.
- **Shared language.** `GLOSSARY.md` and ADRs keep agents concise and naming consistent. Agents propose terms; humans confirm them.
- **Feedback loops.** Red → green at agreed seams; validator runs real checks and a two-axis review (standards, spec).
- **Deep modules.** Small interfaces, lots of behaviour behind them; tests through the interface.
- **Phases, not pipelines.** Work is typed analyze / implement / validate; any agent may create work in any phase, every task leaves a handoff.
- **Tickets are durable, tasks are disposable.** Everything the next run needs lives on GitHub.
- **Pointers, not imports.** `CLAUDE.md` holds a short `## Agent skills` block; agents read `docs/agents/*` when the pointer fires.
- **Humans merge.** Agents open PRs, never merge, never push main.
- **Infra auto-applies only through a deterministic gate.** `scripts/tf-gate` checks the saved plan against `infra-policy.json` (environment allowlist, no destroys, protected types, change limit). Lead applies on pass and escalates on fail or doubt. Credential scope is the real boundary: agents never hold prod write credentials.

## Install

```sh
claude --plugin-dir /path/to/heinzelwerk         # try locally
/plugin marketplace add mradomsky/heinzelwerk     # or from GitHub
/plugin install heinzelwerk
```

Enable agent teams in `~/.claude/settings.json`: `{ "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" } }`

Start team runs **without MCP servers**: every teammate otherwise loads every connected server's tool definitions on every turn.

```sh
claude --model opus --strict-mcp-config   # coordinator on Opus; no MCP servers in this session
```

Need one for a run (e.g. an issue tracker without `gh`)? Pass only that one: `claude --strict-mcp-config --mcp-config ./mcp-run.json`.

## Workflow

1. **Once per repo or workspace**: `/heinzelwerk:setup` → interview → one PR per repo with `docs/agents/*`, optional seeded `GLOSSARY.md`/ADRs, and the `## Agent skills` block. Review, merge. In a multi-repo folder, run it from the parent folder; it also writes the workspace docs into the tickets repo.
2. **Shape (you + product)**: `/heinzelwerk:shape [issue | idea]`. Product grills you, writes the spec, slices it into `ready-for-agent` tickets with blocking edges, and lists the frontier. Also the way back in after a run stops on `needs-info`. Want only the interview? Stop after the grill. `/heinzelwerk:to-spec` and `/heinzelwerk:to-tickets` stay typeable for odd cases (e.g. slicing a spec written elsewhere).
3. **Build (you + coordinator)**: `/heinzelwerk:feature <slice>` or `/heinzelwerk:bugfix <issue>`. Your session becomes coordinator: your single point of contact, routes scope questions to product and technical ones to lead, watches the team, posts the final report.

## Roles

| Role | Owns | Where | Model |
|---|---|---|---|
| coordinator | process: your channel, lifecycle, observation, final report | main session of a run (`skills/coordinator`) | Opus |
| product | what: shaping, spec gate, scope answers, acceptance verdict | main session of `/shape`; teammate in runs | Opus in `/shape`, Sonnet in runs |
| lead | how: tasks, seams, technical triage, diagnose, docs PR | teammate | Opus |
| backend / frontend | building, test-first | teammates | Sonnet |
| infra | Terraform: plan, never apply | teammate | Sonnet |
| validator | checks + two-axis review | teammate | Sonnet; Opus review on the project's risk areas |

Escalation and degradation happen through subagents (Opus for depth, Haiku for breadth and mechanical work), per `skills/model-selection`.
4. **Review** the PRs, including the docs PR (that review is how glossary, ADRs, and learnings get approved). Merge.
5. **Weekly**: `/heinzelwerk:retro` over the week's runs, including an architecture survey (deepening candidates filed as `needs-triage`) → retro record + doc PR for the project, issues in this repo for the team. Good use of leftover tokens.
6. **New docs appeared?** `/heinzelwerk:adopt-docs` absorbs only new or changed docs (ledger in `docs/agents/adopted.md`).

## What gets written into a target repo

```
CLAUDE.md                 ## Agent skills pointer block
GLOSSARY.md               lazily, resolved terms only
docs/adr/                 lazily, decisions meeting all three ADR criteria
docs/agents/
  issue-tracker.md  triage-labels.md  domain.md  team.md  repo-map.md  learnings.md
  design.md               UI repos: design system
  infra-policy.json       infra repos: tf-gate policy
scripts/tf-gate  scripts/ui-shots   copied by setup when infra / UI exist
  adopted.md              ledger of adopted docs
  retros/                 retro records
  workspace.md            tickets repo only, workspace mode
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
- `skills/phased-workflow` — phases, handoffs, tickets, done notes, docs candidates
- `skills/team-modes` — single-repo vs workspace cooperation rules
- `skills/adopt-docs` — existing docs → ADRs, glossary, repo map, issues; also runnable directly
- `skills/diagnosing-bugs` — red loop → minimise → hypothesise → instrument → fix, used by `/bugfix`
- `skills/handoff` — run state to the ticket when context gets heavy or a run stops
- `skills/improve-codebase-architecture` — deepening opportunities; run weekly by retro, or directly for an ad-hoc survey
- `skills/prototype` — throwaway UI variations / logic walkthroughs, used by `/shape`
- `skills/model-selection` — which tier for which work; heinzelwerk role table and escalation triggers
- `skills/ponytail` — smallest-complete-change discipline, preloaded into backend, frontend, infra
- `skills/ponytail-debt` — `shortcut:` ledger, used by retro
- `skills/caveman` — terse voice, preloaded into lead, backend, frontend
- `skills/tdd`, `skills/code-review`, `skills/codebase-design`, `skills/domain-modeling`, `skills/grilling`, `skills/writing-for-agents`

Other:
- `agents/` — roles, usable as subagents or teammates
- `hooks/` — `guard.sh` blocks push/merge to main, plain `--force`, `--no-verify`, adding secret/state files, raw `terraform apply/destroy/import/state`, `-auto-approve`
- `docs/test-run-plan.md` — staged plan for the first runs
- `prompts/` — loose prompts, staging area before `skills/` or `commands/` (e.g. `review-plugin.md`: independent review of this plugin)

## License

heinzelwerk is MIT (`LICENSE`). Skills copied from mattpocock/skills (MIT), JuliusBrussee/caveman (Apache-2.0), and dietrichgebert/ponytail (MIT) keep their own licenses; which files, what was adapted, and the full texts are in `THIRD_PARTY_NOTICES.md`. Some ideas come from Hephaestus (AGPL-3.0); no code or text copied.

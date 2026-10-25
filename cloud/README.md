# heinzelwerk-cloud

The [heinzelwerk](../README.md) roles and skills for **cloud Claude Code sessions** (claude.ai/code, the Claude app),
where a probe of the root plugin ([stagehopper `docs/runs/2026-10-25-cloud-probe.md`](https://github.com/mradomsky/stagehopper/blob/claude/gallant-wozniak-xn24ex/docs/runs/2026-10-25-cloud-probe.md))
found these facts:

| In cloud | Consequence |
|---|---|
| plugin loads from `CLAUDE_CODE_PLUGIN_DIRS`; agents, skills, hooks and `bin/` on PATH all work | same plugin shape, same guard hook, same `tf-gate` and `ui-shots` |
| `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` is ignored: no team dir, no shared task list, no messaging; a spawned role is a plain subagent that ends with one report | roles are subagents, the coordinator spawns every task and routes every question; reports replace messages |
| a subagent has no `Agent` tool | no Opus/Haiku escalation, no two review sub-agents, no design drafters inside a role; the role asks (`escalate:`) and the coordinator reruns it on that tier |
| the `effort` on a spawn is ignored (reads low) | role frontmatter keeps it; expect low |
| GitHub GraphQL is rejected (403): every `gh pr`, `gh issue`, `gh label`, `gh search` subcommand; `gh api` REST and `gh pr diff` work | `skills/team-modes/gh-rest.md` is the command table; `bin/merge-gate` is a REST port; the setup template `issue-tracker-github.md` is REST |
| remote branches cannot be deleted (403 on push `--delete` and on `DELETE git/refs`) | the final report lists branches for the human to delete |
| the session model is fixed by the environment; `--model opus` and `--strict-mcp-config` don't exist; connected MCP servers load in every subagent | commands carry no `model:`; keep the environment's MCP servers few |
| workspace mode (a folder of repos) has no cloud equivalent | single mode only |

Everything else is the root plugin: same principles, same target-repo docs (`docs/agents/heinzelwerk/*`, shared with
local runs), same gates and policies, same `heinzelwerk: validated <sha>` marker, same metrics block (plus `platform: cloud`).

## Install

Cloud sessions install no plugins through `/plugin`; the environment loads it from a directory:

- setup script: `git clone --depth 1 https://github.com/mradomsky/heinzelwerk ~/heinzelwerk`
- environment variable: `CLAUDE_CODE_PLUGIN_DIRS=~/heinzelwerk/cloud`

Local sessions can run it too (`claude --plugin-dir /path/to/heinzelwerk/cloud`) when you want the subagent flow
without agent teams. Marketplace entry: `heinzelwerk-cloud` in this repo's `.claude-plugin/marketplace.json`.

## Layout

`cloud/` is a derived plugin. `sync.sh` copies every file under `agents`, `bin`, `commands`, `hooks`, `skills` from the
root plugin with the skill namespace renamed (`heinzelwerk:x` → `heinzelwerk-cloud:x`), except the **forks** it lists,
which cloud maintains by hand because the team mechanics changed:

- `commands/feature.md`, `commands/bugfix.md`, `commands/shape.md`
- `agents/*` (reports instead of messages, no subagents, REST)
- `skills/coordinator` (spawns every task, holds the task board in the run-state comment, runs `merge-gate`)
- `skills/team-modes` (reports, `gh-rest.md`, single mode only)
- `skills/phased-workflow` (task = one spawn, routing lines, fix cap by report)
- `skills/code-review` (both axes by the reviewer itself)
- `skills/setup/issue-tracker-github.md` (REST)
- `bin/merge-gate` (REST)

After changing the root plugin, run `cloud/sync.sh` and review the forks by hand; `hooks/guard-test.sh` covers the hook.

## Known gaps

- `effort` cannot be set on a cloud subagent; validator and tech-lead run at whatever the platform gives.
- The REST merge (`PUT pulls/N/merge`) and retarget (`PATCH pulls/N`) paths are untested through the cloud proxy:
  the first live run tells.
- Commands with `disable-model-invocation` are hidden from the model in cloud; the user types them.

# Workspace

This repo is the **tickets repo** of a multi-repo workspace. Mode rules live in the `heinzelwerk:team-modes` skill. Verified against <sha> <date>.

- **Tickets**: <owner/name>, the source of truth for the workspace: tickets, this file, `GLOSSARY-MAP.md`, workspace-wide ADRs, learnings
- **Autonomy**: <full | guarded> (see each repo's `team.md`)
- **Integration** (validator runs it across all touched repos on the shared branch name; omit if none): <e.g. `docker compose up -d && npm run smoke`>

## Repos

| Dir | GitHub | Role (owner) | Checks |
|---|---|---|---|
| <dir> | <owner/name> | <backend / frontend / infra> | see `<dir>/docs/agents/heinzelwerk/team.md` |

## Who calls whom

- <repo A> → <repo B> (provider): <HTTP / queue / shared package / MCP>, contract at <path>

## Cross-repo traps

- <facts only>

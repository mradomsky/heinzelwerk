# Workspace

This repo is the **tickets repo** of a multi-repo workspace. Mode rules live in the `team-modes` skill.

- **Tickets**: <owner/name>
- **Integration** (validator runs it across all touched repos on the shared branch name; omit if none): <e.g. `docker compose up -d && npm run smoke`>

## Repos

| Dir | GitHub | Role (owner) | Checks |
|---|---|---|---|
| <dir> | <owner/name> | <backend / frontend / infra> | see `<dir>/docs/agents/team.md` |

## Who calls whom

- <repo A> → <repo B> (provider): <HTTP / queue / shared package / MCP>, contract at <path>

## Cross-repo traps

- <facts only>

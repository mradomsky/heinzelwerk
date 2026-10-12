# Workspace mode (several repos)

Rules that apply only in workspace mode. The shared rules are in [SKILL.md](SKILL.md).

| Topic | Rule |
|---|---|
| Tickets | only in the tickets repo named in its `docs/agents/heinzelwerk/workspace.md`. Refs always `owner/repo#N`, also in commits |
| Ownership | by repo, from the repo table in `docs/agents/heinzelwerk/workspace.md` (role column). Inside a repo, that repo's own `docs/agents/heinzelwerk/team.md` applies as in single mode |
| Same feature, several repos | **same branch name in every touched repo**. That name is the feature's key; tech-lead writes it in the plan |
| Task granularity | one task per repo. A task never edits two repos. Contract tasks are always cross-repo here |
| Cross-repo contract | change a consumer task depends on: provider repo's task first (it owns the contract); consumer tasks blocked-by it; consumer PR body: `Depends on owner/provider-repo#<PR>`. Compatible change no consumer task needs: provider PR with the `contract: compatible` line (see **Contract changes** in SKILL.md) |
| PR body | `Refs owner/tickets-repo#N` on all PRs; `Closes owner/tickets-repo#N` only on the last PR tech-lead names |
| Checks | each repo's own `checks:`, run inside that repo's worktree |
| Integration | if `docs/agents/heinzelwerk/workspace.md` defines one, validator creates worktrees of the shared branch name in every touched repo (main for untouched ones) and runs it from there |
| Learnings, `GLOSSARY-MAP.md`, workspace-wide ADRs | only in tickets repo. Per-repo `GLOSSARY.md` and ADRs stay in their repo |
| Repo not in workspace map | do not touch. Tell tech-lead |

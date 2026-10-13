# Single mode (one repo)

Rules that apply only in single mode. The shared rules are in [SKILL.md](SKILL.md).

| Topic | Rule |
|---|---|
| Tickets | issues of this repo, refs `#N` |
| Ownership | by path, from `docs/agents/heinzelwerk/team.md` (backend, frontend, infra, shared paths). Never edit outside your paths. Shared paths (types, config) → only the task's named owner touches them |
| Parallel work | two tasks may touch the same repo, never the same file. Tech-lead checks file overlap when seeding; overlap → make one task block the other |
| Contract | rules in [contracts.md](contracts.md); a consumer task blocked by an unmerged same-repo contract task branches from it: `worktree add ... -b <branch> origin/<contract-branch>` |
| PR body | `Closes #N` on the PR that completes the ticket, `Refs #N` on the others |
| Checks | from `docs/agents/heinzelwerk/team.md` |

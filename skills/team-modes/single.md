# Single mode (one repo)

Rules that apply only in single mode. The shared rules are in [SKILL.md](SKILL.md).

| Topic | Rule |
|---|---|
| Tickets | issues of this repo, refs `#N` |
| Ownership | by path, from `docs/agents/heinzelwerk/team.md` (backend, frontend, infra, shared paths). Never edit outside your paths. Shared paths (types, config) → only the task's named owner touches them |
| Parallel work | two tasks may touch the same repo, never the same file. Tech-lead checks file overlap when seeding; overlap → make one task block the other |
| Contract | paths from **Contracts** in `docs/agents/heinzelwerk/team.md`. Contract change a consumer task depends on (compatible or breaking): own task for the provider role, lands in a PR first; consumer tasks blocked-by it and branch from the contract branch: `worktree add ... -b <branch> origin/<contract-branch>`. Compatible change no consumer task needs: in the provider's own PR (see **Contract changes** in SKILL.md) |
| PR body | `Closes #N` on the PR that completes the ticket, `Refs #N` on the others |
| Checks | from `docs/agents/heinzelwerk/team.md` |
| Validator | checks out PR branch in its own worktree, runs checks, walks criteria |

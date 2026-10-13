# Team rules

How heinzelwerk agents work in this repo. Mode rules (single repo vs workspace) live in the `heinzelwerk:team-modes` skill; this file holds only what is specific to this repo.

- **Backend paths**: <e.g. services/>
- **Frontend paths**: <e.g. command-interface/>
- **E2E** (validator runs it on the integrated slice; omit if none): <e.g. `npm run e2e -- --reporter=dot`, a smoke script>
- **UI preview**: <start command with port, e.g. `npm run dev -- --port $PORT`> · base URL <http://localhost:$PORT> · screenshots via `npx playwright screenshot` · publish via `scripts/ui-shots`
- **Infra paths**: <e.g. infra/> (environment dirs under it, e.g. infra/envs/dev)
- **Infra checks**: <e.g. `terraform fmt -check -recursive`, `tflint`>
- **Infra policy**: `docs/agents/heinzelwerk/infra-policy.json`, enforced by `scripts/tf-gate`
- **Shared paths** (only the task's named owner edits): <e.g. packages/types/>
- **Worktree setup** (run once in every new task worktree; omit if none): <e.g. `npm ci --prefer-offline --no-audit --no-fund`>
- **Checks** (validator runs every one, in order; quiet variants, failures only): <e.g. `npm run build --silent`, `npm run lint -- --quiet`, `npm test -- --reporter=dot`>
- **Security**: <secret scan pre-commit hook, e.g. gitleaks> · <dependency audit in checks, e.g. `npm audit --audit-level=high`>
- **Coding standards**: <path to CODING_STANDARDS.md / CONTRIBUTING.md, or "none: smell baseline only">; UI repos also `docs/agents/heinzelwerk/design.md`
- **Risk areas** (validator reviews diffs touching these on Opus). Project-specific; each entry is a path/glob or a described kind of change, plus why it is risky:
  - <e.g. `services/auth/**`: authorization decisions>
  - <e.g. any DB migration: irreversible on prod data>
  - <e.g. calls to the payment provider: money moves>
  - infra paths: always a risk area
- **Contracts** (team-modes **Contract changes**; validator checks every diff touching these):
  - API: <e.g. docs/api-contract.md> = single source of truth backend ↔ frontend · provider backend
  - Infra outputs: <e.g. infra/**/outputs.tf> · provider infra
  - Shared types: <e.g. packages/types/> · provider = the task's named owner

# Team rules

How heinzelwerk agents work in this repo. Mode rules (single repo vs workspace) live in the `heinzelwerk:team-modes` skill. This file holds only what is specific to this repo.

- **Autonomy**: <full | guarded>. Full: agents merge and apply on their own; breakages are learnings. Guarded: humans merge risky changes; agents never read secrets. In both: secrets are never published (name the variable, never the value), and the gate never merges its own policy.
- **Backend paths**: <e.g. services/>
- **Frontend paths**: <e.g. command-interface/>
- **E2E** (validator runs it on the integrated slice; omit if none): <e.g. `npm run e2e -- --reporter=dot`, a smoke script>
- **UI preview**: <start command with port, e.g. `npm run dev -- --port $PORT`> · base URL <http://localhost:$PORT> · screenshots via `npx playwright screenshot` · publish via `ui-shots`
- **Infra paths**: <e.g. infra/> (environment dirs under it, e.g. infra/envs/dev)
- **Infra checks**: <e.g. `terraform fmt -check -recursive`, `tflint`>
- **Infra policy**: `docs/agents/heinzelwerk/infra-policy.json`, enforced by the plugin's `tf-gate`
- **Infra apply order** (provider before consumer, from `terraform_remote_state`): <e.g. network → data → services>
- **Infra secrets**: <stacks whose plan decrypts secrets, e.g. `infra/envs/prod`: no agent plan | agents may plan them (full autonomy)> · agent credentials can write to <e.g. dev only | all environments>
- **Shared paths** (only the owner named in the task edits them): <e.g. packages/types/>
- **Worktree setup** (run once in every new task worktree; omit if none): <e.g. `npm ci --prefer-offline --no-audit --no-fund && cp "$(cd "$(git rev-parse --git-common-dir)/.." && pwd)/.env.local" .`; the common dir, never a `../` chain: worktree depth varies>
- **Checks** (validator runs every one, in order; copied from CI, quiet flags only): <e.g. `npm run build --silent`, `npm run lint -- --quiet`, `npm test -- --reporter=dot`, `npm audit --audit-level=high (red on main: #12)`, `docker build -q . (unverified locally: docker)`, `actionlint (CI only: needs $RUNNER_TEMP)`>
- **Verified against**: <sha> <date> (checks and every ref in this file; retro bumps it)
- **Run cap** (wall clock per run; coordinator stops the run past it; omit for none): <e.g. 3h>
- **Coding standards**: <path to CODING_STANDARDS.md / CONTRIBUTING.md, or the lint config this repo's `package.json` names, or "none: smell baseline only">; UI repos also `docs/agents/heinzelwerk/design.md`
- **Risk areas** (validator reviews diffs touching these on Opus). Project-specific; each entry is a path/glob or a described kind of change, plus why it is risky. A file family gets its glob, not one member (`contract-skip*`, `scripts/cutover-*`); a gate or judge script is listed with the inputs it reads:
  - <e.g. `services/auth/**`: authorization decisions>
  - <e.g. `scripts/run-contract.cjs` and its inputs `contract-skip*`, `contract-skip.expected`: decide what the contract suite may skip>
  - <e.g. `POST /webhooks/anomaly` in `src/server.ts`: unauthenticated, triggers paid calls>
  - <e.g. any DB migration: irreversible on prod data>
  - <e.g. calls to the payment provider: money moves>
  - infra paths: always a risk area
- **Contracts** (see team-modes **Contract changes**; validator checks every diff touching these):
  - API: <e.g. docs/api-contract.md> = single source of truth backend ↔ frontend · provider backend
  - Provided (omit if none; everything another repo depends on by shape or by name, not only routes): <e.g. `POST /webhooks/anomaly` in `src/server.ts:16-26`, called by automation-service; the outbound webhook body `{id,type,…}` in `src/webhookDelivery.ts:177-185`, received by ai-service; the error strings pinned by meta `fixtures/gateway-errors.json` (`src/server.ts:248`), asserted by agent-service and fleet-service; infra: the SSM document `<svc>-bootstrap-*` and its `imageTag` parameter, the CI role `github-actions-deploy`, invoked by name from each service's workflow> · consumers <repos>
  - Consumed: <e.g. `POST /auth/v1/m2m-token` of auth-service, called from `src/auth.ts:40`> · provider <repo>
  - Vendored: <e.g. `contract/fixtures/introspection.json`, copy of meta `fixtures/introspection.json`, pinned in `contract/fixtures/SOURCE.txt`; or `src/generated/` from meta `openapi/x.json`, unpinned> · provider <repo>; a provider change means a re-vendor or regenerate here
  - Infra outputs: <e.g. infra/**/outputs.tf> · provider infra
  - Shared types: <e.g. packages/types/> · provider = the task's named owner

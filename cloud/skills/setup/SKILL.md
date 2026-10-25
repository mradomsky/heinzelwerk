---
name: setup
description: Set up a repo, or a folder of repos, for the dev team — issue tracker, triage labels, domain docs (glossary, ADRs), team rules, repo map, learnings, and the CLAUDE.md (or AGENTS.md) pointer block. Run once per repo or workspace before any team run.
disable-model-invocation: true
---

# Setup

Scaffold the agentic documentation the dev team assumes:

- **Issue tracker**: GitHub issues, one tracker per repo or one tickets repo per workspace
- **Triage labels**: the five canonical triage roles
- **Domain docs**: where `GLOSSARY.md` and ADRs live, and the consumer rules for reading them
- **Team rules**: paths, checks, coding standards, contracts
- **Repo map** and **learnings**

This is a prompt-driven skill, not a deterministic script. Explore, present what you found, confirm with the user, then write. Every file you write is a document an agent consumes: follow the `heinzelwerk-cloud:writing-for-agents` skill.

## 1. Explore

Read whatever exists; don't assume.

- **Mode**: cwd is a git repo → single mode. Not a repo but child dirs with `.git` → workspace mode (see `heinzelwerk-cloud:team-modes` skill §0).
- Per repo: `git remote -v`, `CLAUDE.md` / `AGENTS.md` (existing `## Agent skills (heinzelwerk)` block?), `GLOSSARY.md`, `GLOSSARY-MAP.md`, `CONTEXT.md` (older name for the glossary), `docs/adr/`, `docs/agents/`, `CODING_STANDARDS.md`, `CONTRIBUTING.md`, existing design docs, build/test/lint scripts, CI config, `gh label list`.
- Map each repo (or each top-level area in single mode) with parallel Haiku Explore subagents (effort low; `heinzelwerk-cloud:model-selection`). Each returns, max 15 lines: purpose, entry points, how to build/test/run, patterns to follow, traps, and in workspace mode what it calls / is called by.

## 2. Present findings and ask

Summarise what's present and what's missing. Then take the sections in order: one section, one answer, then the next. Lead each section with the recommended answer so the user can accept it in a word. Skip a section entirely when exploration already settled it.

**A — Mode and tickets.** Single: tickets are this repo's issues. Workspace: ask which repo holds the tickets (recommend the one already holding cross-cutting issues).

**B — Triage labels.** Ask exactly one question: keep the default five (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`)? Recommended: yes. Only on no, collect overrides so existing labels are reused instead of duplicated.

**C — Team rules** (per repo). Propose backend paths, frontend paths, shared paths, risk areas (see below), E2E command (e2e or smoke tests, if any), worktree setup (the install command a fresh checkout needs, e.g. `npm ci` when a lockfile exists), security checks (deterministic, never a model: a secret scan such as gitleaks installed as a pre-commit hook so it runs in every worktree, and a dependency audit such as `npm audit --audit-level=high` or osv-scanner in `checks`), checks (from scripts/CI, in their quiet/summary form: flags that print failures only; any check that scans the whole repo must ignore `.claude/worktrees/`, where task worktrees live, else propose that ignore edit), coding standards source, contracts (API, infra outputs, shared types: paths and provider role for each). **Risk areas** are this project's, not a fixed list. Derive candidates from the code (security, money, persistence and migrations, data deletion, infra-as-code, public or cross-repo contracts, concurrency, personal data, external integrations, anything with past incidents in issues or docs), then ask the user for risks only they know. Each entry: path/glob or kind of change, plus why. Workspace: also propose each repo's role and the integration command if one exists (compose file, smoke script).

**C2 — Infra** (only if Terraform/OpenTofu found). Propose infra paths and checks. Then the apply policy, recommended answers first:
- Which environment dirs may agents auto-apply to? Recommend dev/sandbox only; never prod.
- Protected resource types: start from [infra-policy.json](infra-policy.json), add project-specific ones (state backend, DNS, data stores, anything listed as a risk area).
- Allowed deletes: recommend none to start.
- `.gitignore`: `plan.bin`, `*.tfplan`, `*.tfstate*` (saved plans carry sensitive values; the guard checks only explicit `git add` arguments, so `git add -A` must not see them).
- Credentials: tell the user the real boundary is credential scope — agents get credentials that can write only the auto-apply environments and read (plan) elsewhere; prod write credentials never exist in the agent environment. Ask them to confirm this is set up; record the answer in `team.md`.
- Post-merge apply for higher environments: CI job if they have one (recommend), else tech-lead applies through the gate in the next run where policy allows.

**C3 — Frontend design and preview** (only if a UI exists). Propose:
- `docs/agents/heinzelwerk/design.md` from [design.md](design.md): extract tokens, components, and style rules from the code, theme files, and existing style docs; ask the user for rules only they know.
- UI preview: the command that starts the app for screenshots (dev server with a port argument, or a static build + preview) and the base URL; Playwright as the screenshot tool (`npx playwright screenshot`, no MCP needed); screenshots are published by the plugin's `ui-shots`. Record both in `team.md`.

**D — Domain docs.** Default single-context: `GLOSSARY.md` + `docs/adr/` at repo root. Workspace: one context per repo plus `GLOSSARY-MAP.md` and workspace-wide ADRs in the tickets repo. A legacy `CONTEXT.md` → offer to rename it to `GLOSSARY.md`.

**E — Seed the domain model (optional).** Recommend yes when no glossary exists. Run a short session with the `heinzelwerk-cloud:grilling` and `heinzelwerk-cloud:domain-modeling` skills: propose 5–15 candidate terms found in code and docs, let the user resolve them, write only resolved terms. Offer ADRs only for decisions the user confirms and that meet all three ADR criteria. Never write a term or ADR the user didn't confirm.

**F — Existing docs.** If exploration found docs outside the agent structure, recommend adopting them now: run the `heinzelwerk-cloud:adopt-docs` skill on this setup's branch, after section E. It can be rerun later whenever new docs appear.

**G — Auto-merge** (single mode; workspace: off). Check first whether a merge to `main` deploys anywhere (workflows triggered on push to `main`). Recommend **on** when it doesn't, or when the project isn't production-critical; **off** when `main` ships to users. On:
- Policy from [merge-policy.json](merge-policy.json) with `enabled: true`. `allow_paths: ["*"]` unless the user names areas that must always wait for a human (`deny_paths`); risk areas still get Opus review either way. `merge_method` as the repo's history merges (merge commits vs squash). The gate and its policy always need a human. Say once: the `validated` line the gate trusts could be posted by any role (one `gh` login for all); acceptable while `main` is not production.
- CI on pull requests: `require_checks` stays true. No workflow runs on `pull_request` → propose `.github/workflows/heinzelwerk-checks.yml` running the **Worktree setup** and every **Checks** command from `team.md`.
- Permission: add `Bash(merge-gate *)` to `permissions.allow` in `.claude/settings.json` (committed; merge into an existing file). Without it, Claude Code's auto mode blocks the gate as "merge without review". The gate itself runs from the plugin's `bin/`, so updates arrive with the plugin and no PR can change it.
- Docs PRs merge through the gate too (validator checks their formats). Terms, ADRs, or learnings that should wait for a human → their paths in `deny_paths`.

## 3. Confirm

Show drafts of the `## Agent skills (heinzelwerk)` block (below) and every file under `docs/agents/heinzelwerk/`. Let the user edit before writing.

## 4. Write

Per repo, on a fresh branch from main `docs/heinzelwerk-setup`:

- `docs/agents/heinzelwerk/issue-tracker.md` from [issue-tracker-github.md](issue-tracker-github.md)
- `docs/agents/heinzelwerk/triage-labels.md` from [triage-labels.md](triage-labels.md); create missing labels with `gh label create`
- `docs/agents/heinzelwerk/domain.md` from [domain.md](domain.md)
- `docs/agents/heinzelwerk/team.md` from [team.md](team.md)
- UI found: `docs/agents/heinzelwerk/design.md` (C3)
- infra found: `docs/agents/heinzelwerk/infra-policy.json` from [infra-policy.json](infra-policy.json) with the answers from C2, and the `.gitignore` lines from C2 (`tf-gate` needs `jq` on the machine)
- `docs/agents/heinzelwerk/merge-policy.json` from [merge-policy.json](merge-policy.json) with the answers from G (off if G was skipped); G on → also the CI workflow and the `.claude/settings.json` permission
- **Upgrade from an older plugin**: `scripts/merge-gate`, `scripts/tf-gate`, `scripts/ui-shots` in the repo are copies an earlier setup made; delete them, replace `Bash(scripts/merge-gate *)` with `Bash(merge-gate *)`, and drop `max_changed_lines` from the policy unless the user wants a cap. The plugin's `bin/` provides the scripts now.
- `docs/agents/heinzelwerk/repo-map.md`: from the exploration, max 120 lines, facts only
- `GLOSSARY.md` / `docs/adr/` only if section E produced resolved content (lazy otherwise)

**Pick the file to edit**: always `CLAUDE.md`; Claude Code ignores `AGENTS.md` whenever any `CLAUDE.md` exists in the folder or above it. Only `AGENTS.md` exists → create `CLAUDE.md` with `@AGENTS.md` as its first line, then the block. If an `## Agent skills (heinzelwerk)` block exists, update it in place. Never edit another tool's block (e.g. a plain `## Agent skills`); add heinzelwerk's own below it. Don't overwrite user edits to surrounding sections.

The block:

```
## Agent skills (heinzelwerk)

- **Precedence**: for heinzelwerk team work, these pointers override any other agent-skills block in this file.
- **Issue tracker**: <one line>. See `docs/agents/heinzelwerk/issue-tracker.md` before creating, reading, or labelling issues.
- **Triage labels**: <one line>. See `docs/agents/heinzelwerk/triage-labels.md` before applying any label.
- **Domain docs**: <single- or multi-context>. Read `docs/agents/heinzelwerk/domain.md` before exploring code or naming anything.
- **Team rules**: read `docs/agents/heinzelwerk/team.md` before any team task.
- **Repo map**: see `docs/agents/heinzelwerk/repo-map.md` when locating code.
- **Design system** (UI repos): read `docs/agents/heinzelwerk/design.md` before building or reviewing any UI.
- **Learnings**: read `<path to learnings.md>` before starting any task.
```

**Workspace mode, additionally**, in the tickets repo on the same branch:

- `docs/agents/heinzelwerk/workspace.md` from [workspace.md](workspace.md)
- `docs/agents/heinzelwerk/learnings.md` from [learnings.md](learnings.md) (only here; other repos point at it)
- `GLOSSARY-MAP.md` if section E ran
- `CLAUDE.workspace.md`: an `## Agent skills (heinzelwerk)` block pointing at `docs/agents/heinzelwerk/workspace.md`, `GLOSSARY-MAP.md`, and the learnings file, plus one line: "Workspace mode: follow the `heinzelwerk-cloud:team-modes` skill."

Then tell the user to create, in the unversioned workspace folder, a `CLAUDE.md` containing only `@<tickets-repo-dir>/CLAUDE.workspace.md`. Do not create it yourself.

Single mode: `docs/agents/heinzelwerk/learnings.md` from [learnings.md](learnings.md) in the repo itself.

Commit `docs: set up agent docs`, open one PR per repo. Do not merge.

## 5. Done

Tell the user which PRs are open, that `/heinzelwerk-cloud:adopt-docs` absorbs docs added later and `/heinzelwerk-cloud:retro` reviews runs (weekly works well), and the next step: review and merge them, then shape work with `/heinzelwerk-cloud:shape`, and run `/heinzelwerk-cloud:feature <ticket>` on a `ready-for-agent` ticket. The `docs/agents/heinzelwerk/*.md` files can be edited directly later; re-run setup only to add a repo or start over.

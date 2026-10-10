---
name: setup
description: Set up a repo, or a folder of repos, for the dev team — issue tracker, triage labels, domain docs (glossary, ADRs), team rules, repo map, learnings, and the CLAUDE.md pointer block. Run once per repo or workspace before any team run.
disable-model-invocation: true
---

# Setup

Scaffold the agentic documentation the dev team assumes:

- **Issue tracker**: GitHub issues, one tracker per repo or one tickets repo per workspace
- **Triage labels**: the five canonical triage roles
- **Domain docs**: where `GLOSSARY.md` and ADRs live, and the consumer rules for reading them
- **Team rules**: paths, checks, coding standards, contracts
- **Repo map** and **learnings**

This is a prompt-driven skill, not a deterministic script. Explore, present what you found, confirm with the user, then write. Every file you write is a document an agent consumes: follow the `writing-for-agents` skill.

## 1. Explore

Read whatever exists; don't assume.

- **Mode**: cwd is a git repo → single mode. Not a repo but child dirs with `.git` → workspace mode (see `team-modes` skill §0).
- Per repo: `git remote -v`, `CLAUDE.md` / `AGENTS.md` (existing `## Agent skills` block?), `GLOSSARY.md`, `GLOSSARY-MAP.md`, `CONTEXT.md` (older name for the glossary), `docs/adr/`, `docs/agents/`, `CODING_STANDARDS.md`, `CONTRIBUTING.md`, existing design docs, build/test/lint scripts, CI config, `gh label list`.
- Map each repo (or each top-level area in single mode) with parallel Haiku Explore subagents (effort low; `model-selection`). Each returns, max 15 lines: purpose, entry points, how to build/test/run, patterns to follow, traps, and in workspace mode what it calls / is called by.

## 2. Present findings and ask

Summarise what's present and what's missing. Then take the sections in order: one section, one answer, then the next. Lead each section with the recommended answer so the user can accept it in a word. Skip a section entirely when exploration already settled it.

**A — Mode and tickets.** Single: tickets are this repo's issues. Workspace: ask which repo holds the tickets (recommend the one already holding cross-cutting issues).

**B — Triage labels.** Ask exactly one question: keep the default five (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`)? Recommended: yes. Only on no, collect overrides so existing labels are reused instead of duplicated.

**C — Team rules** (per repo). Propose backend paths, frontend paths, shared paths, risk areas (see below), acceptance command (e2e / smoke tests if any exist), security checks (deterministic, never a model: a secret scan such as gitleaks installed as a pre-commit hook so it runs in every worktree, and a dependency audit such as `npm audit --audit-level=high` or osv-scanner in `checks`), checks (from scripts/CI, in their quiet/summary form: flags that print failures only), coding standards source, contracts (API, infra outputs, shared types: paths and provider role for each). **Risk areas** are this project's, not a fixed list. Derive candidates from the code (security, money, persistence and migrations, data deletion, infra-as-code, public or cross-repo contracts, concurrency, personal data, external integrations, anything with past incidents in issues or docs), then ask the user for risks only they know. Each entry: path/glob or kind of change, plus why. Workspace: also propose each repo's role and the integration command if one exists (compose file, smoke script).

**C2 — Infra** (only if Terraform/OpenTofu found). Propose infra paths and checks. Then the apply policy, recommended answers first:
- Which environment dirs may agents auto-apply to? Recommend dev/sandbox only; never prod.
- Protected resource types: start from [infra-policy.json](infra-policy.json), add project-specific ones (state backend, DNS, data stores, anything listed as a risk area).
- Allowed deletes: recommend none to start.
- Credentials: tell the user the real boundary is credential scope — agents get credentials that can write only the auto-apply environments and read (plan) elsewhere; prod write credentials never exist in the agent environment. Ask them to confirm this is set up; record the answer in `team.md`.
- Post-merge apply for higher environments: CI job if they have one (recommend), else lead applies through the gate in the next run where policy allows.

**C3 — Frontend design and preview** (only if a UI exists). Propose:
- `docs/agents/design.md` from [design.md](design.md): extract tokens, components, and style rules from the code, theme files, and existing style docs; ask the user for rules only they know.
- UI preview: the command that starts the app for screenshots (dev server with a port argument, or a static build + preview) and the base URL; Playwright as the screenshot tool (`npx playwright screenshot`, no MCP needed). Record both in `team.md`.

**D — Domain docs.** Default single-context: `GLOSSARY.md` + `docs/adr/` at repo root. Workspace: one context per repo plus `GLOSSARY-MAP.md` and workspace-wide ADRs in the tickets repo. A legacy `CONTEXT.md` → offer to rename it to `GLOSSARY.md`.

**E — Seed the domain model (optional).** Recommend yes when no glossary exists. Run a short session with the `grilling` and `domain-modeling` skills: propose 5–15 candidate terms found in code and docs, let the user resolve them, write only resolved terms. Offer ADRs only for decisions the user confirms and that meet all three ADR criteria. Never write a term or ADR the user didn't confirm.

**F — Existing docs.** If exploration found docs outside the agent structure, recommend adopting them now: run the `adopt-docs` skill on this setup's branch, after section E. It can be rerun later whenever new docs appear.

## 3. Confirm

Show drafts of the `## Agent skills` block (below) and every `docs/agents/*.md` file. Let the user edit before writing.

## 4. Write

Per repo, on a fresh branch from main `docs/agent-setup`:

- `docs/agents/issue-tracker.md` from [issue-tracker-github.md](issue-tracker-github.md)
- `docs/agents/triage-labels.md` from [triage-labels.md](triage-labels.md); create missing labels with `gh label create`
- `docs/agents/domain.md` from [domain.md](domain.md)
- `docs/agents/team.md` from [team.md](team.md)
- UI found: `docs/agents/design.md` (C3) and `scripts/ui-shots` copied from [scripts/ui-shots](scripts/ui-shots) (executable)
- infra found: `docs/agents/infra-policy.json` from [infra-policy.json](infra-policy.json) with the answers from C2, and `scripts/tf-gate` copied from [scripts/tf-gate](scripts/tf-gate) (executable; needs `jq`)
- `docs/agents/repo-map.md`: from the exploration, max 120 lines, facts only
- `GLOSSARY.md` / `docs/adr/` only if section E produced resolved content (lazy otherwise)

**Pick the file to edit**: if `CLAUDE.md` exists, edit it; else if `AGENTS.md` exists, edit it; if neither exists, ask the user which one to create. Never create one when the other exists. If an `## Agent skills` block exists, update it in place. Don't overwrite user edits to surrounding sections.

The block:

```
## Agent skills

- **Issue tracker**: <one line>. See `docs/agents/issue-tracker.md` before creating, reading, or labelling issues.
- **Triage labels**: <one line>. See `docs/agents/triage-labels.md` before applying any label.
- **Domain docs**: <single- or multi-context>. Read `docs/agents/domain.md` before exploring code or naming anything.
- **Team rules**: read `docs/agents/team.md` before any team task.
- **Repo map**: see `docs/agents/repo-map.md` when locating code.
- **Design system** (UI repos): read `docs/agents/design.md` before building or reviewing any UI.
- **Learnings**: read `<path to learnings.md>` before starting any task.
```

**Workspace mode, additionally**, in the tickets repo on the same branch:

- `docs/agents/workspace.md` from [workspace.md](workspace.md)
- `docs/agents/learnings.md` from [learnings.md](learnings.md) (only here; other repos point at it)
- `GLOSSARY-MAP.md` if section E ran
- `CLAUDE.workspace.md`: an `## Agent skills` block pointing at `docs/agents/workspace.md`, `GLOSSARY-MAP.md`, and the learnings file, plus one line: "Workspace mode: follow the `team-modes` skill."

Then tell the user to create, in the unversioned workspace folder, a `CLAUDE.md` containing only `@<tickets-repo-dir>/CLAUDE.workspace.md`. Do not create it yourself.

Single mode: `docs/agents/learnings.md` from [learnings.md](learnings.md) in the repo itself.

Commit `docs: set up agent docs`, open one PR per repo. Do not merge.

## 5. Done

Tell the user which PRs are open, that `/heinzelwerk:adopt-docs` absorbs docs added later and `/heinzelwerk:retro` reviews runs (weekly works well), and the next step: review and merge them, then shape work with `/heinzelwerk:shape`, and run `/heinzelwerk:feature <ticket>` on a `ready-for-agent` ticket. The `docs/agents/*.md` files can be edited directly later; re-run setup only to add a repo or start over.

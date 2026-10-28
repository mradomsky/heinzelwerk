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
- **Team rules**: autonomy, paths, checks, coding standards, contracts
- **Repo map** and **learnings**

This is a prompt-driven skill, not a deterministic script. Explore, present what you found, confirm with the user, then write. Every file you write is a document an agent consumes: follow the `heinzelwerk:writing-for-agents` skill.

## 1. Explore

Read whatever exists; don't assume.

- **Mode**:
  - cwd is a git repo → single mode.
  - cwd is not a repo, but child dirs have `.git` → workspace mode (see the `heinzelwerk:team-modes` skill §0).
- **Fetch first.** `git -C <repo> fetch origin` in every repo. Everything below reads `origin/main`, never the local checkout: `git show origin/main:<path>`, or a detached worktree (`git -C <repo> worktree add <scratchpad>/<repo> origin/main --detach`; remove it in §4). Tell the user which local mains are behind `origin/main` and by how many commits.
- **Per repo**, read: `git remote -v`, `CLAUDE.md` / `AGENTS.md` (is there an existing `## Agent skills (heinzelwerk)` block?), `GLOSSARY.md`, `GLOSSARY-MAP.md`, `CONTEXT.md` (older name for the glossary), `docs/adr/`, `docs/agents/`, `CODING_STANDARDS.md`, `CONTRIBUTING.md`, existing design docs, build/test/lint scripts, CI config, `gh label list`. Also `command -v jq tflint osv-scanner docker`: a check whose tool is missing is written as `unverified locally`, never as green.
- **Map** each repo with one Sonnet subagent at effort medium, per the `heinzelwerk:model-selection` skill. In single mode, map each top-level area instead. Sonnet, not Haiku: nothing mechanical checks this output, and a wrong port or class name in `repo-map.md` is read on every run. Each subagent returns at most 40 lines, **every fact with `path:line`**, in this order:
  1. purpose, one line;
  2. entry points: routes with method, path, and the auth they require;
  3. unauthenticated routes, listed on their own;
  4. money or spend paths: code that moves game or real credits, calls to paid external APIs, anything with a bill;
  5. what the repo calls and what calls it (workspace mode), including vendored copies of another repo's fixtures or schemas and the file that pins them;
  6. how to build, test, run: exact commands, plus any git-ignored file the app needs to start (`.env.local`);
  7. CI jobs and their steps, in order, with arguments, so checks are copied, not guessed; which jobs deploy or release, on which trigger;
  8. persistence and migrations;
  9. patterns to follow;
  10. traps not visible from one file;
  11. existing docs outside the agent structure (for section F).
  A fact the code can't confirm is left out, not guessed. Evidence is a `path:line` or a command and its output, never the conversation, a memory, or another repo's generalisation.
- **Verify** each map with one Opus subagent at effort medium before you draft anything from it: it opens every cited `path:line` on `origin/main`, deletes or corrects what the code contradicts, and adds unauthenticated routes or money paths the mapper missed. Haiku finders with no stronger pass after them are what `model-selection` forbids ("a cheap tier as the final check"); this is that pass.
- **Start the checks now**, so they run while the user answers §2. Per repo, in the detached `origin/main` worktree: run the **Worktree setup** command, then every check CI runs, exactly as CI invokes it, one repo after another in a single background script. Build steps inside deploy or release jobs count as checks: a merge triggers them. A multi-line CI step is written to a temp script file and run from there, never pasted inline (quoting mangles heredocs). A step that needs CI-only state (`$RUNNER_TEMP`, `GITHUB_*`, an `actions/*` download) is recorded as `CI only` unless a local equivalent is obvious. Write exit code and the last 20 lines per check to `<scratchpad>/checks-<repo>.txt`. A check whose tool is missing is recorded as `unverified locally`, and the script goes on. §3 reads these files.

## 2. Present findings and ask

Summarise what's present and what's missing. Then take the sections in order: one section, one answer, then the next. Lead each section with the recommended answer so the user can accept it in a word. Skip a section entirely when exploration already settled it.

**A — Mode, tickets, autonomy.**
- Single mode: tickets are this repo's issues.
- Workspace mode: one repo is the **source of truth** for the whole workspace: tickets, `workspace.md`, `GLOSSARY-MAP.md`, workspace-wide ADRs, learnings. Recommend the repo already holding cross-cutting issues (often named `meta`). None exists → propose creating `<org>/meta`, private, with `gh repo create`; ask once, create only on yes, then clone it next to the others.
- **Autonomy**, one answer per workspace or repo, written into `team.md` (and `workspace.md`):
  - **full**: agents merge and apply on their own; breakages and leaks are accepted as learnings. Sets G to on with `allow_paths: ["*"]` (also in workspace mode), C2 to every environment dir with deletes allowed, and lets agents plan stacks whose plan reads secrets.
  - **guarded**: humans merge risky changes; secrets never reach an agent. Sets G to off, or on with the risk areas in `deny_paths`; C2 to dev/sandbox only, no deletes; stacks whose plan reads secrets are off limits.
  - Kept in both: the gate never merges changes to itself or its policy files; protected resource types stay protected (the user may empty the list); secrets are never published (no value in a PR body, ticket, done note, learning, or doc: name the variable, not the value).
  - Recommend **guarded** for anything that serves users or holds real credentials, **full** for a playground. C2 and G below still show the resulting values, so the user sees what the answer did.

**B — Triage labels.** Ask exactly one question: keep the default five (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`)? Recommended: yes. Only if the answer is no: collect overrides, so existing labels are reused instead of duplicated.

**C — Team rules** (per repo). Every line comes from that repo's verified map, with its evidence; the template's examples are examples. A sentence about "every repo" is written only when each repo's map shows it. Propose each of these:
- Backend paths, frontend paths, shared paths.
- Risk areas (see below).
- E2E command: e2e or smoke tests, if any.
- Worktree setup: the install command a fresh checkout needs, e.g. `npm ci` when a lockfile exists, plus a copy of each git-ignored file the app needs from the main checkout (`cp ../../.env.local .`), or a preview route that needs none.
- Dependency audit, a deterministic tool, never a model: `npm audit --audit-level=high`, osv-scanner, or whatever CI runs, listed in `checks`.
- Checks, copied from CI: the same steps, in the same order, with the same arguments and the same preceding steps (an `npm pack` before a script that takes the tarball), including build steps from deploy jobs. Add only flags that drop output without changing the exit code (`--silent`, `-q`); never a reporter or filter flag, which can hide the failure the validator needs. A step the runner marked `CI only` keeps that suffix, or gets the local equivalent. Any check that scans the whole repo must ignore `.claude/worktrees/`, where task worktrees live; if one doesn't, the ignore edit goes into this setup's PR (§4).
- Coding standards source: only what this repo's own config and dependencies use, cited (`package.json:<line>`); a shared config another repo uses is not this repo's standard.
- Run cap: wall clock per run, e.g. 3h. Propose none until the user knows how long a normal run takes.
- Contracts (API, infra outputs, shared types): paths and provider role for each, both what this repo provides and what it consumes from another repo, and every vendored copy of another repo's fixture or schema with its pin file. Infra outputs are a contract by default whenever `outputs.tf` files exist.

**Risk areas** are this project's, not a fixed list. Start from the verified map: every unauthenticated route and every money or spend path is a candidate. Add from the code: security, persistence and migrations, data deletion, infra-as-code, public or cross-repo contracts, concurrency, personal data, external integrations, anything with past incidents in issues or docs; what `CLAUDE.md` or the README marks as dangerous or production-touching. "A merge to `main` deploys" is an entry only where a workflow does that, cited by `path:line`. Then ask the user for risks only they know. Each entry: path/glob or kind of change, plus why.

Workspace mode: also propose each repo's role, and the integration command if one exists (compose file, smoke script).

**C2 — Infra** (only if Terraform/OpenTofu found). Propose infra paths and checks. Then the apply policy, defaults from the autonomy answer in A, shown so the user can change them:
- Which environment dirs may agents auto-apply to? Guarded: dev/sandbox only, never prod. Full: all.
- Protected resource types: start from [infra-policy.json](infra-policy.json), add project-specific ones (state backend, DNS, data stores, anything listed as a risk area). Kept in both settings.
- Allowed deletes: guarded none; full all.
- **Apply order.** Grep the stacks for `terraform_remote_state` and data sources that read another stack. Write the provider-before-consumer order into `team.md`; the user confirms it.
- **Secrets in plans.** Ask which stacks decrypt secrets during plan or refresh (SecureString parameters, sensitive outputs, data sources that return key material). Guarded: those stacks are listed in `team.md` as `no agent plan`, and infra skips them unless a task names one explicitly. Full: agents may plan them; the values stay on the machine.
- `.gitignore`: `plan.bin`, `*.tfplan`, `*.tfstate*`. Saved plans carry sensitive values. The guard checks only the files named explicitly on `git add`, so the ignore lines must keep them out of `git add -A`.
- Credentials: ask what the agent machine's credentials can write to, and record the answer as it is in `team.md`, also when it is "prod". Guarded: recommend credentials that write only the auto-apply environments and plan elsewhere, and say that this, not the policy file, is the real boundary.
- Post-merge apply for higher environments: a CI job if they have one (recommended). Otherwise tech-lead applies through the gate in the next run where policy allows.

**C3 — Frontend design and preview** (only if a UI exists). Propose:
- `docs/agents/heinzelwerk/design.md` from [design.md](design.md): extract tokens, components, and style rules from the code, theme files, and existing style docs. Ask the user for rules only they know. Every rule is checked against the code before it is written: a rule the code breaks in forty places is an aspiration, and the template forbids those.
- UI preview: the command that starts the app for screenshots (a dev server with a port argument, or a static build + preview) and the base URL. Playwright is the screenshot tool (`npx playwright screenshot`, no MCP needed). The plugin's `ui-shots` publishes the screenshots. Record the command and the base URL in `team.md`.

**D — Domain docs.**
- Default, single-context: `GLOSSARY.md` + `docs/adr/` at repo root.
- Workspace mode: one context per repo, plus `GLOSSARY-MAP.md` and workspace-wide ADRs in the tickets repo.
- A legacy `CONTEXT.md` exists → offer to rename it to `GLOSSARY.md`.
- Numbered decisions that live inside other docs (an "ADR-equivalent") → list them in `domain.md` under **ADRs elsewhere**, so readers find them without a move.

**E — Seed the domain model (optional).** Recommend yes when no glossary exists. Run a short session with the `heinzelwerk:grilling` and `heinzelwerk:domain-modeling` skills:
- Propose 5–15 candidate terms found in code and docs.
- Let the user resolve them. Write only resolved terms.
- Offer ADRs only for decisions the user confirms and that meet all three ADR criteria.
- Never write a term or ADR the user didn't confirm.

**F — Existing docs.** If exploration found docs outside the agent structure, recommend adopting them now. The `heinzelwerk:adopt-docs` skill then runs in §4, after the setup commit and before any PR opens, so one PR per repo carries both commits and nothing can be merged under it. That skill can be rerun later whenever new docs appear.

**G — Auto-merge.** Default from the autonomy answer in A: full → on, also in workspace mode; guarded → check first whether a merge to `main` deploys anywhere (workflows triggered on push to `main`).
- Recommend **on** when a merge doesn't deploy, or when the project isn't production-critical.
- Recommend **off** when `main` ships to users.

When on:
- Policy from [merge-policy.json](merge-policy.json) with `enabled: true`. `allow_paths: ["*"]`, unless the user names areas that must always wait for a human; those go in `deny_paths` (guarded: the risk areas, by default). Risk areas still get Opus review either way. `merge_method`: whichever the repo's history already uses (merge commits or squash). Changes to the gate itself and to its policy always wait for a human; the gate never merges them. Tell the user once: the `validated` line the gate trusts could be posted by any role, since all roles share one `gh` login; that is acceptable while `main` is not production.
- CI on pull requests: `require_checks` stays true. If no workflow runs on `pull_request`, propose `.github/workflows/heinzelwerk-checks.yml` running the **Worktree setup** and every **Checks** command from `team.md`, with the action versions the repo's (or workspace's) other workflows pin.
- Permission: add `Bash(merge-gate *)` to `permissions.allow` in `.claude/settings.json` (the committed file; merge into it if it already exists). Without it, Claude Code's auto mode blocks the gate as "merge without review". The gate itself runs from the plugin's `scripts/`, so updates arrive with the plugin and no PR can change it.
- Docs PRs merge through the gate too; validator checks their formats. If terms, ADRs, or learnings should wait for a human, put their paths in `deny_paths`.

## 3. Confirm the drafts

First read `<scratchpad>/checks-<repo>.txt` for every repo:
- Red on `origin/main` → the user keeps the check with the suffix `(red on main: <ticket>)`, where the ticket is opened `ready-for-human` in the tickets repo, or drops it. A red check stays in the list only with that suffix; the validator reads it (validator §1).
- Invocation differs from CI (argument, preceding step) → fix the check line, not the check.
- Red locally but green on `origin/main` in CI → the runner is the suspect, not the check: write `unverified locally (<reason>)`, never "fails on <OS>".
- `unverified locally` or `CI only` → the line keeps that suffix; the user may install the tool and rerun.
- Still running → wait, or write `unverified locally` and go on; the user decides.
- The user changed a check in C → rerun only that one.

Then show drafts of the `## Agent skills (heinzelwerk)` block (below) and every file under `docs/agents/heinzelwerk/`. Let the user edit before writing.

## 4. Write the files

Per repo, on a fresh branch `docs/heinzelwerk-setup` cut from `origin/main`:

- `docs/agents/heinzelwerk/issue-tracker.md` from [issue-tracker-github.md](issue-tracker-github.md); workspace mode: keep its **Workspace** paragraph and fill the tickets repo in
- `docs/agents/heinzelwerk/triage-labels.md` from [triage-labels.md](triage-labels.md); create missing labels with `gh label create` (workspace mode: in the tickets repo only)
- `docs/agents/heinzelwerk/domain.md` from [domain.md](domain.md)
- `docs/agents/heinzelwerk/team.md` from [team.md](team.md), including the `Autonomy` line and `Checks verified on main <sha> <date>`
- UI found: `docs/agents/heinzelwerk/design.md` as drafted in C3
- infra found: `docs/agents/heinzelwerk/infra-policy.json` from [infra-policy.json](infra-policy.json) with the answers from C2, and the `.gitignore` lines from C2. Keep only `protected_types` of providers the stacks use; `allowed_delete_types` takes globs, `"*"` for every unprotected type. `tf-gate` needs `jq` installed on the machine.
- `docs/agents/heinzelwerk/merge-policy.json` from [merge-policy.json](merge-policy.json) with the answers from G (off if G was skipped); G on → also the CI workflow and the `.claude/settings.json` permission
- the `.claude/worktrees/` ignore edit for every whole-repo check that lacked it (C)
- **Upgrade from an older plugin**: `scripts/merge-gate`, `scripts/tf-gate`, `scripts/ui-shots` in the repo are copies an earlier setup made. The plugin's `scripts/` provides them now (on PATH through its SessionStart hook). Delete the copies. Replace `Bash(scripts/merge-gate *)` with `Bash(merge-gate *)`. Drop `max_changed_lines` from the policy unless the user wants a cap.
- `docs/agents/heinzelwerk/repo-map.md`: from the verified map, max 120 lines, facts only
- `GLOSSARY.md` / `docs/adr/` only if section E produced resolved content; otherwise they are created later, when first needed

**Pick the file to edit**: always `CLAUDE.md`; Claude Code ignores `AGENTS.md` whenever any `CLAUDE.md` exists in the folder or above it.
- Only `AGENTS.md` exists → create `CLAUDE.md` with `@AGENTS.md` as its first line, then the block.
- An `## Agent skills (heinzelwerk)` block exists → update it in place.
- Never edit another tool's block (e.g. a plain `## Agent skills`); add heinzelwerk's own below it.
- Don't overwrite user edits to surrounding sections.

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
- `CLAUDE.workspace.md`: an `## Agent skills (heinzelwerk)` block pointing at `docs/agents/heinzelwerk/workspace.md`, `GLOSSARY-MAP.md`, and the learnings file, plus one line: "Workspace mode: follow the `heinzelwerk:team-modes` skill."

Then tell the user to create, in the unversioned workspace folder, a `CLAUDE.md` containing only `@<tickets-repo-dir>/CLAUDE.workspace.md`. Do not create it yourself.

Single mode: `docs/agents/heinzelwerk/learnings.md` from [learnings.md](learnings.md) in the repo itself.

Run `check-refs` (plugin script, on PATH) and fix every line it prints, then commit `docs: set up agent docs`. **F said yes → run `heinzelwerk:adopt-docs` now**, on the same branch; it adds its own commit and reconciles the refs its corrections moved. Only then open one PR per repo. Remove the detached worktrees from §1. Do not merge.

## 5. Done: tell the user

Tell the user:
- Which PRs are open. Workspace mode: the tickets repo's PR merges first, since every other PR points at its files.
- Which checks are red on main (with their tickets), `unverified locally` (with the missing tool), or `CI only`.
- Tools the gates still need on this machine (`jq` for `tf-gate`), before any auto-apply.
- `/heinzelwerk:adopt-docs` absorbs docs added later; `/heinzelwerk:retro` reviews runs (weekly works well).
- The next step: review and merge the PRs, then shape work with `/heinzelwerk:shape`, and run `/heinzelwerk:feature <ticket>` on a `ready-for-agent` ticket.
- The `docs/agents/heinzelwerk/*.md` files can be edited directly later. Re-run setup only to add a repo or start over.

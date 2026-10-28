---
name: adopt-docs
description: "heinzelwerk: absorb a repo's existing docs into the agent structure. Use from setup section F, or when new docs appeared."
---

# Adopt docs

Existing docs hold decisions, vocabulary, and planned work the team can't use until they sit where the team looks. This skill moves the **content** into the agent structure; the original files stay where they are.

Follow `heinzelwerk:writing-for-agents` for anything you write. Terms and ADRs go through `heinzelwerk:domain-modeling` formats and rules.

## 1. Inventory

- Read the mode from the `heinzelwerk:team-modes` skill §0. In a workspace, cover every repo, each handled in its own repo.
- Read `docs/agents/heinzelwerk/adopted.md` if it exists. It is the ledger of docs already adopted, with each doc's content hash at adoption.
- List candidate docs: Markdown and text docs anywhere outside `node_modules`, build output, and vendored code. Skip the agent structure: `docs/agents/heinzelwerk/`, `GLOSSARY*.md`, `docs/adr/`, `CLAUDE*.md`, `AGENTS*.md`. Other tools' files in `docs/agents/` are candidates.
- Keep only docs that are **new** or **changed**:
  - **new**: not in the ledger;
  - **changed**: `git hash-object <path>` differs from the ledger hash. Work on the diff (`git diff <ledger hash> $(git hash-object -w <path>)`), not the whole file;
  - a legacy ledger entry with a commit SHA: use `git rev-parse <sha>:<path>` as the ledger hash. If that fails, treat the doc as new.
- Nothing left → tell the user, stop.

## 2. Classify

Run Haiku subagents in parallel, 8–10 docs each, at effort medium. Medium because classifying feeds your decisions; 8–10 per subagent because one subagent per doc would pay the start-up context once per doc. Each returns, per doc, its content split into these classes, quoting the source heading for every item and, for a **stale** verdict, the `path:line` in the code that contradicts it:

| Class | Destination |
|---|---|
| **decision** with rationale | ADR candidate, only if hard to reverse, surprising without context, and a real trade-off. Otherwise drop it or make it a learning |
| **term**: a domain concept, possibly with synonyms | glossary candidate |
| **how-to**: build, run, deploy, where code lives | `docs/agents/heinzelwerk/repo-map.md` or `docs/agents/heinzelwerk/team.md` (checks, paths) |
| **planned work**: not built yet | spec issue candidate |
| **reference**: still-true material too long to restate | stays in place, gets a pointer line |
| **stale**: contradicted by code or by another doc | flagged for the user |
| **gotcha**: trap, constraint, or warning not visible in code | learning candidate |
| **design rule**: token, component usage, style or interaction rule | `docs/agents/heinzelwerk/design.md` |

Cross-check claims against the code. A doc that disagrees with the code is **stale** for that item, even if the rest is fine.

A Haiku verdict is a candidate, not a finding (`heinzelwerk:model-selection`: a cheap tier is never the final check). Before §3, verify every stale item, every ADR candidate, and every gotcha: a claim about files matching or differing is settled by `git hash-object` or `diff`, never by reading; everything else is checked by one Opus subagent at effort medium that opens the cited `path:line` on `origin/main`. For an ADR or gotcha it also names the `path:line` where the code does what the doc says. Drop what it cannot confirm.

## 3. Resolve with the user

Present per class, one class per round, recommended answer first (`heinzelwerk:grilling` format):

- **ADRs**: draft each in ADR format: 1–3 sentences that say only what the source says (no rationale the source lacks), the verified `path:line` of the code, and a `Source: <path>#<heading>` line, or `Source: <path>:<line>` when the item sits under no heading. User accepts, edits, or drops each.
- **Terms**: run `heinzelwerk:domain-modeling` with the `heinzelwerk:grilling` skill on the candidates. Pick canonical words, list `_Avoid_` synonyms, challenge against existing `GLOSSARY.md` and the code. Before a new `_Avoid_` word is written, grep the adopted docs and the code for it: where it appears in doc headings, tell the user which docs, since those stay as they are; where code identifiers use it, list them next to the term as exempt (`_Avoid_` governs prose and new names; an existing identifier keeps its name). Write only resolved terms.
- **Planned work**: one line each. Accepted items become issues labelled `needs-triage`, body = summary + link to the source section. The user shapes them later with `/heinzelwerk:shape <issue>`.
- **Design rules**: proposed additions to `docs/agents/heinzelwerk/design.md`. Contradictions with the code are flagged like stale items.
- **How-to, reference, gotchas**: show the proposed edits to repo map, team rules, and learnings. Reference docs get a pointer line under `## Reference docs` in the repo map, worded as a trigger: `- <path>: read when <condition>.`
- **Stale**: list item, source, and what contradicts it (the verified `path:line`). User decides: correct the doc, mark it, or ignore. **Correct** means append, never rewrite: a dated correction right below the stale item, in the doc's own convention (a dated note where the doc keeps dated notes, otherwise one line `Correction (<date>): <fact>, see <path:line>`). The stale line itself stays as it is: it is a record. Never correct a source doc silently.

**Workspace**: a decision or term that spans repos goes to the tickets repo: decisions as workspace ADRs, terms as `GLOSSARY-MAP.md` relationships. Everything else stays in its own repo.

## 4. Write

- Branch: when called from setup, reuse setup's branch; setup runs this skill after its own commit and before it opens the PR, so the PR carries both commits. Otherwise, per repo, a fresh branch from `origin/main` named `docs/adopt-docs`. Before pushing to a branch that already has a PR, check `gh pr view <branch> --json state`: anything but `OPEN` → cut a fresh `docs/adopt-docs` from `origin/main` and open a new PR; a commit pushed to a merged branch never reaches main.
- Write resolved ADRs, glossary terms, repo-map/team/learnings edits; create accepted issues.
- Update `docs/agents/heinzelwerk/adopted.md` (create if missing): one line per processed doc, `- <path> @ <hash>: <classes found> → <where content went>`. `<hash>` is `git hash-object <path>`: a content hash, not a commit SHA, because it survives squash and rebase merges.
- Never delete, move, or rewrite original docs. The only edit to an original is the appended dated correction from §3.
- **Reconcile the agent docs with this commit.** Setup verified its `path:line` refs against `origin/main`; the corrections above moved lines, and nothing else re-checks the branch head. So, before committing:
  - for every corrected file, shift each `path:line` in `docs/agents/heinzelwerk/*.md` that points past an insertion by the lines inserted, and update any "N lines" count. This is arithmetic, not a model's job;
  - a fact established in §2 or §3 that contradicts a line in `docs/agents/heinzelwerk/*.md`, `GLOSSARY.md` or an ADR fixes that line (those files are new on this branch, so rewriting them is fine); a renamed file (`CONTEXT.md` → `GLOSSARY.md`) is fixed in every pointer;
  - run `check-refs` (plugin script, on PATH): every cited path must exist at the branch head and every line must be inside its file. Fix or justify each line it prints.
- Commit `docs: adopt existing docs into agent structure`, then open a PR, or leave the commit on setup's branch for setup to open the PR. PR body lists stale items, corrections appended, and anything the user dropped. Do not merge.

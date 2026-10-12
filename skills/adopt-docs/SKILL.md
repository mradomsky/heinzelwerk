---
name: adopt-docs
description: Move a repo's existing docs into the heinzelwerk structure (ADRs, glossary, repo map, team rules, spec issues, pointers). Use to adopt or migrate docs, when new docs appeared, or from setup section F.
---

# Adopt docs

Existing docs hold decisions, vocabulary, and planned work the team can't use until they sit where the team looks. This skill moves the **content** into that structure; the original files stay where they are.

Follow `heinzelwerk:writing-for-agents` for anything you write. Terms and ADRs go through `heinzelwerk:domain-modeling` formats and rules.

## 1. Inventory

- Mode from the `heinzelwerk:team-modes` skill §0. Workspace: every repo, each handled in its own repo.
- Read `docs/agents/heinzelwerk/adopted.md` if it exists: the ledger of docs already adopted, with each doc's content hash at adoption.
- List candidate docs: Markdown and text docs anywhere outside `node_modules`, build output, and vendored code. Skip the agent structure (`docs/agents/heinzelwerk/`, `GLOSSARY*.md`, `docs/adr/`, `CLAUDE*.md`, `AGENTS*.md`). Other tools' files in `docs/agents/` are candidates.
- Keep only docs that are **new** (not in the ledger) or **changed** (`git hash-object <path>` differs from the ledger hash). Changed docs: work on the diff (`git diff <ledger hash> $(git hash-object -w <path>)`), not the whole file. Legacy entry with a commit SHA: use `git rev-parse <sha>:<path>` as the ledger hash; if that fails, treat the doc as new.
- Nothing left → tell the user, stop.

## 2. Classify

One Haiku subagent per doc (parallel, effort medium: classifying feeds your decisions; `heinzelwerk:model-selection`). Each returns its doc's content split into these classes, quoting the source heading for every item:

| Class | Destination |
|---|---|
| **decision** with rationale | ADR candidate (only if hard to reverse, surprising without context, and a real trade-off; otherwise drop or make it a learning) |
| **term**: a domain concept, possibly with synonyms | glossary candidate |
| **how-to**: build, run, deploy, where code lives | `docs/agents/heinzelwerk/repo-map.md` or `docs/agents/heinzelwerk/team.md` (checks, paths) |
| **planned work**: not built yet | spec issue candidate |
| **reference**: still-true material too long to restate | stays in place, gets a pointer line |
| **stale**: contradicted by code or by another doc | flagged for the user |
| **gotcha**: trap, constraint, or warning not visible in code | learning candidate |
| **design rule**: token, component usage, style or interaction rule | `docs/agents/heinzelwerk/design.md` |

Cross-check claims against the code. A doc that disagrees with the code is **stale** for that item, even if the rest is fine.

## 3. Resolve with the user

Present per class, one class per round, recommended answer first (`heinzelwerk:grilling` format):

- **ADRs**: draft each in ADR format (1–3 sentences, `Source: <path>#<heading>` line). User accepts, edits, or drops each.
- **Terms**: run `heinzelwerk:domain-modeling` with the `heinzelwerk:grilling` skill on the candidates: pick canonical words, list `_Avoid_` synonyms, challenge against existing `GLOSSARY.md` and the code. Write only resolved terms.
- **Planned work**: one line each. Accepted items become issues labelled `needs-triage`, body = summary + link to the source section. The user shapes them later with `/heinzelwerk:shape <issue>`.
- **Design rules**: proposed additions to `docs/agents/heinzelwerk/design.md`, contradictions with the code flagged like stale items.
- **How-to, reference, gotchas**: show the proposed edits to repo map, team rules, and learnings. Reference docs get a pointer line under `## Reference docs` in the repo map, worded as a trigger: `- <path>: read when <condition>.`
- **Stale**: list item, source, and what contradicts it. User decides: fix the doc, mark it, or ignore. Never fix a source doc silently.

Workspace: a decision or term spanning repos goes to the tickets repo (workspace ADRs, `GLOSSARY-MAP.md` relationships); everything else stays in its own repo.

## 4. Write

- Called from setup: reuse setup's branch and PR. Otherwise, per repo, fresh branch from main `docs/adopt-docs`.
- Write resolved ADRs, glossary terms, repo-map/team/learnings edits, create accepted issues.
- Update `docs/agents/heinzelwerk/adopted.md` (create if missing): one line per processed doc, `- <path> @ <hash>: <classes found> → <where content went>`, where `<hash>` is `git hash-object <path>`. Content hash, not commit SHA: it survives squash and rebase merges.
- Never delete, move, or rewrite original docs.
- Commit `docs: adopt existing docs into agent structure`, open PR (or add to setup's). PR body lists stale items and anything the user dropped. Do not merge.

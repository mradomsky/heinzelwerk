---
description: "Shape an idea or issue into ready-for-agent slice tickets with the product owner. Usage: /heinzelwerk-cloud:shape [issue-number | idea]"
disable-model-invocation: true
---
You are **product owner** for this session: you own **what** gets built, the user owns every decision. No team, no code. Follow `docs/agents/heinzelwerk/domain.md`, `docs/agents/heinzelwerk/issue-tracker.md`, and for UI work `docs/agents/heinzelwerk/design.md`.

GitHub only through REST: `gh pr`, `gh issue`, `gh label`, and `gh search` are rejected in cloud sessions; use [gh-rest.md](../skills/team-modes/gh-rest.md) from the `heinzelwerk-cloud:team-modes` skill.

Input: `$ARGUMENTS`. An issue number → read it with comments. Free text → that's the idea. Empty → list open `needs-triage` and `needs-info` issues and ask which one.

Pick the path by state:
- **`needs-info` issue** (a run stopped on it): put its questions to the user with the `heinzelwerk-cloud:grilling` skill, comment the answers on the issue, update its acceptance criteria, relabel `ready-for-agent`. Done.
- **Slice ticket that only needs sharpening**: grill only the open points, update it, label `ready-for-agent`. Done.
- **Idea, `needs-triage` issue, or spec issue** → full shaping:
  1. **Grill**: `heinzelwerk-cloud:grilling` + `heinzelwerk-cloud:domain-modeling` skills together. Resolve the design tree with the user; write resolved terms and ADRs as they land.
  1b. **Prototype** (when the slice changes what a screen looks like or how a flow behaves, and the user hasn't seen it yet): offer it; on yes, use the `heinzelwerk-cloud:prototype` skill: a few radically different UI variations, or a logic walkthrough. The user picks; the chosen variant and the question it settled go into the spec, the prototype goes to a throwaway branch with a pointer from the spec issue.
  2. **Spec**: `heinzelwerk-cloud:to-spec` skill, publishing to the tracker (an existing issue → update it into the spec instead of creating a new one).
  3. **Slice**: `heinzelwerk-cloud:to-tickets` skill on that spec. Tickets come out as sub-issues labelled `ready-for-agent`.
  4. Glossary or ADR changes from step 1 → commit on a fresh branch `docs/shape-<topic>`, `docs: update domain docs from shaping`, open PR.

Finish with the frontier: slices with no open blockers, each as the exact command to run (`/heinzelwerk-cloud:feature <n>`).

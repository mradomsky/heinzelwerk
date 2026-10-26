---
description: "Shape an idea or issue into ready-for-agent slice tickets with the product owner. Start the session with --model opus. Usage: /heinzelwerk:shape [issue-number | idea]"
model: opus
disable-model-invocation: true
---
You are **product owner** for this session: you own **what** gets built, the user owns every decision. No team, no code. Follow `docs/agents/heinzelwerk/domain.md`, `docs/agents/heinzelwerk/issue-tracker.md`, and for UI work `docs/agents/heinzelwerk/design.md`.

Input: `$ARGUMENTS`.
- Issue number → read it with comments.
- Free text → that's the idea.
- Empty → list open `needs-triage` and `needs-info` issues and ask which one.

Pick the path by state:
- **`needs-info` issue** (a run stopped on it): put its questions to the user with the `heinzelwerk:grilling` skill, comment the answers on the issue, update its acceptance criteria, relabel it `ready-for-agent`. Done.
- **Slice ticket that only needs sharpening**: grill only the open points, update the ticket, label it `ready-for-agent`. Done.
- **Idea, `needs-triage` issue, or spec issue** → full shaping:
  1. **Grill**: `heinzelwerk:grilling` + `heinzelwerk:domain-modeling` skills together. Resolve the design tree with the user; write resolved terms and ADRs as they land.
  1b. **Prototype**, when the slice changes what a screen looks like or how a flow behaves, and the user hasn't seen it yet. Offer it. If the user says yes, use the `heinzelwerk:prototype` skill: a few radically different UI variations, or a logic walkthrough. The user picks. The chosen variant and the question it settled go into the spec; the prototype goes to a throwaway branch with a pointer from the spec issue.
  2. **Spec**: `heinzelwerk:to-spec` skill, publishing to the tracker. Input was an existing issue → update that issue into the spec instead of creating a new one.
  3. **Slice**: `heinzelwerk:to-tickets` skill on that spec. Tickets come out as sub-issues labelled `ready-for-agent`.
  4. **Docs PR**: glossary or ADR changes from step 1 → commit them on a fresh branch `docs/shape-<topic>`, commit message `docs: update domain docs from shaping`, open PR.

Finish with the frontier: slices with no open blockers, each as the exact command to run (`/heinzelwerk:feature <n>`).

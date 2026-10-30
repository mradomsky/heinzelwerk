# Handoff texts have fixed fields checked by a script, not a JSON schema

Done notes and verdicts keep their prose shape (`did:`, `evidence:`, `checks:`, …; `heinzelwerk: validated <sha>` as the last line) and `scripts/check-note` verifies the fields before they are posted and again when the validator reads them. Branch names are deterministic (`<type>/<ticket>-<slug>[-<role>]`) so a second run on the same ticket finds its branch.

## Considered Options

1. **Prose only, checked by the reading agent** — rejected. The first retro found short shas, missing `checks:` codes, and dropped fields that no reader caught until the gate skipped or the retro guessed.
2. **Tagged JSON blocks next to the prose** (`<done-note>{…}</done-note>`) — rejected for now. Two copies drift on fix rounds; the gate and retro need only the fields the prose check can read. Kept in `docs/out-of-scope.md` with its revisit condition.
3. **Prose with a deterministic checker** (chosen). Same shape agents already write, one bash script, the same `scripts/` pattern as `check-refs`.

## Consequences

- A done note gains a `session:` line (the transcript path) so retro and the hand-back fallback can find the conversation; transcripts are never copied into a repo.
- The `checks:` line is exit codes only; what a check said moves to `evidence:`.
- Free topic words in branch names are gone; the slug comes from the ticket title, and a resumed run reads the recorded name before inventing one.

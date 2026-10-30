# Upstream skills are vendored as adapted copies, pinned, under the plugin's namespace

Skills from mattpocock/skills and dietrichgebert/ponytail are copied into `skills/<name>/`, adapted with marked `_(heinzelwerk …)_` passages, and described as "heinzelwerk copy … Use inside heinzelwerk …". `THIRD_PARTY_NOTICES.md` lists each file and its licence.

## Considered Options

1. **Depend on the upstream plugins at runtime** — rejected. Upstream renames skills and sections without notice; a run that loads `mattpocock-skills:code-review` one week may find a different step 3 the next. Users may also not have them installed.
2. **Automatic sync from upstream** — rejected. Same instability, plus the adaptations would be overwritten or conflict on every pull.
3. **Pinned copies, adapted by hand, namespaced** (chosen). `heinzelwerk:tdd` and `mattpocock-skills:tdd` coexist; the descriptions steer the user's own sessions to upstream and runs to ours.

## Consequences

- Upstream improvements arrive only when someone re-reads the upstream file and ports them (parked in `docs/out-of-scope.md`).
- Hephaestus (AGPL-3.0) contributed ideas only; no text or code is copied from it.

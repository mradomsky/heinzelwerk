# Plugin executables live in `scripts/`, put on PATH by a SessionStart hook

The gates and checkers (`merge-gate`, `tf-gate`, `ui-shots`, `check-refs`, `check-note`, `spawn-context`) live in the plugin's `scripts/`; `hooks/path.sh` appends that directory to the Bash tool's PATH through `CLAUDE_ENV_FILE`. Target repos carry no copies.

## Considered Options

1. **Copies in each target repo (`scripts/merge-gate` written by setup)** — rejected, after being the first design. Every plugin fix needed a PR per repo, and a PR could edit the gate that judges it.
2. **A top-level `bin/` in the plugin** — rejected. The claude.ai and Cowork plugin directory refuses a plugin with `bin/`; `claude plugin validate` does not catch it.
3. **`scripts/` plus a PATH hook** (chosen). Same invocation (`merge-gate <PR>`), accepted by the directory, one place to fix.

## Consequences

- On Windows the hook needs `cygpath`: a `C:/` path splits PATH at the colon.
- `.gitattributes` keeps `scripts/*` LF (`-text`); `text`/`eol` attributes count as content rewriting and the directory refuses them.
- The old copies are deleted by setup's upgrade step.

# Test-run plan

Goal: prove heinzelwerk end to end, from interactive single-repo runs to a multi-repo workspace run. Fix the plugin between runs; each fix on a fresh branch from main with a conventional commit.

| Run | Issue | What it proves |
|---|---|---|
| 1 | stagehopper #105 Extract runtime config | One role (frontend), spawn-on-demand, TDD, quiet output, full loop at minimal risk. Acceptance: the 882 tests pass **unmodified** |
| 2 | stagehopper #103 `isListedOnLanding` | Vertical slice: `lambda/` + shared `types.ts` + landing page + admin form. Contract ordering, slice acceptance, screenshots, docs PR. Trap: `undefined` must read as *listed* |
| 3 | SpaceTraders meta#49 dynamic `MINING_SHIP_SYMBOL` | Vague issue → full `/heinzelwerk:shape` grilling; then workspace mode across repos |

## Phase 0 — Prerequisites (~30 min)

1. Repo `mradomsky/heinzelwerk` exists (private), cloned at `~/heinzelwerk`.
2. Laptop: Claude Code ≥ 2.1.32, `gh auth status` OK, `jq`, Node, `npx playwright install chromium`, gitleaks.
3. `~/.claude/settings.json`: `{ "env": { "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1" } }`.
4. Note the usage meter (token baseline).

Every session below starts the same way:

```sh
claude --plugin-dir ~/heinzelwerk --model opus --strict-mcp-config
```

## Phase 1 — Preflight (~45 min, scratch repo)

| Check | How | If it fails |
|---|---|---|
| Plugin loads | `/agents` lists the roles, `/help` lists `/heinzelwerk:*` | fix layout / manifest |
| Marketplace install | `/plugin marketplace add mradomsky/heinzelwerk`, `/plugin install heinzelwerk` | fix `marketplace.json` (`source` path) |
| No MCP | `/mcp` is empty | find the right flag |
| Guard hook | ask Claude to run `git push origin main`, `terraform apply x`, `git push --force origin x` | fix `hooks.json` / `${CLAUDE_PLUGIN_ROOT}` |
| Task states | team of 2: one creates `[proposed] test`, the other moves it to under review | no custom states → title prefixes `[proposed]`, `[review]`, `[needs-work]` in `phased-workflow` |
| Plugin agents as teammates | spawn `backend` as teammate; ask its model and whether caveman is active | `skills:` / `model:` ignored → move into prompt text |
| Subagent model override | that teammate spawns a Haiku subagent and reports its model | fallback agent defs `finder` (Haiku), `deep-analyst` (Opus) |
| Skill namespacing | `/heinzelwerk:shape` on a toy idea: do `grilling` + `domain-modeling` load from inside it? | use namespaced names |
| Hide building blocks | find a frontmatter flag that hides `to-spec` / `to-tickets` from the slash menu while keeping them callable by `/shape` | leave them visible |

Then run the independent review and fix its "will it run?" findings:

```sh
claude --model opus --strict-mcp-config --allowedTools "Read,Grep,Glob,WebFetch,WebSearch" -p "$(cat prompts/review-plugin.md)"
```

## Phase 2 — Set up stagehopper (~45–60 min)

1. Permissions: allowlist in `stagehopper/.claude/settings.local.json` for git, gh, npm scripts, `npx playwright`, `scripts/*`. No `Bash(*)`.
2. `/heinzelwerk:setup`. Expected answers:
   - paths: backend `lambda/`, frontend `src/`, shared `src/lib/stagehopper/types.ts`
   - checks (quiet): tests, lint, typecheck, `npm audit --audit-level=high`; gitleaks as pre-commit
   - risk areas: record validation in `lambda/index.ts`, storage keys, `data/festivals.json`
   - design: theme and layout rules → `design.md`; UI preview = Vite dev server with port
   - section F: adopt existing docs
3. Review the setup PR carefully (first agent-written docs). Merge.

## Phase 3 — Run 1: #105 (~1–2 h)

1. `/heinzelwerk:shape 105` → expect the "only needs sharpening" path, label `ready-for-agent`.
2. New session: `/heinzelwerk:feature 105`.
3. Watch for:
   - coordinator states mode; spawns product + lead, then **only frontend**, then validator
   - spec gate passes; plan comment with seams and worktree paths
   - frontend works in `../.worktrees/…`, never the main checkout; quiet test output
   - validator: checks + two-axis review; "tests unmodified" verified explicitly
   - final report + `heinzelwerk-metrics` block on the issue; docs PR if anything to add
4. Answer escalations, take notes, don't steer unless it derails. Review the PR.

## Phase 4 — Run 2: #103 (~2–3 h)

Same procedure. Watch for:
- spec gate turns the `undefined → listed` rule into a Given/When/Then
- lead orders `types.ts` + validation (backend) first, frontend tasks blocked by it
- screenshots of landing page and admin form published via `scripts/ui-shots`
- slice acceptance in an integration worktree: an existing festival without the field still on `/`; an unlisted one gone from `/`, its `/room/` and embed routes still working
- discoveries go through lead as proposals, nothing silently fixed

## Phase 5 — Retro (~1 h)

`/heinzelwerk:retro` over both runs: findings with evidence, architecture survey on stagehopper, plugin issues in `mradomsky/heinzelwerk`. Fix the top plugin issues before run 3.

## Phase 6 — SpaceTraders, workspace mode

1. From the parent folder: `/heinzelwerk:setup meta`. Section F adopts `autopilot-design.md`. Add the parent `CLAUDE.md` pointer line.
2. `/heinzelwerk:shape 49`: full grilling (arm body vs knob, persistence, UI), spec, slices.
3. `/heinzelwerk:feature <first slice>`: shared branch name across repos, PR order, `Depends on` lines.
4. Infra gate: separate test later, only with scoped dev credentials and `auto_apply_dirs` set.

## Notes per run

```
run: <issue> | start–end | usage before/after
worked: …
broke: <what, where, which plugin file to change>
escalations to me: <n>, necessary?
my edits before merge: …
```

## Stop criteria

Stop the run (coordinator writes a handoff) if an agent edits the main checkout, two roles fight over one file, review rounds loop without progress, or usage burns far past expectations in the first 30 minutes. Fix the plugin first.

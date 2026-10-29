---
name: retro
description: "Weekly retrospective over recent heinzelwerk runs: what went well, what went wrong, concrete changes to the project's agent environment and to the team itself, plus an architecture survey for deepening opportunities."
disable-model-invocation: true
model: opus
---

The user has asked for a **retrospective**. You are suggesting improvements to the coding agents' **environment** (this project) and to the **team** (the heinzelwerk plugin) to improve future runs. Evidence first: every finding cites a run, PR, or comment.

## Steps

1. Call the Skill tool with `heinzelwerk:writing-for-agents` for the writing style guide.

2. **Scope.** Default: everything since the last retro. The last retro is the newest file in `docs/agents/heinzelwerk/retros/` (workspace: in the tickets repo). The user may give a date or ticket list instead.

   Read the last retro's actions. For each one: did it happen, and did it help? An action is a finding when its `remove when` condition has fired, or when it never helped. That finding is: prune the rule, check, or risk area the action added.

3. **Gather primary sources** for runs in scope:
   - Final reports (posted by coordinator): `gh search issues "heinzelwerk-metrics in:comments" --repo <tickets repo>`, then read each report and its metrics block.
   - PRs from those runs: state (merged / closed / open), review comments, needs-work rounds.
   - **Human edits**: on each merged agent branch, commits after the run's final report, or commits without the agent's `Co-Authored-By` trailer, are probably the human's fixes. Confirm the list with the user: commits a human made with Claude Code also carry the trailer. Read those diffs. They are the strongest signal.
   - Issues the team filed (`needs-triage`, `needs-info`) and what the human did with them.
   - Docs PRs: what the human accepted, edited, or dropped from glossary, ADR, and learnings candidates.
   - Session logs on this machine, when the user points at them or a finding needs detail.
   - Token usage: ask the user once; never estimate.
   - Human run notes: ask the user once for the path (usually `docs/runs/` in their heinzelwerk checkout), then read the notes for runs in scope. Their `broke:` lines and `For /retro` items are findings to check against the sources above.
   - Shortcut debt: run the `heinzelwerk:ponytail-debt` skill; compare its output with the ledger in the last retro record.
   - **Doc freshness** (per repo): `check-refs --since-header` prints every `path:line` whose line no longer reads as it did at the doc's `Verified against` commit (a ref that only shifted is not printed). Hand those, every `(unverified)` item, and every `(verified <date> …)` dated before the last retro to one Opus subagent at effort medium (`heinzelwerk:setup` **Evidence** for the kinds). It opens each ref on `origin/main` and returns, per item: still true with the ref, true with a new ref, or false with the `path:line` that contradicts it. A ref it confirms makes a tagged item evidenced; a false item is a finding.
   - **Post-merge outcomes**, since the last retro:
     - reverts of agent PRs: `git log origin/main --grep '^Revert'`;
     - CI runs that failed on `main` after an agent merge: `gh run list --branch main --status failure`, with the merge that preceded each;
     - issues that reference a merged agent PR and report a bug: `gh api repos/{owner}/{repo}/issues/<PR>/timeline --jq '.[] | select(.event=="cross-referenced") | .source.issue.html_url'`.

     Each one is evidence that a `validated` PR was not good enough. Trace it to the validator, a missing check, or the spec.

4. **Look for candidates for improvement** in these categories.

**Environment** (the project):

- **Navigation**: how easy was it for the agent to find the right files? Are there hidden dependencies between files? Would a **navigation pointer** make it easier? _Use when_ the session took a long time to find a piece of information.
- **Automated checks**: are there automated checks that could catch errors the agent made? Linting, typing, tests, filesystem linters? Read the repo's own check command first: its `package.json`/build-tool `lint`/`check` scripts, its CI workflow. A check that already exists but is unwired or silently broken is the finding: wire or fix that check rather than build a new one. A repo with no **guardrail** is itself a finding; a guardrail is a pre-commit hook or a CI job running the repo's lint/typecheck/test command. An un-linted repo is a standing missed opportunity, not a neutral default. _Use when_ the agent made a mistake an automated check could have caught, or the repo has no guardrail at all.
- **Coding standards**: should the **reviewer agent** be given a new rule to enforce? Should an existing rule be removed or clarified? Classify the violation first:
  - **Mechanical** (a fixed syntactic pattern, a banned API, an import shape, a file-location rule) → a deterministic check, full stop: a custom rule in the repo's own linter, a new pre-commit hook, or a new CI job, whichever the repo's language and existing guardrail make cheapest. Default to building the check over writing the rule.
  - **Judgement call** (cross-file consistency, "matches the surrounding style," anything no guardrail could ever substitute for) → `CODING_STANDARDS.md`. Reserve that file for genuine judgement calls.

  _Use when_ the reviewer agent failed to catch a mistake.
- **Global AGENTS.md**: are there any steering instructions that should be moved to coding standards (or automated checks) instead? _Use when_ the AGENTS.md file is particularly large - in the repo OR the user's global scope.
- **Tool economy**: did the agent make expensive tool calls that could be streamlined? Is there any custom tooling (CLI's, MCP's) that is particularly token-inefficient? _Use when_ the agent made an expensive tool call.
- **No-ops**: look for instructions in steering files that don't modify the agent's behavior. _Use when_ the steering files are large and unwieldy.
- **Information access**: look for opportunities to increase the agent's access to information. Examples: teeing dev server logs, read-only access to third-party services. _Use when_ a crucial piece of information was not available to the agent.

**Team** (the heinzelwerk plugin):

- **Role prompts**: did a role act outside its job, miss its job, or need the same correction twice? _Use when_ the human or tech-lead corrected one role repeatedly.
- **Task splitting**: were tasks too big (many review rounds, diagnose rounds), too small (many tasks, little per PR), or overlapping (file conflicts, duplicates)? _Use when_ review rounds or diagnose rounds are high.
- **Discovery**: how many proposals were accepted vs rejected, and did accepted ones matter?
  - Many rejections → proposers need a sharper bar.
  - Many escalations to product → slices too vague.
  - Tech-lead slow to triage → bottleneck signal.

  _Use when_ proposals appear in metrics.
- **Handoffs and phases**: did work stall between phases, or did a done note miss what the next agent needed? _Use when_ a teammate sat idle or redid work.
- **Plan depth**: read the plan comments' Decisions, Pre-mortem, and Critique lines. Did an `obvious:` call turn out wrong? Did a chosen option cause fix rounds or human edits? Did critique points or pre-mortems catch something real, or only cost tokens? Adjust the "hard to reverse" list or the critique trigger to match what you found. _Use when_ a run had fix rounds, diagnose rounds, or human edits.
- **Spec gate**: did product pass slices that later failed on spec, or block runnable ones? _Use when_ validator's Spec axis found gaps product should have caught.
- **Validator**: did merged PRs need human fixes, reverts, or bug fixes the validator should have caught? Classify each:
  - mechanical → a check (environment category);
  - judgement → a coding-standards rule.

  _Use when_ human edits or post-merge outcomes exist on validator-passed PRs.
- **Coordinator**: count nudges that changed what an agent did versus noise; were escalations to the user necessary, or answerable by product or tech-lead? _Use when_ nudges or escalations appear in metrics.
- **Model choice**: did Opus escalations find what Sonnet missed? Did Haiku subagents produce work that later failed? Did a Sonnet review let something through in an area that should be a risk area? If so, propose adding that area to `team.md`. Judge with the `heinzelwerk:model-selection` anti-patterns. _Use when_ escalations appear in metrics or human edits cluster in one role.
- **Acceptance**: did slice acceptance fail on things per-PR validation passed? Did you find integration issues after merge that acceptance missed? _Use when_ `acceptance` appears in metrics.
- **UI**: did you have to fix visual or UX issues after merge?
  - Missing design rules → propose additions to `design.md`.
  - Screenshots missing or useless → tighten the frontend step.

  _Use when_ human edits touch UI code.
- **Infra**: were gate fails and tech-lead escalations real catches, or was the policy too strict? Any auto-apply you had to undo? Propose policy changes (`infra-policy.json`) with evidence: widen only what proved safe. Infra PRs closed unmerged that carry a `heinzelwerk: applied` comment are unreverted dev drift → file a `ready-for-agent` issue. _Use when_ `infra_applies` appears in metrics.
- **Shortcut debt**: new `shortcut:` markers since last retro, and any with `no-trigger`.
  - A marker whose upgrade trigger has fired → finding with a `ready-for-agent` issue.
  - Growing ledger with no triggers firing → fine.
  - Growing `no-trigger` count → tighten the implementer prompts.

  _Use when_ the ledger changed.
- **Budget caps**: were caps hit, and did hitting them help or cut off good work? _Use when_ caps appear in metrics.
- **Docs flow**: are glossary terms, ADRs, and learnings landing, or piling up as dropped candidates? Is the learnings file near its cap with stale lines? _Use when_ docs PRs were edited heavily or skipped.
- **Wins**: what worked well enough to protect? Name it, so a later change doesn't break it.

4b. **Architecture survey.** Run the `heinzelwerk:improve-codebase-architecture` skill's explore and report steps, not its grilling loop yet. Point it at the code that changed since the last retro, weighted by the friction step 4 found. Friction means modules with many review rounds, human edits, diagnose rounds, or repeated proposals. Haiku subagents walk the code, per `heinzelwerk:model-selection`; judging candidates stays with you. Never change code here.

5. **Present** findings to the user in order of severity, wins last; architecture candidates as their own group with the report path. Each finding gives its evidence, the proposed change, and where the change goes. The user picks which to act on.

6. **Write**, for the picked findings only:
   - **Retro record**: `docs/agents/heinzelwerk/retros/<YYYY-MM-DD>.md` (workspace: tickets repo). Contents:
     - metrics table summed over runs in scope;
     - post-merge outcomes (reverts, red `main` runs, linked bugs);
     - wins;
     - problems;
     - actions as a table `action | owner | evidence | remove when`. `remove when` is the condition that makes the added rule, check, or risk area unnecessary, e.g. "a CI job covers it" or "no hit in 3 retros"; `never` only for a safety rule;
     - architecture candidates filed;
     - shortcut ledger summary (count, no-trigger count, new since last retro);
     - the follow-up on last retro's actions.

     Max 60 lines.
   - **Environment actions**: doc changes (pointers, learnings prune and consolidate, team rules, coding standards) go on a fresh branch from main named `docs/retro-<YYYY-MM-DD>`, in one PR together with the retro record. The doc-freshness results go in the same PR, whether or not the user picked a finding: shifted refs fixed, confirmed items untagged or re-dated, false items corrected, and each doc's `Verified against` line set to the `origin/main` sha the subagent read. `check-refs --since-header` prints nothing before the PR opens. Code changes (a new check, a hook, a CI job) become issues labelled `ready-for-agent` or `ready-for-human`, never made here.
   - **Architecture candidates**: every **Strong** and **Worth exploring** candidate becomes an issue, whether or not the user picked it now. Labels: `needs-triage` and `heinzelwerk-survey` (`gh label create heinzelwerk-survey -f` first). Title in `heinzelwerk:codebase-design` vocabulary. Body: problem, solution, benefits, files, strength. Dedup against open issues: when one already covers the candidate, comment on it instead of creating a new issue. List them in the retro record.
   - **Team actions**: issues in the heinzelwerk repo the user names. Ask once which repo: upstream `mradomsky/heinzelwerk`, or their fork. `gh issue create -R <repo>`, title `<role or skill>: <change>`, body = evidence + proposed wording + `remove when`.
   - Do not merge.

7. **Explore one candidate** (optional): ask which architecture candidate to explore now. If the user picks one, run the `heinzelwerk:improve-codebase-architecture` grilling loop. Otherwise the user shapes it later with `/heinzelwerk:shape <issue>`.

## Reference

### Implementation vs Review: who enforces standards

Remember that all work goes through two stages: implementation and review. The implementation agent has the most **context pressure**. They are responsible for exploration, writing code, and debugging failures.

The review agent has the least context pressure. It receives a diff, so no exploration is needed. It often does not need to write code or debug.

This means that the review agent should be responsible for imposing coding standards, not the implementation agent.

### Files in the repo

You have access to several files in the repo:

- `CLAUDE.md`/`AGENTS.md`: these files are pushed to the context window of any agent working in this repo. They should be used incredibly sparingly, usually only for **navigation pointers** to other files.
- `CODING_STANDARDS.md`: this file is read during review, not implementation. Add **navigation pointers** to docs folders if the standards file gets more than 1,000 lines long.
- Docs: use docs as reference files, pointed to by other files. Look for existing docs before writing new ones.
- Skills: use skills for docs, since their description goes into the agent's context window, or for user-invoked commands. Follow the advice in the `heinzelwerk:writing-for-agents` skill.

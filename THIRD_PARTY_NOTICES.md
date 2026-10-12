# Third-party notices

heinzelwerk includes material from the projects below. Each keeps its own license; heinzelwerk's own license (`LICENSE`) does not apply to it.

| Project | License | Files in this repo | Modified? |
|---|---|---|---|
| [mattpocock/skills](https://github.com/mattpocock/skills) | MIT | `skills/tdd`, `skills/code-review`, `skills/codebase-design`, `skills/domain-modeling`, `skills/grilling`, `skills/to-spec`, `skills/to-tickets`, `skills/prototype`, `skills/diagnosing-bugs`, `skills/handoff`, `skills/improve-codebase-architecture`, `skills/writing-for-agents`, core of `skills/retro`, templates in `skills/setup/` (`issue-tracker-github.md`, `triage-labels.md`, `domain.md`); `skills/setup/SKILL.md` adapted from `setup-matt-pocock-skills` | Small adaptations marked inline as `_(heinzelwerk …)_`; frontmatter descriptions rewritten to heinzelwerk contexts (tdd, code-review, codebase-design, domain-modeling, grilling, prototype, diagnosing-bugs, writing-for-agents); upstream-only branches removed (local-file tickets in `to-tickets`, PR-triage section in `issue-tracker-github.md`) |
| [dietrichgebert/ponytail](https://github.com/dietrichgebert/ponytail) | MIT | `skills/ponytail-debt` | No |

Ideas (no code or text) are also drawn from [Ido-Levi/Hephaestus](https://github.com/Ido-Levi/Hephaestus) (AGPL-3.0): phases, guardian (now part of coordinator), validation loop, diagnose step.

`skills/model-selection` is heinzelwerk's own text (rewritten 2026-10-12 to replace an earlier adaptation of an unidentified source). Ideas (no text) from [zscole/model-hierarchy-skill](https://github.com/zscole/model-hierarchy-skill) (MIT): a default middle tier, escalating one tier at a time, batching small jobs.

Adding material from a new source: add a row and its license text below. More files from a source already listed only need the table row updated.

---

## mattpocock/skills — MIT

```
MIT License

Copyright (c) 2026 Matt Pocock

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## dietrichgebert/ponytail — MIT

```
MIT License

Copyright (c) 2026 DietrichGebert

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

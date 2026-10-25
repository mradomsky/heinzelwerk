#!/usr/bin/env bash
# Rebuild cloud/ from the root plugin. Every file under agents, bin, commands, hooks, skills is copied with the skill
# namespace renamed (`heinzelwerk:x` → `heinzelwerk-cloud:x`; protocol markers like `heinzelwerk: validated` keep their
# space and stay), except the FORKS below, which cloud maintains by hand. Run after changing the root plugin.
set -euo pipefail
cd "$(dirname "$0")"
FORKS='agents/* commands/* bin/merge-gate skills/coordinator/SKILL.md skills/team-modes/SKILL.md skills/team-modes/gh-rest.md
  skills/phased-workflow/* skills/code-review/SKILL.md skills/setup/issue-tracker-github.md'
for src in $(git -C .. ls-files agents bin commands hooks skills); do
  for f in $FORKS; do [[ $src == $f ]] && continue 2; done
  mkdir -p "$(dirname "$src")"
  sed 's/heinzelwerk:\([a-z]\)/heinzelwerk-cloud:\1/g' "../$src" > "$src"
  [ -x "../$src" ] && chmod +x "$src" || true
done
echo "synced; forks kept: $FORKS"

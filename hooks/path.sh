#!/usr/bin/env bash
# Puts the plugin's scripts/ (merge-gate, tf-gate, ui-shots) on the Bash tool's PATH for this session.
# scripts/, not bin/: claude.ai and Cowork refuse to install a plugin that has a top-level bin/.
[ -n "${CLAUDE_ENV_FILE:-}" ] || exit 0
dir="$CLAUDE_PLUGIN_ROOT/scripts"
# Git Bash: C:/x has a colon that would split PATH; /c/x does not
command -v cygpath >/dev/null && dir=$(cygpath -u "$dir")
printf 'export PATH="%s:$PATH"\n' "$dir" >> "$CLAUDE_ENV_FILE"

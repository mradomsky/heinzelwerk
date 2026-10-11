#!/usr/bin/env bash
# PreToolUse guard for Bash. Exit 2 = blocked, stderr goes back to the agent. Fails closed when jq is missing.
block() { echo "blocked by heinzelwerk: $1" >&2; exit 2; }
command -v jq >/dev/null 2>&1 || block "jq is missing, so the guard cannot read the command; install jq"
cmd=$(jq -r '.tool_input.command // ""')
git='git(\s+-C\s+\S+)?\s+'
grep -qE "${git}push\b.*(\s|:|/)(main|master)(\s|$)" <<<"$cmd" && block "agents never push main"
grep -qE "${git}(checkout|switch)\s+(main|master)\b" <<<"$cmd" && block "agents never work on main; use a worktree on a task branch"
grep -qE 'gh pr merge\b' <<<"$cmd" && block "agents never merge; humans merge"
grep -qE '(^|[;&|(]|\s)(terraform|tofu)(\s+-chdir=\S+)?\s+(apply|destroy|import|state\s+(rm|mv|push|replace-provider)|force-unlock|workspace\s+delete)\b' <<<"$cmd" \
  && block "raw terraform apply/destroy/import/state changes are not allowed; use scripts/tf-gate apply <dir> <plan>"
grep -qE -- '-auto-approve' <<<"$cmd" && block "-auto-approve is not allowed"
grep -qE "${git}push\b.*(\s-f\b|--force(\s|$))" <<<"$cmd" && block "use --force-with-lease, never plain --force"
grep -qE "${git}(commit|push)\b.*--no-verify" <<<"$cmd" && block "--no-verify skips the secret scan"
if grep -qE "${git}add\b.*(\.env(\.|\s|$)|\.tfstate|\.tfvars\b|\.pem\b|\.key\b|id_rsa|id_ed25519|credentials\.json)" <<<"$cmd" \
  && ! grep -qE '\.env\.(example|sample|template)\b' <<<"$cmd"; then
  block "looks like a secret or state file; never commit it"
fi
exit 0

#!/usr/bin/env bash
# PreToolUse guard for Bash. Exit 2 = blocked, stderr goes back to the agent.
cmd=$(jq -r '.tool_input.command // ""')
block() { echo "blocked by heinzelwerk: $1" >&2; exit 2; }
grep -qE 'git (push|merge)\b.*\b(main|master)\b' <<<"$cmd" && block "agents never push or merge main"
grep -qE '(^|[;&|(]|\s)(terraform|tofu)(\s+-chdir=\S+)?\s+(apply|destroy|import|state\s+(rm|mv|push|replace-provider)|force-unlock|workspace\s+delete)\b' <<<"$cmd" \
  && block "raw terraform apply/destroy/import/state changes are not allowed; use scripts/tf-gate apply <dir> <plan>"
grep -qE -- '-auto-approve' <<<"$cmd" && block "-auto-approve is not allowed"
grep -qE 'git push\b.*(\s-f\b|--force(\s|$))' <<<"$cmd" && block "use --force-with-lease, never plain --force"
grep -qE 'git (commit|push)\b.*--no-verify' <<<"$cmd" && block "--no-verify skips the secret scan"
grep -qE 'git add\b.*(\.env\b|\.tfstate|\.tfvars\b|\.pem\b|\.key\b|id_rsa|id_ed25519|credentials\.json)' <<<"$cmd" && block "looks like a secret or state file; never commit it"
exit 0

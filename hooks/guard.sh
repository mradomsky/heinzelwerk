#!/usr/bin/env bash
# PreToolUse guard for Bash. Exit 2 = blocked, stderr goes back to the agent. No dependencies: reads the
# command with jq if present, else node, else plain bash; fails closed only if the command cannot be read.
block() { echo "blocked by heinzelwerk: $1" >&2; exit 2; }
input=$(cat); raw=""; read_ok=no
if command -v jq >/dev/null 2>&1; then
  raw=$(jq -r '.tool_input.command // ""' <<<"$input" 2>/dev/null) && read_ok=yes
elif command -v node >/dev/null 2>&1; then
  raw=$(node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{process.stdout.write(String(JSON.parse(s).tool_input?.command??""))}catch{process.exit(3)}})' <<<"$input" 2>/dev/null) && read_ok=yes
else
  # Pull the first "command":"..." string and undo the JSON escapes that matter for matching.
  m=$(grep -oE '"command" *: *"(\\.|[^"\\])*"' <<<"$input" | head -1)
  [ -n "$m" ] && { raw=$(sed -E 's/^"command" *: *"//; s/"$//; s/\\"/"/g; s/\\n/ /g; s/\\t/ /g; s#\\/#/#g; s/\\\\/\\/g' <<<"$m"); read_ok=yes; }
fi
[ $read_ok = yes ] || ! grep -q '"command"' <<<"$input" || block "the guard could not read the command (no jq or node, and the fallback parser failed)"
# Normalise: collapse whitespace, strip quotes and backticks, so quoting cannot hide an argument.
cmd=$(printf '%s' "$raw" | tr -s '[:space:]' ' ' | tr -d "\"'\`")
git='git( +(-[cC] +[^ ]+|--[a-z-]+(=[^ ]+)?))* +'
ref='[ :/+](main|master)( |$)'
grep -qE "${git}push\b.*${ref}" <<<"$cmd" && block "agents never push main"
grep -qE "${git}push\b.*--(mirror|all)\b" <<<"$cmd" && block "agents never push --all or --mirror"
grep -qE "${git}(checkout|switch)( +-[bB])? +(main|master)( |$)" <<<"$cmd" && block "agents never work on main; use a worktree on a task branch"
grep -qE "${git}worktree +add\b.* (main|master)( |$)" <<<"$cmd" && block "a worktree on main is still main; add it on a task branch"
grep -qE 'gh +pr +merge\b|pulls/[0-9]+/merge\b' <<<"$cmd" && block "agents never merge; humans merge"
grep -qE '(^|[;&|(]| )(terraform|tofu)( +-chdir=[^ ]+)? +(apply|destroy|import|state +(rm|mv|push|replace-provider)|force-unlock|workspace +delete)\b' <<<"$cmd" \
  && block "raw terraform apply/destroy/import/state changes are not allowed; use scripts/tf-gate apply <dir> <plan>"
grep -qE -- '-auto-approve' <<<"$cmd" && block "-auto-approve is not allowed"
grep -qE "${git}push\b.*( -f\b|--force( |$))" <<<"$cmd" && block "use --force-with-lease, never plain --force"
grep -qE "${git}commit\b.*( -n\b|--no-verify\b)" <<<"$cmd" && block "--no-verify skips the secret scan"
grep -qE "${git}push\b.*--no-verify\b" <<<"$cmd" && block "--no-verify skips the secret scan"
# git add: judge every argument on its own, so one safe file cannot whitelist a secret beside it.
for arg in $(grep -oE "${git}add\b[^;&|]*" <<<"$cmd" | sed -E "s/^${git}add//"); do
  case $arg in
    -*) ;;
    *.env.example|*.env.sample|*.env.template) ;;
    *.env|*.env.*|*.tfstate|*.tfstate.*|*.pem|*.key|*id_rsa*|*id_ed25519*|*credentials.json)
      block "looks like a secret or state file ($arg); never commit it" ;;
  esac
done
exit 0

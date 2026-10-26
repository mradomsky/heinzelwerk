#!/usr/bin/env bash
# PreToolUse guard for the Bash and PowerShell tools (same tool_input.command). Exit 2 = blocked, stderr goes back to
# the agent. No dependencies: reads the command with jq if present, else node, else plain bash; fails closed only if
# the command cannot be read.
block() { echo "blocked by heinzelwerk: $1" >&2; exit 2; }
input=$(cat); raw=""; read_ok=no
if command -v jq >/dev/null 2>&1; then
  raw=$(jq -r '.tool_input.command // ""' <<<"$input" 2>/dev/null) && read_ok=yes
elif command -v node >/dev/null 2>&1; then
  raw=$(node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>{try{process.stdout.write(String(JSON.parse(s).tool_input?.command??""))}catch{process.exit(3)}})' <<<"$input" 2>/dev/null) && read_ok=yes
else
  # Pull the first "command":"..." string and undo the JSON escapes that matter for matching.
  m=$(grep -oE '"command" *: *"(\\.|[^"\\])*"' <<<"$input" | head -1)
  [ -n "$m" ] && { raw=$(sed -E 's/^"command" *: *"//; s/"$//; s/\\"/"/g; s/\\n/\n/g; s/\\t/ /g; s#\\/#/#g; s/\\\\/\\/g' <<<"$m"); read_ok=yes; }
fi
[ $read_ok = yes ] || ! grep -q '"command"' <<<"$input" || block "the guard could not read the command (no jq or node, and the fallback parser failed)"
# Heredoc bodies and quoted -m/-b/-t/body= "..." arguments are text (commit messages, PR bodies, comments), never
# commands: dropped before any rule runs, so a verdict quoting "gh pr merge" or containing "|" never trips a rule.
# [<][<], not two literal angle brackets: the directory validator reads those as an unclosed here-document
text=$(awk -v q="'" 'h { if ($0 ~ "^[ \t]*" t "[ \t]*$") h=0; next }
  { print; op = "[<][<]-?[ ]*[\"" q "]?"; if (match($0, op "[A-Za-z_]+")) { t=substr($0, RSTART, RLENGTH); sub(op, "", t); h=1 } }' <<<"$raw")
opt='((-m|--message|-b|--body|-t|--title)(=| +)|(-f|-F|--field|--raw-field) +body=)'
msgfree=$(sed -E "s/$opt\"([^\"\\\\]|\\\\.)*\"//g; s/$opt'[^']*'//g" <<<"$text")
# One line per command: continuation lines joined, split on newline && || ; |, whitespace collapsed, quotes, backticks,
# backslashes, parentheses and $ stripped so quoting or expansion cannot hide an argument.
segments() {
  printf '%s\n' "$1" | awk '{ if (sub(/\\$/, "")) printf "%s ", $0; else print }' | tr '\n' ';' | tr -s '[:space:]' ' ' \
    | tr -d "\"'\`\\\\()\$" | sed -E 's/&&|[|][|]|[;|]/\n/g'; echo
}
# Wrappers in front of the command (env assignments, env/sudo/eval, bash -c, timeout) are dropped so every rule anchors
# on the command itself: text that merely mentions a command (grep, echo, a comment body) never matches.
wrap='^ *((env|sudo|time|nohup|command|exec|eval|timeout +[0-9]+[smh]?|[A-Za-z_][A-Za-z0-9_]*=[^ ]*|(bash|sh|zsh|dash) +-[a-z]*c) +)*'
git='^git( +(-[cC] +[^ ]+|--[a-z-]+(=[^ ]+)?))* +'
ref='[ :/+](main|master)( |$)'
flags='( +-[a-zA-Z]+| +--[a-z-]+(=[^ ]+)?)*'
# hook-skipping variables count wherever they are set (export, $env:, an earlier segment) if anything commits
hookskip=no; grep -qE '(^|[ ;&|:])(HUSKY|LEFTHOOK|SKIP|PRE_COMMIT_ALLOW_NO_CONFIG|GIT_CONFIG_PARAMETERS)=' <<<"$msgfree" && hookskip=yes
while IFS= read -r seg; do
  cmd=$(sed -E "s/$wrap//" <<<"$seg")
  grep -qE "${git}push\b.*${ref}" <<<"$cmd" && block "agents never push main"
  grep -qE "${git}push\b.*--(mirror|all)\b" <<<"$cmd" && block "agents never push --all or --mirror"
  grep -qE "${git}(checkout|switch)${flags} +(main|master)( |$)" <<<"$cmd" \
    && ! grep -qE "${git}checkout${flags} +(main|master) +--( |$)" <<<"$cmd" && block "agents never work on main; use a worktree on a task branch"
  grep -qE "${git}worktree +add\b.* (main|master)( |$)" <<<"$cmd" && block "a worktree on main is still main; add it on a task branch"
  grep -qE "${git}branch\b.*( -[a-zA-Z]*[fmMdD][a-zA-Z]*| --(force|move|delete|copy))\b.* (main|master)( |$)" <<<"$cmd" \
    && block "local main is a read-only reference; never move, rename, or delete it"
  grep -qE "${git}update-ref\b.*refs/heads/(main|master)( |$)" <<<"$cmd" && block "local main is a read-only reference; never move it"
  grep -qE '^gh +pr +merge\b' <<<"$cmd" && block "merge only through merge-gate <pr>"
  grep -qE '^gh +api\b.*(pulls/[0-9]+/merge\b|mergePullRequest|enablePullRequestAutoMerge)' <<<"$cmd" && block "merge only through merge-gate <pr>"
  grep -qE '^(terraform|tofu)( +-chdir=[^ ]+)? +(apply|destroy|import|state +(rm|mv|push|replace-provider)|force-unlock|workspace +delete)\b' <<<"$cmd" \
    && block "raw terraform apply/destroy/import/state changes are not allowed; use tf-gate apply <dir> <plan>"
  grep -qE "${git}push\b.*( -[a-zA-Z]*f[a-zA-Z]*\b|--force( |$))" <<<"$cmd" && block "use --force-with-lease, never plain --force"
  grep -qE "${git}push\b.*--no-verify\b" <<<"$cmd" && block "--no-verify skips the secret scan"
  grep -qE "${git}commit\b.*( -[a-zA-Z]*n[a-zA-Z]*\b|--no-verify\b)" <<<"$cmd" && block "--no-verify skips the secret scan"
  [ $hookskip = yes ] && grep -qE "${git}commit\b" <<<"$cmd" && block "hook-skipping variables disable the secret scan"
  grep -qiE 'core\.hookspath' <<<"$seg" && block "core.hooksPath moves the secret-scan hook; leave it"
  grep -qE -- '-auto-approve' <<<"$seg" && block "-auto-approve is not allowed"
  # git add (and commit -i/--include): judge every argument on its own, so one safe file cannot whitelist a secret beside it.
  args=$(grep -oE "${git}(add|stage|update-index)\b.*" <<<"$cmd" | sed -E "s/^${git}(add|stage|update-index)//")
  [ -n "$args" ] || args=$(grep -oE "${git}commit\b.*( -[a-zA-Z]*i[a-zA-Z]*| --include) .*" <<<"$cmd" | sed -E "s/^.*( -[a-zA-Z]*i[a-zA-Z]*| --include) //")
  for arg in $args; do
    case $arg in
      -*) ;;
      *.env.example|*.env.sample|*.env.template) ;;
      *.env|*.env.*|*.tfstate|*.tfstate.*|*.tfplan|*.tfplan.*|*plan.bin|*.pem|*.key|*id_rsa*|*id_ed25519*|*credentials.json)
        block "looks like a secret, state, or plan file ($arg); never commit it" ;;
    esac
  done
done < <(segments "$msgfree")
exit 0

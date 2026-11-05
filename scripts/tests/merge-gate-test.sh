#!/usr/bin/env bash
# merge-gate regression suite: argument handling (-C, usage) and the marker rules (validated, accepted main-only).
#
# merge-gate is copied into a scratch dir next to a fake review-gate (always "BOT REVIEW: off"), and a fake `gh` on
# PATH answers the policy and `gh pr view` calls: a green, open, mergeable PR whose head is HEAD_SHA, with the
# comment and review bodies read from FAKE_BODIES_FILE. FAKE_CWD, when set, is the directory every gh call must run in.
# So this suite covers the bash logic; the --jq programs are checked live against a real PR.
#
# Usage: bash scripts/tests/merge-gate-test.sh [scripts/merge-gate]

src=${1:-"$(dirname "$0")/../merge-gate"}
failures=0
cases=0
workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

mkdir -p "$workdir/bin" "$workdir/plugin" "$workdir/repo"
cp "$src" "$workdir/plugin/merge-gate"
printf '#!/usr/bin/env bash\necho "BOT REVIEW: off"\n' >"$workdir/plugin/review-gate"
chmod +x "$workdir/plugin/merge-gate" "$workdir/plugin/review-gate"

cat >"$workdir/bin/gh" <<'FAKE_GH'
#!/usr/bin/env bash
if [ -n "${FAKE_CWD:-}" ] && [ "$(pwd -P)" != "$FAKE_CWD" ]; then echo "fake gh: ran in $(pwd -P)" >&2; exit 1; fi
case "$*" in
  *merge-policy.json*".enabled"*)            echo true ;;
  *merge-policy.json*".require_validation"*) echo true ;;
  *merge-policy.json*".require_checks"*)     echo true ;;
  *merge-policy.json*".allow_paths"*)        echo '*' ;;
  *merge-policy.json*".merge_method"*)       echo squash ;;
  *merge-policy.json*)                       echo "" ;;
  "pr view "*"--json baseRefName"*)          echo main ;;
  "pr view "*"--json statusCheckRollup"*)    echo SUCCESS ;;
  "pr view "*"--json state"*)                echo OPEN ;;
  "pr view "*"--json isDraft"*)              echo false ;;
  "pr view "*"--json mergeable"*)            echo MERGEABLE ;;
  "pr view "*"--json headRefOid"*)           echo "$HEAD_SHA" ;;
  "pr view "*"--json comments,reviews"*)     cat "$FAKE_BODIES_FILE" ;;
  "pr view "*"--json body"*)                 echo "## Done note" ;;
  "pr view "*"--json files"*)                echo README.md ;;
  "pr merge "*)                              exit 0 ;;
  *)                                         echo "fake gh: unexpected call: $*" >&2; exit 1 ;;
esac
FAKE_GH
chmod +x "$workdir/bin/gh"
export PATH="$workdir/bin:$PATH" MERGE_GATE_WAIT=0
export HEAD_SHA=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa OLD_SHA=bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
export FAKE_BODIES_FILE="$workdir/bodies.txt"

# expect <case name> <expected substring> <comment and review bodies> [merge-gate args…]; runs from $workdir
expect() {
  local name="$1" expected="$2" bodies="$3"; shift 3
  printf '%s\n' "$bodies" >"$FAKE_BODIES_FILE"
  local output
  output=$(cd "$workdir" && bash plugin/merge-gate "$@" 2>&1)
  cases=$((cases + 1))
  local flag="  ok "
  if [[ $output != *"$expected"* ]]; then flag="**BAD**"; failures=$((failures + 1)); fi
  printf '%s | %-48s | %s\n' "$flag" "$name" "${output//$'\n'/ ⏎ }"
}

validated="heinzelwerk: validated $HEAD_SHA"
main_only="Checks: docker build inconclusive: main only: docker build; verify on the first main run
$validated"

echo "--- arguments"
FAKE_CWD=$(cd "$workdir/repo" && pwd -P) expect "-C runs gh in the repo dir" "MERGED: PR 7" "$validated" -C repo 7
expect "-C missing dir" "MERGE SKIP: no repo dir nope" "$validated" -C nope 7
expect "-C without a value" "MERGE SKIP: usage" "$validated" -C
expect "-C without a PR" "MERGE SKIP: usage" "$validated" -C repo
expect "-C after the PR" "MERGE SKIP: usage" "$validated" 7 -C repo
expect "no arguments" "MERGE SKIP: usage" "$validated"
expect "PR not a number" "MERGE SKIP: usage" "$validated" abc
expect "extra argument" "MERGE SKIP: usage" "$validated" 7 8

echo "--- validated line"
expect "validated head merges" "MERGED: PR 7" "$validated" 7
expect "7-char prefix merges" "MERGED: PR 7" "heinzelwerk: validated ${HEAD_SHA:0:7}" 7
expect "old sha skips" "no \"heinzelwerk: validated $HEAD_SHA\"" "heinzelwerk: validated $OLD_SHA" 7
expect "CRLF bodies still match" "MERGED: PR 7" "$validated"$'\r' 7

echo "--- main-only acceptance"
expect "main-only without acceptance skips" "main-only check docker build not accepted" "$main_only" 7
expect "accepted at head merges" "MERGED: PR 7" "$main_only
heinzelwerk: accepted main-only docker build @ $HEAD_SHA" 7
expect "accepted at a head prefix merges" "MERGED: PR 7" "$main_only
heinzelwerk: accepted main-only docker build @ ${HEAD_SHA:0:7}" 7
expect "accepted at an old head skips" "main-only check docker build not accepted" "$main_only
heinzelwerk: accepted main-only docker build @ $OLD_SHA" 7
expect "accepted for another check skips" "main-only check docker build not accepted" "$main_only
heinzelwerk: accepted main-only e2e @ $HEAD_SHA" 7
expect "accepted with a short sha skips" "main-only check docker build not accepted" "$main_only
heinzelwerk: accepted main-only docker build @ aaaa" 7
expect "check name is no pattern" "main-only check d.cker build not accepted" "inconclusive: main only: d.cker build; verify on the first main run
$validated
heinzelwerk: accepted main-only docker build @ $HEAD_SHA" 7
expect "two checks, one accepted skips" "main-only check e2e not accepted" "$main_only
inconclusive: main only: e2e; verify on the first main run
heinzelwerk: accepted main-only docker build @ $HEAD_SHA" 7
expect "two checks, both accepted merges" "MERGED: PR 7" "$main_only
inconclusive: main only: e2e; verify on the first main run
heinzelwerk: accepted main-only docker build @ $HEAD_SHA
heinzelwerk: accepted main-only e2e @ $HEAD_SHA" 7
expect "acceptance not at line start ignored" "main-only check docker build not accepted" "$main_only
note: heinzelwerk: accepted main-only docker build @ $HEAD_SHA" 7

echo "$cases cases, $failures bad"; [ $failures -eq 0 ]

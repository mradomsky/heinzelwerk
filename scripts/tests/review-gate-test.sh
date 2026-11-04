#!/usr/bin/env bash
# review-gate regression suite.
#
# A fake `gh` on PATH answers the three calls the script makes: the policy keys come from FAKE_MODE and
# FAKE_BOT, `gh repo view` is constant, and `gh api graphql` prints a fixture of already-flattened state
# lines (the shape review-gate's own --jq produces: draft / head / review / thread / ratelimit).
# So this suite covers the bash logic; the jq program is checked live against a reviewed PR.
#
# Usage: bash scripts/tests/review-gate-test.sh [scripts/review-gate]

script_under_test=$(cd "$(dirname "${1:-"$(dirname "$0")/../review-gate"}")" && pwd)/$(basename "${1:-review-gate}")
failures=0
cases=0
workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

mkdir -p "$workdir/bin"
cat >"$workdir/bin/gh" <<'FAKE_GH'
#!/usr/bin/env bash
case "$*" in
  *merge-policy.json*bot_review*) echo "${FAKE_MODE:-off}" ;;
  *merge-policy.json*review_bot*) echo "${FAKE_BOT:-}" ;;
  "repo view"*)                   echo "owner/repo" ;;
  "api graphql"*)                 if [ "${FAKE_GRAPHQL_FAILS:-}" = yes ]; then echo "boom" >&2; exit 1; fi
                                  cat "$FAKE_STATE_FILE" ;;
  *)                              echo "fake gh: unexpected call: $*" >&2; exit 1 ;;
esac
FAKE_GH
chmod +x "$workdir/bin/gh"
export PATH="$workdir/bin:$PATH"
export FAKE_MODE=best-effort FAKE_BOT='coderabbitai[bot]'

# expect <case name> <expected output prefix> <state lines> [review-gate args…]
expect() {
  local name="$1" expected="$2" state="$3"; shift 3
  printf '%s\n' "$state" >"$workdir/state.txt"
  local output
  output=$(FAKE_STATE_FILE="$workdir/state.txt" bash "$script_under_test" 7 "$@" 2>&1)
  cases=$((cases + 1))
  local flag="  ok "
  if [[ $output != "$expected"* ]]; then flag="**BAD**"; failures=$((failures + 1)); fi
  printf '%s | %-44s | %s\n' "$flag" "$name" "${output//$'\n'/ ⏎ }"
}

# fake 40-char shas: the PR head, and an older commit the bot reviewed before the last push
HEAD_SHA=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
OLD_SHA=bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
ready_pr="draft false
head $HEAD_SHA"

echo "--- policy"
FAKE_MODE= expect "policy absent → off"  "BOT REVIEW: off" "$ready_pr"
FAKE_MODE=off expect "bot_review off"    "BOT REVIEW: off" "$ready_pr"
FAKE_BOT= expect "no review_bot → off"   "BOT REVIEW: off" "$ready_pr"

echo "--- draft"
expect "draft PR is unavailable" "BOT REVIEW: unavailable: draft" "draft true
head $HEAD_SHA
review APPROVED $HEAD_SHA 2026-01-01T00:00:00Z"

echo "--- clean"
expect "head reviewed, only resolved threads" "BOT REVIEW: clean $HEAD_SHA" "$ready_pr
review COMMENTED $HEAD_SHA 2026-01-01T00:00:00Z
thread T1 true src/a.ts:3 old nit"
expect "CHANGES_REQUESTED then APPROVED" "BOT REVIEW: clean $HEAD_SHA" "$ready_pr
review CHANGES_REQUESTED $HEAD_SHA 2026-01-01T00:00:00Z
review APPROVED $HEAD_SHA 2026-01-01T00:05:00Z"
expect "old rate limit, head reviewed since" "BOT REVIEW: clean $HEAD_SHA" "$ready_pr
ratelimit 2026-01-01T00:00:00Z 5
review COMMENTED $HEAD_SHA 2026-01-01T00:10:00Z"

echo "--- open"
expect "two unresolved threads, listed" "BOT REVIEW: open 2
  T1 src/a.ts:3 nit one
  T2 src/b.ts:9 nit two" "$ready_pr
review COMMENTED $HEAD_SHA 2026-01-01T00:00:00Z
thread T1 false src/a.ts:3 nit one
thread T0 true src/a.ts:1 resolved
thread T2 false src/b.ts:9 nit two"
expect "CHANGES_REQUESTED without threads" "BOT REVIEW: open 0" "$ready_pr
review CHANGES_REQUESTED $HEAD_SHA 2026-01-01T00:00:00Z"

echo "--- pending"
expect "only an older sha reviewed" "BOT REVIEW: pending" "$ready_pr
review COMMENTED $OLD_SHA 2026-01-01T00:00:00Z
thread T1 false src/a.ts:3 old thread"
expect "no review at all" "BOT REVIEW: pending" "$ready_pr"
expect "rate limit older than the last review" "BOT REVIEW: pending" "$ready_pr
ratelimit 2026-01-01T00:00:00Z 5
review COMMENTED $OLD_SHA 2026-01-01T00:10:00Z"

echo "--- unavailable"
expect "rate limit newer than the last review" "BOT REVIEW: unavailable: rate limit, retry in 17 min" "$ready_pr
review COMMENTED $OLD_SHA 2026-01-01T00:00:00Z
ratelimit 2026-01-01T00:10:00Z 17"
expect "rate limit, never reviewed" "BOT REVIEW: unavailable: rate limit, retry in ? min" "$ready_pr
ratelimit 2026-01-01T00:10:00Z ?"
FAKE_GRAPHQL_FAILS=yes expect "gh api graphql fails" "BOT REVIEW: unavailable: gh api graphql failed: boom" "$ready_pr"

echo
echo "$cases cases, $failures bad"
exit $(( failures ? 1 : 0 ))

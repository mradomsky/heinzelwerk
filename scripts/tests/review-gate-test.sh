#!/usr/bin/env bash
# review-gate regression suite: a fake `gh` on PATH answers the policy, repo, and GraphQL calls from env/fixtures.
# Usage: bash scripts/tests/review-gate-test.sh [scripts/review-gate]
rg=$(cd "$(dirname "${1:-"$(dirname "$0")/../review-gate"}")" && pwd)/$(basename "${1:-review-gate}"); bad=0; n=0
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
mkdir -p "$tmp/bin"; cat >"$tmp/bin/gh" <<'GH'
#!/usr/bin/env bash
case "$*" in
  *merge-policy.json*bot_review*) echo "${FAKE_MODE:-off}" ;;
  *merge-policy.json*review_bot*) echo "${FAKE_BOT:-}" ;;
  "repo view"*) echo "o/r" ;;
  "api graphql"*) [ "${FAKE_FAIL:-}" = yes ] && { echo "boom" >&2; exit 1; }; cat "$FAKE_STATE" ;;
  *) echo "fake gh: unexpected: $*" >&2; exit 1 ;;
esac
GH
chmod +x "$tmp/bin/gh"; export PATH="$tmp/bin:$PATH" FAKE_MODE=best-effort FAKE_BOT='coderabbitai[bot]'
t() { local name="$1" exp="$2" state="$3"; shift 3
  printf '%s\n' "$state" >"$tmp/state.txt"; out=$(FAKE_STATE="$tmp/state.txt" bash "$rg" 7 "$@" 2>&1); n=$((n+1))
  if [[ $out == $exp* ]]; then flag="  ok "; else flag="**BAD**"; bad=$((bad+1)); fi
  printf '%s | %-40s | %s\n' "$flag" "$name" "${out//$'\n'/ ⏎ }"; }
# fake 40-char shas: the PR head, and an older commit the bot reviewed before the last push
HEAD_SHA=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa; OLD_SHA=bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
base="draft false
head $HEAD_SHA"
FAKE_MODE= t "policy absent"   "BOT REVIEW: off" "$base" ; FAKE_MODE=off t "mode off" "BOT REVIEW: off" "$base"
FAKE_BOT= t "no bot named"  "BOT REVIEW: off" "$base"
t "draft"                   "BOT REVIEW: unavailable: draft" "draft true
head $HEAD_SHA
review APPROVED $HEAD_SHA 2026-01-01T00:00:00Z"
t "clean: head reviewed, no threads" "BOT REVIEW: clean $HEAD_SHA" "$base
review COMMENTED $HEAD_SHA 2026-01-01T00:00:00Z
thread T1 true src/a.ts:3 old nit"
t "open: two unresolved threads" "BOT REVIEW: open 2
  T1 src/a.ts:3 nit one
  T2 src/b.ts:9 nit two" "$base
review COMMENTED $HEAD_SHA 2026-01-01T00:00:00Z
thread T1 false src/a.ts:3 nit one
thread T0 true src/a.ts:1 resolved
thread T2 false src/b.ts:9 nit two"
t "open: CHANGES_REQUESTED, 0 threads" "BOT REVIEW: open 0" "$base
review CHANGES_REQUESTED $HEAD_SHA 2026-01-01T00:00:00Z"
t "clean: later APPROVED wins"  "BOT REVIEW: clean $HEAD_SHA" "$base
review CHANGES_REQUESTED $HEAD_SHA 2026-01-01T00:00:00Z
review APPROVED $HEAD_SHA 2026-01-01T00:05:00Z"
t "pending: only old sha reviewed" "BOT REVIEW: pending" "$base
review COMMENTED $OLD_SHA 2026-01-01T00:00:00Z
thread T1 false src/a.ts:3 old thread"
t "pending: no review at all"   "BOT REVIEW: pending" "$base"
t "rate limit newer than review" "BOT REVIEW: unavailable: rate limit, retry in 17 min" "$base
review COMMENTED $OLD_SHA 2026-01-01T00:00:00Z
ratelimit 2026-01-01T00:10:00Z 17"
t "rate limit, no review ever"  "BOT REVIEW: unavailable: rate limit, retry in ? min" "$base
ratelimit 2026-01-01T00:10:00Z ?"
t "rate limit older than review → pending" "BOT REVIEW: pending" "$base
ratelimit 2026-01-01T00:00:00Z 5
review COMMENTED $OLD_SHA 2026-01-01T00:10:00Z"
t "rate limit but head reviewed → clean" "BOT REVIEW: clean $HEAD_SHA" "$base
ratelimit 2026-01-01T00:00:00Z 5
review COMMENTED $HEAD_SHA 2026-01-01T00:10:00Z"
FAKE_FAIL=yes t "graphql fails"  "BOT REVIEW: unavailable: gh api graphql failed: boom" "$base"
echo; echo "$n cases, $bad bad"; exit $(( bad ? 1 : 0 ))

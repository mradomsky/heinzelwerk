#!/usr/bin/env bash
# stack-check regression suite.
#
# A fake `gh` on PATH answers the calls the script makes:
#   gh repo view                      FAKE_REPO (default owner/repo)
#   gh pr view 7 (the PR under test)  base FAKE_BASE (default main), head HEAD_SHA, body FAKE_BODY
#   gh pr view <dependency>           state FAKE_DEP_STATE (default OPEN; FAIL = gh error), head FAKE_DEP_HEAD
#                                     (default DEP_SHA), branch feat/170-base; FAKE_REQUIRE_REPO, when set, must
#                                     be the -R value of the call
#   gh pr view <base branch>          the base's PR number, FAKE_BASE_PR (default 170; empty = no PR)
#   gh api …/compare/<a>...<b>        FAKE_COMPARE (default ahead; empty = gh error)
#
# Usage: bash scripts/tests/stack-check-test.sh [scripts/stack-check]

script_under_test=$(cd "$(dirname "${1:-"$(dirname "$0")/../stack-check"}")" && pwd)/$(basename "${1:-stack-check}")
failures=0
cases=0
workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT

mkdir -p "$workdir/bin" "$workdir/repo"
cat >"$workdir/bin/gh" <<'FAKE_GH'
#!/usr/bin/env bash
case "$*" in
  "repo view"*)
    echo "${FAKE_REPO:-owner/repo}" ;;
  "pr view 7 --json baseRefName,headRefOid,body"*)
    printf '%s\n%s\n%s\n' "${FAKE_BASE:-main}" "$HEAD_SHA" "${FAKE_BODY:-## Done note}" ;;
  "pr view "*"--json state,headRefOid,headRefName"*)
    if [ "${FAKE_DEP_STATE:-OPEN}" = FAIL ]; then exit 1; fi
    if [ -n "${FAKE_REQUIRE_REPO:-}" ] && [[ "$*" != *"-R $FAKE_REQUIRE_REPO "* ]]; then exit 1; fi
    echo "${FAKE_DEP_STATE:-OPEN} ${FAKE_DEP_HEAD:-$DEP_SHA} feat/170-base" ;;
  "pr view "*"--json number"*)
    if [ -z "${FAKE_BASE_PR-170}" ]; then exit 1; fi
    echo "${FAKE_BASE_PR-170}" ;;
  "api repos/{owner}/{repo}/compare/$DEP_SHA...$HEAD_SHA"*)
    if [ -z "${FAKE_COMPARE-ahead}" ]; then exit 1; fi
    echo "${FAKE_COMPARE-ahead}" ;;
  *)
    echo "fake gh: unexpected call: $*" >&2; exit 1 ;;
esac
FAKE_GH
chmod +x "$workdir/bin/gh"
export PATH="$workdir/bin:$PATH"

# fake 40-char shas: the PR's head, the dependency's head, and the dependency's head after it moved
export HEAD_SHA=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
export DEP_SHA=dddddddddddddddddddddddddddddddddddddddd
MOVED_SHA=eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee

# expect <case name> <expected substring> [stack-check args…]; runs from $workdir. A leading `!` on the
# expected text means the output must not contain it.
expect() {
  local name="$1" expected="$2"; shift 2
  local output
  output=$(cd "$workdir" && bash "$script_under_test" "$@" 2>&1)
  cases=$((cases + 1))
  local flag="  ok "
  if [[ $expected == "!"* ]]; then
    if [[ $output == *"${expected#!}"* ]]; then flag="**BAD**"; fi
  elif [[ $output != *"$expected"* ]]; then
    flag="**BAD**"
  fi
  if [ "$flag" != "  ok " ]; then failures=$((failures + 1)); fi
  printf '%s | %-48s | %s\n' "$flag" "$name" "${output//$'\n'/ ⏎ }"
}

same_repo_line="Depends on #170, last snapshot $DEP_SHA"
other_repo_line="Depends on owner/provider#12, last snapshot $DEP_SHA"

echo "--- arguments"
expect "no arguments" "STACK ERROR: usage"
expect "PR not a number" "STACK ERROR: usage" abc
expect "extra argument" "STACK ERROR: usage" 7 8
expect "-C missing dir" "STACK ERROR: no repo dir nope" -C nope 7
expect "-C runs in the repo dir" "STACK NONE" -C repo 7
expect "owner/repo#N in the right repo" "STACK NONE" Owner/Repo#7
expect "owner/repo#N in another repo" "is owner/repo, not other/repo" other/repo#7

echo "--- no snapshot"
expect "plain body, base main" "STACK NONE" 7
FAKE_BODY="Depends on #170" expect "Depends on without a snapshot" "STACK NONE" 7
FAKE_BODY="retry depends on the config, last snapshot of it is old" expect "prose names no PR" "STACK NONE" 7

echo "--- same repo"
FAKE_BODY="$same_repo_line" expect "open, head is the snapshot" "STACK OK: #170 @ $DEP_SHA" 7
FAKE_BODY="Depends on #170, last snapshot ${DEP_SHA:0:7}" expect "7-char snapshot" "STACK OK: #170 @ $DEP_SHA" 7
FAKE_BODY="$same_repo_line" FAKE_DEP_HEAD=$MOVED_SHA expect "open, head moved" "STACK STALE: #170 snapshot $DEP_SHA, head $MOVED_SHA (git rebase --onto origin/feat/170-base $DEP_SHA" 7
FAKE_BODY="$same_repo_line" FAKE_DEP_STATE=MERGED expect "merged at the snapshot" "STACK MERGED: #170 @ $DEP_SHA" 7
FAKE_BODY="$same_repo_line" FAKE_DEP_STATE=MERGED FAKE_DEP_HEAD=$MOVED_SHA expect "merged at another head" "(git rebase --onto origin/main $DEP_SHA" 7
FAKE_BODY="$same_repo_line" FAKE_DEP_STATE=CLOSED expect "closed without a merge" "STACK CLOSED: #170" 7
FAKE_BODY="$same_repo_line" FAKE_DEP_STATE=FAIL expect "unreadable dependency" "STACK ERROR: #170 is no readable PR" 7
FAKE_BODY="$same_repo_line" FAKE_COMPARE=diverged expect "line updated without the rebase" "STACK STALE: #170 snapshot $DEP_SHA is not in this PR's history" 7
FAKE_BODY="$same_repo_line" FAKE_COMPARE=identical expect "PR head is the snapshot itself" "STACK OK: #170" 7
FAKE_BODY="$same_repo_line" FAKE_COMPARE= expect "compare fails" "STACK ERROR: could not compare" 7
FAKE_BODY="$same_repo_line" FAKE_DEP_STATE=MERGED FAKE_COMPARE=diverged expect "merged: history is not compared" "STACK MERGED: #170" 7

echo "--- another repo"
FAKE_BODY="$other_repo_line" FAKE_REQUIRE_REPO=owner/provider FAKE_COMPARE=diverged expect "open, head is the snapshot, no compare" "STACK OK: owner/provider#12 @ $DEP_SHA" 7
FAKE_BODY="$other_repo_line" FAKE_DEP_HEAD=$MOVED_SHA expect "head moved" "(read what changed in owner/provider between the two" 7
FAKE_BODY="Depends on Owner/Repo#170, last snapshot $DEP_SHA" FAKE_COMPARE=diverged expect "own repo written in full is this repo" "STACK STALE: #170 snapshot $DEP_SHA is not in this PR's history" 7

echo "--- how the line may be written"
FAKE_BODY="Depends on https://github.com/owner/provider/pull/12, last snapshot $DEP_SHA" expect "pull URL" "STACK OK: owner/provider#12" 7
FAKE_BODY="**Depends on** \`#170\`, last snapshot \`$DEP_SHA\`" expect "bold and backticks" "STACK OK: #170" 7
FAKE_BODY="Depends on [#170](https://github.com/owner/repo/pull/170), last snapshot $DEP_SHA" expect "markdown link" "STACK OK: #170" 7
FAKE_BODY="Depends on PR #170, last snapshot: $DEP_SHA" expect "PR #N and a colon" "STACK OK: #170" 7
FAKE_BODY="Refs #19
$same_repo_line
$other_repo_line

## Done note" expect "two lines, the second one too" "STACK OK: owner/provider#12" 7

echo "--- stacked PR (base is another PR's branch)"
FAKE_BASE=feat/170-base FAKE_BODY="$same_repo_line" expect "line names the base's PR" "!STACK MISSING" 7
FAKE_BASE=feat/170-base expect "no line at all" "STACK MISSING: stacked on #170 (base feat/170-base)" 7
FAKE_BASE=feat/170-base FAKE_BODY="$other_repo_line" expect "line names another PR only" "STACK MISSING: stacked on #170" 7
FAKE_BASE=feat/170-base FAKE_BASE_PR= expect "base has no PR" "STACK ERROR: base feat/170-base is not main and has no PR" 7

echo
echo "$cases cases, $failures bad"
exit $(( failures ? 1 : 0 ))

#!/usr/bin/env bash
# check-note regression suite. Usage: bash scripts/tests/check-note-test.sh [scripts/check-note]
cn=${1:-"$(dirname "$0")/../check-note"}; bad=0; n=0
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cat >"$tmp/team.md" <<'EOF'
# Team rules
- **Checks** (validator runs every one, in order): `npm run build --silent`, `npm test -- --reporter=dot`, `npm audit --audit-level=high (red on main: #12)`
EOF
cat >"$tmp/list-team.md" <<'EOF'
- **Checks** (validator runs every one, in order; failures only):
  1. `npm run check -- --threshold error`
  2. `npm test -- --reporter=dot` (covers `src/`, `lambda/` specs)
  - build: `npm run build`
- **Coding standards**: none
EOF
printf '# Team rules\n- **Run cap**: 3h\n' >"$tmp/empty-team.md"
t() { local name="$1" mode="$2" exp="$3" input="$4"; shift 4
  out=$(printf '%s\n' "$input" | bash "$cn" "$mode" "$@" 2>&1); rc=$?
  res=$([ $rc -eq 0 ] && echo PASS || echo FAIL); n=$((n+1))
  if [ "$res" = "$exp" ]; then flag="  ok "; else flag="**BAD**"; bad=$((bad+1)); fi
  printf '%s %s | %-44s | %s\n' "$flag" "$res" "$name" "${out:0:80}"; }

good='did: added webhook, src/a.ts
evidence: npm test 12 passed
checks: 0 0 0
handoff: #19 validate backend: webhook
left: none
escalations: none
session: ~/.claude/projects/x/3f2a9c1b-1.jsonl'

echo "--- note: must pass"
t "full note, team count" note PASS "$good" --team "$tmp/team.md"
t "full note, --checks 3" note PASS "$good" --checks 3
t "list-form Checks, 3 commands" note PASS "$good" --team "$tmp/list-team.md"
t "inside PR body" note PASS "## Summary
hi
## Done note
$good
## Other
x" --checks 3
t "abandoned note" note PASS "abandoned: teammate crashed"
t "CRLF body" note PASS "$(printf '%s\r\n' $'## Done note' "$good")" --checks 3
t "no Checks entry in team.md" note PASS "$good" --team "$tmp/empty-team.md"
t "optional fields" note PASS "$good
term: Anomaly
learning: flaky test x" --checks 3
echo "--- note: must fail"
t "missing session" note FAIL "$(grep -v '^session' <<<"$good")" --checks 3
t "checks count short" note FAIL "$good" --checks 4
t "checks count vs team.md" note FAIL "$(sed 's/^checks:.*/checks: 0 0/' <<<"$good")" --team "$tmp/team.md"
t "checks no code" note FAIL "$(sed 's/^checks:.*/checks: all green/' <<<"$good")" --checks 3
t "empty field" note FAIL "$(sed 's/^left:.*/left:/' <<<"$good")" --checks 3
t "out of order" note FAIL "evidence: x
did: y
checks: 0 0 0
handoff: h
left: none
escalations: none
session: abc12345" --checks 3
t "secret value" note FAIL "$good
evidence: token ghp_abcdefghijklmnop" --checks 3
t "session bare word" note FAIL "$(sed 's/^session:.*/session: yes/' <<<"$good")" --checks 3

echo "--- verdict: must pass"
t "full sha last line" verdict PASS "## Standards
ok
## Spec
ok
heinzelwerk: validated 0123456789abcdef0123456789abcdef01234567"
t "inconclusive with reason" verdict PASS "manual check: inconclusive: needs a device; verify on a phone
heinzelwerk: validated 0123456789abcdef0123456789abcdef01234567"
t "timestamp with UTC" verdict PASS "ran at 2026-10-30 12:00 UTC
heinzelwerk: validated 0123456789abcdef0123456789abcdef01234567"
t "file:line:col is not a time" verdict PASS "smell at src/a.ts:120:45 (Mysterious Name)
— heinzelwerk
heinzelwerk: validated 0123456789abcdef0123456789abcdef01234567"
echo "--- verdict: must fail"
t "short sha" verdict FAIL "heinzelwerk: validated 0123456"
t "sha not last" verdict FAIL "heinzelwerk: validated 0123456789abcdef0123456789abcdef01234567
thanks"
t "inconclusive bare" verdict FAIL "repro: inconclusive
heinzelwerk: validated 0123456789abcdef0123456789abcdef01234567"
t "timestamp without UTC" verdict FAIL "ran at 12:00
heinzelwerk: validated 0123456789abcdef0123456789abcdef01234567"

echo "$n cases, $bad bad"; [ $bad -eq 0 ]

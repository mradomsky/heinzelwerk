#!/usr/bin/env bash
# check-refs ledger-format regression suite (corrections.md). Usage: bash scripts/tests/check-refs-test.sh [scripts/check-refs]
cr=$(cd "$(dirname "${1:-$0/../../check-refs}")" && pwd)/$(basename "${1:-check-refs}"); bad=0; n=0
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cd "$tmp" && git init -q && mkdir -p docs/agents/heinzelwerk && printf 'x\n' >a.md
printf '# Team\n\n- see `a.md:1`\n' >docs/agents/heinzelwerk/team.md
t() { local name="$1" exp="$2" line="$3"
  printf '# Corrections\n\nintro\n\n%s\n' "$line" >docs/agents/heinzelwerk/corrections.md
  out=$(bash "$cr" 2>&1); rc=$?
  res=$([ $rc -eq 0 ] && echo PASS || echo FAIL); n=$((n+1))
  if [ "$res" = "$exp" ]; then flag="  ok "; else flag="**BAD**"; bad=$((bad+1)); fi
  printf '%s %s | %-44s | %s\n' "$flag" "$res" "$name" "${out:0:80}"; }
p='- 2026-11-03 a.md:1: was "old" → now "new", see'
echo "--- corrections.md: must pass"
t "same-repo ref" PASS "$p a.md:1"
t "same-repo ref with why" PASS "$p a.md:1; why: ported to TypeScript"
t "line list and range" PASS "$p src/x.ts:12,14-16"
t "dot path" PASS "$p .github/workflows/ci.yml:45-56"
t "cross-repo ref with why" PASS "$p V-M-Pioneer-Trading/meta .github/workflows/openapi-sync.yml:45-56; why: synced"
t "old sentence with quotes" PASS '- 2026-11-03 a.md:1: was "the "Go" table" → now "the TS table", see a.md:1'
t "CRLF line end" PASS "$p a.md:1"$'\r'
echo "--- corrections.md: must fail"
t "no see" FAIL '- 2026-11-03 a.md:1: was "old" → now "new"'
t "see with no path" FAIL "$p nothing"
t "cross-repo, no path" FAIL "$p V-M-Pioneer-Trading/meta"
t "trailing junk" FAIL "$p V-M-Pioneer-Trading/meta src/x.ts:12 extra junk"
t "local folder path" FAIL "$p ../meta/x.yml:4"
t "absolute path" FAIL "$p C:/Users/max/x.yml:4"
t "URL" FAIL "$p https://github.com/o/r/blob/main/x.yml:4"
t "bad date" FAIL '- 2026-11 a.md:1: was "old" → now "new", see a.md:1'
echo "$n cases, $bad bad"; [ $bad -eq 0 ]

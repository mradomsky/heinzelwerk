#!/usr/bin/env bash
# Guard regression suite (needs node for the JSON encoding). Usage: bash hooks/guard-test.sh [hooks/guard.sh]
guard=${1:-"$(dirname "$0")/guard.sh"}; bad=0; n=0
t() { local cmd="$1" exp="$2" json out rc res flag
  json=$(printf '{"tool_input":{"command":%s}}' "$(printf '%s' "$cmd" | node -e 'let s="";process.stdin.on("data",d=>s+=d).on("end",()=>process.stdout.write(JSON.stringify(s)))')")
  out=$(printf '%s' "$json" | bash "$guard" 2>&1); rc=$?
  res=$([ $rc -eq 2 ] && echo BLOCK || echo PASS); n=$((n+1))
  if [ "$res" = "$exp" ]; then flag="  ok "; else flag="**BAD**"; bad=$((bad+1)); fi
  printf '%s %s | %-62s | %s\n' "$flag" "$res" "${cmd//$'\n'/⏎}" "${out:0:70}"; }
echo "--- must block"
t 'git push origin main' BLOCK
t 'git push origin HEAD:main' BLOCK
t 'git push -u origin main' BLOCK
t 'git push origin +main' BLOCK
t 'git push origin feat/1:main' BLOCK
t 'git push origin feat/1:refs/heads/main' BLOCK
t 'git push origin refs/heads/main' BLOCK
t 'git push origin main:main' BLOCK
t 'git push origin "main"' BLOCK
t "git push origin 'HEAD:main'" BLOCK
t 'git push origin --delete main' BLOCK
t 'git push origin :main' BLOCK
t 'git push origin feat/x:main --force-with-lease' BLOCK
t 'git push --repo=https://x origin main' BLOCK
t 'git -C ../repo push origin main' BLOCK
t 'git -c x=y push origin main' BLOCK
t 'git --no-pager push origin main' BLOCK
t 'git push origin HEAD:main&&echo hi' BLOCK
t 'git push origin HEAD:main; echo' BLOCK
t 'git push origin HEAD:main|cat' BLOCK
t 'git "push" origin main' BLOCK
t 'git push origin $(echo main)' BLOCK
t 'git push origin ma\in' BLOCK
t 'git push origin \
main' BLOCK
t 'git push origin main # comment' BLOCK
t 'cd repo && git push origin main' BLOCK
t '(cd repo && git push origin main)' BLOCK
t 'bash -c "git push origin main"' BLOCK
t 'sh -lc "git push origin main"' BLOCK
t 'FOO=1 git push origin main' BLOCK
t 'env FOO=1 git push origin main' BLOCK
t 'eval "git push origin main"' BLOCK
t 'timeout 30 git push origin main' BLOCK
t 'git push --force origin feat/1' BLOCK
t 'git push origin feat/1 -f' BLOCK
t 'git push --mirror origin' BLOCK
t 'git push --all origin' BLOCK
t 'git push --no-verify origin feat/1' BLOCK
t 'git checkout main' BLOCK
t 'git switch main' BLOCK
t 'git checkout master' BLOCK
t 'git checkout -B main origin/main' BLOCK
t 'git checkout -b main' BLOCK
t 'git switch -c main' BLOCK
t 'git switch --create main' BLOCK
t 'git -C ../x checkout main' BLOCK
t 'git worktree add ../x main' BLOCK
t 'git branch -f main HEAD' BLOCK
t 'git branch -D main' BLOCK
t 'git branch -m feat/x main' BLOCK
t 'git branch --force main HEAD' BLOCK
t 'git update-ref refs/heads/main HEAD' BLOCK
t 'gh pr merge 12' BLOCK
t 'gh pr merge 12 --squash' BLOCK
t 'gh pr merge' BLOCK
t 'gh api --method PUT repos/o/r/pulls/12/merge' BLOCK
t 'gh api repos/o/r/pulls/12/merge -X PUT' BLOCK
t 'gh api -X PUT /repos/o/r/pulls/12/merge' BLOCK
t 'gh api graphql -f query="mutation { mergePullRequest(input:{pullRequestId:\"x\"}) { clientMutationId } }"' BLOCK
t 'gh api graphql -f query="mutation { enablePullRequestAutoMerge(input:{pullRequestId:\"x\"}) { clientMutationId } }"' BLOCK
t 'git commit -n -m "x"' BLOCK
t 'git commit --no-verify -m "x"' BLOCK
t 'git commit -m "x" --no-verify' BLOCK
t 'git commit -am "x" -n' BLOCK
t 'git commit -nm "x"' BLOCK
t 'git commit --no-verify' BLOCK
t 'git -c core.hooksPath=/dev/null commit -m x' BLOCK
t 'git commit -m "x" -c core.hooksPath=/dev/null' BLOCK
t 'git config core.hooksPath /dev/null' BLOCK
t 'HUSKY=0 git commit -m x' BLOCK
t 'SKIP=gitleaks git commit -m x' BLOCK
t 'LEFTHOOK=0 git commit -m x' BLOCK
t 'git add .env' BLOCK
t 'git add .env.local' BLOCK
t 'git add .env.production' BLOCK
t 'git add ./.env' BLOCK
t 'git add "./.env"' BLOCK
t 'git add config/.env' BLOCK
t 'git add -- .env' BLOCK
t 'git add -f .env' BLOCK
t 'git add README.md .env' BLOCK
t 'git add infra/terraform.tfstate' BLOCK
t 'git add terraform.tfstate.backup' BLOCK
t 'git add secrets/credentials.json' BLOCK
t 'git add id_rsa' BLOCK
t 'git add private.key' BLOCK
t 'git add server.pem' BLOCK
t 'git add plan.bin' BLOCK
t 'git add infra/dev/plan.tfplan' BLOCK
t 'git stage .env' BLOCK
t 'git update-index --add .env' BLOCK
t 'terraform apply plan.bin' BLOCK
t 'terraform -chdir=infra/dev apply' BLOCK
t 'cd infra && terraform apply' BLOCK
t 'tofu destroy' BLOCK
t 'tofu -chdir=x apply' BLOCK
t 'terraform state rm x' BLOCK
t 'terraform state push x' BLOCK
t 'terraform import x y' BLOCK
t 'terraform force-unlock x' BLOCK
t 'terraform workspace delete x' BLOCK
t 'terraform plan -out=p && terraform apply p' BLOCK
t 'terraform apply -auto-approve' BLOCK
t 'terraform apply -input=false p' BLOCK
t 'terraform  apply' BLOCK
t 'TF_CLI_ARGS_apply=-auto-approve terraform apply' BLOCK
t 'bash -c "terraform apply"' BLOCK
t 'sudo terraform apply' BLOCK
t 'git checkout -q main' BLOCK
t 'git checkout --force main' BLOCK
t 'git switch --quiet main' BLOCK
t 'git push -fu origin x' BLOCK
t 'export HUSKY=0; git commit -m x' BLOCK
t '$env:HUSKY=0; git commit -m x' BLOCK
t 'git commit -i .env -m x' BLOCK
t 'git commit -m x --include .env' BLOCK
echo "--- must pass"
t 'gh pr review 12 --comment -b "checks: pass | gh pr merge not run"' PASS
t 'gh issue comment 5 --body "ran checks && gh pr merge was refused"' PASS
t 'gh pr comment 12 --body "PASS | git push origin main is blocked"' PASS
t 'git commit -m "a; git push origin main"' PASS
t 'gh api repos/o/r/issues/1/comments -f body="x && gh pr merge y"' PASS
t 'git commit -m "x" -i src/a.ts' PASS
t 'git checkout -q -- file.txt' PASS
t 'git switch -c feat/1 main' PASS
t 'git push origin feat/1 --force-with-lease' PASS
t 'git push origin feat/22-main-page' PASS
t 'git push origin feat/22-maintenance' PASS
t 'git push origin domain/main-site' PASS
t 'git push origin main:feat/x' PASS
t 'git push origin HEAD' PASS
t 'git push -u origin feat/1' PASS
t 'git push origin feat/1 && gh pr create --base main --fill' PASS
t 'git push origin feat/1
gh pr create --base main' PASS
t 'git commit -m "x" && git push origin feat/1 && gh pr create --base main --body "Closes #5"' PASS
t 'git merge origin/main' PASS
t 'git merge --no-ff --no-edit origin/feat/1' PASS
t 'git rebase origin/main' PASS
t 'git fetch origin main' PASS
t 'git log main..HEAD' PASS
t 'git log --grep="terraform apply"' PASS
t 'git diff main' PASS
t 'git diff origin/main...HEAD' PASS
t 'git show origin/main:docs/x' PASS
t 'git show origin/main:docs/agents/heinzelwerk/merge-policy.json' PASS
t 'git checkout origin/main' PASS
t 'git checkout -b feat/2 main' PASS
t 'git checkout main -- file.txt' PASS
t 'git reset --hard origin/main' PASS
t 'git rev-parse main' PASS
t 'git rev-list --count @{u}..HEAD' PASS
t 'git branch -D feat/1' PASS
t 'git branch -D feat/22-main-page' PASS
t 'git branch --list main' PASS
t 'git branch -a' PASS
t 'git worktree add x -b feat/1 origin/main' PASS
t 'git worktree add ../x -b feat/1 origin/main' PASS
t 'git worktree add .claude/worktrees/heinzelwerk/fix-1 -B fix/1 origin/fix/1' PASS
t 'git -C repo worktree add repo/.claude/worktrees/heinzelwerk/val-1 origin/feat/1 --detach' PASS
t 'git worktree add path origin/main --detach' PASS
t 'git worktree remove path && git worktree prune' PASS
t 'git add src/main.ts' PASS
t 'git add key.ts' PASS
t 'git add monkey.txt' PASS
t 'git add docs/keys.md' PASS
t 'git add envelope.env.example' PASS
t 'git add .env.example' PASS
t 'git add src/environment.ts' PASS
t 'git add README.md' PASS
t 'git add -A' PASS
t 'git add .' PASS
t 'git add . && git commit -m x' PASS
t 'git add plan.md' PASS
t 'git add docs/plan-binding.md' PASS
t 'git commit -a -m "x"' PASS
t 'git commit -am "x"' PASS
t 'git commit -s -m "x"' PASS
t 'git commit --amend --no-edit' PASS
t 'git commit -F msg.txt' PASS
t 'git commit -m "fix: -n handling and --no-verify docs"' PASS
t 'git commit -m "do not push main"' PASS
t 'git commit -m "docs: explain why -auto-approve is banned"' PASS
t 'git commit -m "docs: core.hooksPath note"' PASS
t "git commit -m 'single -n quoted'" PASS
t 'git commit -m "msg with
--no-verify inside"' PASS
t 'git commit -m "$(cat <<EOF
x --no-verify
EOF
)"' PASS
t 'gh pr create --base main --title "x" --body "$(cat <<'"'"'EOF'"'"'
gh pr merge
EOF
)"' PASS
t 'gh pr create --base main --body "see pulls/12/merge docs"' PASS
t 'gh pr view main --json state' PASS
t 'gh pr view 12 --json comments,reviews' PASS
t 'gh pr review 12 --comment -b "heinzelwerk: validated abc"' PASS
t 'gh pr edit 12 --body "- [x] done"' PASS
t 'gh pr checks 12 --watch' PASS
t 'gh issue comment 5 --body "validator: never run gh pr merge yourself"' PASS
t 'gh issue edit 5 --remove-label ready-for-agent --add-label needs-info' PASS
t 'gh api repos/{owner}/{repo}/issues/comments/1 -X PATCH -f body=x' PASS
t 'grep -rn "git push origin main" docs/' PASS
t 'grep -rn "terraform apply" .' PASS
t 'echo "gh pr merge is blocked"' PASS
t 'echo main' PASS
t 'cat docs/agents/heinzelwerk/team.md | grep "terraform apply"' PASS
t 'npm run build' PASS
t 'npm test -- --reporter=dot' PASS
t 'npx playwright screenshot http://localhost:3000 x.png' PASS
t 'merge-gate 12' PASS
t 'tf-gate check infra/dev plan.bin' PASS
t 'tf-gate apply infra/dev plan.bin' PASS
t 'ui-shots 12/task a.png' PASS
t 'scripts/merge-gate 12' PASS
t 'bash <(git show origin/main:scripts/tf-gate) check infra plan.bin' PASS
t 'terraform fmt -check' PASS
t 'terraform validate' PASS
t 'terraform plan -input=false -out=plan.bin' PASS
t 'terraform show -json plan.bin' PASS
t 'terraform state list' PASS
t 'terraform state show x' PASS
t 'terraform state pull' PASS
t 'terraform taint x' PASS
t 'terraform init' PASS
t 'ls ~/.claude/teams/' PASS
t 'cat ~/.claude/teams/session-abc/config.json' PASS
echo "$n cases, $bad bad"

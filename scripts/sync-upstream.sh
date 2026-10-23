#!/usr/bin/env sh
set -eu

cd "$(git rev-parse --show-toplevel)"

upstream_remote="${UPSTREAM_REMOTE:-upstream}"
upstream_branch="${UPSTREAM_BRANCH:-main}"
fork_branch="${FORK_BRANCH:-mitch-lldap}"
timestamp="$(date +%Y%m%d-%H%M%S)"
sync_branch="${SYNC_BRANCH:-chore/sync-upstream-$timestamp}"
backup_branch="backup/pre-sync-$timestamp"
upstream_ref="$upstream_remote/$upstream_branch"

if [ -n "$(git status --porcelain)" ]; then
  printf 'Working tree is not clean. Commit or stash changes before syncing.\n' >&2
  exit 1
fi

if ! git remote get-url "$upstream_remote" >/dev/null 2>&1; then
  printf "Missing remote '%s'. Add it with:\n  git remote add %s https://github.com/lldap/lldap.git\n" "$upstream_remote" "$upstream_remote" >&2
  exit 1
fi

if ! git show-ref --verify --quiet "refs/heads/$fork_branch"; then
  printf "Local branch '%s' does not exist.\n" "$fork_branch" >&2
  exit 1
fi

if git show-ref --verify --quiet "refs/heads/$sync_branch"; then
  printf "Branch '%s' already exists.\n" "$sync_branch" >&2
  exit 1
fi

git fetch "$upstream_remote" --prune --tags

if ! git rev-parse --verify --quiet "$upstream_ref" >/dev/null; then
  printf "Upstream ref '%s' does not exist after fetch.\n" "$upstream_ref" >&2
  exit 1
fi

git branch "$backup_branch" "$fork_branch"
git switch -c "$sync_branch" "$fork_branch"

if git merge --no-ff "$upstream_ref" -m "merge: sync $upstream_ref into $fork_branch"; then
  :
else
  merge_status=$?
  if [ -n "$(git diff --name-only --diff-filter=U)" ]; then
    printf '\nMerge stopped on conflicts:\n' >&2
    git diff --name-only --diff-filter=U
    printf '\nResolve them using docs/fork-upstream-sync.md, then run:\n' >&2
    printf '  git add <resolved-files>\n' >&2
    printf '  git commit\n' >&2
    printf '  sh scripts/verify-fork.sh\n' >&2
    exit 2
  fi
  printf 'Merge failed with status %s.\n' "$merge_status" >&2
  exit "$merge_status"
fi

if ! sh scripts/verify-fork.sh; then
  printf '\nFork invariant check failed. Fix the issues, then run:\n  sh scripts/verify-fork.sh\n' >&2
  exit 1
fi

printf '\nSync branch: %s\n' "$sync_branch"
printf 'Backup branch: %s\n' "$backup_branch"
printf '\nNext steps:\n'
printf '  cargo fmt --all --check\n'
printf '  cargo clippy --tests --all -- -D warnings\n'
printf '  cargo build --workspace\n'
printf '  cargo test --workspace\n'
printf '  git push -u origin %s\n' "$sync_branch"
printf '  gh pr create --base %s --title "chore: sync upstream"\n' "$fork_branch"

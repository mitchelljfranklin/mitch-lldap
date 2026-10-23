#!/usr/bin/env sh
set -eu

cd "$(git rev-parse --show-toplevel)"

failures=0

record_failure() {
  printf 'FAIL: %s\n' "$1" >&2
  failures=$((failures + 1))
}

check_file() {
  if [ ! -f "$1" ]; then
    record_failure "missing $1"
  fi
}

check_contains() {
  if [ ! -f "$1" ]; then
    record_failure "missing $1"
    return
  fi
  if ! grep -Fq -e "$2" "$1"; then
    record_failure "$1 does not contain: $2"
  fi
}

required_files='
.github/README.md
.github/workflows/docker-build-fork.yml
.github/workflows/fork-invariants.yml
.github/workflows/rust.yml
AGENTS.md
CHANGELOG.md
schema.graphql
Dockerfile
app/index.html
app/index_local.html
app/src/components/admin_settings.rs
app/static/style.css
crates/frontend-options/src/lib.rs
crates/sql-backend-handler/src/sql_migrations.rs
server/src/tcp_server.rs
server/tests/graphql.rs
server/tests/integrations.rs
server/tests/ldap.rs
scripts/sync-upstream.sh
docs/fork-upstream-sync.md
'

for required_file in $required_files; do
  check_file "$required_file"
done

check_contains .github/README.md "ghcr.io/mitchelljfranklin/mitch-lldap"
check_contains .github/workflows/docker-build-fork.yml "mitch-lldap"
check_contains .github/workflows/docker-build-fork.yml "linux/amd64,linux/arm64"
check_contains .github/workflows/docker-build-fork.yml "workflow_dispatch"
check_contains .github/workflows/rust.yml "mitch-lldap"
check_contains Cargo.toml "mitchelljfranklin/mitch-lldap"
check_contains crates/frontend-options/src/lib.rs "BrandingOptions"
check_contains app/src/components/admin_settings.rs "BrandingOptions"
check_contains server/src/tcp_server.rs "get_settings"
check_contains server/src/tcp_server.rs "put_settings"
check_contains crates/sql-backend-handler/src/sql_migrations.rs "BrandingSettings"
check_contains Dockerfile "index_local.html"
check_contains app/index.html "bootstrap@5.3"
check_contains app/index_local.html "bootstrap.min.css"
check_contains app/index_local.html "data-bs-theme"
check_contains app/static/style.css "--lldap-accent"

for test_file in server/tests/*.rs; do
  check_contains "$test_file" "#![cfg(unix)]"
done

if git grep -qE '^(<<<<<<< |>>>>>>> )' -- . 2>/dev/null; then
  record_failure "conflict markers remain in tracked files"
fi

if [ "$failures" -ne 0 ]; then
  printf '\nFork invariant check failed with %s issue(s).\n' "$failures" >&2
  exit 1
fi

printf 'Fork invariants OK.\n'

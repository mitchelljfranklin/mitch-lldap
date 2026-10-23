# AGENTS.md

Fork of [lldap/lldap](https://github.com/lldap/lldap): a lightweight LDAP server in Rust with a Yew/WASM admin UI. This fork adds branding/theme settings, Bootstrap 5.3, multi-arch Docker images, and fork-specific docs/CI.

## Repo and branches

- **`mitch-lldap`** is the default deployment branch (protected, PRs required). Fork-only work branches from it.
- **`main`** tracks `upstream/main`. Upstream-bound work branches from it and must not include fork-only branding.
- Container image: `ghcr.io/mitchelljfranklin/mitch-lldap`.
- Root `README.md` is upstream's; the GitHub-facing fork README is `.github/README.md` — edit the latter.
- Commit/PR titles follow `tag: imperative sentence` (e.g. `server: ...`, `app: ...`, `docker: ...`).
- `.github/copilot-instructions.md` is an older upstream-oriented guide; prefer this file when they disagree.

## Upstream sync

`mitch-lldap` merges `upstream/main` directly. Do **not** merge `main` into `mitch-lldap` wholesale: `main` carries a deliberately stripped UI for upstream PRs and can remove branding. Sync `main` separately when preparing an upstream PR.

```sh
sh scripts/sync-upstream.sh
sh scripts/verify-fork.sh
```

The sync script creates a backup branch and a `chore/sync-upstream-*` branch, merges `upstream/main`, and runs the invariant checks. See `docs/fork-upstream-sync.md` for the conflict policy, rollback steps, and release flow.

## Commands

```sh
cargo build --workspace                         # full workspace; allow 300s+
cargo test --workspace --lib                    # unit tests
cargo test --workspace                          # adds Unix-only integration tests
cargo test -p lldap --test ldap <test_name>     # one integration test (Unix)
cargo fmt --all --check
cargo clippy --tests --all -- -D warnings       # ~90s
./app/build.sh                                  # WASM frontend; allow 300s+
./export_schema.sh                              # regenerate schema.graphql
sh scripts/verify-fork.sh                       # fork customization checks
cargo run -- run --config-file lldap_config.toml
```

- Bare `cargo build` builds only `server` (`default-members = ["server"]`), not the workspace.
- Toolchain is pinned to **1.91.0** in `rust-toolchain.toml` and CI; do not use newer language features.

## Testing quirks

- `server/tests/{ldap,graphql,integrations}.rs` are all `#![cfg(unix)]`. On Windows they compile but run zero tests.
- Integration tests spawn the real `lldap` binary, bind ports 3890/17170, share the repo-root SQLite file `e2e_test.db` (override with `LLDAP_DATABASE_URL`), and are serialized with `serial_test`.
- CI runs `cargo test --workspace` on Ubuntu; on Windows use `--lib` for local verification.
- `.config/nextest.toml` exists, but CI uses plain `cargo test`.

## GraphQL and frontend

- `schema.graphql` is checked in and consumed at compile time by `app`, `migration-tool`, and `server/tests` (`schema_path = "../schema.graphql"`). After any GraphQL type change run `./export_schema.sh`; CI regenerates and diffs it. Update affected `.graphql` query files too.
- `app` is a Yew 0.19 WASM cdylib. `./app/build.sh` needs `wasm-pack`, `gzip`, and a POSIX shell (Git Bash/WSL on Windows); it writes `app/pkg`, including the gzipped wasm.
- The server serves assets from `assets_path` (default `./app`), so start it from the repo root.
- `app/index.html` (local dev, CDN assets) and `app/index_local.html` (Docker, `/static` assets) are near-duplicates; mirror markup changes in both.
- Do not bump `indexmap = "=1.6.2"` in `app/Cargo.toml` (aHash WASM issue). `yew_form`/`yew_form_derive` come from a pinned git rev, not crates.io.

## Server and configuration

- Subcommands: `run`, `healthcheck`, `export_graphql_schema`, `create_schema`, `send_test_email`.
- LLDAP reads `lldap_config.toml` (gitignored; start from `lldap_config.docker_template.toml`). Root `config.toml` only contains Cargo linker settings; it is not an LLDAP config.
- Precedence: built-in defaults < TOML file < `LLDAP_*` env < CLI. Nested keys use `__`, e.g. `LLDAP_SMTP_OPTIONS__SERVER`; unknown `LLDAP_*` variables only warn.
- `jwt_secret` is always required; `ldap_user_pass` is required when creating or resetting the admin user. If `key_seed` is set and a `server_key` file exists, startup aborts; delete the file.
- DB schema auto-migrates at startup (SeaORM). SQLite is default; PostgreSQL and MariaDB/MySQL are supported. Any query, migration, or conflict-handler change must work on all three.
- Ports: LDAP 3890, HTTP 17170, LDAPS 6360 (disabled).

## Architecture

- `server/` — `lldap` binary: CLI/config, Actix HTTP + GraphQL, LDAP listener.
- `crates/graphql-server` → `crates/domain`, `domain-handlers`, `domain-model` → `crates/sql-backend-handler` (SeaORM).
- Supporting crates: `access-control`, `auth`/`opaque-handler` (OPAQUE), `ldap`, `validation`, `frontend-options`, `test-utils`.
- `app/` — Yew WASM UI; `migration-tool/` — OpenLDAP import CLI; `set-password/` — password CLI.

## Docker and CI

- Root `Dockerfile` builds everything from source with cargo-chef. Release images use `.github/workflows/Dockerfile.ci.multiarch` with prebuilt amd64/arm64 artifacts.
- `docker-build-fork.yml` runs only on published releases or manual dispatch and pushes `ghcr.io/mitchelljfranklin/mitch-lldap`.
- `rust.yml` runs on pushes to `main`/`mitch-lldap` and PRs: build, tests + schema diff, clippy, fmt. The coverage job only runs in `lldap/lldap`, not this fork.
- `fork-invariants.yml` runs on `mitch-lldap` pushes/PRs to catch lost branding, fork identity, or Windows test fixes.
- Local container test: `docker run -e LLDAP_JWT_SECRET=secret -e LLDAP_LDAP_USER_PASS=pass -p 17170:17170 -v lldap_data:/data mitch-lldap:test`.

## Conventions and quality gates

- No stubs: no `TODO`/`FIXME`, empty bodies, or dead/commented-out code.
- No comments unless explicitly requested.
- No `unwrap()`/`expect()` without justification; validate external input and use `thiserror` for structured errors.
- Use descriptive names and early returns; match the surrounding module's import/error/naming style.
- Before finishing: `cargo fmt --all --check`, `cargo clippy --tests --all -- -D warnings`, `cargo build --workspace`, `cargo test --workspace --lib`, and `sh scripts/verify-fork.sh` must pass. Frontend changes also require `./app/build.sh`; GraphQL changes also require `./export_schema.sh`.

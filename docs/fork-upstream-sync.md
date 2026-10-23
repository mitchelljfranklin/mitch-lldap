# Keeping the fork in sync with upstream

`mitch-lldap` is a deployment fork, not a mirror. Upstream changes are **merged** into it. Fork commits are never rebased or force-pushed.

## Branch model

| Ref | Purpose | How it syncs |
| --- | --- | --- |
| `upstream/main` | Upstream `lldap/lldap` | Fetch only |
| `main` | Upstream-ready changes, without fork branding | Merge `upstream/main` when preparing an upstream PR |
| `mitch-lldap` | Default deployment branch | Merge `upstream/main` on a sync branch, then open a PR |

Do **not** merge `main` into `mitch-lldap` wholesale. `main` contains a deliberately stripped UI for upstream review and can remove fork branding. Port individual commits when an upstream-ready change is also wanted in the fork.

Do not use GitHub's **Sync fork** button on `mitch-lldap`. It can discard divergent fork commits. Sync locally with the script and open a PR.

## One-time setup

```sh
git remote add upstream https://github.com/lldap/lldap.git
git fetch upstream --prune --tags
git config rerere.enabled true
git config rerere.autoupdate true
```

Skip `remote add` if `git remote -v` already shows `upstream`. `rerere` records conflict resolutions and replays them on later syncs; it is local-only configuration.

## Routine sync

```sh
sh scripts/sync-upstream.sh
```

On Windows, run the shell scripts from Git Bash or WSL. The script requires a clean working tree, fetches `upstream`, creates a `backup/pre-sync-*` branch, creates a `chore/sync-upstream-*` branch from `mitch-lldap`, merges `upstream/main`, and runs `scripts/verify-fork.sh`. It never pushes.

If the merge stops on conflicts, resolve them using the policy below, then:

```sh
git add <resolved-files>
git commit
sh scripts/verify-fork.sh
```

Run the normal quality gates before opening the PR:

```sh
cargo fmt --all --check
cargo clippy --tests --all -- -D warnings
cargo build --workspace
cargo test --workspace
```

On Windows, use `cargo test --workspace --lib` because the integration tests are Unix-only. If the sync touches the frontend, also run `./app/build.sh`; if it touches GraphQL types, also run `./export_schema.sh`.

Push the sync branch and open a PR into `mitch-lldap`:

```sh
git push -u origin HEAD
gh pr create --base mitch-lldap --title "chore: sync upstream"
```

## Conflict policy

| Area | Resolution |
| --- | --- |
| Root `README.md` | Take upstream. The fork README is `.github/README.md`. |
| `.github/README.md`, `AGENTS.md`, `CHANGELOG.md` | Keep the fork version; merge in relevant upstream details. |
| `.github/workflows/docker-build-fork.yml` | Keep the fork workflow and its multi-arch/release behavior. |
| `.github/workflows/rust.yml` | Combine: keep the `mitch-lldap` trigger and fork-only steps, take upstream action/dependency updates. |
| Root `Cargo.toml` metadata | Keep the fork repository, author, and container identity; take upstream dependency and toolchain changes. |
| Branding/theme code | Keep the fork feature. If upstream refactored the same code, reapply the feature onto the new structure. |
| `app/index.html` and `app/index_local.html` | Keep both and mirror markup changes; Docker uses `index_local.html`. Keep the fork's Bootstrap 5.3/theme block, but adopt upstream's relative `static/...` URLs so the UI works behind custom paths. |
| `server/tests/*.rs` | Keep `#![cfg(unix)]`; it is the fork's Windows fix. |
| Database migrations | Keep both the fork branding migration and upstream migrations. Verify migration ordering and run the SQL backend tests. |
| Generic upstream code and docs | Take upstream unless the fork deliberately changed that behavior. |

Do not use `git merge -X ours` or `-X theirs` for the whole sync. Those discard one side of every conflict and silently drop customizations.

## Fork customization inventory

- **Identity:** `.github/README.md`, `AGENTS.md`, `CHANGELOG.md`, `Cargo.toml` workspace metadata, issue templates, and `.github/workflows/rust.yml`.
- **Branding and theme:** `crates/frontend-options`, `app/src/components/admin_settings.rs`, `app/src/components/app.rs`, `app/src/components/banner.rs`, `app/static/style.css`, `server/src/tcp_server.rs`, and the branding migration/table in `crates/sql-backend-handler`.
- **Bootstrap 5.3 UI:** `app/index.html`, `app/index_local.html`, `app/static/libraries.txt`, and `app/static/style.css`.
- **Multi-arch Docker:** `.github/workflows/docker-build-fork.yml`, `.github/workflows/Dockerfile.ci.multiarch`, and root `Dockerfile`.
- **Windows test fix:** the `#![cfg(unix)]` attributes in `server/tests`.
- **Docs:** fork URLs and removed upstream-only links in `docs/` and `example_configs/`.

`sh scripts/verify-fork.sh` checks the highest-risk identity and feature markers. It runs in CI on `mitch-lldap`.

## Rollback

Before pushing:

```sh
git merge --abort          # while conflicts are unresolved
git switch mitch-lldap
git branch -D chore/sync-upstream-<timestamp>
```

If the merge was already committed but not pushed, reset to the backup branch:

```sh
git reset --hard backup/pre-sync-<timestamp>
```

The `backup/pre-sync-*` branch still points at the pre-sync commit.

If the merge was already pushed, revert it on `mitch-lldap` with `git revert -m 1 <merge-commit>` instead of rewriting the protected branch.

## Releasing after a sync

1. Update `CHANGELOG.md` with the upstream changes and any fork-specific changes.
2. Bump the version if needed.
3. Tag the release from `mitch-lldap`.
4. Publish the GitHub release; `docker-build-fork.yml` builds and pushes the multi-arch image.

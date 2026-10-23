# mitch-lldap Changelog

This is a fork of [lldap/lldap](https://github.com/lldap/lldap). Entries below describe
changes unique to this fork. Upstream changes are pulled in periodically and tracked
separately.

---

## [1.1.0] — 2026-07-21

### Added
- **Docker multi-arch builds**: Images now built for `linux/amd64` and `linux/arm64`
  (Raspberry Pi 3B+, 4, 5). Uses Rust cross-compilation via `cross` — no QEMU for
  the heavy compile step.
- **Docker workflow triggers on release only**: Container images published via
  `ghcr.io/mitchelljfranklin/mitch-lldap` on each release (`v*` tag) or manual
  dispatch. Tags: `latest`, `v{major}`, `v{major}.{minor}`, `v{version}`, SHA, date.

### Fixed
- **CI noise**: Codecov upload skipped on fork (no `CODECOV_TOKEN` secret).
- **Docker binary permissions**: `chmod +x` applied to cross-compiled binaries in CI
  image.

### Changed
- **Documentation overhaul**: README fork notice, "What's the difference" section,
  container image reference. Docs updated with fork URLs, Discord/Twitter links
  removed.
- **New README**: Complete rewrite — quick-start compose, features table, badge row,
  config reference, side-by-side screenshot layout, curated upstream docs links.
- **Repository identity**: GitHub URLs point to this fork.
  `.github/FUNDING.yml` removed. Issue templates point here.
- **Footer**: Shows `mitch-lldap v{version}` with GitHub link only.
- **AGENTS.md**: Compact AI agent guide covering branch structure, sync routine,
  build commands, gotchas, quality gates, and code style.
- **Dependencies**: 131 packages updated including critical `lettre` CVE fix
  (TLS hostname verification), `anyhow` unsoundness fix, and yanked `spin` crate.

---

## [1.0.0] — 2026-07-21

### Added
- **Branding & theme system**: Admin settings page for app name, logo upload, accent
  color, default color scheme (Light / Dark / Auto).
- **Bootstrap 5.3.3 upgrade**: Replaced Bootstrap 5.1 and Bootstrap Icons 1.5 with
  5.3.3 and 1.11.3. Removed legacy Font Awesome 4 and `bootstrap-dark-5` dependencies.
- **CSS design tokens**: Light/dark palettes defined side-by-side with custom
  properties (`--lldap-accent`, spacing variables, radius, shadows).
- **Dark mode**: Browser-native `data-bs-theme` with localStorage persistence and a
  pre-paint inline script to avoid flash.
- **UI refresh**: Sticky nav header with app logo and centered links, user dropdown
  with avatar, auth-card layout for login and password reset, table cards with hover
  highlighting, restyled footer.
- **Admin settings page**: Configure app name, logo (upload or URL), default color
  scheme, and accent color through the web UI.
- **Database migration**: `branding_settings` table (v12 schema) for persisting
  branding options.
- **Fork-specific workflows**: Docker image published to
  `ghcr.io/mitchelljfranklin/mitch-lldap`, Rust CI running on `mitch-lldap` branch.
- **Default branch**: `mitch-lldap` with branch protection.

### Security
- Random password reset and refresh tokens switched to `OsRng`.
- Password modify returns `InsufficientAccessRights` instead of panicking.

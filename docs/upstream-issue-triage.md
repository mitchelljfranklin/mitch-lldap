# Upstream issue triage

Snapshot: **2026-11-26**. Source: `gh issue list --repo lldap/lldap --state open --limit 500` — **112 non-PR issues** (GitHub's 159 open items include pull requests). Fork baseline: `mitch-lldap` at `85cd8e8`, upstream `99c510a`.

This is a working backlog, not a promise. “Fork” means we can ship it without waiting for upstream; “Upstream first” means the change is large, architectural, or likely to conflict with upstream direction.

Legend: **S** < 1 day, **M** 1–3 days, **L** > 3 days. **Verified** means reproduced or confirmed in our tree; **Likely** means the upstream report matches our code; **Repro** means it needs a test before we patch.

## Do next: small, high impact

| Issue | Why it matters | Route | Effort | Status |
| --- | --- | --- | --- | --- |
| [#1479](https://github.com/lldap/lldap/issues/1479) — refresh web assets across frontend updates | We hit this in v1.1.0: a browser kept the old WASM and showed the old version. Add `Cache-Control: no-cache` for the loader/WASM or content-hash the asset URLs. | Fork + upstream | S | Verified: no cache headers |
| [#1548](https://github.com/lldap/lldap/issues/1548) — failed LDAP bind keeps administrator authorization | A connection that was bound as admin stays admin after a failed bind. Clear `user_info` at the start of every bind. | Fork + upstream | S | Verified in `do_bind` |
| [#1542](https://github.com/lldap/lldap/issues/1542) — LDAP modify panics on a mixed-case DN | The `assert!` in `parse_distinguished_name` turns a client request into a panic/DoS. | Fork + upstream | S | Verified |
| [#1554](https://github.com/lldap/lldap/issues/1554) — base-object search on `ou=people` / `ou=groups` ignores the filter | Clients probing a DN get a false “yes”. Evaluate the filter for the fixed OU entries. | Fork + upstream | S | Verified |
| [#1553](https://github.com/lldap/lldap/issues/1553) — unknown extended operation returns `unwillingToPerform` | RFC 4511 requires `protocolError`. One-line result-code fix. | Fork + upstream | S | Verified |
| [#1552](https://github.com/lldap/lldap/issues/1552) — unrecognised critical control is ignored | Unsupported critical controls must return `unavailableCriticalExtension`. | Fork + upstream | M | Verified: catch-all path |
| [#1551](https://github.com/lldap/lldap/issues/1551) — Abandon request is answered with an ExtendedResponse | Breaks `ldap3` keep-alives; RFC says no response. Add an `AbandonRequest => None` arm. | Fork + upstream | S | Verified |
| [#1534](https://github.com/lldap/lldap/issues/1534) — hidden custom user attributes exposed by LDAP Search and Compare | Security/privacy leak of `isVisible=false` attributes. GraphQL already hides them. | Fork + upstream | M | Repro |
| [#1549](https://github.com/lldap/lldap/issues/1549) — Web UI: reload on redirected or unexpected 401 | Stale UI after auth redirects. Small frontend reliability fix. | Fork | S | Repro |
| [#1507](https://github.com/lldap/lldap/issues/1507) — Web UI password change produces an unverifiable OPAQUE registration | Maintainer suspects a cache issue and it may disappear after #1479. Retest after the asset fix before changing OPAQUE code. | Fork | S | Repro |
| [#1513](https://github.com/lldap/lldap/issues/1513) — paged-results response control sent when not requested | Breaks at least one IP-phone phonebook client. Only emit the control when the request carried it. | Fork + upstream | S | Verified |
| [#1202](https://github.com/lldap/lldap/issues/1202) — attributes with the same name can have different types | Data-integrity bug and an upstream `good first issue`. | Upstream first | S–M | Repro |

## Session and auth security

These are related and likely need one design pass rather than four independent patches.

| Issue | Why it matters | Route | Effort | Status |
| --- | --- | --- | --- | --- |
| [#1516](https://github.com/lldap/lldap/issues/1516) — JWT privileges not revoked after group or password changes | An old admin JWT remains admin after removal from `lldap_admin`. | Upstream first | M–L | Likely |
| [#1541](https://github.com/lldap/lldap/issues/1541) — logout and password reset do not revoke other refresh tokens | A second/stolen refresh token can mint a new JWT after logout or recovery. | Upstream first | M | Likely |
| [#1517](https://github.com/lldap/lldap/issues/1517) — OPAQUE registration-finish is reusable after logout/reset | A staged finish request can replace a password later. Needs expiry and one-time use. | Upstream first | M | Likely |
| [#1026](https://github.com/lldap/lldap/issues/1026) — prevent timing attacks to detect valid emails | Password-reset timing leaks account existence; upstream added a 3-second pause. | Fork + upstream | S–M | Repro |
| [#39](https://github.com/lldap/lldap/issues/39) — check passwords against Have I Been Pwned | Security feature; off by default. | Upstream first | M | Repro |
| [#1526](https://github.com/lldap/lldap/issues/1526) — optional mTLS client-certificate verification on LDAPS | Defence in depth for LDAP clients such as Authelia. | Upstream first | M | Repro |

## Reliability, DB, and multi-DB

The fork advertises SQLite, PostgreSQL, and MariaDB/MySQL. These issues matter more to us than to a SQLite-only deployment.

| Issue | Why it matters | Route | Effort | Status |
| --- | --- | --- | --- | --- |
| [#1476](https://github.com/lldap/lldap/issues/1476) — Postgres connection leak on `/auth/simple/login` | Exhausts `max_connections` over days and takes the directory down. | Upstream first | L | Repro |
| [#1532](https://github.com/lldap/lldap/issues/1532) — no SIGTERM shutdown with TLS Postgres | systemd/Kubernetes need a clean stop; reproduction also reported on MySQL. | Upstream first | M | Repro |
| [#1467](https://github.com/lldap/lldap/issues/1467) — startup migration race with multiple instances | Kubernetes replicas can race migrations. Upstream is discussing a `create_schema`-first workflow. | Upstream first | M | Repro |
| [#1463](https://github.com/lldap/lldap/issues/1463) — MariaDB panic after SQLite migration | Directly affects the fork's multi-DB promise. Needs a MariaDB reproduction and sanitiser check. | Upstream first | M | Repro |
| [#1513](https://github.com/lldap/lldap/issues/1513) — paged-results response control sent when not requested | Breaks at least one IP-phone phonebook client. | Fork + upstream | M | Repro |
| [#1510](https://github.com/lldap/lldap/issues/1510) — derive RFC2307 `memberUid` from membership | Improves POSIX/Linux-client compatibility. | Upstream first | M | Repro |
| [#1425](https://github.com/lldap/lldap/issues/1425) — group search still runs for person-only filters | Noisy warnings and unnecessary work. | Fork + upstream | S | Repro |
| [#999](https://github.com/lldap/lldap/issues/999) — unable to search using firstname | Common client expectation. | Upstream first | M | Repro |
| [#585](https://github.com/lldap/lldap/issues/585) — password change fails when user ID contains a space | Small correctness fix. | Fork + upstream | S | Repro |
| [#1320](https://github.com/lldap/lldap/issues/1320) — routing userID with slash fails | UI routing edge case. | Fork | S | Repro |
| [#946](https://github.com/lldap/lldap/issues/946) — multibyte characters break client | Internationalisation correctness. | Upstream first | M | Repro |
| [#1165](https://github.com/lldap/lldap/issues/1165) — users/groups seen as containers instead of leafs | LDAP browser/client compatibility. | Upstream first | M | Repro |

## Fork differentiators and UX

These are good fits for this fork even if upstream declines them.

| Issue | Why it matters | Route | Effort | Status |
| --- | --- | --- | --- | --- |
| [#1544](https://github.com/lldap/lldap/issues/1544) — regular rebuild of container image | Base-image CVEs should reach `latest` without waiting for a feature release. Add a scheduled rebuild from the latest release tag. | Fork | S | Confirmed gap: workflow is release/manual only |
| [#1455](https://github.com/lldap/lldap/issues/1455) — show custom user attributes in tables | `uidNumber`/`gidNumber` and similar are currently one click per user. High-value admin UX. | Fork | M | Repro |
| [#492](https://github.com/lldap/lldap/issues/492) — show avatars in the user list | We already have an avatar component and branding work. | Fork | M | Repro |
| [#19](https://github.com/lldap/lldap/issues/19) — improve accessibility | ARIA labels, focus order, keyboard/mobile forms; aligns with the UI refresh. | Fork + upstream | S–M | Repro |
| [#1148](https://github.com/lldap/lldap/issues/1148) — customise login/password-reset pages | Upstream says no; we already have branding settings. Natural fork extension. | Fork | M | Repro |
| [#986](https://github.com/lldap/lldap/issues/986) — precompress WASM with Brotli/Zstd | Better first-load performance; we already ship gzip. | Fork | M | Repro |
| [#1133](https://github.com/lldap/lldap/issues/1133) — search multi-valued custom attributes | LDAP compatibility gap. | Upstream first | M | Repro |
| [#1129](https://github.com/lldap/lldap/issues/1129) — Boolean custom attribute type | Common schema request. | Upstream first | M | Repro |
| [#1308](https://github.com/lldap/lldap/issues/1308) — `GreaterOrEqual` filter for built-in timestamps | Client compatibility. | Upstream first | M | Repro |
| [#1329](https://github.com/lldap/lldap/issues/1329) — binary attributes beyond `jpegPhoto` | Schema flexibility. | Upstream first | M | Repro |

## Upstream-first: larger or design-sensitive

These are valuable but too large to carry as fork-only patches without a high maintenance cost. Track upstream direction and only fork after a design is settled.

- **Auth and account lifecycle:** [#631](https://github.com/lldap/lldap/issues/631) TOTP, [#783](https://github.com/lldap/lldap/issues/783) password expiration, [#521](https://github.com/lldap/lldap/issues/521) password policy, [#750](https://github.com/lldap/lldap/issues/750) disable LDAP users, [#1383](https://github.com/lldap/lldap/issues/1383) inactive-account timeout, [#1381](https://github.com/lldap/lldap/issues/1381) `pwdLastSet`, [#1017](https://github.com/lldap/lldap/issues/1017) invite links, [#1189](https://github.com/lldap/lldap/issues/1189) reset link in the UI, [#727](https://github.com/lldap/lldap/issues/727) email login.
- **Directory model:** [#13](https://github.com/lldap/lldap/issues/13) group inheritance, [#67](https://github.com/lldap/lldap/issues/67) arbitrary/duplicate text fields, [#712](https://github.com/lldap/lldap/issues/712) OpenSSH-LPK schema, [#599](https://github.com/lldap/lldap/issues/599) Samba integration, [#1493](https://github.com/lldap/lldap/issues/1493) Samba schema.
- **Synchronisation and extensibility:** [#301](https://github.com/lldap/lldap/issues/301) two-way SCIM/LDAP sync, [#717](https://github.com/lldap/lldap/issues/717) external IDM sync, [#1052](https://github.com/lldap/lldap/issues/1052) Entra ID sync, [#714](https://github.com/lldap/lldap/issues/714) plugin system.
- **Transport and deployment:** [#701](https://github.com/lldap/lldap/issues/701) LDAP over Unix sockets, [#813](https://github.com/lldap/lldap/issues/813) HTTPS on the app listener, [#352](https://github.com/lldap/lldap/issues/352) header/forward-auth SSO, [#1069](https://github.com/lldap/lldap/issues/1069) `RO_ADMIN` via env, [#1340](https://github.com/lldap/lldap/issues/1340) DB URL from parts/file, [#539](https://github.com/lldap/lldap/issues/539) migration-tool progress/automation.
- **Schema/UI edges:** [#1399](https://github.com/lldap/lldap/issues/1399) avatar `MEDIUMBLOB`, [#1390](https://github.com/lldap/lldap/issues/1390) required-attribute toggle, [#1406](https://github.com/lldap/lldap/issues/1406) change hardcoded attributes, [#1336](https://github.com/lldap/lldap/issues/1336) substring search, [#1472](https://github.com/lldap/lldap/issues/1472) approximate match, [#1473](https://github.com/lldap/lldap/issues/1473) result-set limit, [#1375](https://github.com/lldap/lldap/issues/1375) multilingual UI.

## Docs and integrations

Low code risk, good for contributors, but not release blockers.

- [#1396](https://github.com/lldap/lldap/issues/1396) bootstrap.sh docs, [#1416](https://github.com/lldap/lldap/issues/1416) Stalwart aliases, [#1374](https://github.com/lldap/lldap/issues/1374) Docker MailServer/Dovecot, [#1154](https://github.com/lldap/lldap/issues/1154) Fortiauthenticator, [#1123](https://github.com/lldap/lldap/issues/1123) Zeppelin/Hue, [#863](https://github.com/lldap/lldap/issues/863) Etherpad, [#831](https://github.com/lldap/lldap/issues/831) Dolibarr, [#739](https://github.com/lldap/lldap/issues/739) SSSD, [#172](https://github.com/lldap/lldap/issues/172) backup/restore, [#600](https://github.com/lldap/lldap/issues/600) log verbosity, [#1229](https://github.com/lldap/lldap/issues/1229) MSRV, [#1435](https://github.com/lldap/lldap/issues/1435) SMTP password from file (already supported; document it).

## Defer or skip

- **Config/environment problems, not code:** [#1151](https://github.com/lldap/lldap/issues/1151) SMTP TLS, [#1372](https://github.com/lldap/lldap/issues/1372) Docker certificate path, [#1528](https://github.com/lldap/lldap/issues/1528) missing `wasm.gz` from an old `gzip`.
- **Upstream explicitly not a goal:** [#1290](https://github.com/lldap/lldap/issues/1290) local-time logs, [#1394](https://github.com/lldap/lldap/issues/1394) phpLDAPadmin compatibility.
- **Policy or out of scope:** [#1349](https://github.com/lldap/lldap/issues/1349) LLM-usage disclosure, [#579](https://github.com/lldap/lldap/issues/579) crates.io publishing, [#707](https://github.com/lldap/lldap/issues/707) generic CLI support, [#1147](https://github.com/lldap/lldap/issues/1147) non-OPAQUE password changes.
- **Too large without upstream buy-in:** the Samba, plugin, synchronisation, duplicate-field, group-inheritance, and CockroachDB items in the upstream-first section.
- **Low value or already covered:** [#400](https://github.com/lldap/lldap/issues/400) cookie name, [#464](https://github.com/lldap/lldap/issues/464) logo (fork has branding), [#401](https://github.com/lldap/lldap/issues/401) other avatar formats, [#572](https://github.com/lldap/lldap/issues/572) avatar pixel limit, [#994](https://github.com/lldap/lldap/issues/994) mail-client CA, [#1022](https://github.com/lldap/lldap/issues/1022) vague login report, [#874](https://github.com/lldap/lldap/issues/874) / [#1281](https://github.com/lldap/lldap/issues/1281) / [#1335](https://github.com/lldap/lldap/issues/1335) logging polish, [#1527](https://github.com/lldap/lldap/issues/1527) `-c` help text.

## Suggested sequence

1. **v1.1.1 — low-risk correctness:** #1479, #1548, #1542, #1554, #1553, #1552, #1551, #1513, #1549.
2. **v1.1.2 / v1.2 — security and auth:** #1534, #1516, #1541, #1517, #1202, then retest #1507.
3. **v1.2 — fork polish:** #1544, #1455, #492, #19, #986.
4. **Upstream-first:** #1463, #1476, #1532, #1467, #1133, #1129, #1308, #1329.
5. **Only after upstream design:** #631, #783, #521, #599, #714, #301, #717, #1052, #67, #13.

The first batch is deliberately small: it removes the stale-asset problem we just hit, closes three LDAP security/compliance bugs, and fixes a crash. That is a good v1.1.1 before touching session revocation.

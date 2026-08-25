# Security Review

Static review of the codebase as of `main` @ `bd49310` (v0.2.0, 2026-08), updated after the 2026-08 hardening pass. This is the working document for the "security hardening" milestone: each finding has an ID, severity, and remediation sketch. When a finding is fixed, move it to the *Resolved* section with the PR reference.

Severity scale: **High** = practical account/session compromise under a realistic threat model; **Medium** = meaningful weakening of the security posture; **Low** = defense-in-depth / hardening; **Info** = document-and-accept candidates.

## Open findings

### SEC-1 · High · Tokens stored in plaintext
`devise_api_tokens.access_token` / `refresh_token` are stored as-is (`lib/devise/api/token.rb`, migration template). Anyone with read access to the DB (backup leak, SQL injection elsewhere in the host app, log of the row) holds live bearer credentials for every active session.

**Remediation:** store a digest (e.g. `SHA256`) and look up by digest; return the raw token only once at creation. Needs a migration path (dual-read window or forced re-login) and is a breaking change for host apps that query tokens directly — consider a `hash_token_secrets` config flag defaulting on in the next minor. This also resolves SEC-6.

**Partial mitigation shipped (2026-08):** token values are now filtered from request logs (`filter_parameters` via the engine initializer) and from `Token#inspect` (`filter_attributes`), addressing GH-51. Raw SQL logging can still print values; digest storage remains the real fix.

### SEC-3 · Medium · Tokens accepted in URL params by default
`authorization.location` defaults to `:both`, and `info` is a GET route — so `GET /users/tokens/info?access_token=…` is a documented usage. Query-string tokens end up in server/proxy/CDN access logs, browser history, and potentially `Referer` headers.

**Remediation:** change the default to `:header` (breaking; needs a major-version changelog callout). **Interim (shipped 2026-08):** the README "Security recommendations" section now tells host apps to set `api.authorization.location = :header`, and token params are filtered from request logs. `:params`/`:both` remain opt-in-by-default until the next breaking release.

### SEC-6 · Low · Token lookup is not constant-time
`find_by(access_token: token)` compares via DB index. With 60-char `friendly_token` entropy the timing side channel is not practically exploitable, noted for completeness. Hashing tokens (SEC-1) makes this moot.

### SEC-8 · Info · No rate limiting
The gem relies entirely on Devise `lockable` (if enabled) to slow credential stuffing; `sign_in`/`sign_up`/`refresh` are otherwise unthrottled. Out of scope to implement in-gem. The README "Security recommendations" section now recommends `rack-attack` (or equivalent) on the token endpoints; keeping open as Info in case in-gem throttling hooks are ever wanted.

### SEC-9 · Info · `sign_up.extra_fields` is a mass-assignment and disclosure lever
Fields listed there are both *writable at sign-up* and *echoed in every token/info response* (`TokenResponse#default_resource_owner`). A host app adding `:role` or `:admin` here creates a privilege-escalation hole. Warnings shipped 2026-08 in the README (config example + "Security recommendations"); keeping open as Info because the sharp edge itself remains.

### SEC-10 · Info · Deliberate CSRF skip
`skip_before_action :verify_authenticity_token` is correct for bearer-token endpoints; note that accepting tokens from params (`SEC-3`) is what keeps CSRF relevant — cookie-less bearer auth in the header is not CSRF-able.

## Positive observations

- Default generators use `Devise.friendly_token(60)` — ample entropy, URL-safe.
- Password verification delegates to Devise (`valid_password?` is constant-time via `Devise.secure_compare` internally; lockable counters handled by `valid_for_authentication?`).
- `dependent: :destroy` on the owner association prevents orphaned live tokens after account deletion.
- Params are strictly `permit`ted from `authentication_keys` + Devise defaults + explicit config.
- Sign-up wraps user+token creation in a transaction; do-notation failure unwinds roll it back.

## Resolved

### SEC-2 · Medium · No refresh-token rotation invalidation or reuse detection — *resolved 2026-08 (opt-in)*
`TokensService::Refresh` minted a new token but left the presented refresh token fully usable until its own TTL. Fixed with the OAuth2 Security BCP pattern behind `refresh_token.rotation_enabled` (default `false` for backward compatibility): each refresh revokes the presented token (same transaction as the mint), and presenting a rotated/revoked refresh token again revokes the whole token family (`Token#revoke_family!`) and returns `revoked_token`. Recommended `true` in the README; consider defaulting on at the next breaking release. Covered by `spec/requests/refresh_token_rotation_spec.rb` and `spec/services/tokens_service/refresh_spec.rb`.

### SEC-4 · Low · Token uniqueness not enforced by the database — *resolved 2026-08*
The migration template now creates `unique: true` indexes on `access_token` and `refresh_token` (existing installs: add the migration listed in the CHANGELOG), and `TokensService::Create` rescues `ActiveRecord::RecordNotUnique` with a regenerate-and-retry (3 attempts). Covered by `spec/devise/api/token_spec.rb` ("database uniqueness") and `spec/services/tokens_service/create_spec.rb`.

### SEC-5 · Low · Account enumeration via differentiated errors — *resolved 2026-08 (opt-in)*
`paranoid` config flag (default `false`, mirroring Devise's `config.paranoid`): unknown accounts, wrong passwords, and locked/unconfirmed accounts all return the same generic `invalid_authentication` (401) with no lockable/confirmable details. Covered by `spec/requests/paranoid_mode_spec.rb`.

### SEC-7 · Low · Lockable error payload aids brute-force pacing — *resolved 2026-08 (opt-in)*
`error_response.verbose_account_state` config flag (default `true` for compatibility, recommended `false`): when disabled, the `lockable`/`confirmable` metadata blocks (`max_attempts`, `failed_attempts`, `locked_at`, `unlock_at`, …) are omitted from error responses. `paranoid` implies it. Covered by `spec/requests/paranoid_mode_spec.rb`.

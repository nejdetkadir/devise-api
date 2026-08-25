# Security Review

Static review of the codebase as of `main` @ `bd49310` (v0.2.0, 2026-08). This is the working document for the planned "security hardening" milestone: each finding has an ID, severity, and remediation sketch. When a finding is fixed, move it to the *Resolved* section with the PR reference.

Severity scale: **High** = practical account/session compromise under a realistic threat model; **Medium** = meaningful weakening of the security posture; **Low** = defense-in-depth / hardening; **Info** = document-and-accept candidates.

## Open findings

### SEC-1 · High · Tokens stored in plaintext
`devise_api_tokens.access_token` / `refresh_token` are stored as-is (`lib/devise/api/token.rb`, migration template). Anyone with read access to the DB (backup leak, SQL injection elsewhere in the host app, log of the row) holds live bearer credentials for every active session.

**Remediation:** store a digest (e.g. `SHA256`) and look up by digest; return the raw token only once at creation. Needs a migration path (dual-read window or forced re-login) and is a breaking change for host apps that query tokens directly — consider a `hash_token_secrets` config flag defaulting on in the next minor. This also resolves SEC-6.

### SEC-2 · Medium · No refresh-token rotation invalidation or reuse detection
`TokensService::Refresh` mints a new token but leaves the presented refresh token fully usable until its own TTL (`docs/data-model.md#refresh-semantics-important`). A stolen refresh token can be replayed repeatedly, in parallel with the legitimate client, with no signal. The `previous_refresh_token` chain already stores exactly the data needed for reuse detection but nothing consumes it.

**Remediation (OAuth2 Security BCP pattern):** on refresh, revoke the presented token row; on presentation of an already-used refresh token (a row that has `refreshes.any?` or is revoked-by-rotation), revoke the whole chain ("token family") and force re-authentication. Could ship behind `refresh_token.rotation_enabled` for backward compatibility.

### SEC-3 · Medium · Tokens accepted in URL params by default
`authorization.location` defaults to `:both`, and `info` is a GET route — so `GET /users/tokens/info?access_token=…` is a documented usage. Query-string tokens end up in server/proxy/CDN access logs, browser history, and potentially `Referer` headers.

**Remediation:** change the default to `:header` (breaking-ish; needs changelog callout), or at minimum document the risk prominently and exclude the params path from examples. Keep `:params`/`:both` as opt-in.

### SEC-4 · Low · Token uniqueness not enforced by the database
The migration template indexes `access_token` / `refresh_token` but **not uniquely**; uniqueness relies on an AR validation plus a check-then-insert loop (`generate_uniq_*`), which races under concurrency. A duplicate token would make `find_by(access_token:)` return an arbitrary row — i.e. one user's token could resolve to another user's session in the pathological case.

**Remediation:** `unique: true` on both indexes (new migration for existing installs + template change), rescue `ActiveRecord::RecordNotUnique` with a regenerate-and-retry in `TokensService::Create`.

### SEC-5 · Low · Account enumeration via differentiated errors
`Authenticate` returns `:invalid_email` (400, "Email is invalid") when no account exists vs `:invalid_authentication` (401) when the password is wrong — a clean oracle for enumerating registered emails. Sign-up validation errors ("Email has already been taken") enumerate too.

**Remediation:** optionally collapse both to `invalid_authentication` behind a `paranoid`-style config flag (mirror Devise's `config.paranoid`), defaulting off to preserve current API behavior.

### SEC-6 · Low · Token lookup is not constant-time
`find_by(access_token: token)` compares via DB index. With 60-char `friendly_token` entropy the timing side channel is not practically exploitable, noted for completeness. Hashing tokens (SEC-1) makes this moot.

### SEC-7 · Low · Lockable error payload aids brute-force pacing
`ErrorResponse#devise_lockable_info` exposes `max_attempts`, `failed_attemps` (sic), `locked_at`, `unlock_at` to the unauthenticated caller — an attacker learns exactly how many guesses remain and when to resume.

**Remediation:** gate the lockable/confirmable detail blocks behind a config flag (e.g. `error_response.verbose_account_state`, default true for compatibility, recommended false).

### SEC-8 · Info · No rate limiting
The gem relies entirely on Devise `lockable` (if enabled) to slow credential stuffing; `sign_in`/`sign_up`/`refresh` are otherwise unthrottled. Out of scope to implement in-gem, but the README/docs should recommend `rack-attack` (or equivalent) on the token endpoints.

### SEC-9 · Info · `sign_up.extra_fields` is a mass-assignment and disclosure lever
Fields listed there are both *writable at sign-up* and *echoed in every token/info response* (`TokenResponse#default_resource_owner`). A host app adding `:role` or `:admin` here creates a privilege-escalation hole. Needs a loud documentation warning (config docs + README).

### SEC-10 · Info · Deliberate CSRF skip
`skip_before_action :verify_authenticity_token` is correct for bearer-token endpoints; note that accepting tokens from params (`SEC-3`) is what keeps CSRF relevant — cookie-less bearer auth in the header is not CSRF-able.

## Positive observations

- Default generators use `Devise.friendly_token(60)` — ample entropy, URL-safe.
- Password verification delegates to Devise (`valid_password?` is constant-time via `Devise.secure_compare` internally; lockable counters handled by `valid_for_authentication?`).
- `dependent: :destroy` on the owner association prevents orphaned live tokens after account deletion.
- Params are strictly `permit`ted from `authentication_keys` + Devise defaults + explicit config.
- Sign-up wraps user+token creation in a transaction; do-notation failure unwinds roll it back.

## Resolved

*(empty — move findings here with PR links as they land)*

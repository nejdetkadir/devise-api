# Known Issues & Code-Quality Findings

Working backlog from a full-codebase review (`main` @ `bd49310`, v0.2.0). Ordered by user impact. Security-relevant items live in [security-review.md](security-review.md) and are only cross-referenced here. Check this list before "fixing" surprising code — some quirks are shipped public API.

## Bugs / API warts

### KI-1 · `failed_attemps` typo is public API
`ErrorResponse#devise_lockable_info` (`lib/devise/api/responses/error_response.rb:85`) emits the misspelled key `failed_attemps`. Clients may already depend on it. Fix path: emit **both** `failed_attempts` and the deprecated misspelling for one minor version, changelog it, drop the typo at the next breaking release.

### KI-2 · `invalid_refresh_token` error type is unreachable
Declared in `ERROR_TYPES`, mapped to 400, has a locale string — but no code path ever produces it (the refresh action returns `invalid_token` for unknown refresh tokens). Either use it there (more precise; mildly breaking for clients matching on `error`) or remove it.

### KI-3 · `invalid_email` hardcodes "email" while lookup uses `authentication_keys`
Since PR #46, `Authenticate` finds resources via `resource_class.authentication_keys` (which may be `username`, etc.), but a miss still returns `error: :invalid_email` / "Email is invalid". Misleading for non-email authentication keys. A generic `invalid_login` (with alias period) would fit better.

### KI-4 · Duplicate, divergent `current_devise_api_refresh_token`
Defined twice: memoized in `TokensController` (`app/controllers/devise/api/tokens_controller.rb:168`) and unmemoized in `Controllers::Helpers` (`lib/devise/api/controllers/helpers.rb:34`). The helper version hits the DB on every call and the two can drift. Consolidate into the helper (memoized, mirroring `current_devise_api_token`) and delete the controller override.

## Dead / vestigial code

### KI-5 · ~~Dead method in `TokensService::Create`~~ (resolved)
`#authenticate_service` was never called and referenced `params` / `resource_class`, which didn't exist on this service — it would have `NameError`d if invoked. Copy-paste leftover; deleted as part of the coverage push.

### KI-6 · RBS stub
`sig/devise/api.rbs` declares only the `VERSION` constant. Either flesh out signatures or drop the `sig/` directory to avoid signaling type support that doesn't exist.

## Consistency / hygiene

### KI-7 · Mixed time sources
`Token#expired?` / `#refresh_token_expired?` use `Time.now.utc`; `TokensService::Revoke` stamps `Time.zone.now`. Harmless while columns are UTC datetimes, but standardize on `Time.current` for Rails idiom.

### KI-8 · `refresh_token.expires_in` is not snapshotted per row
Access-token TTL is copied into the row (`expires_in` column); refresh-token TTL is computed from *live config* at check time, so changing the config re-times every existing token (see [data-model.md](../data-model.md)). At minimum keep documented; ideally add a `refresh_token_expires_in` column for symmetry.

### KI-9 · CHANGELOG stale
Only records `0.0.0` while the gem is at `0.2.0` with substantive releases in between (git history has the real story). Backfill before the next release; releases without changelog entries should fail review.

### KI-10 · Controller carries rubocop-disable scar tissue
`TokensController` disables `Metrics/ClassLength` and `Metrics/AbcSize` around every action; each action repeats the same error-render boilerplate. Extracting a private `render_error(error, record: nil)` / `render_token(token, action:)` pair would drop the disables and shrink the class substantially.

### KI-11 · README nits
"orginally" typo in the Routes section; `rake rspec` in the Development section should read `bundle exec rake rspec`; the service example calls `Create.call(...)` but `BaseService` defines no class-level `.call` (instances are `new(...).call`).

## Test-coverage gaps (feeds the "add more tests" milestone)

### KI-12 · ~~Service specs are placeholders~~ (resolved)
All six `spec/services/**` files now assert the monad contracts (`Success`/`Failure` per branch, per [services.md](../services.md)), including the failure paths unreachable through the HTTP API (`:invalid_resource_owner`, `:devise_api_token_create_error`, `:devise_api_token_revoke_error`, sign-up transaction rollback).

### KI-13 · ~~No generator specs~~ (resolved)
`rails g devise_api:install` is covered by `spec/devise/api/generators/install_generator_spec.rb` (migration template rendering with the current Active Record version, locale copy, migration numbering).

### KI-14 · Non-default configuration is untested (mostly resolved)
`spec/requests/configuration_overrides_spec.rb` covers `authorization.location = :header`/`:params` exclusively, `sign_up.enabled = false`, `refresh_token.enabled = false` and `sign_up.extra_fields` end-to-end; `spec/devise/api/token_spec.rb` covers `expires_in_infinite` procs and custom generators; `spec/devise/api/configuration_spec.rb` covers overrides on fresh instances; callback invocation was already asserted in `spec/requests/tokens_spec.rb`. Still untested: custom `authorization.key`/`scheme`/`params_key` and `base_token_model`/`base_controller` overrides.

## Cross-references into security review

- Non-unique token indexes → [SEC-4](security-review.md)
- Plaintext token storage → [SEC-1](security-review.md)
- No refresh rotation → [SEC-2](security-review.md)
- Default `:both` token location + GET `info` → [SEC-3](security-review.md)

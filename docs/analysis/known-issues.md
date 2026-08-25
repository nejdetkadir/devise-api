# Known Issues & Code-Quality Findings

Working backlog from a full-codebase review (`main` @ `bd49310`, v0.2.0), updated after the 2026-08 fix pass. Ordered by user impact. Security-relevant items live in [security-review.md](security-review.md) and are only cross-referenced here. Check this list before "fixing" surprising code — some quirks are shipped public API.

## Open

### KI-8 · `refresh_token.expires_in` is not snapshotted per row
Access-token TTL is copied into the row (`expires_in` column); refresh-token TTL is computed from *live config* at check time, so changing the config re-times every existing token (see [data-model.md](../data-model.md)). At minimum keep documented; ideally add a `refresh_token_expires_in` column for symmetry.

### KI-14 · Non-default configuration is untested (mostly resolved)
`spec/requests/configuration_overrides_spec.rb` covers `authorization.location = :header`/`:params` exclusively, `sign_up.enabled = false`, `refresh_token.enabled = false` and `sign_up.extra_fields` end-to-end; `spec/requests/refresh_token_rotation_spec.rb` and `spec/requests/paranoid_mode_spec.rb` cover `rotation_enabled`, `paranoid` and `verbose_account_state`; `spec/devise/api/token_spec.rb` covers `expires_in_infinite` procs and custom generators; `spec/devise/api/configuration_spec.rb` covers overrides on fresh instances. Still untested: custom `authorization.key`/`scheme`/`params_key` and `base_token_model`/`base_controller` overrides.

## Resolved

### KI-1 · ~~`failed_attemps` typo is public API~~ (resolved 2026-08)
`ErrorResponse#devise_lockable_info` now emits both the canonical `failed_attempts` and the deprecated misspelled `failed_attemps` (kept for backward compatibility). Drop the typo at the next major release; changelogged.

### KI-2 · ~~`invalid_refresh_token` error type is unreachable~~ (resolved 2026-08)
The `refresh` action now returns `invalid_refresh_token` (400) for missing/unknown refresh tokens instead of the generic `invalid_token` (401). Breaking-ish for clients matching on the error symbol; changelogged.

### KI-3 · ~~`invalid_email` hardcodes "email" while lookup uses `authentication_keys`~~ (resolved 2026-08)
`Authenticate` now returns `invalid_email` only when `:email` is one of the model's `authentication_keys`, and a new generic `invalid_login` (400, "Login credentials are invalid") otherwise. With `paranoid` enabled, both collapse into `invalid_authentication`.

### KI-4 · ~~Duplicate, divergent `current_devise_api_refresh_token`~~ (resolved 2026-08)
Consolidated into `Controllers::Helpers` with memoization mirroring `current_devise_api_token`; the controller-level override was deleted.

### KI-5 · ~~Dead method in `TokensService::Create`~~ (resolved)
`#authenticate_service` was never called and referenced `params` / `resource_class`, which didn't exist on this service — it would have `NameError`d if invoked. Copy-paste leftover; deleted as part of the coverage push.

### KI-6 · ~~RBS stub~~ (resolved 2026-08)
`sig/devise/api.rbs` declared only the `VERSION` constant; the `sig/` directory was removed.

### KI-7 · ~~Mixed time sources~~ (resolved 2026-08)
Standardized on `Time.current` (`Token#expired?`/`#refresh_token_expired?`/`#revoke!`, `TokensService::Revoke`).

### KI-9 · ~~CHANGELOG stale~~ (resolved 2026-08)
Backfilled 0.1.0 → 0.2.0 from git history plus an Unreleased section for the current pass. Releases without changelog entries should fail review.

### KI-10 · ~~Controller carries rubocop-disable scar tissue~~ (resolved 2026-08)
`TokensController` now uses private `render_token_response` / `render_error_response` / `render_resource_owner_service_result` / `perform_refresh` helpers; all `rubocop:disable` comments are gone.

### KI-11 · ~~README nits~~ (resolved 2026-08)
Fixed the "orginally" typo, the `rake rspec` command, and the service example (`.new(...).call` instead of the non-existent class-level `.call`).

### KI-12 · ~~Service specs are placeholders~~ (resolved)
All six `spec/services/**` files now assert the monad contracts (`Success`/`Failure` per branch, per [services.md](../services.md)), including the failure paths unreachable through the HTTP API (`:invalid_resource_owner`, `:devise_api_token_create_error`, `:devise_api_token_revoke_error`, sign-up transaction rollback).

### KI-13 · ~~No generator specs~~ (resolved)
`rails g devise_api:install` is covered by `spec/devise/api/generators/install_generator_spec.rb` (migration template rendering with the current Active Record version, unique token indexes, locale copy, migration numbering).

## Cross-references into security review

- Non-unique token indexes → [SEC-4](security-review.md) (resolved)
- Plaintext token storage → [SEC-1](security-review.md) (open; log filtering shipped)
- No refresh rotation → [SEC-2](security-review.md) (resolved, opt-in `rotation_enabled`)
- Default `:both` token location + GET `info` → [SEC-3](security-review.md) (documented; default unchanged)

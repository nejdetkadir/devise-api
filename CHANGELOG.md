# Changelog

## [0.3.0] - 2026-08-25

### Added
- Refresh token rotation with reuse detection behind `refresh_token.rotation_enabled` (default `false`): each refresh revokes the presented refresh token, and presenting an already-rotated/revoked refresh token revokes the whole token family (SEC-2)
- Paranoid mode behind `paranoid` (default `false`): unknown accounts and wrong passwords both return the generic `invalid_authentication` error with no lockable/confirmable details, preventing account enumeration (SEC-5)
- `error_response.verbose_account_state` (default `true`): set to `false` to omit the `lockable`/`confirmable` metadata blocks from error responses (SEC-7)
- `Devise::Api::Token#revoke!` and `#revoke_family!` helpers
- New `invalid_login` error (HTTP 400) returned instead of `invalid_email` when the model's `authentication_keys` do not include `:email`
- Lockable error responses now include the correctly spelled `failed_attempts` key alongside the deprecated `failed_attemps` (the misspelling will be removed in the next major release)
- `access_token`, `refresh_token` and `previous_refresh_token` are added to the host app's `filter_parameters`, and the token model filters them from `#inspect` output (GH-51)

### Changed
- **Breaking-ish:** `POST /<scope>/tokens/refresh` with an unknown refresh token now returns `invalid_refresh_token` (HTTP 400) instead of `invalid_token` (HTTP 401)
- The install generator's migration now creates **unique** indexes on `access_token` and `refresh_token`; token creation rescues `ActiveRecord::RecordNotUnique` and retries with a fresh token (SEC-4). Existing installs should add a migration:
  ```ruby
  remove_index :devise_api_tokens, :access_token
  remove_index :devise_api_tokens, :refresh_token
  add_index :devise_api_tokens, :access_token, unique: true
  add_index :devise_api_tokens, :refresh_token, unique: true
  ```
- `current_devise_api_refresh_token` is now memoized in the shared controller helpers (the duplicate controller-level override was removed)
- Internal time handling standardized on `Time.current`

### Removed
- Vestigial RBS stub (`sig/devise/api.rbs`)

## [0.2.0] - 2024-09-27

- Resource lookup uses the model's `authentication_keys` instead of hardcoding `email` (#46)
- Fixed nil memoization of `current_devise_api_token` / `current_devise_api_refresh_token` (#48)
- Fixed the translation key for the unconfirmed signup message (#49)

## [0.1.3] - 2023-08-08

- Fixed `AbstractController::DoubleRenderError` on refresh (#29)
- Allowed defining extra fields for sign up via `sign_up.extra_fields` (#36, #38)
- Disabled parameter wrapping in `TokensController` (#42)

## [0.1.2] - 2023-05-30

- Added `sign_up.enabled` option to disable the sign up endpoint (#15)
- Fixed refresh behavior (#14)
- Fixed undefined variable error in the controller helper (#25)
- Migration template respects the configured primary/foreign key types (#23)

## [0.1.1] - 2023-01-14

- Fixed invalid strategy error (#2)

## [0.1.0] - 2023-01-14

- First public release: `:api` Devise module with token sign up / sign in / refresh / revoke / info endpoints (#1)

## [0.0.0] - 2023-01-09

- Initial release

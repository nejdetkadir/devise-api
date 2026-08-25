# HTTP API Reference

All endpoints are drawn by `devise_for :<scope>` for any model with the `:api` module. Examples below use `devise_for :users`. Path segment (`tokens`) and controller are customizable — see [extending.md](extending.md).

| Route helper | Verb | Path | Action | Auth required |
|---|---|---|---|---|
| `sign_up_user_tokens` | POST | `/users/tokens/sign_up` | `sign_up` | no |
| `sign_in_user_tokens` | POST | `/users/tokens/sign_in` | `sign_in` | no |
| `refresh_user_tokens` | POST | `/users/tokens/refresh` | `refresh` | refresh token |
| `revoke_user_tokens` | POST | `/users/tokens/revoke` | `revoke` | access token (silently no-ops if absent/invalid) |
| `info_user_tokens` | GET | `/users/tokens/info` | `info` | access token (via `authenticate_devise_api_token!`) |

Tokens are sent per `authorization` config (default `:both`): `Authorization: Bearer <token>` header **or** `access_token` query/body param (params win over header). The **same extraction** is used for access and refresh tokens — `refresh` expects the *refresh* token in the same slot.

## Success payloads

Built by `Devise::Api::Responses::TokenResponse` (`lib/devise/api/responses/token_response.rb`).

### Default token body (`sign_in` 200, `refresh` 200, `sign_up` 201)

```json
{
  "token": "<access_token>",
  "refresh_token": "<refresh_token>",
  "expires_in": 3600,
  "token_type": "Bearer",
  "resource_owner": { "id": 1, "email": "a@b.c", "created_at": "...", "updated_at": "..." }
}
```

- `refresh_token` is omitted (`compact`) when `refresh_token.enabled` is `false`.
- `resource_owner` contains `id, email, created_at, updated_at` plus any configured `sign_up.extra_fields`.
- `sign_up` on a confirmable model additionally merges `"confirmable": { "confirmed": false, "message": "<signed_up_but_unconfirmed locale>" }` and still returns `201` with tokens (unconfirmed users get tokens at sign-up; they cannot sign *in* until confirmed).

### `info` (200)

Returns just the `resource_owner` object (same key set as above).

### `revoke` (204)

Empty body. Returned even when no/invalid token was supplied (revoke is idempotent-by-design; see known-issues).

## Error payload

Built by `Devise::Api::Responses::ErrorResponse` (`lib/devise/api/responses/error_response.rb`):

```json
{
  "error": "<error_type>",
  "error_description": ["human readable message(s)"],
  "lockable":   { "locked": true, "max_attempts": 5, "failed_attemps": 5, "locked_at": "...", "unlock_at": "..." },
  "confirmable": { "confirmed": false, "confirmation_sent_at": "..." }
}
```

- `lockable` / `confirmable` blocks appear **only** for `invalid_authentication` errors on models with those Devise modules (`compact` removes them otherwise). Note the `failed_attemps` key is a shipped typo — treat as public API until a deliberate breaking change (see [analysis/known-issues.md](analysis/known-issues.md)).
- `error_description` comes from `record.errors.full_messages` when a record with validation errors is attached; otherwise from `config/locales/en.yml` under `devise.api.error_response.<error>`.

## Error catalog

Source of truth: `ErrorResponse::ERROR_TYPES` + `#status`. Every symbol must have a locale entry.

| `error` | HTTP status | Raised by / when |
|---|---|---|
| `invalid_authentication` | 401 | `Authenticate` — bad password, locked, or unconfirmed account (description specializes per module state) |
| `invalid_token` | 401 | helpers `authenticate_devise_api_token!` (no/unknown access token); `refresh` when refresh token unknown |
| `expired_token` | 401 | helpers — access token past `expires_in` |
| `expired_refresh_token` | 401 | `TokensService::Refresh` — refresh token past `refresh_token.expires_in` |
| `revoked_token` | 401 | helpers / `refresh` — token has `revoked_at` |
| `invalid_email` | 400 | `Authenticate` — no resource found for the given authentication keys |
| `invalid_refresh_token` | 400 | (declared; mapped to 400) |
| `refresh_token_disabled` | 400 | `refresh` action when `refresh_token.enabled` is false |
| `sign_up_disabled` | 400 | `sign_up` action when `sign_up.enabled` is false |
| `invalid_resource_owner` | 400 | `TokensService::Create` — owner doesn't respond to `access_tokens` (model lacks `:api`) |
| `resource_owner_create_error` | 422 | `SignUp` — model validation failure (description = validation messages) |
| `devise_api_token_create_error` | 422 | `TokensService::Create` — token row failed to save |
| `devise_api_token_revoke_error` | 422 | `TokensService::Revoke` — update failed |

## Accepted parameters

- **sign_in**: `resource_class.authentication_keys` (usually `email`) + Devise's default sign-in params (`password`, `remember_me`).
- **sign_up**: authentication keys + Devise's default sign-up params (`password`, `password_confirmation`) + `Devise.api.config.sign_up.extra_fields`.
- Params are `permit`ted then `.to_h` — anything else is dropped.

## Devise module interplay

| Devise module on the model | Effect |
|---|---|
| `trackable` | `sign_in`/`sign_up` call `update_tracked_fields!(request)` |
| `lockable` | failed sign-ins increment `failed_attempts` (via `valid_for_authentication?`); lock state reported in error payload; successful sign-in resets attempts |
| `confirmable` | unconfirmed users can sign **up** (get tokens + confirmable notice) but cannot sign **in** (`active_for_authentication?` fails → `invalid_authentication` with unconfirmed description) |

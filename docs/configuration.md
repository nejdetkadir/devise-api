# Configuration Reference

All settings live on the single global `Devise.api.config`, a `Dry::Configurable` tree defined in `lib/devise/api/configuration.rb`. Host apps configure it inside `Devise.setup`:

```ruby
# config/initializers/devise.rb
Devise.setup do |config|
  config.api.configure do |api|
    api.access_token.expires_in = 30.minutes
  end
end
```

Settings are read **at use time**, never cached at boot — changing them (e.g. in a test) takes effect immediately.

## `access_token`

| Setting | Default | Type | Consumed by |
|---|---|---|---|
| `expires_in` | `1.hour` | `ActiveSupport::Duration` | `TokensService::Create` (stored per-row as integer seconds), `Token#expired?` via stored `expires_in` |
| `expires_in_infinite` | `proc { \|owner\| false }` | proc → bool | `Token#expired?` (skips expiry check) and the `expires_in` presence validation |
| `generator` | `proc { \|owner\| Devise.friendly_token(60) }` | proc → String | `Token.generate_uniq_access_token` (looped until unique) |

## `refresh_token`

| Setting | Default | Type | Consumed by |
|---|---|---|---|
| `enabled` | `true` | bool | refresh action gate, `refresh_token` presence validation, `TokenResponse` (omits field), `Token.generate_uniq_refresh_token` (returns `nil` when disabled) |
| `expires_in` | `1.week` | Duration | `Token#refresh_token_expired?` — computed from `created_at`, **not stored per-row** (a config change retroactively affects existing tokens) |
| `expires_in_infinite` | `proc { \|owner\| false }` | proc → bool | `Token#refresh_token_expired?` |
| `generator` | `proc { \|owner\| Devise.friendly_token(60) }` | proc → String | `Token.generate_uniq_refresh_token` |
| `rotation_enabled` | `false` | bool | `TokensService::Refresh` (revokes the presented token in the same transaction as minting the new one) and the `refresh` action's reuse detection (a rotated/revoked refresh token presented again triggers `Token#revoke_family!`) |

## `sign_up`

| Setting | Default | Consumed by |
|---|---|---|
| `enabled` | `true` | `sign_up` action gate (→ `sign_up_disabled` error) |
| `extra_fields` | `[]` | permitted sign-up params **and** extra keys in the `resource_owner` response object (both directions!) |

## `error_response`

| Setting | Default | Consumed by |
|---|---|---|
| `verbose_account_state` | `true` | `ErrorResponse` — when `false`, the `lockable`/`confirmable` metadata blocks are omitted from error bodies (the locked/unconfirmed `error_description` specialization is kept) |

## `paranoid`

| Setting | Default | Consumed by |
|---|---|---|
| `paranoid` | `false` | `Authenticate` (unknown account returns `invalid_authentication` instead of `invalid_email`/`invalid_login`) and `ErrorResponse` (always the generic description, never lockable/confirmable details). Mirrors Devise's `config.paranoid`: makes existent and non-existent accounts indistinguishable to callers. |

## `authorization`

| Setting | Default | Consumed by |
|---|---|---|
| `key` | `'Authorization'` | header name read by `extract_devise_api_token_from_headers` |
| `scheme` | `'Bearer'` | prefix stripped from the header; echoed as `token_type` in responses |
| `location` | `:both` | `:header`, `:params`, or `:both` (params win); anything else raises `ArgumentError` |
| `params_key` | `'access_token'` | param name read by `extract_devise_api_token_from_params` |

## Base classes (string names, `constantize`d at use sites)

| Setting | Default | Notes |
|---|---|---|
| `base_token_model` | `'Devise::Api::Token'` | Used for the `has_many :access_tokens` class name, all token lookups, association class names inside `Token` itself, and uniqueness checks in the generators. Subclass `Devise::Api::Token` and point this at it. |
| `base_controller` | `'::DeviseController'` | Superclass of `TokensController`, resolved **at class-definition time** — must be set before the controller is first loaded. |

## Lifecycle callbacks

All default to no-op procs. Called by `TokensController` around each action:

| Setting | Signature | Timing |
|---|---|---|
| `before_sign_in` | `(params, request, resource_class)` | before `SignIn` service |
| `before_sign_up` | `(params, request, resource_class)` | after the enabled-gate, before `SignUp` service |
| `before_refresh` | `(token, request)` | after token found & not revoked, before `Refresh` service |
| `before_revoke` | `(token, request)` | before `Revoke` service (token may be `nil`) |
| `after_successful_sign_in` | `(resource_owner, token, request)` | after success, before render |
| `after_successful_sign_up` | `(resource_owner, token, request)` | after success, before render |
| `after_successful_refresh` | `(resource_owner, token, request)` | after success, before render |
| `after_successful_revoke` | `(resource_owner_or_nil, token, request)` | after success, before render |

`before_*` return values are ignored — they cannot halt the request (raise if you need to abort, or use a controller `before_action` in a subclassed controller).

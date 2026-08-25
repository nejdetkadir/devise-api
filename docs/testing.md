# Testing Guide

## Commands

```bash
bundle exec rake            # rspec + rubocop — what CI runs; run before finishing any change
bundle exec rake rspec      # full suite
bundle exec rspec spec/requests/tokens_spec.rb          # one file
bundle exec rspec spec/requests/tokens_spec.rb:95       # one example/context by line
bundle exec rspec --only-failures                       # uses .rspec_status
```

CI (`.github/workflows/test.yml`, `rubocop.yml`) runs on push across Ruby 3.2 / 3.3 / 3.4 / 4.0.

## Coverage

SimpleCov runs automatically with every spec run (started at the top of `spec/spec_helper.rb`, before the gem
is required); the HTML report lands in `coverage/index.html` and the summary in `coverage/.last_run.json`.
A **95% line-coverage minimum** is enforced whenever `CI` or `ENFORCE_COVERAGE` is set — `bundle exec rake`
sets `ENFORCE_COVERAGE` via the `enforce_coverage` prerequisite task, so full-suite runs (local and CI) fail
below the bar while single-file `bundle exec rspec` runs stay unaffected. Branch coverage is reported but not
enforced. `lib/devise/api/version.rb` is filtered because the gemspec loads it before SimpleCov can start.

## How the suite is wired

- `spec/spec_helper.rb` sets `RAILS_ENV=test`, starts SimpleCov, requires the gem, then boots the **dummy Rails app** at `spec/dummy` (`require 'dummy/config/environment'`) — a real Rails 8 app with sqlite3 whose `User` model enables `database_authenticatable, registerable, recoverable, rememberable, validatable, confirmable, lockable, trackable, :api` (schema: `spec/dummy/db/schema.rb`). A second bare model, `AdminUser` (`database_authenticatable, registerable, validatable, :api` only), exists to exercise the "optional Devise module not enabled" branches (non-trackable sign-in, error/token responses without `lockable`/`confirmable` info); it has its own `devise_for :admin_users` routes.
- `DatabaseCleaner` wraps every example; spec types are inferred from file location; monkey-patching is disabled (`RSpec.describe` only).
- `spec/supports/` is auto-required: FactoryBot setup, ActiveRecord config, and two request-spec helpers:
  - `authentication_headers_for(owner, token = nil, token_type = :access_token)` → `{ Authorization: "Bearer …" }` (creates a token via FactoryBot when none given; pass `:refresh_token` to authenticate refresh calls)
  - `parsed_body` → `JSON.parse(response.body, object_class: OpenStruct)` (assert with `parsed_body.error`, etc.)

## Factories (`spec/factories/`)

- `:user` — Faker email/password.
- `:admin_user` — Faker email/password (bare model without optional Devise modules).
- `:devise_api_token` — random hex tokens, `expires_in: 1.hour`, associated `:user`. Traits: `:access_token_expired` (backdates `created_at` 2h), `:refresh_token_expired` (2 months), `:revoked`.

Note the traits work by **backdating `created_at`** because all expiry math derives from it — keep that in mind when adding time-sensitive specs (or use `travel_to`).

## Where coverage lives (map)

| Area | Spec | State |
|---|---|---|
| All 5 endpoints × valid/invalid/expired/revoked × header/param | `spec/requests/tokens_spec.rb` (~700 lines) | ✅ primary coverage |
| Endpoints for a bare model (no trackable/lockable/confirmable) | `spec/requests/admin_user_tokens_spec.rb` | ✅ |
| `authenticate_devise_api_token!` on a host controller | `spec/requests/authentication_spec.rb` (via dummy `HomeController`) | ✅ |
| Non-default config (disabled sign_up/refresh, extra_fields, `:header`/`:params`-only location, revoke failure) | `spec/requests/configuration_overrides_spec.rb` | ✅ |
| Refresh-token rotation + family-revocation reuse detection (`rotation_enabled`) | `spec/requests/refresh_token_rotation_spec.rb` | ✅ |
| Enumeration hardening (`paranoid`, `error_response.verbose_account_state`) | `spec/requests/paranoid_mode_spec.rb` | ✅ |
| Engine initializer (`filter_parameters`) | `spec/devise/api/engine_spec.rb` | ✅ |
| Default + customized routes (`controllers:`, `path:`, `path_names:` overrides) | `spec/routing/*.rb` | ✅ |
| Config defaults + overrides on fresh instances | `spec/devise/api/configuration_spec.rb` | ✅ |
| Response classes (incl. locked/unconfirmed/bare-model variants, disabled refresh, extra_fields) | `spec/devise/api/responses/*_spec.rb` | ✅ |
| **Service objects** (monad contract: `Success`/`Failure` per branch) | `spec/services/**` | ✅ |
| Token model (`active?`, expiry incl. `expires_in_infinite`, generator collision retry, conditional validations, `revoke!`/`revoke_family!`, unique-index backstop, `#inspect` redaction) | `spec/devise/api/token_spec.rb` | ✅ |
| Controller helpers (extraction rescue, invalid location `ArgumentError`, memoized refresh-token lookup) | `spec/devise/api/controllers/helpers_spec.rb` | ✅ |
| Generator (migration template, locale copy) | `spec/devise/api/generators/install_generator_spec.rb` | ✅ |

## Conventions for new specs

1. **Behavior → request spec.** Follow the existing pattern in `tokens_spec.rb`: one `describe` per endpoint, `context` per scenario, assert status + `parsed_body` fields + DB side effects (`Devise::Api::Token.count`, `revoked_at`).
2. When filling in service specs, test the monad contract: `.call` returns `Success(token)` / `Failure(error:, record:)` for each branch documented in [services.md](services.md).
3. Config-dependent specs must restore config after (the global `Devise.api.config` leaks between examples — wrap changes in `around` blocks or reset in `after`).
4. Routing specs that redraw routes must restore them (see `customized_routes_spec.rb` `after :all` reload pattern).
5. RuboCop: `Metrics/BlockLength` is excluded for `spec/**/*_spec.rb` — long request specs are fine.

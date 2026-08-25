# Testing Guide

## Commands

```bash
bundle exec rake            # rspec + rubocop — what CI runs; run before finishing any change
bundle exec rake rspec      # full suite
bundle exec rspec spec/requests/tokens_spec.rb          # one file
bundle exec rspec spec/requests/tokens_spec.rb:95       # one example/context by line
bundle exec rspec --only-failures                       # uses .rspec_status
```

CI (`.github/workflows/test.yml`, `rubocop.yml`) runs on push across Ruby 2.7 / 3.0 / 3.1 / 3.2.

## How the suite is wired

- `spec/spec_helper.rb` sets `RAILS_ENV=test`, requires the gem, then boots the **dummy Rails app** at `spec/dummy` (`require 'dummy/config/environment'`) — a real Rails 7 app with sqlite3 whose `User` model enables `database_authenticatable, registerable, recoverable, rememberable, validatable, confirmable, lockable, trackable, :api` (schema: `spec/dummy/db/schema.rb`).
- `DatabaseCleaner` wraps every example; spec types are inferred from file location; monkey-patching is disabled (`RSpec.describe` only).
- `spec/supports/` is auto-required: FactoryBot setup, ActiveRecord config, and two request-spec helpers:
  - `authentication_headers_for(owner, token = nil, token_type = :access_token)` → `{ Authorization: "Bearer …" }` (creates a token via FactoryBot when none given; pass `:refresh_token` to authenticate refresh calls)
  - `parsed_body` → `JSON.parse(response.body, object_class: OpenStruct)` (assert with `parsed_body.error`, etc.)

## Factories (`spec/factories/`)

- `:user` — Faker email/password.
- `:devise_api_token` — random hex tokens, `expires_in: 1.hour`, associated `:user`. Traits: `:access_token_expired` (backdates `created_at` 2h), `:refresh_token_expired` (2 months), `:revoked`.

Note the traits work by **backdating `created_at`** because all expiry math derives from it — keep that in mind when adding time-sensitive specs (or use `travel_to`).

## Where coverage lives (map)

| Area | Spec | State |
|---|---|---|
| All 5 endpoints × valid/invalid/expired/revoked × header/param | `spec/requests/tokens_spec.rb` (~700 lines) | ✅ primary coverage |
| `authenticate_devise_api_token!` on a host controller | `spec/requests/authentication_spec.rb` (via dummy `HomeController`) | ✅ |
| Default + customized routes (`controllers:`, `path:` overrides) | `spec/routing/*.rb` | ✅ |
| Config defaults | `spec/devise/api/configuration_spec.rb` | ✅ defaults only |
| Response classes | `spec/devise/api/responses/*_spec.rb` | partial |
| **Service objects** | `spec/services/**` | ⚠ **placeholders** — each spec only asserts inheritance from `BaseService` |
| Generator | required in spec_helper, no assertions | ⚠ gap |
| Non-default config (custom generators, `:header`-only location, disabled sign_up/refresh, `expires_in_infinite`, extra_fields) | — | ⚠ gap |

## Conventions for new specs

1. **Behavior → request spec.** Follow the existing pattern in `tokens_spec.rb`: one `describe` per endpoint, `context` per scenario, assert status + `parsed_body` fields + DB side effects (`Devise::Api::Token.count`, `revoked_at`).
2. When filling in service specs, test the monad contract: `.call` returns `Success(token)` / `Failure(error:, record:)` for each branch documented in [services.md](services.md).
3. Config-dependent specs must restore config after (the global `Devise.api.config` leaks between examples — wrap changes in `around` blocks or reset in `after`).
4. Routing specs that redraw routes must restore them (see `customized_routes_spec.rb` `after :all` reload pattern).
5. RuboCop: `Metrics/BlockLength` is excluded for `spec/**/*_spec.rb` — long request specs are fine.

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

`devise-api` is a Rails engine gem that adds token-based API authentication (access tokens + refresh tokens) to Devise. It registers an `:api` Devise module that models opt into via `devise :api`. Supports Ruby >= 2.7, Rails >= 6.0.

## Documentation

`docs/` holds the detailed internal documentation — start at `docs/README.md` (index + ground rules for working in this repo). Highlights:

- `docs/architecture.md` — components, boot sequence, request lifecycle (with diagrams)
- `docs/api-reference.md` — endpoints, payloads, full error catalog
- `docs/configuration.md`, `docs/data-model.md`, `docs/services.md`, `docs/extending.md`, `docs/testing.md`, `docs/development.md`
- `docs/analysis/security-review.md` and `docs/analysis/known-issues.md` — the vetted backlog of security findings (SEC-*) and code-quality issues (KI-*). **Consult these before changing surprising code** (some quirks, like the `failed_attemps` response-field typo, are shipped public API), and update them when you fix an item.

Docs are contractual: a PR that changes behavior described in `docs/` must update the matching document.

## Commands

```bash
bundle install                  # install dependencies
bundle exec rake                # default task: rspec + rubocop (what CI runs)
bundle exec rake rspec          # run the full test suite
bundle exec rspec spec/services/tokens_service/refresh_spec.rb        # run one spec file
bundle exec rspec spec/services/tokens_service/refresh_spec.rb:12     # run one example by line
bundle exec rubocop             # lint (config in .rubocop.yml, single quotes, 120-char lines)
```

Tests run against the dummy Rails app in `spec/dummy` (sqlite3, schema in `spec/dummy/db/schema.rb`). `spec/spec_helper.rb` boots it via `require 'dummy/config/environment'`; DatabaseCleaner wraps each example. If token/schema fields change, the dummy app's migrations and schema must be updated alongside the generator template.

## Architecture

Everything is configured through a single global: `Devise.api.config` (a `Dry::Configurable` instance defined in `lib/devise/api/configuration.rb`, installed as `Devise.api` in `lib/devise/api.rb`). Config includes token expiry/generators, sign_up enablement/extra_fields, authorization header/params location, before/after callbacks for each action, and — importantly — `base_token_model` and `base_controller`, which are **string class names resolved with `constantize` at use sites** so host apps can substitute their own subclasses. When touching model/controller references, use the config values, never hardcode `Devise::Api::Token`.

Flow of a request:

1. **Routes** — `lib/devise/api/rails/routes.rb` monkey-patches `ActionDispatch::Routing::Mapper#devise_api`, which `devise_for` invokes because `lib/devise/api.rb` calls `Devise.add_module :api, route: {...}`. Draws POST `sign_up`/`sign_in`/`revoke`/`refresh` and GET `info` under `/<scope>/tokens`.
2. **Controller** — `app/controllers/devise/api/tokens_controller.rb` (inherits from configurable `base_controller`, default `::DeviseController`). Each action runs the configured `before_*` callback, delegates to a service, then renders a `TokenResponse` or `ErrorResponse` and fires the `after_successful_*` callback.
3. **Services** — `app/services/devise/api/**`, all inheriting `Devise::Api::BaseService` which wires up dry-initializer (`option :x, type: Types::...`) and dry-monads (`Success`/`Failure` + do-notation `yield`). Two namespaces: `ResourceOwnerService` (`Authenticate`, `SignIn`, `SignUp`) and `TokensService` (`Create`, `Refresh`, `Revoke`). Services compose: e.g. `SignIn` yields `Authenticate` then `TokensService::Create`. Failures are hashes like `{ error: :invalid_authentication, record: ... }` splatted into `ErrorResponse`.
4. **Responses** — `lib/devise/api/responses/`. `ErrorResponse` maps a symbolic error type (see its `ERROR_TYPES` list) to an i18n message (`config/locales/en.yml`, keys under `devise.api.responses`) and HTTP status. `TokenResponse` shapes the JSON per action.

Supporting pieces:

- **Token model** — `lib/devise/api/token.rb` (`devise_api_tokens` table, polymorphic `resource_owner`). Knows `expired?`/`revoked?`/`active?` and generates unique tokens via the configured generator procs. Refresh chains are linked through `previous_refresh_token`.
- **Controller helpers** — `lib/devise/api/controllers/helpers.rb` is included into all of ActionController on load: `authenticate_devise_api_token!`, `current_devise_api_token`, `current_devise_api_user`. Token extraction honors `authorization.location` (`:header`, `:params`, `:both`).
- **Devise module** — `Devise::Models::Api` in `lib/devise/api.rb` adds the `access_tokens` association and `supported_devise_modules`; the codebase checks that inquiry to conditionally support optional Devise modules (trackable, lockable, confirmable).
- **Generator** — `rails generate devise_api:install` (`lib/devise/api/generators/install_generator.rb`) copies the migration template and locale file into the host app.

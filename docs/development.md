# Development Guide

## Setup

```bash
bin/setup            # bundle install (+ any local setup)
bin/console          # IRB with the gem loaded
```

Requirements: Ruby >= 2.7 (CI tests 2.7–3.2), Bundler. The test suite needs no external services (sqlite3 in-repo dummy app).

## Everyday commands

```bash
bundle exec rake                 # DEFAULT task = rspec + rubocop; the pre-push check
bundle exec rake rspec           # tests only
bundle exec rubocop              # lint only (or: bundle exec rubocop -a for safe autocorrect)
bundle exec rubocop --config .rubocop.yml --parallel   # exactly what CI runs
```

Style highlights (`.rubocop.yml`): target Ruby 2.7, single quotes, 120-char lines, `Style/Documentation` off, method/ABC limits at 30. The codebase currently has no `rubocop:disable` comments — prefer refactoring (extracted helpers, constants) over adding them.

## Repo conventions

- Every Ruby file starts with `# frozen_string_literal: true`.
- Library code resolves the token model and controller through `Devise.api.config` — see the invariants in [architecture.md](architecture.md).
- User-facing strings live in `config/locales/en.yml` only (keys under `devise.api.error_response`). The install generator copies this file into host apps as `devise_api.en.yml` — additions are picked up by new installs automatically, but existing apps keep their copied version.
- Commit style in history: conventional-commit-ish prefixes (`feat:`, `fix:`, `docs:`) with PR number suffix, e.g. `fix: nil memoization (#48)`.

## Versioning & release

- Version constant: `lib/devise/api/version.rb` (currently `0.2.0`). SemVer intent; still pre-1.0 so minor bumps may break.
- `CHANGELOG.md` exists but has not been maintained past the initial release — update it as part of any release work.
- Release flow (maintainer): bump `version.rb` → update CHANGELOG → `bundle exec rake release` (tags, pushes, publishes to rubygems.org). Gem files are `git ls-files` minus `bin|test|spec|features` (see gemspec) — nothing in `spec/dummy` ships.

## CI

Two workflows on every push, matrix over Ruby 3.2 / 3.3 / 3.4 / 4.0 (the development `Gemfile.lock` resolves to Rails 8.x, which needs Ruby >= 3.2; the gemspec still allows Ruby >= 2.7 for host apps):

- `test.yml` — `bundle install` + `bundle exec rake rspec`
- `rubocop.yml` — `bundle exec rubocop --config .rubocop.yml --parallel`

SimpleCov coverage runs with the suite (95% line minimum enforced on full-suite runs — see [testing.md](testing.md)). No scheduled builds, no release automation.

## Pointers for common change types

| Change | Touch points |
|---|---|
| New endpoint action | `rails/routes.rb`, `Devise.add_module` route list in `lib/devise/api.rb`, controller, service, `TokenResponse::ACTIONS`, request specs, [api-reference.md](api-reference.md) |
| New error type | service, `ErrorResponse::ERROR_TYPES` + `#status` mapping, `config/locales/en.yml`, specs, [api-reference.md](api-reference.md) |
| New config setting | `configuration.rb`, use site(s), `configuration_spec.rb`, README config block, [configuration.md](configuration.md) |
| Schema change | generator template, dummy migrations + schema, `Token` model, upgrade migration guidance, [data-model.md](data-model.md) |

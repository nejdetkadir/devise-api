# devise-api Documentation

Internal documentation for contributors and AI coding agents. These documents describe the codebase as it **is** (reference docs) and as it **should evolve** (analysis docs). Keep them in sync with the code: any PR that changes behavior described here must update the matching document.

## Reference

| Document | Contents |
|----------|----------|
| [architecture.md](architecture.md) | Big-picture design: components, boot/integration sequence, request lifecycle, diagrams |
| [api-reference.md](api-reference.md) | HTTP endpoints, request/response payloads, full error catalog with statuses |
| [configuration.md](configuration.md) | Every `Devise.api.config` setting: type, default, where it is consumed |
| [data-model.md](data-model.md) | `devise_api_tokens` schema, token state machine, refresh chains |
| [services.md](services.md) | Service-object contracts: inputs, success/failure values, composition |
| [extending.md](extending.md) | Supported customization points for host applications |
| [testing.md](testing.md) | Test layout, dummy app, helpers/factories, conventions, coverage map |
| [development.md](development.md) | Setup, commands, CI, release process |

## Analysis (working documents)

| Document | Contents |
|----------|----------|
| [analysis/security-review.md](analysis/security-review.md) | Security posture review: findings ranked by severity, with remediation notes |
| [analysis/known-issues.md](analysis/known-issues.md) | Code-quality findings: bugs, dead code, inconsistencies, doc drift |

## Ground rules for AI-driven development in this repo

1. **Read [architecture.md](architecture.md) first.** It explains the two invariants that shape everything: the single `Devise.api.config` global, and the string-based `base_token_model` / `base_controller` indirection (`constantize` at use sites — never hardcode `Devise::Api::Token` or the controller class in library code).
2. **Behavioral changes need request specs.** Real coverage lives in `spec/requests/`; service specs are currently placeholders (see [testing.md](testing.md)).
3. **Error types are public API.** Adding/renaming a symbol in `ErrorResponse::ERROR_TYPES` requires a locale entry in `config/locales/en.yml`, a status mapping, and an entry in [api-reference.md](api-reference.md).
4. **Schema changes touch three places:** the generator template (`lib/devise/api/generators/templates/migration.rb.erb`), the dummy app (`spec/dummy/db/migrate` + `spec/dummy/db/schema.rb`), and [data-model.md](data-model.md). Host apps upgrade via new migrations, so also consider an upgrade path.
5. **Run `bundle exec rake` before finishing** — it runs RSpec and RuboCop, exactly what CI runs.
6. **Check [analysis/known-issues.md](analysis/known-issues.md) before "fixing" something** — several quirks are documented there with context on whether changing them breaks the public API (e.g. the `failed_attemps` response-field typo).

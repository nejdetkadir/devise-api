Create a new git branch following the project's naming conventions.

## Branch Naming Format

```
{type}/{description}
```

## Types

| Type | Use Case |
|------|----------|
| `feature` | New functionality, endpoints, entities |
| `fix` | Bug fixes, issue corrections |
| `chore` | Maintenance, config, non-feature changes |
| `refactor` | Code restructuring without behavior change |
| `ci` | CI/CD pipeline changes |
| `test` | Test additions or modifications |
| `docs` | Documentation only changes |
| `hotfix` | Urgent production fixes |

## Description Rules

1. Use **kebab-case** (words separated by hyphens)
2. Start with a **verb**: `add-`, `fix-`, `update-`, `remove-`, `complete-`, `enable-`, `change-`
3. **Lowercase only** — no uppercase letters
4. Be descriptive but concise

## Workflow

1. Infer the branch type from context (default to `feature` for new functionality)
2. Generate a descriptive branch name based on: $ARGUMENTS (or the work done in the session)
3. **Immediately create and checkout the branch** — no confirmation needed:

```bash
git checkout -b {type}/{description}
```

4. Report the branch name to the user after creation

## Examples

| Description | Branch Name |
|-------------|-------------|
| Adding email notifications | `feature/add-email-notification-structure` |
| Fixing login timeout | `fix/login-timeout-issue` |
| Updating Redis config | `chore/update-redis-configuration` |
| Refactoring ticket service | `refactor/ticket-service` |
| Adding user repo tests | `test/add-user-repository-tests` |

## Anti-patterns

- No uppercase: `Feature/Add-Users`
- No underscores: `feature_add_users`
- No camelCase: `feature/AddUserEndpoint`
- Missing type prefix: `add-users`
- Too vague: `feature/users` (no verb)

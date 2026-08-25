Create a git commit for the current staged/unstaged changes.

## Steps

1. Run `git status` and `git diff` to review all changes
2. Run `git log --oneline -5` to match the project's recent commit style
3. Stage only relevant files — never stage `.env`, `*.pem`, credentials, or build artifacts (`*.gem`, `pkg/`)
4. Draft a commit message following the format below
5. Create the commit

## Commit Message Format

```
<type>(<scope>): <description>
```

**Types:** `feat` | `fix` | `refactor` | `chore` | `docs` | `test` | `perf`

**Scopes** (lowercase, optional — this repo's history mostly omits the scope; use one only when it adds clarity): `tokens` | `services` | `responses` | `config` | `model` | `routes` | `generators` | `locales` | `specs` | `docs` | `ci`

**Rules:**
- Description explains WHY, not WHAT
- Use present tense ("add", not "added")
- If changes span multiple areas, omit the scope
- Keep under 72 characters

## Examples

```
feat(tokens): add token rotation on refresh to block replay
fix(responses): correct translation key for unconfirmed signup message
refactor(services): extract error rendering shared by controller actions
chore(ci): add Ruby 3.3 to the test matrix
test(specs): cover non-default authorization locations
docs: document refresh chain semantics in data-model
```

$ARGUMENTS

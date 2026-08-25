Analyze all commits on the current branch (compared to main) and create a comprehensive PR.

## Steps

1. Run `git log main..HEAD` and `git diff main...HEAD` to understand all changes
2. Generate PR title in conventional format: `<type>(<scope>): <description>`
3. Push the branch to remote if not already pushed
4. Create PR using GitHub CLI:

```bash
gh pr create --title "<title>" --body "<body>"
```

## PR Body Template

```markdown
## Summary
- [1-3 bullet points describing what changed and why]

## Changes
- [List of significant code changes by file/area]

## Architecture Impact
- [Any cross-service changes, new events, DB migrations]

## Test Plan
- [ ] Unit tests added/updated
- [ ] Integration tests pass
- [ ] Manual testing completed
- [ ] Migration tested on clean DB

## Related
- Closes #issue-number (if applicable)
```

## Rules

- Never include credentials or secrets in PR description
- Link related issues with `Closes #N` syntax
- If migration exists, mention it explicitly in Architecture Impact
- Scope: $ARGUMENTS (optional: specific context or issue number)

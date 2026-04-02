---
name: gh-ship
description: Create strong conventional commits and pull requests with git and gh. Use when staging changes, choosing a conventional commit type and gitmoji, writing commit messages and bodies, pushing a branch, or opening a PR with a clear title and description.
argument-hint: "[what-to-commit-or-pr-goal]"
disable-model-invocation: false
user-invocable: true
metadata:
  short-description: Automatically handle commit writing and GitHub PR workflow tasks
---

# GH Ship Skill

> Skill instructions for splitting changes, writing conventional commits with gitmojis, and publishing PRs with `gh`.

You are a commit and PR writer. Follow the `vivaxy/vscode-conventional-commits` workflow and message shape, then use
`gh` to publish a clean PR.

## Sources To Read

Before choosing a commit message, read:

- `references/commit-types.md`
- `references/gitmojis.md`

Those references are extracted from:

- `vivaxy/vscode-conventional-commits`
- `@yi-xu-0100/conventional-commit-types-i18n`
- `carloscuesta/gitmoji` v3.13.1

## Workflow

1. Inspect the worktree with `git status --short`, `git diff --stat`, and the relevant diffs.
2. Identify the smallest coherent change set. Do not mix unrelated changes into one commit.
3. Choose the commit `type` from `references/commit-types.md`.
4. Choose the optional `scope` from the dominant subsystem, package, app, directory, or concern.
5. Choose the best `gitmoji` from `references/gitmojis.md`.
6. Write the commit header in the upstream extension format.
7. Add a body when the diff is non-trivial.
8. Add a footer for breaking changes, issue closing references, or follow-up metadata.
9. Commit with `git`.
10. Push the branch and open or update the PR with `gh`.

## Commit Format

Use this exact header shape:

```text
type(scope): :gitmoji: imperative subject
```

Rules:

- `scope` is optional. If absent, use `type: :gitmoji: subject`.
- Put the gitmoji after `type(scope): `, not before the type.
- Prefer gitmoji code form such as `:sparkles:` because the upstream repo defaults to `emojiFormat=code`.
- Write the subject in imperative mood: `add`, `fix`, `update`, `remove`, `refactor`.
- Keep the subject specific and outcome-focused.
- Do not end the subject with a period.
- Use `[skip ci]` at the end of the header only when the change genuinely should not run CI.

Examples:

```text
feat(auth): :sparkles: add device-bound refresh token rotation
fix(markdown): :bug: handle fenced mermaid blocks without trailing newline
docs(readme): :memo: document plugin installation flow
ci(actions): :green_heart: fix release workflow permissions [skip ci]
```

## Body And Footer

Body:

- Add a body when the diff is not obvious from the header.
- Explain what changed and why.
- Prefer short paragraphs or compact bullets.
- Focus on behavior, constraints, migration impact, and notable tradeoffs.

Footer:

- Use footer lines for issue references: `Closes #123`, `Refs #456`.
- Put breaking changes in the footer, for example: `BREAKING CHANGE: refresh tokens issued before this change are invalid`.
- If there is no footer-worthy information, omit the footer entirely.

## Commit Selection Heuristics

- Choose the `type` by the primary intent, not every side effect in the diff.
- Choose the gitmoji by the visible nature of the change. The gitmoji complements the type; it does not replace it.
- If type and gitmoji pull in different directions, fix the commit split instead of forcing one overloaded message.
- Prefer multiple commits over one mixed commit when the diff spans different intents.
- Preserve existing repo conventions if the repository already uses a narrower type or scope vocabulary through commitlint.

## PR Workflow With `gh`

After committing:

1. Check the current branch and remote tracking.
2. Push with upstream if needed.
3. Summarize the diff before writing the PR.
4. Create the PR with `gh pr create`.

PR title rules:

- Use a concise, review-friendly title.
- Prefer the dominant user-facing change or subsystem outcome.
- Do not mechanically copy a noisy commit message if a clearer PR title exists.

PR body rules:

- Start with a short summary of what changed.
- Include the reason or problem being solved.
- Include testing done, if any.
- Call out risk, migration, or rollout concerns when relevant.
- Link issues explicitly.

Preferred structure:

```markdown
## Summary
- ...

## Testing
- ...

## Notes
- ...
```

When using `gh`, prefer explicit non-interactive commands such as:

```bash
gh pr create --title "Add conventional gh shipper skill" --body-file /tmp/pr-body.md
gh pr view --web
```

## Guardrails

- Never commit unrelated untracked or modified files.
- Never invent testing results. If tests were not run, say so.
- Never use `git commit --amend` unless explicitly requested.
- Never rewrite history unless explicitly requested.
- If the worktree already contains unrelated user changes, work around them and leave them untouched.

## Task

Handle this request: $ARGUMENTS

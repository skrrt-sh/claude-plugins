---
name: gh-ship
description: Create strong conventional commits and focused pull requests with git and gh. Use whenever the agent is about to run git commit, write or rewrite a commit message, choose a conventional commit type or mandatory gitmoji, stage or split changes for commit, push a branch, or create, update, or title a GitHub pull request with gh. This skill should trigger even when the user does not explicitly mention gh-ship but asks the agent to commit changes or open a PR. Gitmoji is required and must appear after the commit type or type(scope) prefix.
argument-hint: "[what-to-commit-or-pr-goal]"
disable-model-invocation: false
user-invocable: true
metadata:
  short-description: Automatically handle commit writing and GitHub PR workflow tasks
---

# GH Ship Skill

> Skill instructions for splitting changes, writing conventional commits with gitmojis, and publishing PRs with `gh`.

You are a commit and PR writer. Follow the `vivaxy/vscode-conventional-commits` workflow, enforce this repository's stricter gitmoji placement rules, and use `gh` to publish a clean PR.

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
6. Write the commit header in the required repository format.
7. Write a description body explaining what changed and why. Treat the body as required for this skill, even though the Conventional Commits spec allows it to be optional.
8. Add footer lines for breaking changes, issue closing references, or follow-up metadata. When the change is breaking, add a `BREAKING CHANGE:` footer.
9. Commit with `git`.
10. Push the branch and open or update the PR with `gh`.

## Commit Format

Use this exact header shape:

```text
type(scope): :gitmoji: imperative subject
```

Rules:

- `scope` is optional. If absent, use `type: :gitmoji: subject`.
- Gitmoji is mandatory for every commit written by this skill.
- Put the gitmoji immediately after `type(scope): ` or `type: `, never before the type and never after the subject.
- Prefer gitmoji code form such as `:sparkles:` because the upstream repo defaults to `emojiFormat=code`.
- Write the subject in imperative mood: `add`, `fix`, `update`, `remove`, `refactor`.
- Keep the subject specific and outcome-focused.
- Do not end the subject with a period.
- Use `[skip ci]` at the end of the header only when the change genuinely should not run CI.

The current stable Conventional Commits 1.0.0 structure is:

```text
<type>[optional scope]: <description>

[optional body]
[optional footer(s)]
```

This skill intentionally applies a stricter house style on top of that spec:

```text
<type>[optional scope]: :gitmoji: <imperative subject>

<description body>

[optional footer(s)]
```

Treat the commit message as three logical sections:

- Message: the first-line header containing type, optional scope, mandatory gitmoji, and imperative subject.
- Description: the body section after one blank line. This skill requires a body so the commit explains what changed and why.
- Breaking Changes: a footer section. Include `BREAKING CHANGE: ...` when the change is breaking. Other trailers such as `Refs:` and `Closes:` also belong in the footer section.

Examples:

```text
feat(auth): :sparkles: add device-bound refresh token rotation
fix(markdown): :bug: handle fenced mermaid blocks without trailing newline
docs(readme): :memo: document plugin installation flow
ci(actions): :green_heart: fix release workflow permissions [skip ci]
```

## Body And Footer

Description body:

- Add a body for every commit produced by this skill.
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
- Do not omit the gitmoji. If no gitmoji seems to fit, the commit is not ready to write yet.
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
- Never place the gitmoji before the commit type or after the subject.
- Never omit the description body for a commit produced by this skill.
- Never use a breaking change without either `!` in the type/scope prefix or a `BREAKING CHANGE:` footer. Prefer including the `BREAKING CHANGE:` footer because it is clearer.

## Task

Handle this request: $ARGUMENTS

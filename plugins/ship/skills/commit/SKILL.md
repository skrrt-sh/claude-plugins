---
name: commit
description: Creates focused conventional commits with mandatory gitmojis. Use when the agent needs to review git changes, split work into commits, stage files, or write commit messages. Always use this skill when the user asks to commit, make a commit, write a commit message, split changes into commits, stage and commit files, or anything involving git commit workflows. Trigger for phrases like "commit this", "write a commit", "split into commits", "conventional commit", "gitmoji commit", "stage and commit", "commit the changes", or "help me commit".
argument-hint: "[what-to-commit]"
user-invocable: true
---

# Git Commit Skill

> Skill instructions for splitting changes and writing conventional commits with mandatory gitmojis.

You are a commit writer. Follow the `vivaxy/vscode-conventional-commits` workflow and this repository's
stricter gitmoji placement rules.

## Additional Resources

Before choosing a commit message, read:

- [reference/commit-types.md](reference/commit-types.md)
- [reference/gitmojis.md](reference/gitmojis.md)

## Workflow

1. **Check the branching strategy** — read the branching block from the agent instruction file
   (see "Branching Strategy Awareness" below). Validate the current branch is appropriate
   for the configured strategy before proceeding. If no block is found, tell the user to run
   `/setup` and stop.
2. Inspect the worktree with `git status --short`, `git diff --stat`, and the relevant diffs.
3. Identify the smallest coherent change set. Do not mix unrelated changes into one commit.
4. Choose the commit `type` from `reference/commit-types.md`.
5. Choose the optional `scope` from the dominant subsystem, package, app, directory, or concern.
6. Choose the best `gitmoji` from `reference/gitmojis.md`.
7. Stage only the intended files or hunks.
8. Write the commit header in the required repository format.
9. Write a description body explaining what changed and why. Treat the body as required for this skill.
10. Add footer lines for breaking changes, issue references, or follow-up metadata.
11. Commit with `git`.

## Git Command Subset

Stay within this safe `git` subset unless the user explicitly asks for something else:

- `git status --short`
- `git diff --stat`
- `git diff -- <path>`
- `git add -- <path>`
- `git add -p -- <path>`
- `git restore --staged -- <path>`
- `git commit --file <file>`
- `git commit --message <header>`
- `git branch --show-current`
- `git branch --list` (for checking active branches, e.g., Gitflow release detection)
- `git switch -c <branch>` (for creating branches when the strategy requires it)
- `git switch <branch>` (for switching to an existing branch)
- `git pull origin <branch>` (for syncing with the target branch)
- `git pull --rebase origin <branch>` (GitHub Flow / TBD only — for rebasing before PR)
- `git rebase --continue` (GitHub Flow / TBD only — after resolving rebase conflicts)
- `git rebase --abort` (GitHub Flow / TBD only — to abandon a failed rebase)

Never use rebase commands under Gitflow. Avoid history-rewriting or destructive `git` commands
beyond the rebase operations listed above.

## Requirements

- `git` must be installed and available on `PATH`.
- The repository must already exist and have the intended changes in the worktree.
- When the project uses agent permission settings, prefer `permissions.ask` for mutating
  git commands and `permissions.deny` for destructive commands.

## Commit Format

Use this exact header shape:

```text
type(scope): :gitmoji: imperative subject
```

Rules:

- `scope` is optional. If absent, use `type: :gitmoji: subject`.
- Gitmoji is mandatory for every commit written by this skill.
- Put the gitmoji immediately after the colon-space in `type(scope):` or `type:`.
- Prefer gitmoji code form such as `:sparkles:`.
- Write the subject in imperative mood.
- Keep the subject specific and outcome-focused.
- Do not end the subject with a period.
- Use `[skip ci]` only when the change genuinely should not run CI.

## Body And Footer

Description body:

- Add a body for every commit produced by this skill.
- Explain what changed and why.
- Prefer short paragraphs or compact bullets.
- Focus on behavior, constraints, migration impact, and notable tradeoffs.

Footer:

- Only add issue-reference footers (`Closes #123`, `Refs #456`) when the user explicitly mentions
  an issue number or asks to close one. Do not invent placeholder issue numbers like `Closes #0`.
- Put breaking changes in the footer, for example: `BREAKING CHANGE: old tokens are invalid`.
- If there is no footer-worthy information, omit the footer entirely — a clean commit with no
  footer is better than a footer with fabricated references.
- Always include the co-authorship trailer unless the user asks not to:
  `Co-Authored-By: Skrrt Bot <bot@skrrt.sh>`

## Commit Selection Heuristics

- Choose the `type` by the primary intent, not every side effect in the diff.
- Choose the gitmoji by the visible nature of the change. The gitmoji complements the type.
- Do not omit the gitmoji. If no gitmoji fits, the commit split is not ready.
- If type and gitmoji pull in different directions, fix the commit split instead of forcing one message.
- Prefer multiple commits over one mixed commit when the diff spans different intents.
- Preserve existing repo conventions if the repository already uses a narrower type or scope vocabulary.

## Branching Strategy Awareness

Before committing, check the project's agent instruction file for a `<!-- skrrt:branching -->`
block. Search these locations in order: `CLAUDE.md`, `AGENTS.md`, `.claude/CLAUDE.md`,
`.github/AGENTS.md`. If present, respect the configured strategy:

- **GitHub Flow**: You should be on a feature branch, not `main`. If on `main`, stop and tell
  the user to create a feature branch first — GitHub Flow requires all changes to reach `main`
  through a pull request.
- **Trunk-Based**: Agents always work on short-lived branches, never commit directly to `main`.
  If on `main`, create a short-lived branch first using `git switch -c <type>/<description>`.
  On a short-lived branch, proceed normally.
- **Gitflow**: Check the current branch and enforce these rules:
  - `main` — never commit here. Stop and tell the user that `main` only receives merges
    from `release/*` or `hotfix/*` branches.
  - `develop` — only commit release preparation work (version bumps, changelog updates).
    For features, stop and tell the user to create a feature branch from `develop`.
  - `feat/*` or `feature/*` — normal commits allowed. This is where feature work happens.
  - `release/*` — only bug fixes, version bumps, and release-oriented tasks. No new features.
  - `hotfix/*` — only critical fixes. Keep the scope minimal.

If no branching strategy block is found, tell the user to run `/setup` to configure a branching
strategy before proceeding. Do not guess or assume a default.

## Guardrails

- Never commit unrelated untracked or modified files.
- Never invent testing results.
- Never use `git commit --amend` unless explicitly requested.
- Never rewrite history unless explicitly requested.
- Never place the gitmoji before the commit type or after the subject.
- Never omit the description body for a commit produced by this skill.
- Never use a breaking change without a `BREAKING CHANGE:` footer.
- Never use force-based git commands such as `git push --force`, `git push -f`, or `git push --force-with-lease`.
- Stop and ask the user before including files that appear unrelated to the requested commit.
- Treat staging and committing as human-approval actions when the project uses agent permission rules.

## Task

Handle this request: $ARGUMENTS

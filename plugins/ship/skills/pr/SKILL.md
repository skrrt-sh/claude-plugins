---
name: pr
description: Creates or updates GitHub pull requests and GitLab merge requests with the matching CLI. Use when Claude needs to push a branch, open a review request, or write PR or MR text.
argument-hint: "[pr-or-mr-goal]"
disable-model-invocation: false
user-invocable: true
metadata:
  short-description: Push branches and open focused PRs or MRs
---

# Git PR Skill

> Skill instructions for pushing branches and creating review requests with the matching forge CLI.

You are a PR or MR writer. Detect the forge from the repository remote first, then use the matching CLI:

- GitHub remote: `gh`
- GitLab remote: `glab`

If the matching CLI is unavailable, stop and tell the user exactly what is missing. Never use `glab` against
GitHub or `gh` against GitLab.

## Requirements

- `git` must be installed and available on `PATH`.
- `gh` is required for GitHub remotes.
- `glab` is required for GitLab remotes.
- If the matching CLI is missing, stop and tell the user exactly what is missing.
- When the project uses Claude Code settings, prefer `permissions.ask` for mutating
  git and forge commands, including force-push variants.

## Forge Detection

Before any PR or MR command, run:

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/detect-forge-cli.sh"
```

Read the output fields:

- `REMOTE_HOST=<host>`
- `FORGE=github|gitlab|unknown`
- `MATCHED_CLI=gh|glab|none`
- `STATUS=ok|no-compatible-cli|unknown-remote|no-remote`

Only continue when `STATUS=ok`.

## Workflow

1. Run the forge detection script.
2. Check the current branch and remote tracking.
3. Push with upstream if needed.
4. Summarize the diff before writing the PR or MR.
5. Use the matched CLI to create or update the review request non-interactively.

## Git Command Subset

Stay within this `git` subset unless the user explicitly asks for more:

- `git status --short`
- `git diff --stat`
- `git branch --show-current`
- `git rev-parse --abbrev-ref --symbolic-full-name @{upstream}`
- `git remote get-url origin`
- `git push -u origin HEAD`
- `git log --oneline --decorate -n <count>`

## CLI Command Subset

For GitHub with `gh`:

- `gh pr create --title <title> --body-file <file>`
- `gh pr edit --title <title> --body-file <file>`
- `gh pr view`

For GitLab with `glab`:

- `glab mr create --title <title> --description <body>`
- `glab mr update --title <title> --description <body>`
- `glab mr view`

Prefer explicit non-interactive commands.

When the description body is long, write it to a temporary file and pass it to the CLI with the closest
supported non-interactive flag:

- GitHub: `--body-file <file>`
- GitLab: `--description <body>`

## PR Or MR Writing Rules

Title rules:

- Use a concise, review-friendly title.
- Prefer the dominant user-facing change or subsystem outcome.
- Do not mechanically copy a noisy commit message if a clearer review title exists.

Body rules:

- Start with a short summary of what changed.
- Include the reason or problem being solved.
- Include testing done, if any.
- Call out risk, migration, or rollout concerns when relevant.
- Link issues explicitly.

Preferred structure:

```markdown
## Summary
- ...

## Test plan
- [ ] ...
- [ ] ...

## Notes
- ...
```

Use checkboxes (`- [ ]`) in the test plan so reviewers can track verification
progress directly in the PR. If no tests were run, say so honestly rather than
inventing results.

## Guardrails

- Never invent testing results. If tests were not run, say so.
- Never assume `origin` points at the same forge as the installed CLI.
- Never open an interactive PR or MR flow when a non-interactive command is available.
- Never use `git push --force`, `git push -f`, or `git push --force-with-lease`.
- Stop if the detector reports `unknown-remote`, `no-remote`, or `no-compatible-cli`.
- Treat the branch push and PR or MR creation as human-approval actions when the project uses Claude permission rules.

## Task

Handle this request: $ARGUMENTS

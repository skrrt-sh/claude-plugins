---
name: pr
description: Creates or updates GitHub pull requests and GitLab merge requests with the matching CLI. Use when the agent needs to push a branch, open a review request, or write PR or MR text. Always use this skill when the user asks to open a PR, create a pull request, push and open a PR, create a merge request, update PR text, write a PR description, or anything involving pull requests or merge requests. Trigger for phrases like "open a PR", "create a pull request", "push and open a PR", "merge request", "MR on gitlab", "update the PR", or "write PR description".
argument-hint: "[pr-or-mr-goal]"
user-invocable: true
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
- When the project uses agent permission settings, prefer `permissions.ask` for mutating
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

1. **Check the branching strategy** — read the branching block from the agent instruction file
   (see "Branching Strategy Awareness" below). Determine the correct target branch before
   proceeding. If no block is found, tell the user to run `/setup` and stop.
2. Run the forge detection script.
3. Check the current branch and remote tracking. Validate the current branch is appropriate
   for the configured strategy (e.g., not `main` for GitHub Flow/TBD, not a feature branch
   targeting `main` for Gitflow).
4. Push with upstream if needed.
5. Summarize the diff before writing the PR or MR.
6. Use the matched CLI to create or update the review request non-interactively, using
   `--base` or `--target-branch` with the strategy-determined target.

## Git Command Subset

Stay within this `git` subset unless the user explicitly asks for more:

- `git status --short`
- `git diff --stat`
- `git branch --show-current`
- `git branch --list`
- `git rev-parse --abbrev-ref --symbolic-full-name @{upstream}`
- `git remote get-url origin`
- `git push -u origin HEAD`
- `git log --oneline --decorate -n <count>`
- `git pull origin <branch>` (for syncing with the target branch)
- `git switch -c <branch>` (for creating branches when the strategy requires it)
- `git switch <branch>` (for switching to an existing branch)
- `git pull --rebase origin <branch>` (GitHub Flow / TBD only — for rebasing before PR)
- `git rebase --continue` (GitHub Flow / TBD only — after resolving rebase conflicts)
- `git rebase --abort` (GitHub Flow / TBD only — to abandon a failed rebase)

## CLI Command Subset

For GitHub with `gh`:

- `gh pr create --title <title> --body-file <file> [--base <branch>]`
- `gh pr edit --title <title> --body-file <file>`
- `gh pr edit <number> --repo <owner/repo> --body-file <file>` (for correlated PR updates)
- `gh pr view`
- `gh pr view --json state`
- `gh pr list --repo <owner/repo> --state open --json number,title,headRefName --limit <count>`

For GitLab with `glab`:

- `glab mr create --title <title> --description <body> [--target-branch <branch>]`
- `glab mr update --title <title> --description <body>`
- `glab mr update <number> --repo <group/project> --description <body>` (for correlated MR updates)
- `glab mr view`
- `glab mr list --repo <owner/repo> --state opened`

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

## Related PRs
- **depends on** owner/repo#N — short description
- **related to** owner/repo#N — short description

## Notes
- ...
```

Omit the `## Related PRs` section when the PR is standalone.

Use checkboxes (`- [ ]`) in the test plan so reviewers can track verification
progress directly in the PR. If no tests were run, say so honestly rather than
inventing results.

End the PR or MR body with the co-authorship line unless the user asks not to:

```text
Co-Authored-By: Skrrt Bot <bot@skrrt.sh>
```

## Branching Strategy Awareness

Before creating a PR or MR, check the project's agent instruction file for a
`<!-- skrrt:branching -->` block. Search these locations in order: `CLAUDE.md`, `AGENTS.md`,
`.claude/CLAUDE.md`, `.github/AGENTS.md`. If present, respect the configured strategy:

- **GitHub Flow**: PRs always target `main`. If the current branch is `main`, create a feature
  branch first using `git switch -c <type>/<description>` before proceeding. Before pushing, rebase the branch onto `main` with
  `git pull --rebase origin main` (Skrrt convention). The PR should be squash merged by the
  forge (Skrrt convention).
- **Trunk-Based**: PRs always target `main`. If the current branch is `main`, create a short-lived
  branch first using `git switch -c <type>/<description>` before pushing. Before creating a new
  branch. Respect the repository's configured merge strategy.
- **Gitflow**: PRs for feature branches target `develop`, not `main`. PRs for `release/*` branches
  target `main` — after merging, remind the user that `release/*` must also be merged back to
  `develop` via a separate PR using `/pr`. PRs for `hotfix/*` branches target `main` — after
  merging, remind the user to open a PR to `develop` (or the active `release/*` branch if one
  exists) using `/pr`. If the user asks to PR a feature branch to `main`, warn them that the
  project uses Gitflow and suggest targeting `develop` instead. Never rebase under Gitflow — the
  forge must use `--no-ff` merge commits.

Use the detected target branch when constructing the CLI command. For example:

- GitHub: `gh pr create --base <target>`
- GitLab: `glab mr create --target-branch <target>`

If no branching strategy block is found, tell the user to run `/setup` to configure a branching
strategy before proceeding. Do not guess or assume a default target branch.

## Correlated PRs

When a feature spans multiple repositories in a workspace or multiple apps/services inside
a monorepo, the PRs form a **correlated set**. Detect this when:

- The user mentions changes across multiple repos or services in the same task.
- The user explicitly says PRs are related or dependent.
- The working directory is a monorepo and changes touch multiple independently deployable
  apps or packages.

For every PR in a correlated set:

1. Add a `## Related PRs` section to the PR body, after the test plan and before notes.
2. List each sibling PR using the forge link format with a dependency label:

GitHub example:

```markdown
## Related PRs
- **depends on** owner/repo#42 — API schema changes (must merge first)
- **required by** owner/other-repo#58 — frontend consumer
- **related to** owner/repo#43 — shared config update (no strict order)
```

GitLab example:

```markdown
## Related MRs
- **depends on** group/project!42 — API schema changes (must merge first)
- **related to** group/project!43 — shared config update (no strict order)
```

Dependency labels:

| Label | Meaning |
|-------|---------|
| `depends on` | This PR requires the linked PR to merge first |
| `required by` | The linked PR requires this one to merge first |
| `related to` | Sibling PRs with no strict merge ordering |

Rules:

- Use the correct forge reference format: GitHub `owner/repo#N`, GitLab `group/project!N`.
- When updating an existing PR in a correlated set (e.g., after a sibling is opened),
  update the related-PRs section of all open siblings to keep references bidirectional.
- If the user provides merge-order constraints, respect them. If not, default to
  `related to` — do not invent dependency order.
- When a correlated PR merges, note it in the remaining siblings' related-PRs section
  as merged (e.g., `~~depends on owner/repo#42~~ — merged`).

To list open PRs across repos for cross-referencing, the following commands are allowed:

- GitHub: `gh pr list --repo <owner/repo> --state open --json number,title,headRefName --limit 10`
- GitLab: `glab mr list --repo <owner/repo> --state opened`

## PR Follow-Up

When the user reports problems after a PR was already created, check the PR state before
making any changes:

1. Run `gh pr view --json state` (GitHub) or `glab mr view` (GitLab) to determine whether
   the PR is open, merged, or closed.
2. **PR is still open** — stay on (or switch to) the PR's source branch, commit fixes using
   `/commit`, and push. The existing PR updates automatically. Do not create a new PR.
3. **PR was merged** — switch to `main`, run `git pull origin main`, create a new short-lived
   branch from the updated `main`, apply fixes, and open a new PR using this skill. Do not
   attempt to reuse a branch that the forge already deleted after merge.
4. **PR was closed without merge** — stop and ask the user whether to reopen the existing
   branch or start a fresh one.

If the agent is on `main` when the user references a PR problem, identify the PR's source
branch and switch to it before committing (for open PRs).

## Guardrails

- Never invent testing results. If tests were not run, say so.
- Never assume `origin` points at the same forge as the installed CLI.
- Never open an interactive PR or MR flow when a non-interactive command is available.
- Never use `git push --force`, `git push -f`, or `git push --force-with-lease`.
- Stop if the detector reports `unknown-remote`, `no-remote`, or `no-compatible-cli`.
- Treat the branch push and PR or MR creation as human-approval actions when the project uses agent permission rules.

## Task

Handle this request: $ARGUMENTS

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

1. **Pre-flight branch check (mandatory)** — run `git branch --show-current` and confirm you
   are on the correct short-lived branch. Never push a PR from a protected branch (`main`,
   `master`, or `develop` under Gitflow). See "Branch Guard" below.
2. **Check for prior PR work in the same problem boundary** — if this PR is a follow-up or
   fix related to a recent PR, run the PR follow-up check in "PR Follow-Up" below before
   pushing. A merged or closed precedent PR means the current branch may be stale and you
   must create a fresh one from an up-to-date `main`.
3. **Check the branching strategy** — read the branching block from the agent instruction file
   (see "Branching Strategy Awareness" below). Determine the correct target branch before
   proceeding. If no block is found, tell the user to run `/setup` and stop.
4. Run the forge detection script.
5. Check the current branch and remote tracking. Validate the current branch is appropriate
   for the configured strategy (e.g., not `main` for GitHub Flow/TBD, not a feature branch
   targeting `main` for Gitflow).
6. Push with upstream if needed.
7. Summarize the diff before writing the PR or MR.
8. Use the matched CLI to create or update the review request non-interactively, using
   `--base` or `--target-branch` with the strategy-determined target.

## Branch Guard

This is a hard pre-flight gate enforced by agent adherence to this skill — not by a
script or hook. Projects that need a machine-enforced backstop should add branch
protection rules on the forge. Before `git push` or any forge CLI command:

1. Run `git branch --show-current`.
2. Compare the result to the configured branching strategy (see below).
3. If the current branch is protected or wrong for this work:
   - `git fetch origin`
   - `git switch main && git pull --ff-only origin main`
   - `git switch -c <type>/<description>`
4. Only after the branch is correct may you push or open the PR.

Never push from a protected branch with a plan to "fix the branch later" — once pushed,
the remote history is visible to reviewers and CI.

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
- `git log origin/<branch>..HEAD` (pre-push sanity check)
- `git fetch origin` (pre-flight to refresh remote state)
- `git fetch origin --prune` (drop stale remote-tracking refs for deleted branches)
- `git pull origin <branch>` (for syncing with the target branch)
- `git pull --ff-only origin <branch>` (safe fast-forward sync; preferred over plain pull)
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

When the user reports a problem in the **same problem boundary** as a recent PR — even if
they do not name the PR — verify the precedent PR's state *before* pushing or opening
anything new. Do not assume the current branch is still active on the remote; a merged PR
usually means the forge has deleted the branch.

1. Identify the precedent PR. If the user does not name it, inspect recent PRs:
   - GitHub: `gh pr list --state all --limit 10 --json number,title,state,headRefName,mergedAt,closedAt`
   - GitLab: `glab mr list --state all --per-page 10`

   Match a candidate to the user's report by (in priority order):
   1. Keyword overlap between the user's description and the PR title or branch name.
   2. Files mentioned in the report overlapping the PR's changed files
      (`gh pr view <n> --json files -q '.files[].path'`).
   3. Recency — prefer PRs merged or closed within the last few days over older ones.
   If two or more candidates are plausible after this scoring, stop and ask the user
   which PR they mean. Never guess.
2. Run `gh pr view <number> --json state,headRefName,mergedAt,closedAt` (GitHub) or
   `glab mr view <number>` (GitLab) to determine whether the PR is open, merged, or closed.
3. Branch on the state:

   **PR is still open** — stay on (or switch to) the PR's source branch. Before pushing,
   pull any remote updates with `git pull --ff-only origin <source-branch>`. Commit fixes
   with `/commit` and push. The existing PR updates automatically. Do not create a new PR.

   **PR was merged** — the source branch has almost certainly been deleted from the remote.
   Resolve the merged PR's target branch first (read it from `gh pr view <n> --json baseRefName`
   or `glab mr view <n>`): `<target>` is `main` for GitHub Flow and TBD, and typically
   `develop` for Gitflow feature PRs (or the release branch for Gitflow hotfixes). Then
   follow this exact sequence, in order:
   1. `git switch <target>`
   2. `git fetch origin --prune`
   3. `git pull --ff-only origin <target>`
   4. `git switch -c <type>/<description>` (fresh short-lived branch from updated `<target>`)
   5. Apply fixes on the new branch, commit with `/commit`, push with `-u origin HEAD`.
   6. Open a new PR with this skill targeting `<target>`. Reference the merged PR in the
      body when useful.

   Never reuse a branch whose PR was already merged.

   **PR was closed without merge** — stop and ask the user whether to reopen the existing
   branch or start fresh from `main`. Do not guess.

4. If the agent is on `main` when the user references a PR problem, do not push from `main`.
   Apply the rules above first.

**Push cleanly**: before any push, confirm `git status` is clean and `git log origin/<branch>..HEAD`
shows only the intended commits. Do not push stray commits carried over from another task.

## Guardrails

- Never invent testing results. If tests were not run, say so.
- Never assume `origin` points at the same forge as the installed CLI.
- Never open an interactive PR or MR flow when a non-interactive command is available.
- Never use `git push --force`, `git push -f`, or `git push --force-with-lease`.
- Stop if the detector reports `unknown-remote`, `no-remote`, or `no-compatible-cli`.
- Treat the branch push and PR or MR creation as human-approval actions when the project uses agent permission rules.

## Task

Handle this request: $ARGUMENTS

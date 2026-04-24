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

1. **Pre-flight branch check (mandatory)** — before touching staging or writing a commit,
   run `git branch --show-current` and confirm you are on the correct short-lived branch for
   the work at hand. Never commit directly to a protected branch (`main`, `master`, `develop`
   under Gitflow). If the branch is wrong, fix it now — do not proceed and "fix it later".
   See "Branch Guard" and "Branching Strategy Awareness" below.
2. **Check for prior PR work in the same problem boundary** — if the current change is a
   fix or follow-up to recent work, run the PR follow-up check in "PR Follow-Up Awareness"
   below *before* staging any files. A closed or merged prior PR means the current branch
   may be stale or orphaned, and you must create a fresh branch from an up-to-date `main`.
3. **Check the branching strategy** — read the branching block from the agent instruction file
   (see "Branching Strategy Awareness" below). Validate the current branch is appropriate
   for the configured strategy before proceeding. If no block is found, tell the user to run
   `/setup` and stop.
4. Inspect the worktree with `git status --short`, `git diff --stat`, and the relevant diffs.
5. Identify the smallest coherent change set. Do not mix unrelated changes into one commit.
6. Choose the commit `type` from `reference/commit-types.md`.
7. Choose the optional `scope` from the dominant subsystem, package, app, directory, or concern.
8. Choose the best `gitmoji` from `reference/gitmojis.md`.
9. Stage only the intended files or hunks.
10. Write the commit header in the required repository format.
11. Write a description body explaining what changed and why. Treat the body as required for this skill.
12. Add footer lines for breaking changes, issue references, or follow-up metadata.
13. Commit with `git`.

## Branch Guard

This is a hard pre-flight gate enforced by agent adherence to this skill — not by a
script or hook. Projects that need a machine-enforced backstop should add branch
protection rules on the forge. Before staging, before writing a commit message, before
anything that mutates git state:

1. Run `git branch --show-current`.
2. Compare the result to the configured branching strategy (see below).
3. If the current branch is protected or wrong for this work:
   - Fetch the latest remote state: `git fetch origin`.
   - Ensure `main` is up to date locally: `git switch main && git pull --ff-only origin main`.
   - Create a new short-lived branch from fresh `main`: `git switch -c <type>/<description>`.
4. Only after the branch is correct may you stage files or write the commit.

Never stage files on the wrong branch with a plan to "move them later" — that path leaks
unrelated work into the commit and loses context. Fix the branch first, every time.

## Git Command Subset

Stay within this safe `git` subset unless the user explicitly asks for something else:

- `git status --short`
- `git diff --stat`
- `git diff -- <path>`
- `git add -- <path>`
- `git add -p -- <path>`
- `git restore --staged -- <path>`
- `git commit --file <file>` (preferred — supports header + body)
- `git commit --message <header>` (only for follow-up fixups when explicitly body-less)
- `git branch --show-current`
- `git branch --list` (for checking active branches, e.g., Gitflow release detection)
- `git switch -c <branch>` (for creating branches when the strategy requires it)
- `git switch <branch>` (for switching to an existing branch)
- `git fetch origin` (pre-flight to refresh remote state)
- `git fetch origin --prune` (drop stale remote-tracking refs for deleted branches)
- `git pull origin <branch>` (for syncing with the target branch)
- `git pull --ff-only origin <branch>` (safe fast-forward sync; preferred over plain pull)
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

- **GitHub Flow**: You should be on a feature branch, not `main`. If on `main`, create a feature
  branch first using `git switch -c <type>/<description>` — GitHub Flow requires all changes to
  reach `main` through a pull request.
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

## PR Follow-Up Awareness

When the user reports an issue inside the **same problem boundary** as a recent PR — even
if they do not explicitly reference the PR — you must verify the state of the precedent PR
*before* staging or committing anything. Assume nothing about the current branch. A branch
that looked active an hour ago may have been merged and deleted by the forge.

1. Identify the precedent PR. If the user does not name it, inspect recent PRs for the same
   scope:
   - GitHub: `gh pr list --state all --limit 10 --json number,title,state,headRefName,mergedAt,closedAt`
   - GitLab: `glab mr list --state all --per-page 10`

   Match a candidate to the user's report by (in priority order):
   1. Keyword overlap between the user's description and the PR title or branch name
      (e.g., "login redirect" matches `fix/login-redirect` or a PR titled "Fix login
      redirect loop").
   2. Files mentioned in the report overlapping the PR's changed files
      (`gh pr view <n> --json files -q '.files[].path'`).
   3. Recency — prefer PRs merged or closed within the last few days over older ones.
   If two or more candidates are plausible after this scoring, stop and ask the user
   which PR they mean. Never guess.
2. Run `gh pr view <number> --json state,headRefName,mergedAt,closedAt` (GitHub) or
   `glab mr view <number>` (GitLab) to check whether the precedent PR is open, merged, or
   closed without merge.
3. Branch on the state:

   **PR is still open** — stay on (or switch to) the PR's source branch, pull any remote
   updates with `git pull --ff-only origin <source-branch>`, then commit the fix. The push
   will update the existing PR. Do not open a new one.

   **PR was merged** — the source branch is almost certainly gone on the remote. Resolve
   the merged PR's target branch first (read it from `gh pr view <n> --json baseRefName`
   or `glab mr view <n>`): `<target>` is `main` for GitHub Flow and TBD, and typically
   `develop` for Gitflow feature PRs (or the release branch for Gitflow hotfixes). Then
   do all of the following, in order, before staging any file:
   1. `git switch <target>`
   2. `git fetch origin --prune` (drops stale remote-tracking refs for deleted branches)
   3. `git pull --ff-only origin <target>` (bring local `<target>` up to the merged state)
   4. `git switch -c <type>/<description>` (create a fresh short-lived branch)
   5. Re-apply the fix on the new branch, then stage and commit.

   Never reuse a branch whose PR was already merged — the forge has deleted it and the
   local copy is now orphaned and stale. A new PR will be needed via `/pr`.

   **PR was closed without merge** — stop and ask the user whether to reopen the existing
   branch (if it still exists locally and on the remote) or start fresh from `main`. Do
   not guess.

4. If the agent is currently on `main` when the user references a PR problem, do not
   commit on `main`. Identify the PR's source branch and apply the rules above.

**Commit cleanly**: whatever path you take, confirm `git status` shows only the intended
changes before staging. Stray modifications from a stale branch must be reconciled (stash,
discard, or include intentionally) — not quietly committed.

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

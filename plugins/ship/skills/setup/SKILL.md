---
name: setup
description: Adds skrrt skills instructions to the current project's CLAUDE.md or AGENTS.md so that commits, PRs, and releases use the ship plugin skills. Use this skill whenever the user wants to set up, configure, install, or wire skrrt skills into a project, add ship plugin instructions to agent config files, or ensure the team uses /commit /pr /release instead of raw git commands. Trigger even when the user says "set up this repo", "add skills to CLAUDE.md", or "configure the ship plugin".
argument-hint: "[options]"
user-invocable: true
---

# Ship Setup Skill

> Adds agent instructions and a branching strategy to the current project so that commits,
> PRs, and releases are handled by the ship plugin skills.

You are a setup helper. Your job is to detect the project's agent instruction file, append
the skrrt skills ship configuration block, and configure the project's branching strategy.

## Additional Resources

Before asking the user to choose a branching strategy, read:

- [reference/branching-strategies.md](reference/branching-strategies.md)

## Workflow

1. **Detect the instruction file.** Check for these files in the project root, in order:
   - `CLAUDE.md`
   - `AGENTS.md`
   - `.claude/CLAUDE.md`
   - `.github/AGENTS.md`

   If none exist, create `CLAUDE.md` in the project root.

2. **Read the existing file content.** Check whether each configuration block already exists
   by looking for the HTML comment markers:
   - `<!-- skrrt:ship -->` — the skills block
   - `<!-- skrrt:branching -->` — the branching strategy block

3. **Append the skills block** if the `<!-- skrrt:ship -->` marker is not present. Use the
   exact block from the "Skills Configuration Block" section below.

4. **Select a branching strategy.** If the `<!-- skrrt:branching -->` marker is not present:
   a. Read the reference file `reference/branching-strategies.md` to understand each strategy.
   b. **Always ask the user** which branching strategy they want. Present these three options
      with a brief one-liner for each:
      - **GitHub Flow** (recommended) — `main` + short-lived branches, PRs, tags for releases.
        The default for most projects.
      - **Trunk-Based Development** — `main` + short-lived branches < 2 days, feature
        flags, tags for releases. For fast-paced projects with mature CI/CD.
      - **Gitflow** — `main` + `develop` + `release/*` + `hotfix/*`. For plugins/skills where
        consumers fetch latest `main`, or projects needing release stabilization.
   c. After the user chooses, append the matching branching strategy block from the
      "Branching Strategy Blocks" section below.

   If the marker already exists, detect which strategy is configured by reading the heading
   line immediately after the marker — it contains the strategy name (e.g.,
   `## Branching strategy — GitHub Flow`). Tell the user which strategy is set and offer to
   replace it if they want a different one.

5. **Report what you did.** Summarize which file was updated and which blocks were added.

## Skills Configuration Block

Append exactly this block (preserve the HTML comment marker):

```markdown
<!-- skrrt:ship -->
## Git workflow — skrrt skills

Use the installed skrrt skills for all git shipping operations:

- **Commits**: Use `/commit` to stage changes and write conventional commits with gitmojis.
- **Pull requests**: Use `/pr` to push branches and open PRs or MRs with the matching forge CLI.
- **Releases**: Use `/release` to draft release notes and publish releases.

Do not write raw `git commit`, `gh pr create`, `gh release create`, `glab mr create`, or
`glab release create` commands manually when these skills are available.
```

## Branching Strategy Blocks

Append exactly one of these blocks based on the user's choice.

### GitHub Flow

```markdown
<!-- skrrt:branching -->
## Branching strategy — GitHub Flow

This project uses **GitHub Flow**. All agents and contributors must follow these rules:

### Branch rules

- `main` is the only long-lived branch and is always deployable.
- All work happens on short-lived, descriptively named branches.
- Never commit directly to `main` — all changes reach `main` through a pull request.
- PRs always target `main`.
- Feature branches must be up to date with `main` before merging.
- Feature branches are deleted after merge.
- CI runs on every PR.
- Releases are cut by tagging commits on `main`.
- Do not create `develop`, `release/*`, or `hotfix/*` branches.

### Branch naming

Use `<type>/<short-description>` with lowercase and hyphens:
- Features: `feat/add-auth`, `feat/search-index`
- Fixes: `fix/login-redirect`, `fix/null-check`
- Other: `docs/api-guide`, `chore/update-deps`, `refactor/auth-module`

### Keeping branches up to date (Skrrt convention)

- Before opening a PR, rebase the feature branch onto `main`: `git pull --rebase origin main`
- If the rebase has conflicts, resolve them and run `git rebase --continue`.
- If the rebase cannot be resolved cleanly, abort with `git rebase --abort` and ask the user for help.

### PR merge strategy (Skrrt convention)

- Use **squash merge** — each PR becomes one clean commit on `main`.
- This keeps `main` history linear: one commit = one PR = one logical change.

### Agent lifecycle (full auto)

1. Create a branch from `main`: `git switch -c <type>/<description>`
2. Make changes and commit using `/commit`.
3. Before opening a PR, rebase onto `main`: `git pull --rebase origin main`
4. Push and open a PR using `/pr` — target is always `main`.
5. After squash merge, the branch is deleted automatically by the forge.
6. To release, tag a commit on `main` using `/release`.
<!-- /skrrt:branching -->
```

### Trunk-Based Development

```markdown
<!-- skrrt:branching -->
## Branching strategy — Trunk-Based Development

This project uses **Trunk-Based Development**. All agents and contributors must follow these rules:

### Branch rules

- `main` is the only long-lived branch.
- Agents always use short-lived branches with PRs — never commit directly to `main`.
- Short-lived branches last at most 2 days, ideally less than 1 day.
- One developer or agent per short-lived branch.
- CI runs on every commit to `main` — broken builds are highest priority.
- Feature flags hide incomplete work and control rollout.
- No code freezes, no integration phases.
- PRs always target `main`.
- Releases are cut by tagging commits on `main`; CI/CD deployment is triggered by tags.
- Just-in-time `release/*` branches may be cut from `main` when needed; fixes go to `main` first, then cherry-pick to the release branch.
- Do not create `develop` or `hotfix/*` branches.
- **Skrrt convention:** No more than 3 active branches at any time.

### Branch naming

Use `<type>/<short-description>` with lowercase and hyphens:
- Features: `feat/add-auth`, `feat/search-index`
- Fixes: `fix/login-redirect`, `fix/null-check`
- Other: `docs/api-guide`, `chore/update-deps`, `refactor/auth-module`

### Keeping branches up to date

- Short-lived branches should rarely need syncing — if they diverge, the branch has lived too long.
- If the forge requires the branch to be up to date, sync with `git pull origin main`.

### PR merge strategy

- Respect the repository's configured merge strategy in the forge settings.
- TBD has no strong opinion on merge strategy — branches are so short-lived it rarely matters.

### Agent lifecycle (full auto)

1. Create a branch from `main`: `git switch -c <type>/<description>`
2. Make small, incremental changes and commit using `/commit`.
3. Push and open a PR using `/pr` — target is always `main`.
4. After PR merge, the branch is deleted automatically by the forge.
5. To release, tag a commit on `main` using `/release`.
<!-- /skrrt:branching -->
```

### Gitflow

```markdown
<!-- skrrt:branching -->
## Branching strategy — Gitflow

This project uses **Gitflow**. All agents and contributors must follow these rules:

### Branch rules

- `main` reflects the current live/distributed version — every commit on `main` is a release.
- `develop` is the integration branch for ongoing work.
- Never commit directly to `main` — it only receives merges from `release/*` or `hotfix/*`.
- Never commit directly to `develop` except for release preparation — features come through feature branch PRs.
- Feature branches branch from `develop` and merge back to `develop` via PR.
- PRs for features always target `develop`, never `main`.
- `release/*` branches are cut from `develop` for stabilization — only bug fixes, version bumps, and release tasks are allowed; new features are prohibited.
- `release/*` branches merge to both `main` and `develop` when stabilization is complete.
- `hotfix/*` branches are cut from `main` for critical fixes, merged back to both `main` and `develop`.
- If a `release/*` branch exists when a hotfix lands, merge the hotfix into the release branch instead of `develop`.
- Tags on `main` are mandatory — every merge to `main` is immediately tagged.
- All merges to `main` and `develop` use `--no-ff`.

### Branch naming

- Features: `feat/<short-description>` (e.g., `feat/add-auth`, `feat/search-index`)
- Releases: `release/<version>` (e.g., `release/1.2.0`)
- Hotfixes: `hotfix/<version-or-description>` (e.g., `hotfix/1.2.1`, `hotfix/fix-crash`)

### Keeping branches up to date

- If the feature branch needs to be up to date with `develop`, sync with `git pull origin develop`.
- Do not rebase any branch — Gitflow relies on merge commits to preserve branch topology.

### PR merge strategy

- Always use **merge commits** (`--no-ff`) for all merges into `main` and `develop`.
- Do not squash or rebase merge — Gitflow requires visible merge points to preserve branch history.
- The forge's merge strategy should be configured to use merge commits only.

### Agent lifecycle — features (full auto)

1. Switch to `develop`: `git switch develop && git pull`
2. Create a feature branch: `git switch -c feat/<description>`
3. Make changes and commit using `/commit`.
4. Push and open a PR using `/pr` — target is `develop`.
5. After PR merge (`--no-ff`), the feature branch is deleted.

### Agent lifecycle — releases (full auto)

1. Cut a release branch from `develop`: `git switch develop && git pull && git switch -c release/<version>`
2. Perform stabilization (bug fixes, version bumps) and commit using `/commit`.
3. When stable, open a PR from `release/<version>` to `main` using `/pr`.
4. After PR merge (`--no-ff`), tag the merge commit: use `/release` to create the tag and release notes.
5. Open a PR from `release/<version>` to `develop` using `/pr` to sync the stabilization changes back.
6. After PR merge, the release branch is deleted by the forge.

### Agent lifecycle — hotfixes (full auto)

1. Cut a hotfix branch from `main`: `git switch main && git pull && git switch -c hotfix/<description>`
2. Fix the issue and commit using `/commit`.
3. Open a PR from `hotfix/<description>` to `main` using `/pr`.
4. After PR merge (`--no-ff`), tag the merge commit: use `/release` to create the tag and release notes.
5. Check for an active release branch: `git branch --list 'release/*'`
   - If a `release/*` branch exists: open a PR from `hotfix/<description>` to `release/<version>` using `/pr`.
   - If no `release/*` branch exists: open a PR from `hotfix/<description>` to `develop` using `/pr`.
6. After PR merge, the hotfix branch is deleted by the forge.
<!-- /skrrt:branching -->
```

## Replacing an Existing Branching Strategy

If the user wants to change the branching strategy:

1. Find the existing `<!-- skrrt:branching -->` block.
2. Identify its end — the block ends at the `<!-- /skrrt:branching -->` end marker.
3. Replace everything between the start and end markers (inclusive) with the new strategy block.
4. Report the change.

## Guardrails

- Never overwrite or reformat existing content in the instruction file outside of the skrrt blocks.
- Never remove existing instructions that are not part of a skrrt block.
- Only append new blocks; do not insert in the middle of the file (except when replacing a branching block).
- If a marker already exists, do not duplicate its block.
- Do not create files other than the instruction file.
- Always ask the user to choose a branching strategy — never auto-select.
- Present all three options with their one-liner descriptions so the user can make an informed choice.

## Task

Handle this request: $ARGUMENTS

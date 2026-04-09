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

Before recommending a branching strategy, read:

- [reference/branching-strategies.md](reference/branching-strategies.md) — branching models,
  project analysis signals, tagging and environment strategy, CI/CD trigger patterns

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

4. **Analyze the project and recommend a branching strategy.** If the `<!-- skrrt:branching -->`
   marker is not present:
   a. Read the reference file `reference/branching-strategies.md` — especially the
      "Project Analysis Signals" section.
   b. **Gather signals from the project.** Run the checks described in the reference to
      understand the project's current state:
      - Check for `develop`, `release/*`, `hotfix/*` branches (local and remote).
      - Check for CI/CD configuration files.
      - Check for feature flag infrastructure.
      - Check git log for contributor count, deployment frequency (tags/releases), and
        whether `develop` is actively used or abandoned.
      - Check if the project is a plugin, skill, or library where consumers track `main`.
      - Check for long-lived unmerged branches.
   c. **Make a tailored recommendation** based on the signals. Follow the recommendation
      logic in the reference. Explain your reasoning — tell the user which signals you
      found and why they point to the recommended strategy.
   d. **If the project currently uses a different strategy** (e.g., has a `develop` branch
      but you recommend GitHub Flow), explain what migration would involve and why the
      switch is worth it. Do not recommend preserving a strategy just because it is
      already in use.
   e. **Present the recommendation to the user** with all three options visible, but mark
      your recommended option. The user always has the final say. Present:
      - Your recommended strategy with reasoning (marked as recommended).
      - The other two strategies with their one-liners for context.
   f. After the user chooses, append the matching branching strategy block from the
      "Branching Strategy Blocks" section below.

   If the marker already exists, detect which strategy is configured by reading the heading
   line immediately after the marker — it contains the strategy name (e.g.,
   `## Branching strategy — GitHub Flow`). Tell the user which strategy is set and offer to
   replace it if they want a different one.

5. **Configure environment tiers.** After appending the branching strategy block:
   a. The default environment tiers (dev, staging, production) are already included in
      each strategy block. Tell the user about the default tier model.
   b. Ask the user if they have additional environments beyond the default three
      (e.g., QA, UAT, pre-prod). If yes, note the custom environments — the tagging
      convention supports them via `vX.Y.Z-{env}.N` labels.
   c. If the user has custom environments, mention that their CI/CD pipelines should
      parse the tag suffix to determine the deployment target (see the reference file
      for CI pattern matching examples).
   d. Do not modify the strategy block for custom environments — the block already
      describes the extension pattern. Custom environment CI configuration is the
      user's responsibility.

6. **Report what you did.** Summarize which file was updated, which blocks were added, and
   the configured environment model (default tiers or custom tiers noted).

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

### Deployment conventions (Skrrt)

These rules apply regardless of branching strategy:

- **Tag format:** `vX.Y.Z` (production), `vX.Y.Z-rc.N` (release candidate), `vX.Y.Z-{env}.N` (custom tier). Always use annotated tags.
- **Tags are immutable.** Never delete or move a tag. If a release is bad, cut a new patch version.
- **Build once, promote the same artifact.** The artifact tested in staging must be identical to what reaches production. Never rebuild from a tag.
- **Lower environments do not need tags.** Dev deploys from branch HEAD on merge. Preview environments are per-PR and SHA-scoped.
- **Manual `workflow_dispatch`** can promote an existing artifact to any environment. It complements the tag-driven flow, not replaces it.
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

### Tagging and environment (Skrrt convention)

Tags are placed **on `main` only** — never on feature branches. See shared deployment conventions above.

| Environment | Trigger | Tag? |
| --- | --- | --- |
| Dev | Merge to `main` (squash merge) | No |
| Staging | Tag `vX.Y.Z-rc.N` on `main` | Yes |
| Production | Tag `vX.Y.Z` on `main` | Yes |

- Promote to staging by tagging an RC on `main`. If it fails, merge fixes via PR and tag a new RC.
- Promote to production by tagging a clean semver release on the validated commit.

### Agent lifecycle (full auto)

1. Create a branch from `main`: `git switch -c <type>/<description>`
2. Make changes and commit using `/commit`.
3. Before opening a PR, rebase onto `main`: `git pull --rebase origin main`
4. Push and open a PR using `/pr` — target is always `main`.
5. After squash merge, the branch is deleted automatically by the forge.
6. To promote to staging, tag an RC on `main`: use `/release` with a pre-release tag.
7. After staging validation, tag the production release on `main`: use `/release`.
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

### Tagging and environment (Skrrt convention)

Tags are placed **on `main` only**. Deploy ≠ Release — feature flags control rollout independently. See shared deployment conventions above.

- **Cadence determines tagging:**
  - High cadence (multiple deploys/day): tagging is optional — every merge to `main` may go straight to production.
  - Medium cadence (weekly/monthly): use RC and release tags to mark promotion milestones.

| Environment | Trigger | Tag? |
| --- | --- | --- |
| Dev | Merge to `main` | No |
| Staging | Tag `vX.Y.Z-rc.N` on `main` | Yes (medium cadence) |
| Production | Tag `vX.Y.Z` on `main` | Yes (medium cadence) |

- Just-in-time `release/*` branches, if used, may carry their own RC tags.
- Fixes for release branches: reproduce on `main`, fix on `main`, cherry-pick to the release branch. Never fix on the release branch first.

### Agent lifecycle (full auto)

1. Create a branch from `main`: `git switch -c <type>/<description>`
2. Make small, incremental changes and commit using `/commit`.
3. Push and open a PR using `/pr` — target is always `main`.
4. After PR merge, the branch is deleted automatically by the forge.
5. **If using tag-based promotions** (medium cadence): tag an RC on `main` using `/release` with a pre-release tag, then after staging validation, tag the production release using `/release`.
6. **If using continuous deployment** (high cadence): merge to `main` is the production deploy — no tags needed.
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

### Tagging and environment (Skrrt convention)

See shared deployment conventions above. Gitflow has strategy-specific tag placement:

- **Production tags** (`vX.Y.Z`) go on `main` only, at the merge commit from `release/*` or `hotfix/*`. Every merge to `main` is immediately tagged — mandatory.
- **RC tags** (`vX.Y.Z-rc.N`) go on `release/*` branches during stabilization. This is the only exception to the main-only rule. RCs mark validation milestones but do not trigger separate deploys.
- **Custom env tags** (`vX.Y.Z-{env}.N`) in Gitflow go on `release/*` branches as milestone labels.

| Environment | Trigger | Tag? |
| --- | --- | --- |
| Dev | Merge to `develop` | No |
| Staging | Push to `release/*` branch | No (branch-triggered) |
| Production | Tag `vX.Y.Z` on `main` | Yes |

- `develop` auto-deploys to dev — the integration environment.
- `release/*` deploys to staging on every push. The release branch IS the staging gate.
- `hotfix/*` may deploy to staging for validation before merging to `main`.

### Agent lifecycle — features (full auto)

1. Switch to `develop`: `git switch develop && git pull`
2. Create a feature branch: `git switch -c feat/<description>`
3. Make changes and commit using `/commit`.
4. Push and open a PR using `/pr` — target is `develop`.
5. After PR merge (`--no-ff`), the feature branch is deleted.

### Agent lifecycle — releases (full auto)

1. Cut a release branch from `develop`: `git switch develop && git pull && git switch -c release/<version>`
2. Perform stabilization (bug fixes, version bumps) and commit using `/commit`.
3. Optionally tag RC milestones on the release branch: `v1.2.3-rc.1` (marks a validation checkpoint; staging deploys are branch-triggered, not tag-triggered).
4. When stable, open a PR from `release/<version>` to `main` using `/pr`.
5. After PR merge (`--no-ff`), tag the merge commit: use `/release` to create the tag (`vX.Y.Z`) and release notes.
6. Open a PR from `release/<version>` to `develop` using `/pr` to sync the stabilization changes back.
7. After PR merge, the release branch is deleted by the forge.

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
- Always analyze the project before recommending a branching strategy — never use a static default.
- Always present the recommendation with reasoning, but let the user make the final choice.
- Never recommend preserving a strategy solely because it is already in use — recommend what is best for the project now.
- Present all three options so the user can override the recommendation if they disagree.

## Task

Handle this request: $ARGUMENTS

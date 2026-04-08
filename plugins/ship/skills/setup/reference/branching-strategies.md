# Branching Strategies Reference

> Actionable rules for each branching strategy. The setup skill reads this file to generate
> the correct CLAUDE.md configuration block for the chosen strategy.

## GitHub Flow (Recommended Default)

**Branch model:** `main` + short-lived feature branches.

**Rules for agents:**

- `main` is the only long-lived branch and is always deployable.
- Never commit directly to `main` — all changes reach `main` through a pull request.
- All work happens on short-lived branches named `<type>/<description>` (e.g., `feat/add-auth`,
  `fix/login-redirect`).
- PRs always target `main`.
- Feature branches must be up to date with `main` before merging.
- Feature branches are deleted after merge.
- CI runs on every PR.
- Releases are cut by tagging commits on `main`.
- Do not create `develop`, `release/*`, or `hotfix/*` branches.

**Branch update strategy:** Rebase onto `main` before PR (`git pull --rebase origin main`).
**PR merge strategy:** Squash merge — one PR = one clean commit on `main`.

**Agent lifecycle:** branch from `main` → commit → rebase onto `main` → PR to `main` →
squash merge → tag for release.

**When to recommend:** Default for most projects. Works for solo and team workflows, including
agentic development.

## Trunk-Based Development

**Branch model:** `main` + short-lived branches (< 2 days).

**Rules for agents:**

- `main` is the only long-lived branch.
- Agents always use short-lived branches with PRs — never commit directly to `main`.
- Short-lived branches named `<type>/<description>` last at most 2 days, ideally less than 1 day.
- One developer or agent per short-lived branch.
- CI runs on every commit to `main` — broken builds are highest priority.
- Feature flags hide incomplete work and control rollout.
- No code freezes, no integration phases.
- PRs always target `main`.
- Releases are cut by tagging commits on `main`; CI/CD deployment is triggered by tags.
- Just-in-time `release/*` branches may be cut from `main` when needed; fixes go to `main`
  first, then cherry-pick to the release branch. These are short-lived, not long-lived.
- Do not create `develop` or `hotfix/*` branches.
- **Skrrt convention:** No more than 3 active branches at any time.

**Branch update strategy:** Short-lived branches rarely need syncing. If needed, `git pull origin main`.
**PR merge strategy:** Respect the repository's configured forge setting. No strong opinion —
branches are so short-lived it rarely matters.

**Agent lifecycle:** branch from `main` → small commits → PR to `main` → merge → tag for release.

**When to recommend:** Fast-paced projects with feature flag infrastructure and mature CI/CD.

## Gitflow

**Branch model:** `main` + `develop` + `release/*` + `hotfix/*` + feature branches.

**Rules for agents:**

- `main` reflects the current live/distributed version — every commit on `main` is a release.
- `develop` is the integration branch for ongoing work.
- Never commit directly to `main` — it only receives merges from `release/*` or `hotfix/*`.
- Never commit directly to `develop` except for release preparation — features come through
  feature branch PRs.
- Feature branches (`feat/<description>`) branch from `develop` and merge to `develop` via PR.
- `release/<version>` branches are cut from `develop` for stabilization — only bug fixes, version
  bumps, and release tasks are allowed; new features are prohibited.
- `release/*` branches merge to both `main` and `develop` when stabilization is complete.
- `hotfix/<description>` branches are cut from `main` for critical fixes, merged back to both
  `main` and `develop`.
- If a `release/*` branch exists when a hotfix lands, merge the hotfix into the release branch
  instead of `develop`.
- Tags on `main` are mandatory — every merge to `main` is immediately tagged.
- All merges to `main` and `develop` use `--no-ff`.

**Branch update strategy:** Sync feature branches with `git pull origin develop` if needed.
Never rebase — Gitflow relies on merge commits to preserve branch topology.
**PR merge strategy:** Always `--no-ff` merge commits into `main` and `develop`. Never squash
or rebase merge — Gitflow requires visible merge points.

**Agent lifecycle — features:** branch from `develop` → commit → PR to `develop` → `--no-ff` merge.
**Agent lifecycle — releases:** `release/*` from `develop` → stabilize → PR to `main` (`--no-ff`)
+ tag → PR back to `develop` (`--no-ff`).
**Agent lifecycle — hotfixes:** `hotfix/*` from `main` → fix → PR to `main` (`--no-ff`) + tag
→ PR to `develop` or active `release/*` (`--no-ff`).

**When to recommend:** Plugins/skills where consumers fetch latest `main` (no tag pinning),
projects needing explicit release stabilization, parallel release tracks, or regulatory gates.

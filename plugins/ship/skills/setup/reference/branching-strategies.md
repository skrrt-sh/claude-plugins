# Branching Strategies Reference

> Actionable rules for each branching strategy. The setup skill reads this file to generate
> the correct CLAUDE.md configuration block for the chosen strategy.

## Project Analysis Signals

Before recommending a strategy, gather these signals from the project. Not all signals will
be present — use what is available and weight accordingly.

### Signals to gather

| Signal | How to check | What it suggests |
| --- | --- | --- |
| `develop` branch exists | `git branch -a \| grep develop` | Legacy Gitflow — but check if it is *actively used* (recent commits) or abandoned. An abandoned `develop` is not a reason to recommend Gitflow. |
| `release/*` or `hotfix/*` branches exist | `git branch -a \| grep -E 'release/\|hotfix/'` | Active Gitflow usage — but only if recent. Old, merged branches are historical artifacts. |
| Release stabilization pattern | Multiple commits on `release/*` branches (bug fixes, version bumps between cut and merge) | Project needs a stabilization phase → Gitflow or careful GitHub Flow with RC tags. |
| Consumers fetch latest `main` (plugin, skill, library without version pinning) | Check if the project is a plugin, skill, or library where downstream consumers track `main` directly | `main` must always be release-quality. GitHub Flow and TBD both guarantee this. Gitflow adds an extra gate via `release/*` stabilization — only recommend it if the project also needs that stabilization phase. |
| CI/CD pipeline exists | Look for `.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`, etc. | Mature CI enables TBD; absence suggests GitHub Flow is safer. If no CI exists, recommend GitHub Flow and treat environment tables as target-state goals — auto-deploy behavior requires CI to be set up first. |
| Feature flag infrastructure | Look for feature flag config files, SDKs (LaunchDarkly, Unleash, GrowthBook, custom) | Feature flags enable TBD — incomplete work can be hidden behind flags. |
| Solo contributor or very small team | Check git log for number of distinct authors | Solo/small → GitHub Flow or TBD; Gitflow overhead is rarely justified. |
| Monorepo or multi-package | Check for `packages/`, `apps/`, workspace config | Monorepos often benefit from TBD with short-lived branches. Note: the `vX.Y.Z` tagging convention assumes a single release unit. For monorepos with independent service versions, define per-service tag prefixes (e.g., `api/v1.2.3`, `web/v1.0.0`) or use release tooling (changesets, lerna, release-please) before applying this convention. |
| Deployment frequency | Check tags/releases — frequent (daily/weekly) vs. infrequent (monthly+) | Frequent → TBD or GitHub Flow; Infrequent → GitHub Flow or Gitflow. |
| Long-lived feature branches | Check for old unmerged branches | Sign of problematic workflow — recommend moving toward shorter branches (TBD or GitHub Flow). |

### Recommendation logic

1. **Default recommendation: GitHub Flow.** It works for most projects, solo or team, and has
   the lowest overhead.

2. **Upgrade to TBD when:** The project has mature CI/CD, feature flag infrastructure, and a
   fast deployment cadence. TBD is GitHub Flow with stricter discipline — it is not a different
   model, just a tighter one.

3. **Recommend Gitflow only when:** The project has a genuine need for release stabilization
   (multiple stabilization commits between cut and merge) AND cannot achieve release quality
   through CI gating alone. Note: GitHub Flow and TBD also keep `main` deployable — Gitflow's
   advantage is the dedicated stabilization branch, not `main` quality per se.

4. **Recommend migrating away from Gitflow when:** The project has a `develop` branch but
   does not actively use release stabilization, has few contributors, or has a simple
   deployment model. In this case, note what migration involves (merge `develop` into `main`,
   delete `develop`, update any CI that references `develop`).

5. **Never recommend Gitflow solely because `develop` exists.** A `develop` branch is a
   signal to investigate, not a reason to perpetuate the strategy.

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

**When to recommend:** Projects needing explicit release stabilization (dedicated branch for
bug fixes and version bumps before production), parallel release tracks, or regulatory gates
that require a formal pre-release phase.

## Tagging and Environment Strategy (Skrrt Convention)

This section defines the Skrrt convention for tagging, environment promotion, and CI/CD
deployment layered on top of each branching strategy. These conventions are informed by
industry best practices but are not canonical parts of GitHub Flow, TBD, or Gitflow
themselves — they are an opinionated overlay that the setup skill applies to all strategies
for consistency.

### Core Principles

1. **Deploy ≠ Release.** Deployment pushes code to an environment. Release makes functionality
   visible to users. Feature flags bridge the gap — code can be deployed to production without
   being released.

2. **Build once, promote the same artifact.** The artifact tested in staging must be the exact
   artifact deployed to production. Rebuilding from a tag risks subtle differences. Promote
   artifacts (container images, binaries) by content-addressable identity (SHA/checksum), not
   by rebuilding from source.

3. **Tags are immutable.** Never delete and re-create a tag. If a release is bad, cut a new
   patch version. Moving tags breaks reproducibility, confuses registries, and destroys
   audit trails.

4. **Tag format is consistent.** Use one format across the entire project. Mixed formats
   break CI pattern matching, changelog generators, and sorting.

5. **Lower environments do not need tags.** Dev/preview environments deploy automatically
   from branch HEAD or merge events. Only milestone promotions (staging, production) need
   tags. This keeps the tag namespace clean.

### Tag Format Specification

All tags follow SemVer 2.0.0 with a `v` prefix:

```
v{MAJOR}.{MINOR}.{PATCH}[-{label}.{n}]
```

| Tag | Meaning | Example |
| --- | --- | --- |
| `vX.Y.Z` | Production release | `v1.2.3` |
| `vX.Y.Z-rc.N` | Release candidate (staging) | `v1.2.3-rc.1` |
| `vX.Y.Z-{env}.N` | Custom environment promotion | `v1.2.3-qa.1`, `v1.2.3-uat.2` |

Rules:
- Always use **annotated tags** (`git tag -a`), which store tagger, date, and message.
- The `v` prefix is mandatory — it is the dominant convention across Go modules, npm, GitHub
  Releases, and most CI tooling.
- Pre-release labels use lowercase and dot separators: `-rc.1`, `-qa.2`, `-uat.1`.
- Do not use underscores, uppercase, or non-standard separators (`_rc1`, `-RC.1`, `-STAGING`).
- SemVer precedence: `v1.2.3-rc.1 < v1.2.3-rc.2 < v1.2.3` (pre-releases sort before the
  associated release).

### Environment Tiers

The default model has three tiers. Projects may add custom tiers between staging and
production (see "Custom Environments" below).

| Tier | Purpose | Trigger | Tag required? |
| --- | --- | --- | --- |
| **Dev** | Integration testing, latest merged code | Merge to `main` (or `develop` for Gitflow) | No — deploy from HEAD automatically |
| **Staging** | Pre-production validation, QA, UAT | Strategy-specific (see notes) | Depends on strategy |
| **Production** | Live/end-user traffic | Tag `vX.Y.Z` pushed | Yes |

Notes:
- **Preview/ephemeral environments** (per-PR) are triggered by PR events, not tags. They use
  the commit SHA as identifier and are destroyed when the PR closes.
- Dev deploys on every merge to the integration branch. No human action needed.
- Staging deploys when an RC tag is pushed (GitHub Flow, TBD) or when code is pushed to a
  `release/*` branch (Gitflow — the release branch IS the staging gate). See per-strategy
  rules below for the exact trigger.
- Production deploys when a clean semver tag is pushed. This is the final promotion.

### Per-Strategy Tagging Rules

#### GitHub Flow

- Tags are placed **on `main`** only. Never tag feature branches.
- After squash-merging a PR, the resulting commit on `main` auto-deploys to dev.
- When ready to promote to staging: `git tag -a v1.2.3-rc.1 -m "RC1 for v1.2.3"` on a `main`
  commit.
- After staging validation: `git tag -a v1.2.3 -m "Release v1.2.3"` on the same commit (or a
  later one if fixes landed).
- If an RC fails staging, merge fixes via PR, then tag a new RC (`-rc.2`) on the new `main` HEAD.
- Multiple RCs are expected and normal — they are not a sign of failure.
- Hotfixes follow the same flow: branch → PR → squash merge → RC tag → prod tag.

#### Trunk-Based Development

- Tags are placed **on `main`** only.
- At high deployment cadence (multiple deploys/day), tagging is optional — every merge to
  `main` may go straight to production. Paul Hammant: "you're probably not even tagging
  anymore."
- At medium cadence (weekly/monthly), tag on `main` for releases: `v1.2.3`.
- Just-in-time `release/*` branches, if used, may carry RC tags: `v1.2.3-rc.1`.
- Fixes for release branches: reproduce on `main`, fix on `main`, cherry-pick to the release
  branch. Never fix on the release branch first.
- Feature flags control rollout independently of deployment — code can be deployed to
  production with flags off, then released by enabling the flag.

#### Gitflow

- **Production tags** (`vX.Y.Z`) are placed on `main` only, at the merge commit where a
  `release/*` or `hotfix/*` branch is merged. Always annotated.
- **RC tags** (`vX.Y.Z-rc.N`) are placed on `release/*` branches during stabilization.
  These are the only exception to the main-only rule — RC tags mark staging milestones
  on the branch that is actively being hardened.
- Hotfix tags follow the production pattern: merge to `main`, tag immediately.
- Environment mapping:
  - `develop` → auto-deploys to **dev**.
  - `release/*` → deploys to **staging**. The release branch IS the staging gate.
    Staging deploys are triggered by pushes to `release/*` branches; RC tags mark
    specific validation milestones within that deployment.
  - `main` (tagged `vX.Y.Z`) → deploys to **production**.
  - `hotfix/*` → may deploy to staging for validation before merging to `main`.

### Custom Environments

Projects with more than three tiers (e.g., dev, QA, staging, UAT, production) extend the
model by adding pre-release labels:

```
v1.2.3-qa.1     → deploys to QA
v1.2.3-uat.1    → deploys to UAT
v1.2.3-rc.1     → deploys to staging
v1.2.3          → deploys to production
```

Rules for custom environments:
- Each environment gets a unique lowercase label.
- Labels sort lexically, so choose names that reflect promotion order when possible
  (or rely on CI pattern matching rather than sort order).
- Dev remains tag-free (auto-deploy from HEAD).
- Production always uses clean semver (no pre-release suffix).
- Keep the number of tagged tiers minimal — every tagged tier adds process overhead.
  Most projects need at most one pre-production tag tier (RC for staging).
- If the project needs more than 4 tagged tiers, consider whether the environments are
  genuinely distinct or could be consolidated.

### CI/CD Trigger Patterns

CI workflows should respond to these events:

| Event | Action | Environment | Strategies |
| --- | --- | --- | --- |
| PR opened/updated | Run tests, lint, build | Preview (ephemeral, optional) | All |
| Merge to integration branch (`main` or `develop`) | Run tests, build, deploy | Dev | All |
| Push to `release/*` branch | Build, deploy | Staging | Gitflow only |
| Tag `vX.Y.Z-rc.N` pushed | Build (or promote artifact), deploy | Staging | GitHub Flow, TBD |
| Tag `vX.Y.Z-{env}.N` pushed | Build (or promote artifact), deploy | Custom tier | All |
| Tag `vX.Y.Z` pushed (no pre-release suffix) | Promote artifact, deploy | Production | All |
| Manual `workflow_dispatch` | Promote artifact, deploy | Any (operator chooses) | All |

Example CI pattern matching (GitHub Actions):

Example uses GitHub Actions globs; adapt for other CI platforms.

```yaml
on:
  push:
    tags:
      - 'v[0-9]*.[0-9]*.[0-9]*'          # prod: v1.2.3
      - 'v[0-9]*.[0-9]*.[0-9]*-rc.*'     # staging: v1.2.3-rc.1
      - 'v[0-9]*.[0-9]*.[0-9]*-*'        # any pre-release

jobs:
  deploy:
    steps:
      - name: Determine environment
        run: |
          TAG=${GITHUB_REF#refs/tags/}
          if [[ "$TAG" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "environment=production" >> $GITHUB_OUTPUT
          elif [[ "$TAG" =~ -rc\. ]]; then
            echo "environment=staging" >> $GITHUB_OUTPUT
          else
            # Extract custom env label: v1.2.3-qa.1 → qa
            LABEL=$(echo "$TAG" | sed 's/v[0-9]*\.[0-9]*\.[0-9]*-\([a-z]*\)\..*/\1/')
            echo "environment=$LABEL" >> $GITHUB_OUTPUT
          fi
```

For **manual deployment** (`workflow_dispatch`):

```yaml
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Target environment'
        required: true
        type: choice
        options: [dev, staging, production]
      release_comment:
        description: 'Comment about this deployment'
        required: false
        type: string

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: ${{ inputs.environment }}
    steps:
      - name: Deploy
        # Deploy the artifact at the current commit to the chosen environment.
        # The same build-once-promote-same-artifact rule applies —
        # this triggers a promotion, not a rebuild.
```

Manual dispatch is useful for:
- Promoting a specific commit to an environment outside the normal tag flow.
- Hotfix validation on staging before tagging.
- Environments that do not map to a tag label (e.g., internal demo, load-test).
- Recovery — redeploying a known-good commit after a rollback.

Manual dispatch does not replace the tag-driven flow — it complements it. Production
releases should still be tagged for auditability. Use dispatch for operational flexibility,
not as the primary deployment mechanism.

For **artifact promotion** (build once, deploy many):

```yaml
# Build job: triggered by merge to main
build:
  outputs:
    artifact-sha: ${{ steps.build.outputs.sha }}

# Staging: triggered by RC tag, uses the pre-built artifact
deploy-staging:
  needs: build
  environment: staging
  # Deploy the exact artifact from the build job, not a rebuild

# Production: triggered by release tag, promotes the same artifact
deploy-production:
  needs: build
  environment: production
  # Same artifact SHA — no rebuild
```

### Tagging Anti-Patterns

| Anti-pattern | Why it is harmful | What to do instead |
| --- | --- | --- |
| Environment branches (`deploy/staging`, `deploy/prod`) | Branches drift apart; "works in staging" ≠ "works in prod." Violates build-once-deploy-many. | Promote the same artifact through environments using tags or pipeline stages. |
| Moving or re-creating tags | Breaks reproducibility, confuses caches and registries, destroys audit trail. | Release a new patch version (`v1.2.1`). Tags are permanent. |
| Inconsistent tag formats (`v1.2.3`, `1.2.3`, `release-1.2.3`) | Breaks CI pattern matching, sorting, and changelog tooling. | Enforce one format: `vX.Y.Z[-label.N]`. Validate in CI. |
| Tagging unreviewed code (from feature branches) | Creates releases from untested code. | Only tag from `main` (or `release/*` branches for Gitflow RCs). |
| Manual tagging without automation | Human error in tag creation is common. | Use `/release` skill or CI-driven release workflows. |
| Tagging every environment | Tag namespace becomes noisy and unmanageable. | Only tag milestone promotions (staging, production). Use merge events for dev. |

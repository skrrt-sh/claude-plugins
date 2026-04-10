<!-- skrrt:ship -->
## Git workflow — skrrt skills

Use the installed skrrt skills for all git shipping operations:

- **Commits**: Use `/commit` to stage changes and write conventional commits with gitmojis.
- **Pull requests**: Use `/pr` to push branches and open PRs or MRs with the matching forge CLI.
- **Releases**: Use `/release` to draft release notes and publish releases.

Outside these skill workflows, do not manually author raw `git commit`, `gh pr create`,
`gh release create`, `glab mr create`, or `glab release create` commands. Within a skill,
use its allowed command subset.

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

### Branch guard

Before any shipping operation (`/commit`, `/pr`), check the current branch with
`git branch --show-current`. If on `main`, create a short-lived branch first:

```bash
git switch -c <type>/<description>
```

Never commit directly to `main`. This check is automatic — do not ask the user to
create the branch manually.

### Agent lifecycle (full auto)

1. Verify you are on a short-lived branch (see "Branch guard" above).
2. Make small, incremental changes and commit using `/commit`.
3. Push and open a PR using `/pr` — target is always `main`.
4. After PR merge, the branch is deleted automatically by the forge.
5. To release, tag a commit on `main` using `/release`.

### Correlated PRs

When a feature spans multiple repositories in a workspace or multiple apps/services
inside a monorepo, the resulting PRs form a **correlated set**. All PRs in the set
must reference each other:

- Add a `## Related PRs` section to each PR description listing every sibling PR
  with its repo, number, and a short label. Use the correct forge format:
  GitHub `owner/repo#N`, GitLab `group/project!N`.
- Mark dependency direction when merge order matters. Use `depends on` for PRs that
  must merge first and `required by` for PRs that depend on this one.
- If no strict ordering exists, mark them as `related to`.
- Keep the related-PRs section updated as new PRs are opened or existing ones merge.

### PR follow-up

When the user reports problems after a PR was created, check the PR state before
making any fixes:

1. Run `gh pr view --json state` (or `glab mr view`) to determine if the PR is
   open, merged, or closed.
2. **If the PR is still open** — stay on (or switch to) the PR's source branch,
   commit fixes with `/commit`, and push. The existing PR updates automatically.
   Do not create a new PR.
3. **If the PR was merged** — switch to `main`, run `git pull origin main`, create
   a new short-lived branch from the updated `main`, apply fixes, and open a new
   PR with `/pr`. Do not attempt to reuse a branch that the forge already deleted.
4. **If the PR was closed without merge** — ask the user whether to reopen the
   existing branch or start a fresh one.

If the agent is on `main` when the user references a PR issue, identify the PR's
source branch first and switch to it (for open PRs) before making changes.
<!-- /skrrt:branching -->

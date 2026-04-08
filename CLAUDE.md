<!-- skrrt:ship -->
## Git workflow — skrrt skills

Use the installed skrrt skills for all git shipping operations:

- **Commits**: Use `/commit` to stage changes and write conventional commits with gitmojis.
- **Pull requests**: Use `/pr` to push branches and open PRs or MRs with the matching forge CLI.
- **Releases**: Use `/release` to draft release notes and publish releases.

Do not write raw `git commit`, `gh pr create`, `gh release create`, `glab mr create`, or
`glab release create` commands manually when these skills are available.

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

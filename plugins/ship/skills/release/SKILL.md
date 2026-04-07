---
name: release
description: Drafts and publishes GitHub or GitLab releases with curated release notes. Use when the agent needs to prepare release text, compare tags, summarize release changes, or create a release. Always use this skill when the user asks to create a release, draft release notes, publish a release, summarize changes for a version, update a changelog for a release, or anything involving GitHub or GitLab releases. Trigger for phrases like "release notes", "draft a release", "publish release", "create a release", "v1.x.x release", "what changed since last tag", or "prepare release text".
metadata:
  short-description: Draft release notes and publish releases safely
  argument-hint: "[release-goal]"
  user-invocable: true
---

# Git Release Skill

> Skill instructions for preparing release text and publishing releases with the matching forge CLI.

This skill is reserved for release work. Use it only when the user asks for a release, a release draft, or
release notes.

## Requirements

- `git` must be installed and available on `PATH`.
- `gh` is required for GitHub remotes.
- `glab` is required for GitLab remotes.
- If the matching CLI is missing, stop and tell the user exactly what is missing.
- When the project uses agent permission settings, prefer `permissions.ask` for
  mutating git and forge commands, including force-push variants.

## Forge Detection

Before any release command, run:

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/detect-forge-cli.sh"
```

Only continue when:

- `FORGE=github` and `MATCHED_CLI=gh`, or
- `FORGE=gitlab` and `MATCHED_CLI=glab`

If the repository forge and installed CLI do not match, stop and report the mismatch.

## Workflow

1. Run the forge detection script.
2. Inspect tags and commit history to identify the release range.
3. Check whether the repository has a changelog file such as `CHANGELOG.md`, `Changelog.md`, or `changelog.md`.
4. Summarize user-facing changes, fixes, and migration notes.
5. Draft release text in the required house format.
6. If a changelog file exists, update it for the new release before publishing.
7. Create the release with the matched CLI only after the text is ready.

## Git Command Subset

Stay within this `git` subset unless the user explicitly asks for more:

- `git tag --list`
- `git describe --tags --abbrev=0`
- `git log --oneline <range>`
- `git diff --stat <range>`
- `git remote get-url origin`
- `git diff --name-only <range>`

Stay within this file-discovery subset unless the user explicitly asks for more:

- `rg --files -g 'CHANGELOG*.md'`
- `rg --files -g 'changelog*.md'`

## CLI Command Subset

For GitHub with `gh`:

- `gh release create <tag> --title <title> --notes-file <file>`
- `gh release view <tag>`

For GitLab with `glab`:

- `glab release create <tag> --name <title> --notes-file <file>`
- `glab release view <tag>`

## Release Text Rules

- Make the title stable and version-oriented.
- Prefer a curated summary over raw commit logs.
- Group notable changes by theme using conventional-commit intent when possible.
- Include testing only if it is known.
- Include migration, rollout, or breaking-change notes when relevant.
- Add a compare link when the forge and previous tag are known.
- End the release text with the co-authorship line unless the user asks not to:
  `Co-Authored-By: Skrrt Bot <bot@skrrt.sh>`

Preferred structure:

```markdown
## What's Changed

### ✨ Features
- ...

### 🐛 Fixes
- ...

### ⚠️ Breaking Changes
- ...

### 🧰 Internal
- ...

**Full Changelog**: <compare link>

Co-Authored-By: Skrrt Bot <bot@skrrt.sh>
```

Section rules:

- Omit an empty section instead of filling it with noise.
- `feat` usually maps to `✨ Features`.
- `fix` usually maps to `🐛 Fixes`.
- Breaking changes always get a dedicated `⚠️ Breaking Changes` section.
- `docs`, `chore`, `ci`, `build`, and purely internal refactors usually belong
  in `🧰 Internal` only when they matter to release readers.
- Prefer reader-facing summaries over commit-message restatements.

## Changelog Rules

- Always check for an existing changelog before publishing a release.
- If `CHANGELOG.md`, `Changelog.md`, or `changelog.md` exists, update it as part of the release workflow.
- If the changelog follows Keep a Changelog, preserve its structure and add the new version entry in the existing style.
- If the changelog does not follow Keep a Changelog, still preserve the repository's established style.
- Do not create a brand-new changelog unless the user asks for one.
- Keep the release text and changelog entry consistent, but adapt the changelog to the repository's existing format.

## Guardrails

- Never create a release against an unknown forge.
- Never use the wrong CLI for the remote host.
- Never invent release notes from guesswork; derive them from tags, commits, diffs, and user context.
- Never publish a release silently when the user only asked for draft text.
- Stop if the detector reports `unknown-remote`, `no-remote`, or `no-compatible-cli`.
- Never skip updating an existing changelog for a real release unless the user explicitly asks you not to.
- Never use `git push --force`, `git push -f`, or `git push --force-with-lease` as part of the release flow.
- Treat release creation as a human-approval action when the project uses agent permission rules.

## Task

Handle this request: $ARGUMENTS

---
title: "Commit Types Reference"
description: "Reference for the conventional commit types used by the ship commit skill."
author: "skrrt-sh"
created: "2026-04-02"
updated: "2026-04-02"
version: "1.0.0"
status: "published"
tags: ["conventional-commits", "reference", "git", "github"]
category: "guide"
aliases: ["commit-types", "conventional-commit-types"]
related:
  - "../SKILL.md"
  - "./gitmojis.md"
refs:
  - https://github.com/vivaxy/vscode-conventional-commits
  - https://www.npmjs.com/package/@yi-xu-0100/conventional-commit-types-i18n
audience: ["external-developers", "backend-team", "frontend-team"]
---

# Commit Types Reference

> Reference for the conventional commit type titles, descriptions, and practical selection guidance used by `ship:commit`.

## Table of Contents

- [Header Shape](#header-shape)
- [Type Catalog](#type-catalog)
- [Practical Guidance](#practical-guidance)

These commit types are the English type titles and descriptions used by
`vivaxy/vscode-conventional-commits` through
`@yi-xu-0100/conventional-commit-types-i18n` 1.6.0.

## Header Shape

The upstream extension serializes commit messages as:

```text
type(scope): :gitmoji: subject [skip ci]

body

footer
```

Notes:

- `scope` is optional.
- `:gitmoji:` is optional in the extension, but this skill prefers it.
- `[skip ci]` is appended at the end of the header when needed.
- Body and footer are optional and separated by blank lines.

## Type Catalog

| Type | Title | Description |
| --- | --- | --- |
| `feat` | Features | A new feature |
| `fix` | Bug Fixes | A bug fix |
| `docs` | Documentation | Documentation only changes |
| `style` | Styles | Changes that do not affect the meaning of the code (white-space, formatting, missing semi-colons, etc) |
| `refactor` | Code Refactoring | A code change that neither fixes a bug nor adds a feature |
| `perf` | Performance Improvements | A code change that improves performance |
| `test` | Tests | Adding missing tests or correcting existing tests |
| `build` | Builds | Changes that affect the build system or external dependencies (example scopes: gulp, broccoli, npm) |
| `ci` | Continuous Integrations | Changes to our CI configuration files and scripts (example scopes: Travis, Circle, BrowserStack, SauceLabs) |
| `chore` | Chores | Other changes that don't modify src or test files |
| `revert` | Reverts | Reverts a previous commit |

## Practical Guidance

- Start with `feat` or `fix` when behavior changes for users or developers.
- Use `docs` for README, guides, ADRs, and comments that are primarily documentation.
- Use `style` only for formatting-only changes with no behavior impact.
- Use `refactor` when code structure changes without behavior change.
- Use `perf` when the main point is a measurable or intended performance improvement.
- Use `test` when the main change is adding, fixing, or clarifying tests.
- Use `build` for dependencies, package manager, bundling, build scripts, or release packaging.
- Use `ci` for workflow files, CI scripts, pipeline config, or runner behavior.
- Use `chore` sparingly for repo maintenance that does not fit the types above.
- Use `revert` only when the commit itself is a revert.

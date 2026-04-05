---
title: "Skrrt Plugins"
description: "Marketplace overview for the skrrt-sh Claude Code plugins and their documentation."
author: "skrrt-sh"
created: "2026-04-02"
updated: "2026-04-04"
version: "1.0.0"
status: "published"
tags: ["plugins", "marketplace", "markdown", "github"]
category: "guide"
aliases: ["skrrt-plugins", "plugin-marketplace"]
related:
  - "./plugins/md-writer/skills/md-writer/SKILL.md"
  - "./plugins/ship/skills/commit/SKILL.md"
  - "./plugins/ship/skills/pr/SKILL.md"
  - "./plugins/ship/skills/release/SKILL.md"
audience: ["external-developers", "backend-team", "frontend-team"]
---

# Skrrt Plugins

> Marketplace overview for the skrrt-sh plugin catalog, installation flow, and bundled skills.

## Table of Contents

- [Installation](#installation)
- [Plugins](#plugins)
- [Requirements](#requirements)
- [Repository Structure](#repository-structure)
- [License](#license)

Claude Code plugin marketplace by [skrrt-sh](https://github.com/skrrt-sh) — documentation,
developer workflows, and productivity tools.

## Installation

```bash
bunx skills add skrrt-sh/skills
```

Or from inside Claude Code:

```bash
/install skrrt-sh/skills
```

### Team Setup

Add to your project's `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "skrrt-plugins": {
      "source": {
        "source": "github",
        "repo": "skrrt-sh/skills"
      }
    }
  }
}
```

## Plugins

### md-writer

Write well-structured markdown with YAML frontmatter, Mermaid diagrams, and markdownlint validation.

```bash
/plugin install md-writer@skrrt-plugins
```

**Features:**

- YAML frontmatter with required metadata fields
- Mermaid-only diagrams — no ASCII art
- Markdownlint compliance — 20+ rules enforced, zero violations
- PostToolUse hook — auto-validates `.md` files on Write/Edit
- Custom config — respects project-level `.markdownlint.json`

**Usage:**

```text
/md-writer API integration guide for the payments service
```

Or just ask Claude to write markdown — the skill activates automatically.

See [plugins/md-writer/](plugins/md-writer/) for full details.

**Custom lint config:** The plugin ships with a bundled default config. To override it,
place your own config at your project root:

```bash
# Any of these will take precedence over the plugin default:
.markdownlint.json
.markdownlint.jsonc
.markdownlint.yaml
.markdownlint.yml
```

The validation hook walks up from the markdown file looking for the nearest config.
If none exists, it falls back to the plugin's bundled default. The skill is written to conform to the same defaults.

### ship

Create conventional commits with gitmojis, open focused PRs or MRs, and prepare release text with the
matching forge CLI.

```bash
/plugin install ship@skrrt-plugins
```

**Features:**

- Uses the `vivaxy/vscode-conventional-commits` commit shape
- Uses upstream conventional commit type titles and descriptions
- Uses the same gitmoji dataset version referenced by that repo
- Splits work into dedicated `commit`, `pr`, and `release` skills
- Detects whether the repo is hosted on GitHub or GitLab before choosing `gh` or `glab`
- Bundles skill-local forge-detection scripts for portable execution
- Documents a conservative `git` command subset for status, staging, commit, push, and release workflows
- Publishes review requests and releases with explicit non-interactive CLI commands
- Updates an existing `CHANGELOG.md` during release work when the repository has one
- Keeps the skills user-invocable and model-invocable
- Bundles a recommended Claude Code permissions template with `ask` rules for writes and force-push variants

**Usage:**

```text
/ship:commit prepare a clean conventional commit for the auth refresh-token changes
/ship:pr open a review request for the auth refresh-token branch
/ship:release draft release notes for v1.4.0
```

Or ask Claude to commit work, open a PR or MR, or prepare a release.

**Recommended permissions:**

Claude Code permissions are configured in `.claude/settings.json`, not in `SKILL.md`.
This plugin includes a recommended template at
[`plugins/ship/templates/claude-settings.json`](plugins/ship/templates/claude-settings.json).
Merge it into your project's `.claude/settings.json` if you want:

- read-only git and view commands allowed automatically
- mutating git, `gh`, and `glab` commands escalated with `permissions.ask`
- force-push variants escalated to human approval instead of silently allowed
- destructive commands such as `git reset --hard` denied

**Evaluations:**

This plugin also includes lightweight evaluation fixtures under [`plugins/ship/evals`](plugins/ship/evals)
to support the Anthropic recommendation to test skills against representative scenarios before sharing them.

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) v1.0.33+
- Node.js 18+
- `jq` (for validation hooks)

## Repository Structure

```text
skills/
├── .claude-plugin/
│   └── marketplace.json         # Marketplace manifest
├── plugins/
│   ├── md-writer/               # Markdown writer plugin
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json
│   │   ├── skills/
│   │   │   └── md-writer/
│   │   │       └── SKILL.md
│   │   ├── hooks/
│   │   │   ├── hooks.json
│   │   │   └── validate-md.sh
│   │   ├── config/
│   │   │   └── markdownlint-default.json
│   │   └── package.json
│   └── ship/                    # Commit, PR or MR, and release workflow plugin
│       ├── .claude-plugin/
│       │   └── plugin.json
│       ├── evals/
│       │   ├── commit-basic.json
│       │   ├── pr-github.json
│       │   └── release-changelog.json
│       ├── templates/
│       │   └── claude-settings.json
│       └── skills/
│           ├── commit/
│           │   ├── SKILL.md
│           │   └── reference/
│           │       ├── commit-types.md
│           │       └── gitmojis.md
│           ├── pr/
│           │   ├── SKILL.md
│           │   └── scripts/
│           │       └── detect-forge-cli.sh
│           └── release/
│               ├── SKILL.md
│               └── scripts/
│                   └── detect-forge-cli.sh
└── README.md
```

## Contributing

### Dev Setup

Install the pinned development skills before working on the plugins:

```bash
# Install skills from the lockfile (one-time, or after pulling new lock entries)
claude skill install --from skills-lock.json
```

This restores `.agents/` with the exact skill versions the team uses
(currently `skill-creator` from `anthropics/skills`).

### Running Evals

Use the skill-creator to test changes against the eval suites:

```text
/skill-creator audit our skills, run evals
```

Eval workspaces (`md-writer-workspace/`, `ship-workspace/`) are gitignored —
they are local artifacts, not committed.

### Project Layout for Dev Files

```text
.agents/                  # Installed dev skills (gitignored, restored from lockfile)
skills-lock.json          # Lockfile for dev skills (committed)
md-writer-workspace/      # md-writer eval artifacts (gitignored)
ship-workspace/           # ship eval artifacts (gitignored)
```

## License

MIT

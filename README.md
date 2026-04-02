---
title: "Skrrt Plugins"
description: "Marketplace overview for the skrrt-sh Claude Code plugins and their documentation."
author: "skrrt-sh"
created: "2026-04-02"
updated: "2026-04-02"
version: "1.0.0"
status: "published"
tags: ["plugins", "marketplace", "markdown", "github"]
category: "guide"
aliases: ["skrrt-plugins", "plugin-marketplace"]
related:
  - "./plugins/md-writer/skills/md-writer/SKILL.md"
  - "./plugins/gh-ship/skills/gh-ship/SKILL.md"
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
# Add the marketplace (one-time)
/plugin marketplace add skrrt-sh/claude-plugins

# Browse available plugins
/plugin
```

### Team Setup

Add to your project's `.claude/settings.json`:

```json
{
  "extraKnownMarketplaces": {
    "skrrt-plugins": {
      "source": {
        "source": "github",
        "repo": "skrrt-sh/claude-plugins"
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

### gh-ship

Create conventional commits with gitmojis and open focused pull requests with `gh`.

```bash
/plugin install gh-ship@skrrt-plugins
```

**Features:**

- Uses the `vivaxy/vscode-conventional-commits` commit shape
- Uses upstream conventional commit type titles and descriptions
- Uses the same gitmoji dataset version referenced by that repo
- Guides clean commit splitting, commit body/footer writing, and PR authoring
- Publishes PRs with explicit `gh` commands instead of vague instructions

**Usage:**

```text
/gh-ship prepare commits and a PR for the auth refresh-token changes
```

Or ask Claude to write a conventional commit and open a PR with `gh`.

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) v1.0.33+
- Node.js 18+
- `jq` (for validation hooks)

## Repository Structure

```text
claude-plugins/
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
│   └── gh-ship/                 # Conventional commit + gh PR workflow plugin
│       ├── .claude-plugin/
│       │   └── plugin.json
│       └── skills/
│           └── gh-ship/
│               ├── SKILL.md
│               └── references/
│                   ├── commit-types.md
│                   └── gitmojis.md
└── README.md
```

## License

MIT

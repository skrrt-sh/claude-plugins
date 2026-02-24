# skrrt-plugins

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
│   └── md-writer/               # Markdown writer plugin
│       ├── .claude-plugin/
│       │   └── plugin.json
│       ├── skills/
│       │   └── md-writer/
│       │       └── SKILL.md
│       ├── hooks/
│       │   ├── hooks.json
│       │   └── validate-md.sh
│       ├── .markdownlint.json
│       └── package.json
└── README.md
```

## License

MIT

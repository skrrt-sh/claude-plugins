# md-writer

A Claude Code plugin that produces well-structured markdown documents with YAML frontmatter,
Mermaid diagrams, and markdownlint compliance.

## What It Does

When Claude creates or edits `.md` files, this plugin enforces:

- **YAML frontmatter** with required metadata fields (title, description, author, dates, version, status)
- **Mermaid-only diagrams** — no ASCII art or text-based visuals
- **Markdownlint compliance** — 20 rules enforced, zero violations allowed
- **Consistent formatting** — ATX headings, fenced code blocks with language identifiers, proper lists, tables, and links
- **Automatic validation** — a post-write hook runs markdownlint on every `.md` file and feeds violations back to Claude

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) v1.0.33+
- Node.js 18+
- `jq` (for the validation hook)

## Installation

### From GitHub

```bash
# Add the marketplace (one-time)
/plugin marketplace add skrrt-labs/md-writer-skill

# Install the plugin
/plugin install md-writer@skrrt-labs-md-writer-skill
```

### Local Testing

```bash
git clone https://github.com/skrrt-labs/md-writer-skill.git
claude --plugin-dir ./md-writer-skill
```

### Team Setup

Add to your project's `.claude/settings.json` so all team members get the plugin automatically:

```json
{
  "extraKnownMarketplaces": {
    "skrrt-labs-md-writer-skill": {
      "source": {
        "source": "github",
        "repo": "skrrt-labs/md-writer-skill"
      }
    }
  },
  "enabledPlugins": {
    "md-writer@skrrt-labs-md-writer-skill": true
  }
}
```

## Usage

### Invoke Directly

```text
/md-writer API integration guide for the payments service
/md-writer architecture-decision-record.md
```

### Auto-Invocation

Claude activates the skill automatically when you ask it to create or edit markdown files:

```text
"Write a markdown doc explaining our auth flow"
"Create a getting-started guide for the SDK"
"Document the database schema"
```

### Validation Hook

Every time Claude writes or edits a `.md` file, the `PostToolUse` hook runs `markdownlint-cli2`
and reports violations. Claude then fixes them automatically before finishing.

## Custom Markdownlint Config

The plugin ships with a default `.markdownlint.json`. To override it, place your own config file in your project root:

```bash
# Supported config file names (checked in order):
# .markdownlint.json
# .markdownlint.jsonc
# .markdownlint.yaml
# .markdownlint.yml
```

Your project config always takes precedence. Both the skill instructions and the validation hook respect it.

### Default Config

```json
{
  "default": true,
  "MD013": {
    "line_length": 120,
    "code_blocks": false,
    "tables": false
  },
  "MD025": {
    "front_matter_title": ""
  },
  "MD060": {
    "style": "compact"
  }
}
```

## Plugin Structure

```text
md-writer-skill/
├── .claude-plugin/
│   └── plugin.json              # Plugin manifest
├── skills/
│   └── md-writer/
│       └── SKILL.md             # Skill instructions
├── hooks/
│   ├── hooks.json               # PostToolUse hook on Write/Edit
│   └── validate-md.sh           # Runs markdownlint, respects project config
├── .markdownlint.json           # Default lint config (fallback)
├── package.json                 # markdownlint-cli2 dependency
└── README.md
```

## License

MIT

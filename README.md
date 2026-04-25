# Skrrt Plugins

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?logo=opensourceinitiative&logoColor=white)](LICENSE) [![Claude Code](https://img.shields.io/badge/Claude_Code-v1.0.33+-blueviolet?logo=anthropic&logoColor=white)](https://docs.anthropic.com/en/docs/claude-code) [![Version](https://img.shields.io/badge/marketplace-v1.7.0-green?logo=github&logoColor=white)](https://github.com/skrrt-sh/claude-plugins)

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
- Splits work into dedicated `commit`, `pr`, `release`, and `setup` skills
- Detects whether the repo is hosted on GitHub or GitLab before choosing `gh` or `glab`
- Bundles skill-local forge-detection scripts for portable execution
- Documents a conservative `git` command subset for status, staging, commit, push, and release workflows
- Publishes review requests and releases with explicit non-interactive CLI commands
- Updates an existing `CHANGELOG.md` during release work when the repository has one
- Keeps the skills user-invocable and model-invocable
- Bundles a recommended Claude Code permissions template with `ask` rules for writes and force-push variants

**Recommended first step — run `/setup`:**

For the best experience, run `/setup` in your project before using the other
skills. The setup skill wires directives into your project's `CLAUDE.md` (or
`AGENTS.md`) so that Claude automatically uses the ship skills whenever it
commits, opens a PR/MR, or prepares a release — no slash command needed.

Setup also configures a **branching strategy** (GitHub Flow, Trunk-Based
Development, or Gitflow) so that all skills respect the correct target branches,
merge rules, and release workflows.

```text
/setup wire skrrt skills into this project
```

Without `/setup`, the commit, PR, and release skills will prompt you to run
`/setup` first so that a branching strategy is configured.

**Usage:**

```text
/commit prepare a clean conventional commit for the auth refresh-token changes
/pr open a review request for the auth refresh-token branch
/release draft release notes for v1.4.0
```

Or — after running `/setup` — just ask Claude to commit work, open a PR or MR,
or prepare a release and it will use the skills automatically.

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

### squad

> **Requires Claude Code v2.1.117+** (squad uses `CLAUDE_CODE_FORK_SUBAGENT=1` and the Agent tool's `isolation: "worktree"` parameter, both introduced in that release).

Run N subagents in parallel for one big task. Splits the goal into independent pieces, dispatches one Agent per piece in its own auto-managed git worktree, cherry-picks committed work onto an integration branch ready for `/ship:commit`.

> **Rare-case tool.** Worktrees + parallel dispatch are overhead. Reach for squad only when a task is genuinely large AND cleanly splits into independent substantial pieces. Most tasks don't need it — just do them directly.

```bash
/plugin install squad@skrrt-plugins
```

**Features:**

- Single skill: `/squad:spawn <goal>` plans, checkpoints, runs.
- Decomposes into N≥2 sibling tasks with disjoint writable files — refuses pipelines and single-file work.
- Dispatches all children in one assistant turn via parallel Agent tool calls with `isolation: "worktree"` (Claude Code manages the worktrees).
- Cherry-picks each `done` child's commits onto `squad/<id>/integration` directly from the returned branches.
- Cleans up source worktrees and branches after successful integration.
- No on-disk state — the conversation is the source of truth.
- **User-invocable only** (`disable-model-invocation: true`) — Claude will not auto-trigger squad from natural-language requests; you invoke `/squad:spawn` and `/squad:setup` explicitly.

**Recommended first step — run `/squad:setup`:**

Setup adds the multi-agent block to your project's `CLAUDE.md` and writes `CLAUDE_CODE_FORK_SUBAGENT=1` to `.claude/settings.local.json` (required for fork dispatch on Claude Code v2.1.117+). Reopen Claude Code afterward so the env var is picked up.

```text
/squad:setup
```

**Usage:**

```text
/squad:spawn refactor AuthService to use a token bucket rate limiter, update the auth docs, and add a smoke test
```

After spawn finishes, the integration branch is ready — use `/ship:commit` then `/ship:pr` to land it.

**When NOT to use squad:**

- Single-file edits — just do them.
- Pipelines / ordered tasks — squad is fan-out, not orchestration.
- Tightly-coupled work where children would conflict on the same files.

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) v1.0.33+
- Node.js 18+
- `jq` (for validation hooks)

## Repository Structure

```text
.
├── .claude-plugin/
│   └── marketplace.json           # Marketplace manifest
├── plugins/
│   ├── md-writer/                 # Markdown writer plugin
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json
│   │   ├── config/
│   │   │   └── markdownlint-default.json
│   │   ├── evals/
│   │   │   └── evals.json
│   │   ├── hooks/
│   │   │   ├── hooks.json
│   │   │   └── validate-md.sh
│   │   ├── skills/
│   │   │   └── md-writer/
│   │   │       └── SKILL.md
│   │   ├── package.json
│   │   └── package-lock.json
│   ├── ship/                      # Commit, PR or MR, and release workflow plugin
│   │   ├── .claude-plugin/
│   │   │   └── plugin.json
│   │   ├── evals/
│   │   │   ├── commit-basic.json
│   │   │   ├── evals.json
│   │   │   ├── pr-github.json
│   │   │   └── release-changelog.json
│   │   ├── templates/
│   │   │   └── claude-settings.json
│   │   └── skills/
│   │       ├── commit/
│   │       │   ├── SKILL.md
│   │       │   ├── evals/
│   │       │   │   └── trigger-evals.json
│   │       │   └── reference/
│   │       │       ├── commit-types.md
│   │       │       └── gitmojis.md
│   │       ├── pr/
│   │       │   ├── SKILL.md
│   │       │   ├── evals/
│   │       │   │   └── trigger-evals.json
│   │       │   └── scripts/
│   │       │       └── detect-forge-cli.sh
│   │       ├── release/
│   │       │   ├── SKILL.md
│   │       │   ├── evals/
│   │       │   │   └── trigger-evals.json
│   │       │   └── scripts/
│   │       │       └── detect-forge-cli.sh
│   │       └── setup/
│   │           ├── SKILL.md
│   │           ├── evals/
│   │           │   └── trigger-evals.json
│   │           └── reference/
│   │               └── branching-strategies.md
│   └── squad/                     # Multi-agent fan-out plugin
│       ├── .claude-plugin/
│       │   └── plugin.json
│       ├── evals/
│       │   └── evals.json
│       └── skills/
│           ├── setup/
│           │   ├── SKILL.md
│           │   └── block.md
│           └── spawn/
│               └── SKILL.md
├── README.md
├── LICENSE
├── skills-lock.json
└── .gitignore
```

## Contributing

### Dev Setup

Install the pinned development skills before working on the plugins:

```bash
# Install dev skills (one-time, or after pulling new lock entries)
bunx skills add anthropics/skills --skill skill-creator
```

This restores `.agents/` with the skill-creator used for eval workflows.

### Running Evals

Use the skill-creator to test changes against the eval suites:

```text
/skill-creator audit our skills, run evals
```

Eval workspaces (`md-writer-workspace/`, `ship-workspace/`, `squad-workspace/`)
are gitignored — they are runtime artifacts from running evals, not committed.
The eval definitions themselves live in `plugins/*/evals/`.

### Project Layout for Dev Files

```text
.agents/                  # Installed dev skills (gitignored, restored from lockfile)
skills-lock.json          # Lockfile for dev skills (committed)
md-writer-workspace/      # md-writer eval artifacts (gitignored)
ship-workspace/           # ship eval artifacts (gitignored)
squad-workspace/          # squad eval artifacts (gitignored)
```

## License

MIT

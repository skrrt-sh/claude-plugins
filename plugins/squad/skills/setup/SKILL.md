---
name: setup
description: Installs squad. Adds the instruction block to CLAUDE.md and writes CLAUDE_CODE_FORK_SUBAGENT=1 to .claude/settings.local.json. Idempotent.
argument-hint: "[options]"
allowed-tools: Read Write Edit Bash(ls *) Bash(git check-ignore *)
disable-model-invocation: true
---

# Squad Setup

One-shot project install.

## Workflow

### 1. Instruction block

Find the agent file in this order: `CLAUDE.md`, `AGENTS.md`, `.claude/CLAUDE.md`, `.github/AGENTS.md`. Create `CLAUDE.md` at the project root if none exist.

Read `${CLAUDE_SKILL_DIR}/block.md` verbatim — it carries its own `<!-- skrrt:squad -->` markers.

- Markers present: replace content between them.
- Markers absent: append blank line + block.

Never modify content outside the markers.

### 2. Fork subagents (mandatory)

Squad's fork dispatch requires `CLAUDE_CODE_FORK_SUBAGENT=1`.

Before writing, verify `.claude/settings.local.json` is gitignored:

```bash
git check-ignore -q .claude/settings.local.json
```

If exit code is non-zero, warn the user that the file is tracked and may be committed to the repo. Proceed with the write — the env var itself isn't sensitive — but the warning surfaces a setup smell.

Read `.claude/settings.local.json` (treat missing as `{}`). Set `env.CLAUDE_CODE_FORK_SUBAGENT = "1"`. Write back, preserving every other key. Skip the write if already `"1"`; overwrite (and note in the report) if any other value.

Never write this key to `.claude/settings.json` — `settings.local.json` is per-user and gitignored by convention.

If the user's session predates this write, they must reopen Claude Code so the env var is picked up.

### 3. Report

- Instruction file: `<path>` (created | replaced | appended)
- Fork subagents: written | already set | overwritten from `<old>`
- Reopen Claude Code if your session predates the env-var write.

## Guardrails

- Only touch content between `<!-- skrrt:squad -->` markers.
- Read-merge-write `.claude/settings.local.json`; preserve every other key.
- Never write `CLAUDE_CODE_FORK_SUBAGENT` to `.claude/settings.json`.

## Task

Handle this request: $ARGUMENTS

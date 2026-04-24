---
name: setup
description: Installs squad into the current project. Appends the squad block to CLAUDE.md (or AGENTS.md), adds `.claude/squad/` to .gitignore so per-run artifacts stay local, and writes `CLAUDE_CODE_FORK_SUBAGENT=1` to .claude/settings.local.json (squad requires this for fork subagents — mandatory, not optional). Make sure to use this skill whenever the user asks to set up squad, install squad, add squad to CLAUDE.md, wire the squad plugin into this repo, or configure multi-agent orchestration — even if they don't say the word "setup".
argument-hint: "[options]"
allowed-tools: Read Write Edit Bash(git check-ignore *) Bash(ls *)
---

# Squad Setup Skill

> One-shot project install for the squad plugin. Idempotent.

## Workflow

### 1. Install the instruction block

Detect the project's agent instruction file in this order:
`CLAUDE.md`, `AGENTS.md`, `.claude/CLAUDE.md`, `.github/AGENTS.md`. If
none exist, create `CLAUDE.md` at the project root.

The canonical block lives at `${CLAUDE_SKILL_DIR}/block.md` — read it
verbatim. It contains its own `<!-- skrrt:squad -->` /
`<!-- /skrrt:squad -->` markers.

- **Marker present** in the target file: replace content between
  markers with the current block.
- **Marker absent:** append a blank line then the block.

Never modify content outside the markers.

### 2. Gitignore the runtime artifacts

Every squad run writes to `.claude/squad/runs/<run-id>/` (manifests,
worktree maps, child returns, run summaries). This is per-project
session state — short-lived, machine-local, not shareable.

Ensure the project's root `.gitignore` includes `.claude/squad/`:

- If `.gitignore` doesn't exist: create it with `.claude/squad/` as the
  only line.
- If `.gitignore` exists and already ignores `.claude/squad/`
  (check with `git check-ignore -q .claude/squad/anything` returning 0,
  or grep for the pattern): skip.
- Otherwise: append a commented section and the pattern. Do not
  reformat or sort existing entries.

Example append:

```
# skrrt squad — per-run artifacts (manifests, worktree maps, child returns)
.claude/squad/
```

This step is automatic — don't ask.

### 3. Enable fork subagents (mandatory)

Squad **requires** `CLAUDE_CODE_FORK_SUBAGENT=1` in the session
environment. Every squad run uses forks directly (manifests with
`subagent_type: fork`) or indirectly (the `/squad:resolver` skill runs
as a fork under `--auto-resolve`). Without the env var, dispatch fails
and the plugin does not work. This step is not optional and not
prompted.

Write the key unconditionally:

- Read `.claude/settings.local.json` (create `{}` if absent — preserve
  everything else in the file).
- Ensure `env.CLAUDE_CODE_FORK_SUBAGENT = "1"`. If the key is already
  set to `"1"`, skip the write. If it's set to any other value,
  overwrite with `"1"` and note the change in the report.
- Never write this key to `.claude/settings.json` (team-shared); only
  to `.claude/settings.local.json` (per-user, gitignored by
  convention).

Tell the user: the env var is picked up when Claude Code reads
`settings.local.json` on session start. If they're already in a
session, they need to reopen it before `/squad:spawn` will see the
flag.

### 4. Check the ship plugin is available

`/squad:spawn` ends at an integration branch and hands off to
`/ship:commit`. If the ship plugin isn't installed, users will hit a
dead end.

Check whether a `/ship:commit` skill is reachable. The skrrt
convention installs plugins under a marketplace root — inspect the
consumer repo's plugin roots for `ship/skills/commit/SKILL.md`, and
also check the running marketplace at common plugin dirs
(`~/.claude/plugins/`, `./plugins/ship/`). If none found, emit a
clearly-flagged warning (not an error):

```
warning: skrrt ship plugin not detected. /squad:spawn ends at an
integration branch expecting /ship:commit to turn it into a clean
commit series. Install the ship plugin from the same marketplace:
https://github.com/skrrt-sh/skills
```

Do not fail setup over this — the user may have their own commit
workflow. Just surface it loudly once.

### 5. Report

Print one summary:
- Instruction file: `<path>` (appended | replaced | created)
- Gitignore: added `.claude/squad/` | already ignored
- Fork subagents (`CLAUDE_CODE_FORK_SUBAGENT=1`): written | already
  set | overwritten from `<old value>`
- Ship plugin: detected at `<path>` | not detected (warning shown)
- Reminder: if the session predates the env-var write, reopen Claude
  Code so `/squad:spawn` sees the flag.

## Guardrails

- Only ever touch content between `<!-- skrrt:squad -->` and
  `<!-- /skrrt:squad -->` in the instruction file.
- Never duplicate the block — replace between markers when present.
- Never modify `.gitignore` entries outside of appending the one
  section. Don't reformat existing entries.
- Never write `CLAUDE_CODE_FORK_SUBAGENT` to `.claude/settings.json`
  (team-shared). Only to `.claude/settings.local.json` (per-user).
- When editing `.claude/settings.local.json`, read-merge-write —
  preserve every other key in the file.
- Never install `.claude/agents/` profiles for the user. Squad's
  resolver ships as a `context: fork` skill and needs no profile.
- The ship-plugin check is advisory: warn but never fail setup.

## Task

Handle this request: $ARGUMENTS

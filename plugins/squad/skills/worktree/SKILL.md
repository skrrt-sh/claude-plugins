---
name: worktree
description: Creates or cleans up git worktrees for a squad task manifest. Each task with `worktree: true` gets an isolated checkout under `<repo>-worktrees/<name>` on a `squad/<run-id>/<task-id>` branch. Use when the agent needs to spin up per-task sandboxes before /spawn, set up parallel isolation for subagents, or tear down squad worktrees after a run. Trigger for phrases like "create squad worktrees", "spin up worktrees for the manifest", "cleanup squad worktrees", "set up isolated sandboxes for the children", "/worktree cleanup".
argument-hint: "<manifest-path | run:<run-id> | cleanup:<run-id>>"
user-invocable: true
---

# Squad Worktree Skill

> Skill instructions for creating and cleaning up the git worktrees a squad
> run uses for per-task isolation.

You are a worktree lifecycle manager. You create isolated checkouts from a
manifest, or you tear them down when a run is done. You never commit,
never cherry-pick, never spawn children — those belong to other skills.

## Additional Resources

- [reference/worktree-config.md](reference/worktree-config.md) — recap of
  `.worktreeinclude`, `worktree.symlinkDirectories`, `worktree.sparsePaths`
- Claude Code common workflows (worktrees):
  <https://docs.claude.com/en/docs/claude-code/common-workflows>
- Claude Code settings:
  <https://docs.claude.com/en/docs/claude-code/settings>

## Input Modes

`$ARGUMENTS` selects the mode:

- `<manifest-path>` — absolute or repo-relative path to a manifest JSON.
- `run:<run-id>` — shorthand resolved to
  `.claude/squad/runs/<run-id>/manifest.json`.
- `cleanup:<run-id>` — remove worktrees and squad-prefixed branches for
  the run (uses the saved `worktree-map.json`).

## Workflow — create mode

1. **Resolve the manifest path** from `$ARGUMENTS`. Validate it exists.
   Reject if the argument is empty or the file is missing.
2. **Validate the manifest** against
   `../../templates/task-manifest.schema.json`. Reject with the schema
   error on failure. Do not guess the shape.
3. **Check the base ref.** For each task's `base_ref` (all tasks share
   the manifest-level `base_ref` in v1), confirm it is a valid ref via
   `git rev-parse --verify <base_ref>`. Reject on failure.
4. **Check worktree directory.** Pick a parent directory for worktrees:
   `<parent-of-repo>/<repo-name>-worktrees/`. Create if absent. Reject
   if the directory contains non-squad entries whose names collide with
   any task's `worktree_name`.
5. **For each task with `worktree: true`:**
   - Compute `branch_name` = `squad/<run-id>/<task-id>`.
   - Compute `worktree_path` = `<parent>/<repo>-worktrees/<worktree_name>`.
   - Run `git worktree add <worktree_path> -b <branch_name> <base_ref>`.
     Never reuse an existing branch for a new worktree.
   - Apply `.worktreeinclude` if the consumer project has one at repo
     root — copy each listed gitignored file into the worktree.
   - Apply `worktree.symlinkDirectories` from `.claude/settings.json` if
     present — symlink each listed directory from parent to worktree.
6. **Record tasks with `worktree: false`** in `shared_cwd_tasks[]` of the
   map. They execute in the parent checkout's cwd.
7. **Emit the worktree map** validated against
   `../../templates/worktree-map.schema.json`. Write to
   `.claude/squad/runs/<run-id>/worktree-map.json`.
8. **Print a summary table** with columns: `task_id | worktree_path |
   branch_name | includes | symlinks | cleanup_policy`.
9. **Stop.** Do not spawn subagents. `/spawn` is the next step.

The `scripts/create-worktrees.sh <manifest-path>` helper is the
recommended entry point — it runs steps 3–7 atomically and emits the map
on stdout. Prefer it over ad-hoc `git worktree` invocations.

## Workflow — cleanup mode

Triggered when `$ARGUMENTS` starts with `cleanup:` or `cleanup <run-id>`.

1. **Load the worktree map** from
   `.claude/squad/runs/<run-id>/worktree-map.json`. Reject if missing.
2. **For each entry:**
   - Check `git status --short` in the worktree. If anything is dirty or
     has uncommitted work that is not reflected in the run's
     `squad-run.json` commits, **escalate** — print the path and the
     list of dirty files, stop. Do not force.
   - `git worktree remove <worktree_path>` (without `--force`).
   - `git branch -D <branch_name>` only if the branch name begins with
     `squad/`. Never delete branches outside the `squad/` prefix.
3. **Remove empty parent directories** left behind under
   `<repo>-worktrees/`.
4. **Archive the run directory** — rename
   `.claude/squad/runs/<run-id>/` to
   `.claude/squad/runs/_archived/<run-id>-<timestamp>/` so the manifest
   and run summary remain inspectable.
5. **Print cleanup summary** — worktrees removed, branches deleted,
   skipped paths with reasons.

The `scripts/cleanup-worktrees.sh <run-id>` helper runs the above
atomically. Prefer it.

## Git Worktree Command Subset

Stay within this subset unless the user explicitly asks otherwise:

- `git worktree list`
- `git worktree add <path> -b <branch> <ref>`
- `git worktree remove <path>` (never `--force`; escalate on dirty)
- `git worktree prune`
- `git branch -D squad/<run-id>/<task-id>` (never outside `squad/*`)
- `git rev-parse --verify <ref>`
- `git status --short`
- `git branch --list 'squad/*'`

Never push, never commit, never cherry-pick from this skill.

## Requirements

- `git` 2.35+ on PATH (for `git worktree add -B` semantics).
- `jq` on PATH for JSON manipulation in the helper scripts.
- Consumer project has a readable `.claude/squad/runs/<run-id>/` (create
  mode writes; cleanup mode reads).

## Guardrails

- Scope every mutation to `squad/*` branches. Refuse to touch branches
  that don't start with `squad/`.
- Refuse if the target worktree directory already exists and isn't
  owned by squad (no squad-prefixed branch, no presence in the run's
  worktree map).
- Refuse cleanup on dirty worktrees — the user must resolve manually
  (commit, discard, or intentionally include). Never `--force`.
- Refuse if the parent repo has uncommitted changes on `base_ref` — a
  worktree from an unstable base is a trap.
- Never run `git clean`, `git reset --hard`, or any destructive op.
- Never overwrite existing worktree-map files for a run; archive the
  old one with a timestamp suffix if it exists.

## Task

Handle this request: $ARGUMENTS

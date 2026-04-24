---
name: spawn
description: Executes a squad task manifest end-to-end. Creates isolated worktrees per task, dispatches child subagents (fork or named) in parallel tool-call blocks, collects their structured returns, cherry-picks their commits onto a `squad/<run-id>/integration` branch in merge order, runs per-task validation gates, and cleans up on success. This is the "implement" step in explore/plan/implement. Make sure to use this skill whenever the user asks to spawn subagents, fan out children, execute a squad plan, run a task manifest, dispatch children and cherry-pick their work, fan out and merge, or run a multi-agent job end-to-end — even if they don't say the word "spawn". Ends at an integration branch and hands off to /ship:commit.
argument-hint: "<run:<run-id> | <manifest-path>> [--auto-resolve] [--keep-worktrees]"
allowed-tools: Read Write Edit Bash(git *) Bash(jq *) Bash(bash *)
---

# Squad Spawn Skill

> The "implement" step of squad. Creates worktrees, dispatches children,
> cherry-picks their commits onto an integration branch with validation
> gates between them. Ends at a commit-ready branch; never pushes.

You are an orchestrator. You hand each child a crisp prompt and a
worktree, wait for its structured return, cherry-pick its commits onto
a staging branch, and run the task's validation command before the next
child lands. You do not push, amend, or reset --hard.

## Inputs

`$ARGUMENTS` selects the mode:

- `run:<run-id>` — loads the manifest from
  `.claude/squad/runs/<run-id>/manifest.json`.
- `<manifest-path>` — explicit path.

Flags (anywhere in `$ARGUMENTS`):

- `--auto-resolve` — on cherry-pick conflict, dispatch the
  `/squad:resolver` skill (runs as a fork). Without the flag, pause and
  ask the user.
- `--keep-worktrees` — do not cleanup worktrees after a successful run.
  Default is auto-cleanup on success.

## Workflow

### 1. Load and validate

- Read the manifest. Reject if task `id`s are not unique (important:
  the downstream map keys by id).
- Reject if the parent checkout is dirty (`git status --porcelain`
  must be empty). A dirty parent can't be reproduced into worktrees
  reliably.
- For each `named` task, verify `.claude/agents/<profile>.md` exists.
  Refuse for the whole run if any profile is missing.
- **Fork preflight.** Squad requires `CLAUDE_CODE_FORK_SUBAGENT=1` in
  the session env — it's what lets the plugin dispatch fork subagents
  at all, and `/squad:setup` writes it unconditionally to
  `.claude/settings.local.json`. Check it here. If unset, refuse with:
  `CLAUDE_CODE_FORK_SUBAGENT=1 is not set in this session — run
  /squad:setup, then reopen this Claude Code session so the env var
  is picked up.` Apply this check even if the manifest is all-named:
  the resolver runs as a fork and you may need it under
  `--auto-resolve`.
- **Absolute run-dir.** Compute
  `RUN_DIR = "$(git rev-parse --show-toplevel)/.claude/squad/runs/<run-id>"`
  once. Pass this absolute path into every child prompt so children
  running in worktrees (cwd = worktree path) can still write their
  returns into the main checkout.

### 2. Create worktrees

Run:

```bash
bash "${CLAUDE_SKILL_DIR}/scripts/create-worktrees.sh" <manifest-path>
```

The script creates `<repo-parent>/<repo>-worktrees/<run-id>/<task-id>`
per task with a `squad/<run-id>/<task-id>` branch from `base_ref`,
applies `worktree.symlinkDirectories` and `worktree.sparsePaths` from
`.claude/settings.json` if set, ensures the
`.claude/squad/runs/<run-id>/returns/` directory exists (children write
their return JSON there), writes
`.claude/squad/runs/<run-id>/worktree-map.json`, and prints the map.
The `<run-id>` segment in the worktree path keeps concurrent runs with
shared task ids (`docs`, `tests`, `frontend`) from colliding.

### 3. Create the integration branch — do not switch yet

```bash
git branch "squad/<run-id>/integration" "<base_ref>"
```

This creates the ref without changing HEAD. Dispatch happens while the
parent checkout is still on whatever branch the user started from.
Switching early would let any shared-cwd child contaminate integration
(we don't have shared-cwd tasks in v0.1.0, but the ordering matters).

If the branch already exists (a prior run was interrupted after this
step but before cleanup): resolve its tip with
`git rev-parse squad/<run-id>/integration`. If it points at `base_ref`,
reuse it and skip the create. If it points anywhere else, refuse with:
`squad/<run-id>/integration already exists at <sha> (expected <base_ref>).
Delete it manually or rerun /squad:decompose to generate a fresh run id.`
Never force-update.

### 4. Dispatch children in groups

Compute dispatch groups by Kahn's algorithm on `dependencies`:
- Group 0: tasks with no deps.
- Group N: tasks whose deps are all in groups 0..N-1.
- Cap at `SQUAD_MAX_PARALLEL` (default 4); split oversize groups into
  sequential waves.

For each group, dispatch every child in **one assistant turn** using
parallel tool-call blocks. Each dispatch:

- Uses `subagent_type: <named-profile>` for named tasks (from the
  manifest).
- For fork tasks, uses the fork mechanism (requires
  `CLAUDE_CODE_FORK_SUBAGENT=1` — set by `/squad:setup` into
  `.claude/settings.local.json`).
- Passes `cwd: <worktree_path>` (from the worktree map) — squad-managed
  isolation. Do **not** set `isolation: worktree` on the dispatch call;
  that field makes Claude create its own ephemeral worktree and would
  bypass our branch naming.
- Passes the prompt template below, with placeholders filled from the
  task.

### Child prompt template

```
# Objective

<task.title>

<task.rationale>

# Output format

When you finish, write a JSON document to
`<RUN_DIR>/returns/<task.id>.json` (absolute path — do not interpret
relative to your cwd, which is the worktree) with this shape:

{
  "task_id": "<task.id>",
  "status": "done | blocked | failed",
  "summary": "<1–3 sentences, plain English, imperative>",
  "commits": [{"sha": "<7–40 hex>", "subject": "<commit subject>"}],
  "validation_result": {"command": "<the validation cmd>", "exit_code": <int>},
  "blockers": [{"kind": "missing-dep|conflict|spec-unclear|validation-failed",
                "detail": "<what's wrong>"}]
}

Rules:
- If status is `done`, `commits` must be non-empty and `blockers` must be empty.
- If status is `blocked` or `failed`, `blockers` must be non-empty.
- Echo the same JSON in your final message so I can see it too.

# Tools

You may use: <task.allowed_tools joined by ", ">.
Refuse any tool outside that list.

# Boundaries

Edit only these files:
<task.target_files bulleted list>

Do not touch any file outside that list. If the task requires it, stop
and return `status: blocked` with a `spec-unclear` blocker.

# Validation

Before returning `status: done`, run:

  <task.validation_command>

Record the exit code in `validation_result.exit_code`. If it's non-zero,
return `status: blocked` with a `validation-failed` blocker — do not
mark the task done.

# Commit

Make one or more commits on your current branch before returning. List
each sha + subject in `commits[]`. I'll cherry-pick these in
`merge_order`. You may use /ship:commit if available, or write the
commit directly.

# Context

- run_id: <manifest.run_id>
- cwd: <worktree_path>  (a git worktree; commit here on this branch)
- RUN_DIR: <absolute path to .claude/squad/runs/<run-id>/ in the main checkout>
- merge_order: <task.merge_order>
- dependencies: <task.dependencies>
```

### 5. Collect and validate returns

After the group completes, read each
`.claude/squad/runs/<run-id>/returns/<task-id>.json`. Check the
consistency rules (done → non-empty commits + empty blockers;
blocked/failed → non-empty blockers). If a return is missing or
contradictory, re-dispatch that child once with the error attached. On
a second failure, mark the task `failed` and continue with the others.

### 6. Switch to integration, then cherry-pick

Once every dispatched child has returned:

```bash
git switch "squad/<run-id>/integration"
```

Then, for each task with `status: done` in dependency order (ascending
`merge_order` as tiebreak, alphabetical `id` as final tiebreak):

```bash
git fetch "<worktree_path>" "<branch_name>:refs/squad-incoming/<run-id>/<task-id>"
for sha in <task.commits[].sha>; do
  git cherry-pick "$sha"  # on conflict → see §7
done
bash -c "<task.validation_command>"   # validation gate
```

If the validation gate exits non-zero, stop. Don't revert the already-
picked commits. Write a run summary (next step) and tell the user.

Tasks with `status != done` are **skipped** — their commits stay on
their own branches, the integration branch does not include them.

### 7. Conflict handling

**Default mode (no `--auto-resolve`):**
- Abort: `git cherry-pick --abort`.
- Print `git diff --name-only --diff-filter=U`, the two conflicting
  tasks' `summary` + any `blockers` notes.
- Stop and ask the user to resolve manually, or to re-run `/squad:decompose`
  sequencing the tasks via `dependencies`.

**`--auto-resolve` mode:**
- Do not abort. Leave the conflicted state in the working tree.
- Invoke `/squad:resolver <run-id> <task-a-id> <task-b-id>` — it runs
  as a forked subagent, edits the unmerged files to preserve both
  intents, and `git add`s each resolved file. The resolver does not
  commit.
- When the resolver returns, run `git cherry-pick --continue`, then
  run the task's validation command as a gate, and continue the loop.
- If `/squad:resolver` itself can't resolve cleanly (semantic conflict),
  fall back to the default mode.

### 8. Run summary

Write `.claude/squad/runs/<run-id>/squad-run.json`:

```json
{
  "run_id": "<id>",
  "base_ref": "<sha>",
  "integration_branch": "squad/<id>/integration",
  "tasks": [
    {"id": "<task-id>", "outcome": "picked|skipped|conflict|validation-failed",
     "picked_commits": ["<sha>..."], "validation": "pass|fail|skipped"}
  ]
}
```

### 9. Cleanup + final message

On full success (every task `picked` or intentionally `skipped`, gates
green): unless `--keep-worktrees`, run
`bash "${CLAUDE_SKILL_DIR}/scripts/cleanup-worktrees.sh" <run-id>` to
remove the worktrees and their squad-prefixed branches. Archives the
run dir to `.claude/squad/runs/_archived/<run-id>-<timestamp>/`.

On partial failure: leave the worktrees intact so the user can inspect.
Point them at the run summary.

Print one line:
```
Integration branch ready: squad/<run-id>/integration. Run /ship:commit to ship.
```

## Guardrails

- Never push. Never `git reset --hard`. Never `git commit --amend`.
  Never `git rebase -i`.
- Never cherry-pick from a branch outside `squad/<run-id>/*`.
- Never delete branches outside the `squad/` prefix.
- Always abort (or preserve under `--auto-resolve`) on conflict — never
  attempt to silently resolve.
- Every retry (malformed return, resolver) is one-shot. Don't loop.
- Manifest + map must agree on `run_id` and task set; refuse otherwise.
- On partial failure, leave the integration branch intact. The
  `squad-run.json` records what happened.

## Task

Handle this request: $ARGUMENTS

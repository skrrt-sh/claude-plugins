---
name: spawn
description: Run N subagents in parallel for one big task. Splits the goal into independent pieces, dispatches one Agent per piece with isolation:worktree, cherry-picks committed work onto an integration branch ready for /ship:commit.
argument-hint: "<goal> [--yes]"
allowed-tools: Agent Read Grep Glob Bash(git *) Bash(date *)
disable-model-invocation: true
---

# Squad — parallel subagent dispatcher

> **This is a rare-case tool.** Worktrees and parallel dispatch are overhead. Use squad only when the goal is genuinely big AND splits into clearly independent pieces, each substantial on its own. For ordinary work, refuse with "this doesn't need squad — do it directly."

For one big task that splits cleanly into N≥2 independent pieces. Run them in parallel; cherry-pick the results.

Squad is fan-out, not a pipeline. No dependencies, no ordering, no resume. If pieces depend on each other, merge them or do it yourself.

You already know the Agent tool, git, and worktrees. This is the contract.

## Flow

1. **Decompose** the goal into N≥2 sibling tasks with disjoint writable files.
2. **Plan**: emit the task list as JSON in chat — this lets you mechanically verify the constraints. Refuse if N<2 or any two tasks share a path in `files`.

   ```json
   [
     {"title": "...", "files": ["..."], "tools": ["..."], "type": "fork|named", "profile": "...", "validate": "..."}
   ]
   ```

3. **Checkpoint** (skip on `--yes`): print the JSON plan, ask `proceed? [y / abort]`.
4. **Dispatch** in the assistant turn that responds to the user's `y`. Make all Agent tool calls in parallel within that turn. Don't take other actions between approval and dispatch — that's how the plan stays bound to the approval.
5. **Integrate**: create `squad/<id>/integration` from the original HEAD, cherry-pick each `done` child's branch in plan order.
6. **Cleanup**: remove each picked task's source worktree and branch. Tasks that weren't picked keep theirs for inspection.
7. **End**: print the hand-off line.

No on-disk state. The conversation is the source of truth.

## Dispatch — exact call

**Named** task:

```
Agent({
  description: <title>,
  subagent_type: <profile>,
  isolation: "worktree",
  prompt: <child prompt>
})
```

**Fork** task (requires `CLAUDE_CODE_FORK_SUBAGENT=1`):

```
Agent({
  description: <title>,
  isolation: "worktree",
  prompt: <child prompt>
})
```

`isolation: "worktree"` makes Claude Code create the worktree itself. Don't pass `cwd` — there is no such parameter. Each call returns the worktree path and branch when the child commits; record the branch.

## Child prompt template

```
# Objective
<title>

# Boundaries
Edit only these files:
<files>

# Tools
You may use: <tools>. Refuse anything outside the list.

# Validate
Before finishing, run: <validate>
The exit code must be zero. If non-zero, return `blocked`.

# Commit
Commit before finishing. Do not push.

# Final message — JSON only
{
  "status": "done | blocked | failed",
  "summary": "<1-3 sentences>",
  "commits": [{"sha": "<hex>", "subject": "<subject>"}],
  "blockers": [{"kind": "missing-dep|conflict|spec-unclear|validation-failed", "detail": "<text>"}]
}

`done` requires non-empty `commits` and empty `blockers`.
```

## Integrate

```bash
BASE=$(git rev-parse HEAD)
ID=$(date -u +%Y%m%dT%H%M%SZ)
git branch "squad/$ID/integration" "$BASE"
git switch "squad/$ID/integration"

# For each `done` task in plan order:
git cherry-pick "$BASE..<task.branch>"
```

**On cherry-pick conflict:** `git cherry-pick --abort`, print conflicting paths and the two tasks' titles, stop. Ask the user to resolve manually or merge those tasks into one and rerun.

Tasks with `status != done` are skipped — their commits stay on Claude-managed branches.

## Cleanup

After successful integration, remove each picked task's source worktree and branch:

```bash
# For each picked task:
git worktree remove "<task.path>" 2>/dev/null || true
git branch -D   "<task.branch>"   2>/dev/null || true
```

Claude auto-cleans worktrees only when the child made no changes. Worktrees with commits (i.e. all of ours) survive until you remove them — without this step they accumulate across runs.

Tasks that weren't picked (skipped, conflict, failed) keep their worktree + branch so the user can inspect.

## End

```
Integration branch ready: squad/<id>/integration. Run /ship:commit to ship.
```

## Hard rules

- Never push, `--force`, `--hard`, `--amend`, `rebase -i`.
- Never cherry-pick from a branch you didn't get back from your own Agent dispatch this run.
- Only delete a Claude-managed worktree/branch after you successfully cherry-picked from it. Never touch unpicked ones.
- One retry per child. No automatic conflict resolution.
- Refuse on: dirty parent, missing `CLAUDE_CODE_FORK_SUBAGENT=1`, unresolved named profile.

## Task

Handle this request: $ARGUMENTS

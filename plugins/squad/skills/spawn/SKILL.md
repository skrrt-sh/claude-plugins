---
name: spawn
description: Dispatches subagents per a squad task manifest, collects their structured returns, and cherry-picks their commits onto a `squad/<run-id>/integration` branch with per-task validation gates. Use when the agent needs to execute a squad plan, fan out subagents, run the children from a manifest, or merge child branches into one reviewable integration branch. Trigger for phrases like "spawn the subagents", "fan out the children", "execute the squad plan", "run the manifest", "dispatch the children and merge them", "/spawn".
argument-hint: "<run:<run-id> | <manifest-path> <worktree-map-path>> [--auto-resolve]"
user-invocable: true
---

# Squad Spawn Skill

> Skill instructions for executing a squad manifest end-to-end: fan out
> children, collect their structured returns, cherry-pick their commits
> onto an integration branch, and run per-task validation gates.

You are an orchestrator. You dispatch child subagents, you wait for their
structured returns, you replay their commits sequentially onto a staging
branch, and you escalate on conflicts instead of silently resolving. You
never push, never reset --hard, never amend. You end at "integration
branch ready" and hand off to `/commit`.

## Additional Resources

- [reference/child-prompt-template.md](reference/child-prompt-template.md)
  — the exact prompt structure each child receives (objective, output
  format, tool guidance, boundaries)
- [reference/return-contract.md](reference/return-contract.md) — the
  `squad.child-return.v1` shape and why every field matters
- [reference/integration-strategy.md](reference/integration-strategy.md)
  — why we cherry-pick (not rebase), replay ordering, conflict handling
- Claude Code sub-agents:
  <https://docs.claude.com/en/docs/claude-code/sub-agents>
- Anthropic multi-agent research system:
  <https://www.anthropic.com/engineering/multi-agent-research-system>

## Input Modes

`$ARGUMENTS` selects the mode:

- `run:<run-id>` — resolves manifest + map from
  `.claude/squad/runs/<run-id>/{manifest.json,worktree-map.json}`.
- `<manifest-path> <worktree-map-path>` — two explicit paths, space
  separated.

Optional flag anywhere in `$ARGUMENTS`:

- `--auto-resolve` — on cherry-pick conflict, dispatch a named
  `squad-resolver` subagent instead of pausing for the user. Requires the
  profile to exist in `.claude/agents/squad-resolver.md`; otherwise this
  skill falls back to pause-and-ask with a warning.

## Workflow

1. **Load and validate inputs.** Read the manifest and worktree map.
   Validate each against its schema in `../../templates/`. Refuse on
   schema errors or mismatched `run_id`.
2. **Create the integration branch.** `git switch -c
   squad/<run-id>/integration <base_ref>` from the parent checkout. If it
   already exists (e.g. from a prior spawn), refuse — the user must
   `/worktree cleanup:<run-id>` first or rename the prior run.
3. **Compute dispatch groups.** Kahn-style topological grouping of tasks
   by `dependencies`: group 0 is all tasks with no deps; group N is all
   tasks whose deps are satisfied by groups 0..N-1. Respect
   `SQUAD_MAX_PARALLEL` (default 4) per group by splitting oversize
   groups into sequential waves.
4. **Dispatch each group in one turn.** Use the Agent tool with multiple
   tool-call blocks in a single assistant message, one per child. Each
   call uses:
   - `subagent_type: <named-profile-name>` for named children (per
     task's `named_subagent_profile`).
   - Fork children are dispatched via the fork mechanism
     (`CLAUDE_CODE_FORK_SUBAGENT=1` must be set in the session —
     `templates/claude-settings.json` sets it). If fork is unsupported
     in the current runtime, refuse and tell the user.
   - `isolation: worktree` when the task has `worktree: true`, with
     `cwd` pointing at the worktree path from the map.
   - The prompt body from
     [reference/child-prompt-template.md](reference/child-prompt-template.md)
     with every placeholder filled in from the task. Include the
     required return shape inline.
5. **Collect returns.** Each child writes its return JSON to
   `.claude/squad/runs/<run-id>/returns/<task-id>.json` and the Agent
   tool result should echo it back. Validate each against
   `../../templates/child-return.schema.json`.
6. **Retry on malformed returns.** If a child's return fails validation,
   dispatch it a second time with the schema error attached to the
   prompt. On a second failure, mark that task `status: failed` and
   continue with other tasks.
7. **Replay.** Run `scripts/replay-children.sh <run-id>`. This script
   iterates tasks in ascending `merge_order` (dependencies used as
   tiebreakers), fetches each child's branch into
   `refs/squad-incoming/<run-id>/<task-id>`, cherry-picks every commit
   listed in that task's return, and runs the validation gate between
   tasks.
8. **Conflict escalation.**
   - **Default (no flag):** the replay script exits non-zero with the
     conflicting paths in stderr. Pause, print `git diff --name-only
     --diff-filter=U`, print both children's `summary` and
     `notes_for_orchestrator`, and wait for the user to resolve.
   - **`--auto-resolve`:** dispatch a named `squad-resolver` with a
     tight objective: "resolve these N unmerged paths by preserving the
     intent of both children's summaries; run the validation command;
     return a `squad.child-return.v1` with the resolving commit."
9. **Write the run summary.** Emit
   `.claude/squad/runs/<run-id>/squad-run.json` with per-task status,
   replay outcome, cherry-picked commits, validation results, and any
   failed tasks.
10. **Print the final message.** Name the integration branch, summarize
    the run in one table, and tell the user:
    `Integration branch ready: squad/<run-id>/integration. Run /commit to
    ship.`
11. **Never cleanup automatically.** Worktrees stay; cleanup is the
    user's explicit next step via `/worktree cleanup:<run-id>`.

## Child Dispatch — per-task rules

- **Fork** (`subagent_type: fork`) inherits the parent's conversation,
  prompt cache, tools, and model. Use when the task needs deep parent
  context or when siblings dispatched in the same turn can share the
  cache. Forks cannot be safely backgrounded for arbitrary work — run
  foregrounded.
- **Named** (`subagent_type: named`) with `named_subagent_profile =
  <name>` dispatches using `.claude/agents/<name>.md`. If the profile is
  missing, refuse for that task. Named children run with their
  pre-approved tools; unknown tools auto-deny when backgrounded.
- **Worktree isolation** attaches the child to the worktree in the map
  entry. The child's cwd is the worktree path; it sees a clean checkout
  at the task's branch.
- **Shared cwd** (no worktree) means the child runs in the parent's
  checkout. The parent checkout must be idle (no uncommitted changes)
  before spawn proceeds — enforced at step 2.

Every child receives, per the Anthropic multi-agent research post:

1. **Objective** — the task's `title` + `rationale`.
2. **Output format** — the `squad.child-return.v1` schema verbatim.
3. **Tool guidance** — the task's `allowed_tools` list + an explicit
   refusal instruction for tools outside it.
4. **Boundaries** — the `target_files` list with `read_only` flags, and
   an explicit instruction not to touch any file not in the list.
5. **Validation** — the task's `validation_command`; the child must run
   it and include the result in `tests_run`.

## Integration Strategy — summary

Full rationale in
[reference/integration-strategy.md](reference/integration-strategy.md).

- Staging branch: `squad/<run-id>/integration`, cut from `base_ref`.
- Replay order: ascending `merge_order`, `dependencies` as tiebreak.
- Replay method: `git cherry-pick` per commit in each child's
  `commits[]`. Never `git rebase` — rebase rewrites the child's history
  and makes partial-failure recovery ugly.
- Validation gate runs after each child's commits are picked.
- Children with `status != "done"` are skipped, not aborted — the
  integration branch keeps the successful children.

## Git Command Subset

Stay within this subset:

- `git status --short`
- `git diff --name-only [--diff-filter=U]`
- `git diff --stat`
- `git log --oneline -n <n>`
- `git rev-parse --verify <ref>`
- `git switch -c squad/<run-id>/integration <base_ref>`
- `git switch squad/<run-id>/integration`
- `git fetch <worktree_path> <branch>:refs/squad-incoming/<run-id>/<task-id>`
- `git cherry-pick <sha>`
- `git cherry-pick --abort`
- `git cherry-pick --continue`
- `git update-ref refs/squad-incoming/<run-id>/<task-id>` (for pruning)
- `git branch --list 'squad/*'`

Never use: `git push`, `git reset --hard`, `git commit --amend`, `git
rebase -i`, `git worktree remove --force`, `git clean`.

## Requirements

- `git` 2.35+ on PATH.
- `jq` on PATH for the replay script.
- Manifest + worktree map both exist and share the same `run_id`.
- `CLAUDE_CODE_FORK_SUBAGENT=1` in the session if any task is
  `subagent_type: fork`.
- For `--auto-resolve`, a named `squad-resolver` profile must exist in
  `.claude/agents/` of the consumer project.

## Guardrails

- Refuse if manifest and map disagree on `run_id` or task set.
- Refuse if a `named` task's `named_subagent_profile` is not installed.
- Refuse if the parent checkout has uncommitted changes before step 2.
- Refuse if two parallel tasks in the same dispatch group share any
  non-read-only `target_files` — this is a manifest bug; tell the user
  to re-run `/decompose`.
- On a malformed child return, retry exactly once; then mark failed and
  continue. Do not retry forever.
- On a cherry-pick conflict with no `--auto-resolve`, always pause and
  ask. Never silently resolve.
- On partial failure, leave the integration branch intact. Write
  `squad-run.json` with the outcome. Never delete the integration
  branch.
- Worktrees are **not** cleaned up by this skill. `/worktree
  cleanup:<run-id>` is the explicit next step (recommended after
  `/commit`).
- Never push. Never amend. Never rewrite history. Never invent test
  results.

## Task

Handle this request: $ARGUMENTS

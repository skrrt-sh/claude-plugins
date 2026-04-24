# Integration Strategy

How `/spawn` turns N child branches into one reviewable integration branch.

## Branch layout

```
parent checkout
  └─ base_ref (e.g. 7c3e9a1)
        └─ squad/<run-id>/integration   ← integration branch
              cherry-picks from:
                squad/<run-id>/<task-a>  ← child worktree
                squad/<run-id>/<task-b>  ← child worktree
                squad/<run-id>/<task-c>  ← shared cwd, may be unused
```

## Why cherry-pick, not rebase

1. **Rebase rewrites the child's history.** Cherry-pick copies commits
   onto the integration branch without touching the source branch.
   That keeps child worktrees usable if the user decides to inspect or
   re-run them, and keeps the cleanup step simple.
2. **Partial failure recovery is clean.** If task B's cherry-pick
   fails, task A's commits still live on the integration branch, the
   user can fix B manually, and C can still be picked afterwards. With
   a rebase-based flow, a failure in the middle is painful to reason
   about.
3. **Granularity is preserved.** Each child's logical commits survive
   on the integration branch. Downstream `/commit` (or `git rebase
   -i`) can reshape them if desired.
4. **No force-push pressure.** Cherry-picked commits are new commits on
   integration; no existing commit is moved.

## Ordering

1. Sort tasks by `merge_order` ascending.
2. Break ties using topological order of `dependencies` (a task that
   depends on another is picked after its dependency).
3. Skip tasks whose `status != "done"`. Their commits are left on
   their branches; the integration branch does not include them. The
   run summary records the skip.

## Per-task replay procedure

```bash
# Import the child's branch into a local ref we own
git fetch <worktree_path> <branch_name>:refs/squad-incoming/<run-id>/<task-id>

# Pick each commit in order
for sha in <task.commits[].sha>; do
  git cherry-pick "$sha"
done

# Validate
bash scripts/validate-gate.sh <run-id> <task-id>
# non-zero exit → escalate, see below
```

## Validation gate

After each task's commits land, `/spawn` runs that task's
`validation_command` from the integration branch's working tree. The
gate must exit 0 before the next task is picked. If the gate fails:

- Do **not** revert the commits.
- Print the failing command and the task id.
- Stop and ask the user whether to skip the next tasks, fix manually,
  or abort.

## Conflict handling

A `git cherry-pick` conflict means two children edited the same lines
and the manifest's file-ownership check was weaker than reality.

**Default mode (no flag):**

1. `git cherry-pick --abort`
2. Print `git diff --name-only --diff-filter=U` (the unmerged paths).
3. Print both conflicting children's `summary` and
   `notes_for_orchestrator`.
4. Pause and ask the user to resolve. Suggest: re-run `/decompose` with
   sequential `dependencies` between the conflicting tasks, or resolve
   manually and run `/spawn` again with just the remaining tasks.

**`--auto-resolve` mode:**

1. Do **not** abort the cherry-pick. Leave the unmerged state in place.
2. Dispatch a named `squad-resolver` subagent with:
   - Objective: resolve the N unmerged paths by preserving both
     children's intent.
   - Boundaries: only the unmerged files.
   - Validation: the orchestrator's integration-level smoke test (or
     the union of both tasks' validation commands).
3. On success, `git cherry-pick --continue` with the resolver's commit.
4. On failure, fall back to default mode.

If `.claude/agents/squad-resolver.md` doesn't exist, the flag falls back
to default mode with a warning.

## Final state

On success:

- `squad/<run-id>/integration` contains every successful child's commits.
- `.claude/squad/runs/<run-id>/squad-run.json` summarizes the run.
- Worktrees remain (explicit `/worktree cleanup:<run-id>` to remove).
- Integration branch is not pushed.

On partial failure:

- Successfully-replayed children's commits stay on integration.
- `squad-run.json` records which tasks failed or were skipped and why.
- No destructive cleanup. User inspects, optionally re-decomposes the
  failed pieces, and re-spawns.

## Why no octopus merge

An N-way merge commit (octopus) is tempting but:

- Has no per-file provenance once conflicts appear.
- Can't skip a single failed child without re-planning the merge.
- Produces a single opaque commit that `/commit` can't reshape.

Sequential cherry-pick preserves the atomic commits and plays nicely
with downstream commit-shaping.

## References

- Claude Code sub-agents (why structured returns matter):
  <https://docs.claude.com/en/docs/claude-code/sub-agents>
- Anthropic multi-agent research system (when fan-out wins):
  <https://www.anthropic.com/engineering/multi-agent-research-system>

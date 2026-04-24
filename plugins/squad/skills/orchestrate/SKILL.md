---
name: orchestrate
description: Runs the full squad flow end-to-end — decompose → worktree → spawn — with approval checkpoints between phases. Use when the user wants to run the entire squad pipeline on one goal without manually invoking each sub-skill, or when the agent needs the chained fan-out-then-merge workflow. Trigger for phrases like "orchestrate this", "run the full squad flow", "plan and fan out end-to-end", "decompose then spawn", "/orchestrate".
argument-hint: "<goal> [--yes] [--dry-run] [--no-worktree] [--auto-resolve] [--keep]"
user-invocable: true
---

# Squad Orchestrate Skill

> Chained wrapper that runs `/decompose`, then `/worktree`, then `/spawn`
> with a checkpoint between each phase. Produces an integration branch
> ready for `/commit`.

You are a pipeline runner. You invoke the three phase skills in order,
stop at checkpoints to let the user inspect the intermediate artifact,
and on abort roll back cleanly. You never skip a phase and you never
invent arguments.

## Additional Resources

- `/decompose` skill docs:
  [../decompose/SKILL.md](../decompose/SKILL.md)
- `/worktree` skill docs:
  [../worktree/SKILL.md](../worktree/SKILL.md)
- `/spawn` skill docs:
  [../spawn/SKILL.md](../spawn/SKILL.md)

## Flags (parsed from `$ARGUMENTS`)

- `--yes` — skip both checkpoints and run straight through.
- `--dry-run` — stop after `/decompose`. No worktrees, no spawn.
- `--no-worktree` — force all tasks to shared cwd. Refuses if the
  manifest has any task whose parallel-safety check requires isolation.
- `--auto-resolve` — forwarded to `/spawn` for conflict resolution.
- `--keep` — on abort, do not auto-run `/worktree cleanup:<run-id>`.
  Leave the worktrees in place for manual inspection.

Everything else in `$ARGUMENTS` is treated as the goal passed to
`/decompose`.

## Workflow

1. **Parse flags and goal.** Strip flags from `$ARGUMENTS`; the remainder
   is the goal. Refuse if the goal is empty.
2. **Phase 1 — decompose.** Invoke the `/decompose` skill with the goal.
   It writes `.claude/squad/runs/<run-id>/manifest.json`. Read back the
   `run_id`.
3. **Checkpoint 1.** Print the manifest summary table (task count,
   fork/named split, worktree yes/no, dependency graph). Unless
   `--yes` or `--dry-run`, ask the user: `proceed to worktrees?
   [y / edit / abort]`.
   - `y` — continue.
   - `edit` — open the manifest in the user's editor, then re-validate.
     Refuse to continue if validation fails.
   - `abort` — stop cleanly. No worktrees created. Exit.
4. **Stop here if `--dry-run`.** Print the run id and manifest path.
5. **Apply `--no-worktree` if set.** Read the manifest, rewrite every
   task's `worktree` to `false` and `worktree_name` to `null`, re-run
   the parallel-safety check on the modified manifest. If it fails,
   print the violating tasks and abort — do not proceed with shared cwd.
   Write the modified manifest back (preserving the `run_id`).
6. **Phase 2 — worktree.** Invoke the `/worktree` skill with
   `run:<run-id>`. It writes
   `.claude/squad/runs/<run-id>/worktree-map.json`.
7. **Checkpoint 2.** Print the worktree map summary. Unless `--yes`,
   ask: `proceed to spawn? [y / abort]`.
   - `y` — continue.
   - `abort` — unless `--keep`, invoke
     `/worktree cleanup:<run-id>` and then exit. With `--keep`, stop
     and leave the worktrees for manual inspection.
8. **Phase 3 — spawn.** Invoke the `/spawn` skill with
   `run:<run-id>`. Pass `--auto-resolve` if that flag was set.
9. **Final message.** Print: `Integration branch ready:
   squad/<run-id>/integration.` Summarize the run (tasks picked,
   validation passed, any skipped). Tell the user: `Run /commit to ship,
   then /worktree cleanup:<run-id> to remove the worktrees.`

## Checkpoint interaction

- Checkpoints read from stdin. In non-interactive environments (no tty),
  treat missing input as an abort, not a silent continue.
- The `edit` checkpoint option invokes `$EDITOR` on the manifest. If
  `$EDITOR` is unset, print a message pointing at the manifest path and
  ask the user to edit manually before responding `y`.
- Checkpoints never run destructive ops on their own — they only gate
  progression.

## Failure handling

- **Phase 1 fails (decompose refuses):** exit with the decompose error.
  No artifacts are written (decompose's own guardrail).
- **Phase 2 fails (worktree errors):** exit with the error. The
  partially-created worktrees, if any, are recorded by the worktree
  script's idempotent map file. Advise the user to run
  `/worktree cleanup:<run-id>` manually.
- **Phase 3 conflict (no `--auto-resolve`):** do not cleanup. The user
  must resolve via `/spawn` re-run with `--auto-resolve` or manual
  intervention.
- **Phase 3 validation-gate failure:** leave the integration branch
  intact. Do not cleanup. Report which task failed.
- **Any abort with worktrees present** triggers
  `/worktree cleanup:<run-id>` unless `--keep`.

## Guardrails

- Never skip a phase. If `/decompose` wasn't invoked, don't invoke
  `/worktree`. If `/worktree` wasn't invoked, don't invoke `/spawn`.
- `--yes` only bypasses checkpoints — it does not bypass the inner
  skills' guardrails. A malformed manifest still aborts Phase 2.
- Never invoke `/commit` automatically. Orchestrate ends at the
  integration branch; the user runs `/commit` explicitly (or enables
  it manually as a follow-up).
- Never retry a failed phase automatically more than once. Let the user
  decide whether to re-run.
- Never run `git push`, `git reset --hard`, or any destructive op
  yourself. Those are off-limits in every squad skill.

## Task

Handle this request: $ARGUMENTS

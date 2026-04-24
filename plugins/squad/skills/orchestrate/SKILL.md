---
name: orchestrate
description: End-to-end squad run. Invokes /squad:decompose, pauses at a single checkpoint, then invokes /squad:spawn. The chained wrapper for explore/plan/implement. Make sure to use this skill whenever the user wants to run the whole pipeline on one goal, plan and fan out end-to-end, orchestrate a multi-agent job, decompose and then spawn in one shot, or run the squad pipeline — even if they don't say the word "orchestrate".
argument-hint: "<goal> [--yes] [--dry-run] [--auto-resolve] [--keep-worktrees]"
allowed-tools: Read Bash(jq *)
---

# Squad Orchestrate Skill

> The chained wrapper. Plan, checkpoint, implement.

## Flags (parsed from `$ARGUMENTS`)

- `--yes` — skip the checkpoint.
- `--dry-run` — stop after `/squad:decompose`.
- `--auto-resolve` — forwarded to `/squad:spawn`.
- `--keep-worktrees` — forwarded to `/squad:spawn`.

Everything else in `$ARGUMENTS` is the goal.

## Workflow

1. **Plan**: invoke `/squad:decompose <goal>`. It writes the manifest to
   `.claude/squad/runs/<run-id>/manifest.json` and prints a summary
   table. Read back the `run_id`.
2. **Stop if `--dry-run`.** Print the run id and the manifest path.
3. **Checkpoint.** Unless `--yes`: print the summary table and ask
   `proceed? [y / edit / abort]`.
   - `y` — continue with the manifest on disk as written.
   - `edit` — the user opens
     `.claude/squad/runs/<run-id>/manifest.json` themselves (in their
     editor; orchestrate does **not** shell out to `$EDITOR` — it only
     reads and writes files). Tell them the path and wait for them to
     confirm they've saved. When they signal ready, reread the file
     from disk and re-run these checks:
     - JSON parses.
     - `run_id` is unchanged (if the user renamed it, refuse — the
       run dir on disk is already keyed to the original id).
     - Task ids are unique.
     - `dependencies` has no cycles (Kahn sort).
     - Every task has a non-empty `validation_command`.
     - No two parallelizable tasks share a writable `target_files`
       path.
     If any check fails, show the specific error and offer `edit`
     again or `abort`. Only continue once validation passes.
   - `abort` — stop. No worktrees exist yet, so nothing to clean up.
   The manifest on disk is the single source of truth for step 4.
   Orchestrate does not hold an in-memory copy to diff against.
4. **Implement**: invoke `/squad:spawn run:<run-id>`, forwarding
   `--auto-resolve` and `--keep-worktrees` if set.
5. **Final message** is spawn's own:
   `Integration branch ready: squad/<run-id>/integration. Run /ship:commit to ship.`

## Guardrails

- Never skip `/squad:decompose` — spawn requires a valid manifest.
- `--yes` bypasses the checkpoint, not the inner skills' guardrails.
  A malformed manifest still aborts `/squad:spawn`.
- Never invoke `/ship:commit` automatically. The user ships explicitly.
- Never retry a failed phase automatically more than once.

## Task

Handle this request: $ARGUMENTS

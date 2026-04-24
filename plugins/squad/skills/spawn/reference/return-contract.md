# Child Return Contract

Every child subagent spawned by `/spawn` must return a JSON document
matching `squad.child-return.v1`. The canonical schema is
[`../../templates/child-return.schema.json`](../../../templates/child-return.schema.json).

## Why a strict contract

- **Deterministic replay.** `/spawn` cherry-picks the commits listed in
  `commits[]`. Free-form prose can't drive `git cherry-pick`.
- **Honest validation.** `tests_run[]` records the exact command and
  exit code. The orchestrator re-runs the validation command on the
  integration branch; a child that lied is exposed there.
- **Cheap context.** The orchestrator reads summaries, not transcripts.
  Subagents that dump logs back to the parent would defeat the main
  reason to use subagents at all (per the Anthropic sub-agents docs).

## Field reference

| Field                    | Type     | Required | Meaning                                                                |
| ------------------------ | -------- | :------: | ---------------------------------------------------------------------- |
| `return_shape`           | const    |    yes   | Always `"squad.child-return.v1"`                                       |
| `task_id`                | string   |    yes   | Must match the dispatched task's id                                    |
| `status`                 | enum     |    yes   | `done` / `blocked` / `failed`                                          |
| `summary`                | string   |    yes   | ≤120 words, plain English, imperative voice. No transcript paste      |
| `touched_files[]`        | array    |    yes   | `{path, change: added\|modified\|deleted, bytes_delta: int}`          |
| `commits[]`              | array    |    yes   | `{sha, subject}` — the commits `/spawn` will cherry-pick              |
| `tests_run[]`            | array    |    yes   | `{command, exit_code, passed?, failed?}` — at least the validation cmd |
| `blockers[]`             | array    |    yes   | `{kind, detail}` — empty on `status: done`                            |
| `merge_recommendation`   | enum     |    yes   | `cherry-pick` / `squash` / `abort`                                     |
| `notes_for_orchestrator` | string   |    no    | ≤60 words, e.g. "safe to parallelize with X"                          |

## Status semantics

- **`done`** — the task is complete, validation passed, commits exist on
  the child's branch. `blockers` must be empty.
- **`blocked`** — the task is incomplete for a recoverable reason. A
  human or a different subagent could resolve it. Include a blocker
  kind and a detail explaining what's needed.
- **`failed`** — unrecoverable from the child's side (tooling broken,
  permissions denied, spec fundamentally wrong). The orchestrator will
  mark the task failed and continue without its commits.

## Merge recommendation

- **`cherry-pick`** — the default. Replay each commit in `commits[]`
  one by one.
- **`squash`** — the orchestrator should combine the child's commits
  into one when picking. Use when the child made many intermediate
  commits that are not worth preserving individually.
- **`abort`** — do not pick this child's commits. Use when the child
  discovered mid-task that the change shouldn't land.

## Validation and retries

- `/spawn` validates the return against the JSON schema. Malformed
  returns trigger **exactly one retry** with the schema error attached
  to the re-dispatch prompt. A second failure marks the task `failed`.
- `tests_run[]` must include at least one entry matching the task's
  `validation_command` (or a blocker of kind `validation-failed`
  explaining why).

## Writing the return

The child writes the JSON to
`.claude/squad/runs/<run_id>/returns/<task_id>.json` in the consumer repo
**and** echoes it in the final message. The orchestrator reads from the
file; the echoed copy is a fallback for runtimes that don't persist the
file reliably.

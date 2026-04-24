# Child Prompt Template

Every child dispatched by `/spawn` receives a prompt with these five
sections. The template comes from Anthropic's multi-agent research system
post (<https://www.anthropic.com/engineering/multi-agent-research-system>),
which states each subagent needs "an objective, an output format, guidance
on the tools and sources to use, and clear task boundaries."

## Template

```text
# Objective

<task.title>

<task.rationale>

# Output format

Return a JSON document matching `squad.child-return.v1`. Exact schema:

<paste the contents of templates/child-return.schema.json here, or inline
 the required fields: return_shape, task_id, status, summary, touched_files,
 commits, tests_run, blockers, merge_recommendation>

Write your return to `.claude/squad/runs/<run_id>/returns/<task.id>.json`
before reporting back. Echo the same JSON in your final message.

# Tools

You may use: <task.allowed_tools joined by ", ">.
Refuse any tool outside this list. Do not attempt to discover new tools.

# Boundaries

Edit only these files:
- <path> (<read_only ? "read-only" : "writable">)
- ...

Do not touch any file not in the list. If the task requires touching
another file, stop and return `status: blocked` with a `spec-unclear`
blocker.

# Validation

Before returning `status: done`, run:

    <task.validation_command>

Record the exit code, passed count, and failed count in `tests_run`.
If the command fails, return `status: blocked` with a
`validation-failed` blocker and do not commit.

# Commits

Make one or more git commits on your current branch before returning.
Include the commit SHAs and subjects in `commits[]`. /spawn will
cherry-pick these in `merge_order`. Use the ship plugin's `/commit` skill
if available; otherwise write the commit directly with a conventional
header and a body.

# Context

- run_id: <manifest.run_id>
- goal: <manifest.goal>
- base_ref: <manifest.base_ref>
- cwd: <worktree_path or "parent checkout">
- merge_order: <task.merge_order>
- dependencies: <task.dependencies>
```

## Fill-in rules

- **No placeholder leakage.** Every `<...>` above must be replaced before
  the prompt is sent. A child that sees unfilled placeholders should
  refuse and return `status: failed` with `spec-unclear`.
- **No extra context.** Do not include parent conversation snippets for
  named children (fresh-context principle). For forks, the parent
  conversation is inherited automatically — do not also re-paste it.
- **Short and dense.** The whole prompt should fit in under 2k tokens.
  Avoid restating the schema in prose; point at the schema file and
  include the required field names.

## Escalation path

If the child cannot complete the task, it must return `status: blocked`
with a specific blocker kind:

| Kind                  | Meaning                                                  |
| --------------------- | -------------------------------------------------------- |
| `missing-dep`         | A dependency task's output isn't available yet.          |
| `conflict`            | Two siblings' changes conflict at the source level.      |
| `spec-unclear`        | The task description isn't actionable.                   |
| `validation-failed`   | Code is written but the validation command does not pass.|

`status: failed` is for unrecoverable errors (tooling broken, no
permissions, etc.). Prefer `blocked` when a human could resolve the
issue.

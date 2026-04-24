---
name: decompose
description: Decomposes a task into a multi-subagent manifest with per-child file ownership, fork-vs-named-subagent selection, worktree decision, validation commands, and merge order. Use when the agent needs to split parallel work, plan a fan-out, break a goal into subagent tasks, or produce a squad task manifest. Trigger for phrases like "decompose this", "break this into subagent tasks", "split the work across agents", "plan fan-out", "build a task manifest", "plan parallel subagents", "split into forked and named subagents", "squad decompose".
argument-hint: "<goal>"
user-invocable: true
---

# Squad Decompose Skill

> Skill instructions for turning one user goal into a multi-subagent task manifest.

You are a planner. Your job is to decompose a user's goal into the smallest
set of self-contained subtasks that can be executed by child subagents, each
with crisp file ownership, a validation command, and a clear merge order.
You never spawn children here — you only emit the manifest and stop.

## Additional Resources

Before choosing how to split a task, read:

- [reference/fork-vs-named.md](reference/fork-vs-named.md)
- [reference/decomposition-patterns.md](reference/decomposition-patterns.md)
- Anthropic sub-agents docs: https://docs.claude.com/en/docs/claude-code/sub-agents
- Anthropic multi-agent research system post (when multi-agent wins vs loses):
  https://www.anthropic.com/engineering/multi-agent-research-system

## Workflow

1. **Read the goal.** Treat `$ARGUMENTS` as the user's full goal. If the user
   passed file paths, read them first — do not decompose blind.
2. **Screen for single-agent work.** If the goal is a single file edit, a
   trivial fix, or exploratory research where the plan will change every few
   minutes, refuse and tell the user to do the work directly. See Guardrails.
3. **Pick a decomposition pattern** from
   [reference/decomposition-patterns.md](reference/decomposition-patterns.md):
   `breadth-first`, `pipeline`, or `map-reduce`.
4. **Draft each child.** For each subtask, write:
   - `id` (kebab-case, unique in manifest)
   - `title` (≤80 chars), `rationale` (1–3 sentences on why this child exists)
   - `target_files` (list of `{path, read_only}`). Every file belongs to at
     most one non-read-only owner (see File Ownership Rules below)
   - `allowed_tools` (minimal set — e.g. `["Read","Edit","Write","Bash(npm test:*)"]`)
   - `validation_command` (must exit 0 on success; mandatory, no exceptions)
   - `dependencies` (task ids that must merge before this one)
   - `merge_order` (integer; lower merges first)
5. **Choose subagent type per child** using the rules in
   [reference/fork-vs-named.md](reference/fork-vs-named.md) and the
   "Decision Rules" section below. Set `subagent_type` = `"fork"` or
   `"named"`. For `"named"`, also set `named_subagent_profile` (must exist
   in `.claude/agents/` of the consumer project — note the requirement if
   the profile is missing; do not invent profiles).
6. **Choose worktree per child** using the same Decision Rules. Set
   `worktree: true` + a kebab-case `worktree_name` when isolation is needed.
7. **Compute `merge_order` and validate dependencies** — run a cycle check
   (Kahn-style topological sort). Refuse on cycles.
8. **Validate parallel safety.** Any two tasks with no mutual dependency
   are candidates to run in parallel. If they share a non-read-only
   `target_files` path, bump one of them to depend on the other (forcing
   sequential merge) or refuse.
9. **Generate a `run_id`** — kebab-case, include the dominant scope and a
   short random slug, e.g. `auth-rate-limit-2026-04-24-a1b2`.
10. **Emit the manifest** as strict JSON per
    `../../templates/task-manifest.schema.json`. Validate against the schema
    before writing. Write to
    `.claude/squad/runs/<run-id>/manifest.json` in the consumer repo
    (create the directory if absent; suggest gitignoring `.claude/squad/`).
11. **Print a one-screen summary table** with columns: `id | title |
    subagent | worktree | merge_order | deps`. Add a final line pointing at
    the manifest path.
12. **Stop.** Do not call `/worktree` or `/spawn`. The user runs them, or
    invokes `/orchestrate` for the chained flow.

## Output Location

Every decompose run writes under
`.claude/squad/runs/<run-id>/` in the consumer repo:

- `manifest.json` — the task manifest (required)
- `summary.md` — the human-readable table printed in step 11 (optional, nice-to-have)

Downstream skills (`/worktree`, `/spawn`, `/orchestrate`) accept either
an explicit `manifest.json` path or the shorthand `run:<run-id>`, which
they resolve to `.claude/squad/runs/<run-id>/manifest.json`.

## Manifest Contract

Validated against
[../../templates/task-manifest.schema.json](../../templates/task-manifest.schema.json).
Top-level: `manifest_version`, `run_id`, `goal`, `base_ref`, `pattern`,
`tasks[]`, `created_at`, `created_by`. Per-task required fields are listed
in the workflow above; consult the schema for exact types, enums, and
conditional requirements (a `named` task requires `named_subagent_profile`;
a `worktree: true` task requires `worktree_name`).

## Decision Rules

These rules are canonical. The same wording lives in the `squad` CLAUDE.md
block installed by `/setup`.

**Fork when:**
- The child needs deep parent context (recent conversation, loaded files,
  in-flight reasoning).
- The child's work is tightly coupled to a parent decision still in play.
- You want shared prompt cache across siblings dispatched in the same turn.
- The task is short enough that context isolation would cost more than it saves.

**Named when:**
- The child needs a different tool set or permissions than the parent.
- The child's job is well-specified and self-contained (docs, tests, code
  generation).
- Backgrounded execution is expected — named subagents pre-approve their
  tools and auto-deny unknown ones; forks cannot be safely backgrounded for
  arbitrary work.
- You want fresh context to avoid parent-context drift or run a specialist
  prompt.

**Worktree when:**
- Two or more tasks will edit overlapping directories in parallel.
- A task needs a distinct `base_ref` from siblings.
- A task's validation command must run without interference from other
  tasks' uncommitted changes.

**Skip worktree when:**
- Docs-only or a single isolated file.
- Task depends on uncommitted parent state you don't want to reproduce.
- Task is serial (no concurrent sibling) and the parent's checkout is idle.

**Parallel when** (all must hold):
- Tasks share no non-read-only `target_files`.
- Tasks have no mutual `dependencies`.
- Each task has an independent `validation_command`.

**Sequential when:**
- Any parallel precondition fails.
- The multi-agent research post's warning applies — tightly-coupled
  fine-grained coding where children would constantly step on each other.
  Prefer one agent or a sequential pipeline.

## File Ownership Rules

- A `target_files` path appears in at most one task as a non-read-only owner.
- A path may appear in multiple tasks as `read_only: true` (e.g. a sibling's
  API surface).
- Two tasks that share a non-read-only owner path must have an explicit
  `dependencies` edge between them, forcing sequential merge. If no natural
  order exists, merge them into one task.
- Do not list generated files (build output, lockfiles) in `target_files`.

## Pattern Selection

- **breadth-first** — 2–5 independent children finish together; best for
  broad research, parallel refactors with disjoint file sets, or multi-doc
  edits. Default when children are truly independent.
- **pipeline** — children form a chain where each consumes the previous's
  output (e.g. schema → implementation → tests → docs). Each has a
  dependency on the prior.
- **map-reduce** — N sibling workers + one reducer. Workers share a
  structure; the reducer merges and validates. Use when combining many
  small artifacts into one (e.g. per-file migrations + one index update).

## Guardrails

- **Refuse** if the decomposition produces fewer than 2 independent
  subtasks — print "this is a single-agent task, just do it directly" and
  stop. No manifest is written.
- **Refuse** if any task lacks a `validation_command`. Every child must be
  independently verifiable.
- **Refuse** on cyclic dependencies. Print the cycle.
- **Refuse** if two parallel tasks share a non-read-only path and you
  cannot naturally order them.
- **Warn (don't block)** when breadth-first fan-out is chosen for
  fine-grained coding — cite the multi-agent post and suggest a pipeline
  or a single agent.
- Do not invent a `named_subagent_profile` that does not exist. If the
  child would benefit from a named profile the consumer lacks, mark the
  child `subagent_type: fork` and note in `rationale` which named profile
  would be ideal so the user can author it later.
- Never spawn, never create worktrees, never run git commands here.
  `/decompose` is planning only.

## Task

Handle this request: $ARGUMENTS

---
name: decompose
description: Plans a multi-subagent run. Reads the goal, picks a pattern (pipeline, breadth-first, or map-reduce), defines per-child scope with file ownership and a validation command, and writes a task manifest. This is the "plan" step in explore/plan/implement — it produces a manifest and stops. Make sure to use this skill whenever the user asks to split work, plan a fan-out, build a squad manifest, decompose a goal for subagents, break a task into parallel work, plan subagent tasks, or turn a goal into a task manifest — even if they don't say the word "decompose".
argument-hint: "<goal>"
allowed-tools: Read Grep Glob Bash(jq *) Bash(mkdir *) Write
---

# Squad Decompose Skill

> The "plan" step of squad. Produces a task manifest and stops.

You are a planner. Given a user goal, draft a manifest that a subsequent
`/squad:spawn` run can execute. Never spawn children here, never create
worktrees, never run git mutating commands.

## Workflow

1. **Explore first if needed.** If the goal references code you haven't
   read, read the files before drafting the manifest. Grep / Glob for
   anything you're unsure about. Don't decompose blind.
2. **Screen for single-agent work.** If the goal is one file, a typo, a
   small targeted change, or exploratory work — refuse. Tell the user
   to just do the work directly. Do not produce a manifest.
3. **Pick a pattern:** `pipeline` (linear chain, each step reads the
   previous), `breadth-first` (independent parallel children),
   `map-reduce` (N workers + one reducer). One sentence in the manifest
   explaining the choice.
4. **Draft each task** with these fields. Keep disjoint file ownership
   — every non-read-only path appears in exactly one task.
5. **Pick subagent type per task** using the decision rules below.
6. **Generate a `run_id`** — a short kebab-case slug like
   `auth-rate-limit-2026-04-24`.
7. **Write the manifest** to
   `.claude/squad/runs/<run_id>/manifest.json` (create the directory).
   Print a short summary table and stop.

## Manifest shape

Write strict JSON. No version fields, no timestamps — keep it minimal.

```json
{
  "run_id": "auth-rate-limit-2026-04-24",
  "goal": "<user goal verbatim>",
  "base_ref": "<git ref; default current HEAD SHA>",
  "pattern": "pipeline | breadth-first | map-reduce",
  "pattern_reason": "<one sentence>",
  "tasks": [
    {
      "id": "ratelimit-lib",
      "title": "Add token bucket rate limiter module",
      "rationale": "<why this child exists, 1–3 sentences>",
      "target_files": ["src/ratelimit/token_bucket.ts", "tests/ratelimit/token_bucket.test.ts"],
      "allowed_tools": ["Read", "Edit", "Write", "Bash(npm test *)"],
      "subagent_type": "named",
      "named_subagent_profile": "typescript-module-author",
      "validation_command": "npm test -- --run tests/ratelimit",
      "dependencies": [],
      "merge_order": 1
    }
  ]
}
```

Every task has its own git worktree in v0.1.0 (`/squad:spawn` creates
them; you don't need a `worktree: true` field). For `fork` tasks, omit
`named_subagent_profile`. For tasks depending on others, list their ids
in `dependencies` and set `merge_order` accordingly.

## Decision rules

**Fork when:** child needs deep parent context; short task where a
named profile's setup cost would dominate; you want shared prompt cache
across siblings dispatched in the same turn.

**Named when:** child needs a specialist prompt or different tools;
well-specified self-contained work (docs, tests, code-gen); you want
fresh context to avoid parent drift. The profile must exist in the
consumer's `.claude/agents/<name>.md` — `/squad:spawn` will refuse if
it's missing, so if the ideal profile doesn't exist, use `fork` and
note the desired profile in `rationale`.

**Parallel when:** tasks share no writable paths, no mutual
dependencies, each has its own validation command.

**Sequential when:** any of those fails, or the work is tightly-coupled
fine-grained coding where children would step on each other (per the
Anthropic multi-agent research post — see reference).

## Additional resources

- [reference/fork-vs-named.md](reference/fork-vs-named.md) — canonical
  Anthropic terminology for the two subagent shapes, with source links.

## Guardrails

- Refuse if the goal produces fewer than 2 independent subtasks. Say
  "this is a single-agent task, just do it directly" and stop. No
  manifest is written.
- Refuse if any task lacks a `validation_command`. Every child must be
  independently verifiable.
- Refuse on cyclic dependencies. Run a Kahn-style topological sort on
  `dependencies` and print the cycle if it fails.
- Refuse if two parallel tasks share a writable file — sequence them
  via `dependencies`, or merge them into one task.
- Refuse if task ids are not unique.
- Never spawn children, never `git worktree add`, never mutate git.

## Task

Handle this request: $ARGUMENTS

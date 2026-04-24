# Decomposition Patterns

Three patterns are supported by the `pattern` field in the task manifest.
Pick the one that matches the shape of the work; don't force a pattern that
doesn't fit.

## breadth-first

N independent children run in parallel and merge when all are done. Best
when children touch disjoint file sets and no child depends on another's
output.

```
                ┌── child-a (docs)
  /decompose ───┼── child-b (lib)
                └── child-c (config)
```

- Good for: parallel refactors with disjoint owners, multi-doc edits,
  independent test suites, multi-file migrations that don't cross files.
- Dependencies: `[]` for every child.
- `merge_order`: can be sequential in manifest (doesn't affect parallelism
  of execution, only of merge replay).
- Risk: file-ownership violations. The manifest must pass the
  parallel-safety check (no shared non-read-only paths).

## pipeline

Children form a chain where each consumes the previous's output. The
classic shape is `schema → implementation → tests → docs`.

```
  /decompose ── child-a ── child-b ── child-c
```

- Good for: staged work where step N genuinely cannot start until step
  N-1 lands. Schema changes before consumers, spec before implementation,
  implementation before targeted tests.
- Dependencies: each child depends on the previous, forming a linear
  chain.
- Execution is sequential — parallelism is nil.
- Prefer pipeline over breadth-first whenever downstream children need
  to read files the upstream child produced.

## map-reduce

N sibling "worker" children + one "reducer" child. Workers produce similar
artifacts; the reducer combines and validates them.

```
                ┌── worker-1 ──┐
  /decompose ───┼── worker-2 ──┼── reducer
                └── worker-N ──┘
```

- Good for: combining many small artifacts into one index (e.g. per-file
  migrations + one migrations-list update), batch transformations with a
  final cross-file consistency check, multi-module updates rolled up into
  one release-notes entry.
- Dependencies: reducer depends on all workers; workers depend on nothing.
- `merge_order`: workers first (any order), reducer last.
- Risk: the reducer must not edit files the workers own. The reducer
  owns its own output file (e.g. `index.ts`, `migrations/manifest.json`);
  worker files are `read_only` in the reducer's `target_files`.

## Choosing a pattern

- Start with the data flow, not the number of children. Does B need A's
  output? → pipeline. Are workers producing one combined artifact? →
  map-reduce. Everything else with 2+ independent deliverables? →
  breadth-first.
- If you cannot articulate a clean dependency graph in one sentence, the
  task isn't decomposable — refuse and tell the user to do it directly.

## Anti-patterns

- **Parallel children editing overlapping source** — ownership violation,
  refuse.
- **Pipeline for speed reasons** when children don't actually depend on
  each other — use breadth-first instead.
- **Over-decomposition into trivial children** — fewer than 2 meaningfully
  independent deliverables means a single agent is better. See Guardrails
  in `SKILL.md`.
- **Map-reduce without a real reducer** — if there's no cross-child
  consistency step, you have breadth-first.

## See also

- Anthropic multi-agent research system — when breadth-first fan-out
  wins and when it loses:
  <https://www.anthropic.com/engineering/multi-agent-research-system>
- Claude Code agent teams:
  <https://docs.claude.com/en/docs/claude-code/agent-teams>

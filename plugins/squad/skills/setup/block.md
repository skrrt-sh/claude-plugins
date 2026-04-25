<!-- skrrt:squad -->
## Multi-agent fan-out — skrrt squad

> **Rare tool, not a default.** Squad spins up parallel git worktrees and dispatches multiple subagents — that's overhead. Use it only when a task is genuinely large AND cleanly splits into independent pieces. For everything else (most things), just do the work directly. Never reach for squad as the first option.

`/squad:spawn <goal>` splits a big task into N≥2 independent pieces, runs N subagents in parallel (each in its own auto-managed git worktree via `isolation: "worktree"`), and cherry-picks their commits onto `squad/<id>/integration` ready for `/ship:commit`.

Squad is **user-invocable only** — Claude won't auto-trigger it from natural-language requests. The user explicitly types `/squad:spawn` when they want fan-out.

- `/squad:spawn <goal>` — plan, checkpoint, run.
- `/squad:setup` — install.

Flag: `--yes` (skip checkpoint).

### Use squad for

A big task that cleanly splits into N≥2 independent pieces with disjoint writable files. The bar is high: each piece should be substantial on its own, otherwise the dispatch + integration overhead costs more than it saves.

### Don't use squad for

- Anything one agent can do in a single pass — most tasks.
- Single-file edits — just do them.
- Pipelines / ordered tasks — squad is fan-out, not orchestration.
- Tightly-coupled work where children would conflict on the same files.
- Speculative parallelism on small work — the overhead exceeds the gain.

### Setup

`/squad:setup` writes `CLAUDE_CODE_FORK_SUBAGENT=1` to `.claude/settings.local.json` (required for fork dispatch on Claude Code v2.1.117+). Reopen Claude Code after setup so the env var is picked up.
<!-- /skrrt:squad -->

<!-- skrrt:squad -->
## Multi-agent orchestration — skrrt squad

This project uses the **skrrt squad** plugin to decompose work and fan out to
subagents before shipping. Use these skills before `/commit` when a task is
large enough to split:

- `/decompose <goal>` — produces a task manifest (JSON) with per-child scope,
  file ownership, fork-vs-named choice, worktree decision, and validation
  command. Emits the manifest and stops — does not spawn anything.
- `/worktree <manifest-path>` — creates isolated git worktrees per task under
  `<repo>-worktrees/<name>`, branched from manifest `base_ref` as
  `squad/<run-id>/<task-id>`. Cleanup via `/worktree cleanup:<run-id>`.
- `/spawn <manifest-path> <worktree-map-path>` — dispatches children,
  collects structured returns, cherry-picks commits onto an integration
  branch in `merge_order`, runs per-child validation gates. Ends at an
  integration branch — does not commit or push.
- `/orchestrate <goal>` — chained wrapper: decompose → worktree → spawn with
  approval checkpoints between phases. Flags: `--yes` (skip checkpoints),
  `--dry-run` (decompose only), `--no-worktree` (force shared cwd;
  rejects if unsafe), `--auto-resolve` (let a resolver subagent handle
  cherry-pick conflicts), `--keep` (don't auto-cleanup on abort).
- `/setup` — re-runs squad's setup (updates this block).

After `/spawn` (or `/orchestrate`) finishes, use `/commit` from the ship
plugin to turn the integration branch into a clean commit series, then
`/pr` to ship.

### Fork vs Named vs Worktree — decision matrix

| Signal                                          | Fork | Named | Worktree |
| ----------------------------------------------- | :--: | :---: | :------: |
| Needs parent context deeply                     |  yes |   no  |    —     |
| Needs different tool set or permissions         |   no |   yes |    —     |
| Self-contained, well-specified task             |   ok |   yes |    —     |
| Backgrounded / long-running                     |  avoid |   yes |    —     |
| Shares prompt cache with siblings (same turn)   |  yes |   no  |    —     |
| Edits overlap with sibling in parallel          |    — |    —  |    yes   |
| Needs distinct base ref                         |    — |    —  |    yes   |
| Docs-only or single isolated file               |    — |    —  |    skip  |
| Tightly-coupled fine-grained coding             |  avoid parallel |  avoid parallel |    —     |

### Parallelize only when all hold

- Tasks share no non-read-only `target_files`.
- Tasks have no mutual `dependencies`.
- Each task has its own `validation_command`.

Otherwise, sequence them.

### Glossary (Anthropic terms)

- **Fork** — a subagent that inherits the full parent conversation, with the
  same system prompt, tools, and model. Shared prompt cache. Requires
  `CLAUDE_CODE_FORK_SUBAGENT=1`. See
  https://docs.claude.com/en/docs/claude-code/sub-agents.
- **Named subagent** — a subagent with its own definition in
  `.claude/agents/`, fresh context, its own model, and pre-approved tools.
  Tools outside its allowlist are auto-denied when the subagent is
  backgrounded. See
  https://docs.claude.com/en/docs/claude-code/sub-agents.
- **Worktree isolation** — set by `/decompose` when a task needs a detached
  checkout, realized by `/worktree` via `git worktree add`. See
  https://docs.claude.com/en/docs/claude-code/common-workflows.
  Gitignored files are brought in via `.worktreeinclude`; heavy directories
  can be symlinked via `worktree.symlinkDirectories`.

### When NOT to use squad

- Single-file edits — just do the work directly.
- Tightly-coupled refactors where children would constantly step on each
  other. Anthropic's multi-agent research post warns this is where
  multi-agent loses to single-agent:
  https://www.anthropic.com/engineering/multi-agent-research-system.
- Exploratory work where the plan changes every few minutes.

If `/decompose` produces fewer than 2 independent subtasks, it will refuse —
do the work directly with one agent.
<!-- /skrrt:squad -->

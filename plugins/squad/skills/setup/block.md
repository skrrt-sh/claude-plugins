<!-- skrrt:squad -->
## Multi-agent orchestration — skrrt squad

Use the skrrt squad plugin to decompose a large task, fan out to child
subagents in isolated git worktrees, and land their work on an
integration branch ready for `/ship:commit`. This is the
*explore / plan / implement* pattern split across three skills:

- `/squad:decompose <goal>` — **plan**. Drafts a task manifest with
  per-child scope, file ownership, fork-vs-named decision, validation
  command, and merge order. Writes to
  `.claude/squad/runs/<run-id>/manifest.json`. Does not create
  worktrees, does not spawn anything.
- `/squad:spawn run:<run-id>` — **implement**. Creates worktrees,
  dispatches children, cherry-picks their commits onto a
  `squad/<run-id>/integration` branch with per-task validation gates,
  cleans up on success. Flags: `--auto-resolve` (let `/squad:resolver`
  handle cherry-pick conflicts), `--keep-worktrees` (skip auto-cleanup).
- `/squad:orchestrate <goal>` — chained wrapper: decompose, one
  checkpoint, spawn. Flags: `--yes`, `--dry-run`, `--auto-resolve`,
  `--keep-worktrees`.

Supporting skills:

- `/squad:resolver` — auto-invoked by `/squad:spawn --auto-resolve` when
  a cherry-pick conflicts. Runs as a fork; do not invoke directly.
- `/squad:setup` — re-runs this install.

After `/squad:spawn` or `/squad:orchestrate`, use `/ship:commit` to turn
the integration branch into a clean commit series, then `/ship:pr` to
open a PR.

### Runtime artifacts live in `.claude/squad/` (gitignored)

Every run writes per-run state to `.claude/squad/runs/<run-id>/`:

- `manifest.json` (from `/squad:decompose`)
- `worktree-map.json` (from `/squad:spawn`)
- `returns/<task-id>.json` (one per child)
- `squad-run.json` (from `/squad:spawn`)
- `_archived/<run-id>-<timestamp>/` (after cleanup)

These are short-lived machine-local session data. `/squad:setup` adds
`.claude/squad/` to `.gitignore` so they never get committed.

The worktrees themselves live outside the repo tree at
`<parent-of-repo>/<repo-name>-worktrees/<run-id>/<task-id>/` — linked
git worktrees, not inside the repo, so there's nothing to gitignore
there. The `<run-id>` segment keeps concurrent runs with shared task
ids from colliding on disk.

### Decision rules

**Fork** when the child needs deep parent context or you're dispatching
same-turn siblings that can share the prompt cache. Requires
`CLAUDE_CODE_FORK_SUBAGENT=1` in the session env — `/squad:setup`
writes this to `.claude/settings.local.json` unconditionally because
the resolver skill also runs as a fork, so squad cannot function
without it. Reopen the Claude Code session after running `/squad:setup`
so the env var is picked up.

**Named** when the child needs a specialist prompt / different tools /
fresh context. The profile must resolve in one of Claude Code's agent
lookup paths: project `.claude/agents/`, user `~/.claude/agents/`, or
any enabled plugin's bundled `agents/` dir. `/squad:spawn` refuses
only if none of those resolve.

**Parallel** (same dispatch group) when tasks share no writable paths,
no mutual `dependencies`, and each has its own `validation_command`.
Otherwise sequence them via `dependencies` + `merge_order`.

Every task runs in its own worktree in v0.1.0. Shared-cwd tasks are
deferred to a later version.

### When NOT to use squad

- Single-file edits — just do the work directly.
- Tightly-coupled refactors where children would constantly step on
  each other. Anthropic's multi-agent research post warns this is
  where multi-agent loses to single-agent:
  <https://www.anthropic.com/engineering/multi-agent-research-system>.

If `/squad:decompose` produces fewer than 2 independent subtasks, it
refuses. Do the work directly.

### References

- Sub-agents: <https://code.claude.com/docs/en/sub-agents>
- Skills: <https://code.claude.com/docs/en/skills>
- Common workflows (worktrees): <https://code.claude.com/docs/en/common-workflows>
<!-- /skrrt:squad -->

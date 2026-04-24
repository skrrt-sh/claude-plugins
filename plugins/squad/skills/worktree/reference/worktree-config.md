# Worktree Configuration — Reference

Claude Code ships worktree primitives that squad leans on. This file recaps
the bits squad touches. Canonical docs:

- Worktree creation / cleanup:
  <https://docs.claude.com/en/docs/claude-code/common-workflows>
- Worktree settings:
  <https://docs.claude.com/en/docs/claude-code/settings>

## `.worktreeinclude`

A gitignored-files allowlist. When Claude Code (or the squad worktree
script) creates a new worktree, files listed in the consumer's
`.worktreeinclude` are copied into the new worktree so scripts and tests
can run. Typical entries:

```text
.env.test
config/local.json
```

Patterns follow `.gitignore` semantics. Use `!pattern` to exclude subpaths.

Squad's rule: only include what the child subagent's `validation_command`
actually needs. Do not drag secrets in; use `.env.test` or similar
placeholders.

## `worktree.symlinkDirectories`

`.claude/settings.json` setting. Directories listed here are symlinked from
the parent checkout into each new worktree rather than copied. Typical
entries for large monorepos:

```json
{
  "worktree": {
    "symlinkDirectories": ["node_modules", ".venv", "target", ".next"]
  }
}
```

Squad applies these symlinks after `git worktree add`. Symlinks share
package state across worktrees — this is a feature (no re-install cost)
but also a constraint: a task whose validation command rewrites
`node_modules` would affect siblings. That's usually a sign the task
should install into a per-task directory instead.

## `worktree.sparsePaths`

`.claude/settings.json` setting. Restricts the worktree's sparse-checkout
to a subset of paths. Useful in very large monorepos where a child only
needs a slice:

```json
{
  "worktree": {
    "sparsePaths": ["apps/billing", "packages/ui"]
  }
}
```

Squad does not set this automatically; if the consumer configures it,
the worktree helper inherits the setting via Claude Code.

## Branch naming

Squad owns the `squad/<run-id>/<task-id>` namespace. The cleanup script
deletes branches matching this prefix and nothing else. Do not manually
create `squad/*` branches outside a run — a subsequent cleanup may
delete them.

## Pitfalls

- **Dirty base ref.** `git worktree add` from a dirty checkout is
  technically allowed but surprising; squad refuses so the base is
  reproducible.
- **Case-insensitive filesystems.** A `worktree_name` that differs only
  in case from an existing directory collides on macOS default volumes.
  Squad refuses on collision.
- **Nested worktrees.** Git supports them; squad places worktrees at
  `<parent-of-repo>/<repo-name>-worktrees/` to avoid polluting the main
  checkout.
- **Orphaned refs.** `git fetch <worktree_path> <branch>:refs/...`
  creates local refs the spawn skill uses to cherry-pick. Cleanup must
  also prune these; the cleanup script calls `git update-ref -d
  refs/squad-incoming/<run-id>/<task-id>` for each entry.

## See also

- Claude Code release v2.1.118 — fixes resumed-subagent cwd to point at
  the worktree it was spawned from:
  <https://github.com/anthropics/claude-code/releases/tag/v2.1.118>

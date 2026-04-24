---
name: resolver
description: Resolves a cherry-pick conflict during a /squad:spawn run by editing the unmerged files to preserve both children's intent. Invoked by /squad:spawn when --auto-resolve is on; do not invoke directly.
argument-hint: "<run-id> <task-a> <task-b>"
context: fork
agent: general-purpose
user-invocable: false
allowed-tools: Read Edit Write Grep Glob Bash(git add *) Bash(git status *) Bash(git diff *)
---

# Squad Resolver Skill

> Runs in a forked subagent to resolve a cherry-pick conflict left behind
> by `/squad:spawn`. Preserves both children's intent; stages the fixes;
> does not commit.

A squad run has hit a `git cherry-pick` conflict. The parent orchestrator
is paused mid-pick; the conflicted files are in the working tree with
`<<<<<<<` markers and `git status` shows them as unmerged.

`$ARGUMENTS` contains three values in order: `<run-id> <task-a-id> <task-b-id>`.

## Workflow

1. Read `.claude/squad/runs/<run-id>/returns/<task-a-id>.json` and
   `.claude/squad/runs/<run-id>/returns/<task-b-id>.json`. Each return
   has a `summary` describing that child's intent.
2. Run `git status --short` and `git diff --name-only --diff-filter=U`
   to list the unmerged paths. Work only on those paths.
3. For each unmerged file:
   - Read the file. The conflict markers show you which regions came
     from where (`<<<<<<<` through `=======` is the base / ours,
     `=======` through `>>>>>>>` is the incoming change).
   - Edit the file so **both** children's intent is preserved. Do not
     pick one side unless the other is clearly subsumed. Typical moves:
     combine both code blocks, merge import lists, interleave config
     entries. Keep it minimal — no gratuitous reformatting.
   - Run `git add <path>` on the resolved file.
4. When every unmerged path is staged, run `git status --short` to
   confirm no `UU`/`AA`/`DD` lines remain.
5. Return a short summary: which files were resolved, your reasoning in
   one or two sentences per file, and any concerns worth surfacing to
   the parent (e.g., "this is a semantic conflict, not just a merge
   conflict — suggest re-running validation").

## Boundaries

- Touch **only** files in the unmerged list. Do not reformat unrelated
  files, do not run the validation command, do not commit.
- Do not create new files unless resolving the conflict genuinely
  requires one (rare).
- If the conflict is semantic (both changes are correct but the combined
  behavior is wrong), say so in the return and leave the file unmerged
  with a note. The parent will pause and ask the user.
- Do not attempt to `git cherry-pick --continue`. The parent does that
  after you return.

## Not user-invocable

This skill is `user-invocable: false` — only `/squad:spawn` should
dispatch it, under `--auto-resolve`. It dispatches as a fork (per its
`context: fork` frontmatter), so it inherits the parent conversation
and no separate profile is required. A human facing a conflict should
resolve it manually; they don't need a subagent for that.

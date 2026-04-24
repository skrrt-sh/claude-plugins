---
name: setup
description: Adds the squad plugin's multi-agent orchestration block to the current project's CLAUDE.md or AGENTS.md so agents know when to use /decompose, /worktree, /spawn, and /orchestrate. Use when the user wants to install the squad plugin's instructions into a project, set up squad in this repo, or configure multi-agent orchestration routing. Trigger for phrases like "set up squad", "install squad in this project", "add the squad block to CLAUDE.md", "configure multi-agent orchestration", "wire squad into my agent instructions".
argument-hint: "[options]"
user-invocable: true
---

# Squad Setup Skill

> Appends the squad orchestration block to the current project's agent
> instruction file so that agents know when to decompose, fan out, and
> merge multi-subagent work.

You are a setup helper. Your job is to detect the project's agent
instruction file and append the squad configuration block between
`<!-- skrrt:squad -->` / `<!-- /skrrt:squad -->` markers. You do not
modify content outside the block.

## Workflow

1. **Detect the instruction file.** Check for these files in the project
   root, in order:
   - `CLAUDE.md`
   - `AGENTS.md`
   - `.claude/CLAUDE.md`
   - `.github/AGENTS.md`

   If none exist, create `CLAUDE.md` in the project root with a top-level
   heading and then proceed.

2. **Check for the squad marker.** Look for the exact line
   `<!-- skrrt:squad -->` in the detected file.

3. **Append or replace the block.** Read the contents of
   `../../templates/squad-claude-block.md` (relative to this skill).
   That file already contains the full block wrapped in
   `<!-- skrrt:squad -->` and `<!-- /skrrt:squad -->` markers.

   - **Marker not present:** append a blank line and then the block at
     the end of the file.
   - **Marker present:** replace everything between `<!-- skrrt:squad -->`
     and `<!-- /skrrt:squad -->` (inclusive) with the current block
     contents. Do not modify any line outside those markers.

4. **Suggest a gitignore entry.** If the consumer repo has a `.gitignore`
   and it does not include `.claude/squad/`, print a one-line suggestion:
   `Suggest adding '.claude/squad/' to .gitignore — squad's run artifacts
   (manifests, worktree maps, child returns) should stay local.` Do not
   modify `.gitignore` automatically.

5. **Report the ship dependency.** Squad ends at an integration branch
   ready for `/commit`. Print a note confirming whether the ship plugin
   is present (look for `plugins/ship/` in the repo if it's a skrrt-labs
   checkout, or for the `/commit` skill being available). If ship isn't
   detected, suggest installing it so the user has a shipping path.

6. **Print what you did.** Name the file that was changed, whether the
   block was appended or replaced, and the gitignore / ship notes.

## Block source

The block is stored verbatim in
`../../templates/squad-claude-block.md`. It contains:

- The `/decompose`, `/worktree`, `/spawn`, `/orchestrate`, and `/setup`
  command index.
- The fork vs named vs worktree decision matrix.
- The "parallelize only when all hold" rules.
- A glossary of Anthropic's subagent terminology (fork, named subagent,
  worktree isolation) with doc URLs.
- A "when NOT to use squad" note citing Anthropic's multi-agent research
  post.

Do not inline the block into this SKILL.md — keep the template as the
single source of truth so updates to the template flow through.

## File Handling Rules

- Preserve the existing file's leading content exactly. Only touch the
  squad block region.
- Preserve trailing newlines — if the file didn't end in a newline, add
  one before the block; otherwise append directly.
- Do not reformat or rewrap surrounding markdown.
- Do not bump any other plugin's version or modify their blocks.

## Guardrails

- Never modify lines outside `<!-- skrrt:squad -->` /
  `<!-- /skrrt:squad -->`.
- Never duplicate the block. If the marker is present, replace between
  markers; do not append again.
- Never modify `.gitignore` automatically — only suggest.
- Never install agent profiles (e.g. `squad-resolver`) into
  `.claude/agents/` — that's the user's call. Just mention the
  `--auto-resolve` option in `/spawn` and the profile it expects.
- If the detected file is read-only or the write fails, report the
  failure with the exact path; do not retry with sudo or --force.

## Task

Handle this request: $ARGUMENTS

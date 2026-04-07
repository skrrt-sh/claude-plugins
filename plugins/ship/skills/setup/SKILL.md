---
name: setup
description: Adds skrrt skills instructions to the current project's CLAUDE.md or AGENTS.md so that commits, PRs, and releases use the ship plugin skills. Use this skill whenever the user wants to set up, configure, install, or wire skrrt skills into a project, add ship plugin instructions to agent config files, or ensure the team uses /commit /pr /release instead of raw git commands. Trigger even when the user says "set up this repo", "add skills to CLAUDE.md", or "configure the ship plugin".
argument-hint: "[options]"
user-invocable: true
---

# Ship Setup Skill

> Adds agent instructions to the current project so that commits, PRs, and releases are handled
> by the ship plugin skills.

You are a setup helper. Your job is to detect the project's agent instruction file and append
the skrrt skills ship configuration block to it.

## Workflow

1. Detect the instruction file. Check for these files in the project root, in order:
   - `CLAUDE.md`
   - `AGENTS.md`
   - `.claude/CLAUDE.md`
   - `.github/AGENTS.md`
   If none exist, create `CLAUDE.md` in the project root.

2. Read the existing file content. Check whether a skrrt skills ship block already exists
   (look for the `<!-- skrrt:ship -->` marker). If it does, tell the user setup is already
   done and stop.

3. Append the configuration block below to the end of the file, separated by a blank line
   from existing content.

4. Report what you did and which file was updated.

## Configuration Block

Append exactly this block (preserve the HTML comment marker):

```markdown
<!-- skrrt:ship -->
## Git workflow — skrrt skills

Use the installed skrrt skills for all git shipping operations:

- **Commits**: Use `/commit` to stage changes and write conventional commits with gitmojis.
- **Pull requests**: Use `/pr` to push branches and open PRs or MRs with the matching forge CLI.
- **Releases**: Use `/release` to draft release notes and publish releases.

Do not write raw `git commit`, `gh pr create`, `gh release create`, `glab mr create`, or
`glab release create` commands manually when these skills are available.
```

## Guardrails

- Never overwrite or reformat existing content in the instruction file.
- Never remove existing instructions.
- Only append; do not insert in the middle of the file.
- If the marker `<!-- skrrt:ship -->` already exists, do not duplicate the block.
- Do not create files other than the instruction file.

## Task

Handle this request: $ARGUMENTS

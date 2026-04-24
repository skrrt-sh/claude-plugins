# Fork vs Named Subagent

Canonical terminology comes from Anthropic's docs:
<https://code.claude.com/docs/en/sub-agents>.

## The two shapes

| Aspect          | Fork                                                     | Named subagent                                         |
| --------------- | -------------------------------------------------------- | ------------------------------------------------------ |
| Context         | Inherits the full parent conversation                    | Fresh context from its own definition                  |
| System prompt   | Same as parent                                           | From `.claude/agents/<name>.md` frontmatter            |
| Tools           | Same as parent                                           | Pre-approved allowlist; unknown tools auto-deny when backgrounded |
| Model           | Same as parent                                           | Own model (overridable in definition)                  |
| Prompt cache    | Shared with parent                                       | Separate                                               |
| Good for        | Deep-context follow-ups, same-turn sibling fan-out       | Specialist roles, backgrounded work, fresh perspective |

## When to pick fork

- The child needs in-flight parent context (recent reasoning, files
  already loaded).
- You're dispatching siblings in the same turn and want them to share
  the cache.
- The task is short enough that authoring a named profile would cost
  more than inheriting the parent context.

## When to pick named

- The child needs a specialist prompt, tighter tool access, or a
  different model.
- The job is well-specified and self-contained — docs, tests, codegen.
- You want fresh context so the child isn't biased by the parent's
  in-flight assumptions.
- You want to run the child backgrounded.

## Pitfalls

- **Named without a profile.** A named task must reference an existing
  `.claude/agents/<name>.md`. If the profile is missing, `/squad:spawn`
  refuses. If the ideal profile doesn't exist yet, fall back to `fork`
  and note the profile you'd want in the task's `rationale` — the user
  can author it later.
- **Fork + backgrounding.** Anthropic's docs warn that forks can use
  any tool the parent has without an extra permission gate, so they
  should not be backgrounded for arbitrary work. Background named
  children instead.
- **Named that needs parent state.** Named children get a fresh
  context. If the task genuinely needs parent state, either inline it
  into the task's prompt or switch to `fork`.

## See also

- Anthropic multi-agent research system (when multi-agent wins vs
  loses): <https://www.anthropic.com/engineering/multi-agent-research-system>
- Release v2.1.117 (forks on external builds via
  `CLAUDE_CODE_FORK_SUBAGENT=1`):
  <https://github.com/anthropics/claude-code/releases/tag/v2.1.117>

# Fork vs Named Subagent — Decision Reference

Canonical terminology comes from Anthropic's Claude Code sub-agents docs:
<https://docs.claude.com/en/docs/claude-code/sub-agents>.

## Definitions

| Aspect            | Fork                                                                 | Named subagent                                                            |
| ----------------- | -------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| Context           | Inherits the full parent conversation                                | Starts from its own definition with fresh context                         |
| System prompt     | Same as parent                                                       | From `.claude/agents/<name>.md` frontmatter                               |
| Tools             | Same as parent                                                       | Pre-approved list from the definition; unknown tools auto-deny when backgrounded |
| Model             | Same as parent                                                       | Own model (overridable in definition)                                     |
| Prompt cache      | Shared with parent                                                   | Separate cache                                                            |
| Enablement        | Requires `CLAUDE_CODE_FORK_SUBAGENT=1` on external builds            | Always available                                                          |
| Backgrounding     | Avoid for arbitrary work — tool prompts surface to the parent terminal | Safe — pre-approved tools run unattended                                  |
| Permission prompts | Surface to the main session's terminal                              | Resolved by the named profile's frontmatter (`permissionMode`)            |

## When to choose **fork**

- The child needs deep parent context: recent conversation turns, files
  already loaded, reasoning the parent is mid-stream with.
- The work is tightly coupled to a decision the parent is still making
  and may revise.
- You want to fan out multiple siblings in the same turn and share the
  parent's prompt cache — forks dispatched in parallel re-use the same
  cached prefix.
- The task is short enough that the setup cost of a named profile would
  dominate — forking is zero-config.

## When to choose **named**

- The child needs a different tool set or tighter permissions than the
  parent. Named profiles declare their allowlist and are safe to run
  backgrounded.
- The job is well-specified and self-contained: write these docs, author
  these tests, generate this code.
- You want fresh context to avoid parent-context drift — e.g., an
  adversarial reviewer that should not be biased by the writer's reasoning.
- A specialist prompt or different model is appropriate (a small-model
  code formatter, a large-model planner, a fast-model test runner).

## Token and cache economics

- **Fork** shares the parent prompt cache. Dispatching several forks in
  the same turn amortizes the cache over all of them, which is the main
  reason forks can be cheaper than named children despite inheriting the
  full conversation.
- **Named** starts from a fresh context, which costs more the first time
  a named profile runs but keeps the parent's cache clean and avoids
  context duplication across siblings whose tasks don't need parent state.
- If the parent cache is about to expire (5-minute TTL on the Anthropic
  prompt cache), re-using it via fork buys little; named becomes more
  attractive.

## Pitfalls

- **Forks + backgrounding.** Anthropic's docs warn forks cannot be safely
  backgrounded for arbitrary work because their tool inheritance means
  any tool the parent has may be used without an extra permission gate.
  Background named children instead.
- **Named without a profile.** A named task must reference an existing
  definition in `.claude/agents/`. Missing profiles are a hard stop for
  `/spawn`. If the profile doesn't exist yet, either author it first or
  mark the task `fork` and note the desired profile in `rationale`.
- **Named that needs parent state.** Named children get fresh context.
  If the task genuinely needs parent context, the parent must pass it
  explicitly via the prompt — or switch to a fork.

## Further reading

- Claude Code sub-agents: <https://docs.claude.com/en/docs/claude-code/sub-agents>
- Anthropic multi-agent research system (when multi-agent wins):
  <https://www.anthropic.com/engineering/multi-agent-research-system>
- Release v2.1.117 — forks on external builds:
  <https://github.com/anthropics/claude-code/releases/tag/v2.1.117>
- Release v2.1.118 — fork pointer storage + resumed-subagent cwd fix:
  <https://github.com/anthropics/claude-code/releases/tag/v2.1.118>

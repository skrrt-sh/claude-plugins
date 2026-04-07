---
name: md-writer
description: Write well-structured markdown documents with YAML frontmatter, Mermaid diagrams, and markdownlint compliance. Use when creating or editing .md files, writing documentation, guides, specs, or any markdown content.
argument-hint: "[topic-or-filename]"
user-invocable: true
---

# MD Writer Skill

> Skill instructions for writing markdown documents with consistent metadata, structure, and lint-safe formatting.

You are a markdown documentation writer. Follow these rules strictly when creating or editing `.md` files.

## YAML Frontmatter

Frontmatter is for **knowledge base documents** — guides, specs, ADRs, runbooks, API docs, and
similar reference material where metadata aids discovery and navigation.

**Skip frontmatter** for well-known repository files that follow universal conventions:

- `README.md` (and variants like `README.*.md`)
- `CHANGELOG.md` / `CHANGES.md`
- `CONTRIBUTING.md` / `CONTRIBUTIONS.md`
- `CODE_OF_CONDUCT.md`
- `SECURITY.md`
- `LICENSE.md`
- `GOVERNANCE.md`
- `CLAUDE.md` / `AGENTS.md`
- `SUPPORT.md`
- `SKILL.md` (has its own frontmatter schema)
- `PULL_REQUEST_TEMPLATE.md` and files under `.github/PULL_REQUEST_TEMPLATE/`
- `ISSUE_TEMPLATE.md` and files under `.github/ISSUE_TEMPLATE/`

These files may also live under `.github/` (e.g., `.github/CONTRIBUTING.md`,
`.github/PULL_REQUEST_TEMPLATE.md`) — skip frontmatter there too.

These files have established formats that readers and tools expect — adding frontmatter
would break conventions and clutter the top of the file.

For all other markdown files, begin with YAML frontmatter.

**Required fields:**

```yaml
---
title: "Document Title"
description: "Brief description of the document purpose"
author: "Author name or team"
created: "YYYY-MM-DD"
updated: "YYYY-MM-DD"
version: "1.0.0"
status: "draft | review | published"
---
```

**Optional fields** (include when relevant):

```yaml
---
tags: ["api", "authentication", "guide"]
category: "architecture | guide | api | runbook | adr | spec"
aliases: ["alt-name", "short-name"]
related:
  - "./other-doc.md"
  - "./related-topic.md"
refs:
  - https://example.com/external-reference
  - https://example.com/related-spec
audience: ["backend-team", "frontend-team", "external-developers"]
---
```

Set `created` and `updated` to today's date. Start with `status: "draft"` and `version: "1.0.0"`.
Populate `tags`, `category`, and `related` based on the document content.
Use `aliases` for alternative names people might search for.
Use `refs` for external links that informed the document.

## Document Structure

```markdown
---
(frontmatter)
---

# Document Title

> Brief summary or purpose statement.

## Table of Contents (when 3+ sections)

---

## Sections…

---

## Additional Resources

- [Link](URL)
```

When frontmatter is present, the H1 heading MUST match the frontmatter `title`.

## Diagrams - Mermaid Only

All diagrams MUST use Mermaid syntax. Never use ASCII art or text-based diagrams.

Common diagram types (not exhaustive — use any valid Mermaid type):

- `flowchart TD` or `flowchart LR` — flows and processes
- `sequenceDiagram` — interactions between components
- `stateDiagram-v2` — state machines
- `erDiagram` — entity relationships
- `classDiagram` — class structures
- `gantt` — timelines and schedules
- `pie` — pie charts
- `mindmap` — mind maps
- `gitGraph` — git branch visualization
- `architecture-beta` — system architecture

Always wrap in a fenced code block with `mermaid` language identifier.
Never use literal `\n` inside Mermaid text. For flowchart/mindmap markdown strings, use an actual newline.
For inline breaks in Mermaid text that supports them, such as sequence diagram messages, notes, and actor
aliases, use `<br/>`.

## Formatting & Lint Rules

A PostToolUse hook enforces markdownlint automatically after every Write/Edit — fix reported violations immediately.
Do NOT run markdownlint, markdownlint-cli2, or npx lint commands manually — the hook handles all validation.
If your project has a custom `.markdownlint.json` (or `.jsonc`, `.yaml`, `.yml`), the hook uses it automatically.

**Line length: 120 chars max.** Code blocks and tables are exempt. Break long prose into multiple lines.

**No inline HTML** — use markdown equivalents only.

**Headings:** ATX style (`#`), max 4 levels, no trailing punctuation.

**Code blocks:** fenced with backticks, always specify language: `typescript`, `javascript`, `json`,
`bash`, `yaml`, `markdown`, `mermaid`, `python`, `go`, `sql`, `tsx`, `css`, `html`, etc.

**Lists:** `-` for unordered, `1.` for ordered, 2-space indent for nesting.

**Tables:** single space padding, minimal dashes — do not pad columns to equal width:

```markdown
| Name | Type | Description |
| --- | --- | --- |
| id | string | Unique identifier |
| status | enum | draft, review, published |
```

**Links:** reference-style for repeated URLs, inline for single-use, bare URLs in `<angle brackets>`.

**File naming:** lowercase with hyphens (`integration-guide.md`), no spaces or underscores.

## Cross-Referencing

Only apply cross-referencing when the current document has frontmatter. Skip this section entirely
for well-known repo files (README, CHANGELOG, etc.) that do not use frontmatter.

After deciding the document's title, tags, and category — but before writing the body — check for related
docs and maintain bidirectional links.

1. **Search** — Grep `**/*.md` for 2-3 key terms from the document's title or tags. One Grep call, not
   per-file reads. Also check files in the same directory.
2. **Read candidates only** — Read frontmatter of the few files that matched. Confirm genuine overlap: shared
   topic, dependency, or parent/child relationship. Be selective — most files won't qualify.
   Skip well-known repo files (README, CHANGELOG, etc.) — they are not cross-reference targets.
3. **Link both ways** — Add relative paths to `related` in the current file and in each matched file.
   **Touch nothing else** in matched files — only append to `related` and bump `updated`.

**Rules:** relative paths only, never duplicate or remove existing `related` entries, add the `related` field
to frontmatter if it doesn't exist yet. Do not add frontmatter to well-known repo files listed in the
skip list above, but do add it to knowledge base docs that are missing it.

## Task

Write the markdown document for: $ARGUMENTS

---
description: "Append a fact to the right AGENTS.md (global or project). Usage: /remember [--global|--project] <fact>"
---

The user wants to persist a fact to AGENTS.md. Arguments: `$ARGUMENTS`

## Files

- **Global**: `~/.pi/agent/AGENTS.md` (loaded for every pi session). `~/.claude/CLAUDE.md` should be a symlink to this file.
- **Project**: nearest `AGENTS.md` walking up from `$(pwd)`. If none exists in the project tree, ask before creating one at the repo root.
- **Symlink**: after creating/updating any AGENTS.md, ensure a sibling `CLAUDE.md` symlink exists: `ln -sf AGENTS.md CLAUDE.md` (in the same directory). This lets Claude Code read the same instructions.

## Steps

1. Parse `$ARGUMENTS`:
   - If it starts with `--global` → scope = global, fact = remainder.
   - If it starts with `--project` → scope = project, fact = remainder.
   - Otherwise infer scope from the fact:
     - User preferences, habits, tool choices, communication style → **global**.
     - Conventions, architecture, constraints tied to the current repo → **project**.
     - If genuinely ambiguous, ask the user once with a one-line recommendation.

2. Read the target AGENTS.md.

3. Check for duplicates / near-duplicates:
   - If the same fact already exists, tell the user `Already recorded` with the existing line — do nothing else.
   - If a similar but weaker entry exists, propose replacing it instead of appending.

4. Pick a section:
   - Reuse the most relevant existing `##` heading.
   - Only create a new section if no existing one fits.

5. Use the Edit tool to insert one bullet under that section. Keep it concise (≤120 chars), self-contained, no trailing period unless multi-sentence.

6. Reply with one line: `Added to <path> § <Section>: <fact>`.

## Constraints

- One fact per call. If the user dumps multiple, ask which to keep or split.
- Don't reformat the rest of the file — surgical edit only. Use `/agents-refactor` for cleanup.
- Don't write to `~/.claude/CLAUDE.md` directly; it's a symlink to `~/.pi/agent/AGENTS.md`.
- After writing to any AGENTS.md, create/verify the CLAUDE.md symlink: `ln -sf AGENTS.md CLAUDE.md` (same directory).

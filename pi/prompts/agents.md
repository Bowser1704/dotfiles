---
description: Generate minimal AGENTS.md following progressive disclosure principles
argument-hint: "[project-description]"
---
Analyze this project and generate an AGENTS.md file. Follow these principles strictly:

## Principles

1. **Only write what the agent CANNOT infer from reading code or searching online.**
   - Project structure → agent can `find`/`ls` it. Don't write it.
   - Generic tool/framework docs → agent can search them. Don't copy-paste reference manuals.
   - Well-known conventions (K8s API conventions, kubebuilder markers, Go style) → don't explain them.

2. **Never duplicate the global AGENTS.md** (`~/.pi/agent/AGENTS.md`).
   - Read it first. Any rule already there (dev loop, build rules, devbox, ACR, etc.) → skip it.
   - Only add what's specific to THIS project that the global one doesn't cover.

3. **Write project-specific traps, decisions, and constraints.**
   - Architecture decisions that are easy to get wrong (e.g., "annotations on top-level metadata, NOT pod templates").
   - Infrastructure constraints (e.g., specific taints, DNS configs, registry domains).
   - Anti-patterns to avoid (e.g., "don't edit auto-generated files", "don't delete scaffold markers").

4. **Keep it under 800 tokens.** Every line must justify its token cost.
   - If you're unsure whether a line is worth keeping, delete it.
   - Prefer one-line rules over paragraphs of explanation.

5. **No tutorials.** This is a reference of hard-to-guess facts, not a learning guide.
   - No CLI command cheat sheets (agent can read Makefile/README).
   - No "how to scaffold a new API" (that's one-time setup, not daily work).
   - No link collections (agent can search when needed).

## Process

1. Read the global AGENTS.md at `~/.pi/agent/AGENTS.md` to know what's already covered.
2. Explore the project: `ls`, `find`, read key files (Makefile, PROJECT, go.mod, main entrypoints).
3. Identify what's truly project-specific and NOT inferable.
4. Generate a minimal AGENTS.md.
5. Show token estimate. If over 800 tokens, trim further.

If arguments are provided, use them as the project description/one-liner at the top. Otherwise, infer one from the project.

Overwrite the project's AGENTS.md only after showing the draft and getting confirmation.
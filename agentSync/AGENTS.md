# agentSync

Portable coding agent config manager — one repo, one command, all agents.

## Key Constraints

- Sync engine (`src/`, `bin/`): Pure ESM (type: module), all `.mjs`, no TypeScript, no build step. Node ≥20. Zero external dependencies.
- Agent content (`pi/` in parent): lives in `../pi/`, discovered by walking directories.
- Config lives at `~/.agent-sync/config.json`; overlay at `~/.agent-sync/claude-overlay.json`.
- The hardcoded required hook path (`~/.r2c/scripts/claude-cli-hook.sh`) in `src/config.mjs` is intentional — do not make it configurable or remove it.

## Sync Architecture

- `agent-sync sync [claude|pi]` — per-agent or all.
- `src/sync-claude.mjs` — Claude Code: symlinks (CLAUDE.md, skills, commands) + settings merge + config file deployment from `claude/`.
- `src/sync-pi.mjs` — Pi: symlinks (AGENTS.md, models.json) + settings.json generation/update.
- `src/resources.mjs` — shared resource discovery: walks `../pi/skills/` for `SKILL.md` files, walks `../pi/prompts/` for `*.md` files.

## Provider Management

- Self-contained in `providers.json`.
- `src/providers.mjs` — load, list, resolve, switch providers.
- Env values prefixed with `$` are resolved from `process.env` at switch time (secrets stay out of the repo).

## Testing

- `npm run check` — syntax-checks all `.mjs` files (no test framework).

## Anti-patterns

- Don't add runtime dependencies to the root package.json — the sync engine is zero-dep by design.

#!/usr/bin/env bash
# pi/setup.sh — Bootstrap pi config from dotfiles on a new machine
#
# Usage:
#   cd ~/.dotfiles/pi && ./setup.sh
#
# What it does:
#   1. Generates ~/.pi/agent/settings.json from settings.template.json
#   3. Symlinks AGENTS.md and models.json into ~/.pi/agent/
#   4. Installs node_modules if needed
#
# API keys (set in your shell profile, NOT in dotfiles):
#   DASHSCOPE_API_KEY   — Alibaba Cloud Bailian
#   TOKEN_PLAN_API_KEY  — Token Plan
#   (GitHub Copilot / Anthropic / OpenAI auth is managed by pi itself via auth.json)

set -euo pipefail

DOTFILES_PI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PI_AGENT="$HOME/.pi/agent"

echo "dotfiles/pi → $DOTFILES_PI"
echo "~/.pi/agent → $PI_AGENT"
echo ""

# ── 0. ensure ~/.pi/agent exists ──────────────────────────────────────────────
mkdir -p "$PI_AGENT"

# ── 1. settings.json ──────────────────────────────────────────────────────────
SETTINGS="$PI_AGENT/settings.json"
TEMPLATE="$DOTFILES_PI/settings.template.json"

if [[ ! -f "$SETTINGS" ]]; then
  echo "Creating $SETTINGS from template..."
  sed "s|__DOTFILES_PI__|$DOTFILES_PI|g" "$TEMPLATE" > "$SETTINGS"
  echo "  ✅ Created"
else
  # Merge: update the dotfiles package source path in existing settings
  # (keeps auth tokens, lastChangelogVersion, etc. intact)
  echo "Updating dotfiles package path in existing $SETTINGS..."
  python3 - "$SETTINGS" "$DOTFILES_PI" <<'EOF'
import json, sys
path, src = sys.argv[1], sys.argv[2]
with open(path) as f:
    s = json.load(f)
for p in s.get('packages', []):
    if isinstance(p, dict):
        cur = p.get('source', '')
        # replace any local (non-git/npm) source that looks like a dotfiles/pi path
        if not cur.startswith(('git:', 'npm:', 'http')) and 'dotfiles' in cur:
            p['source'] = src
with open(path, 'w') as f:
    json.dump(s, f, indent=2, ensure_ascii=False)
    f.write('\n')
EOF
  echo "  ✅ Updated"
fi

# ── 3. symlinks ───────────────────────────────────────────────────────────────
symlink() {
  local src="$1" dst="$2"
  if [[ -L "$dst" ]]; then
    # already a symlink — update if pointing elsewhere
    if [[ "$(readlink "$dst")" != "$src" ]]; then
      ln -sf "$src" "$dst"
      echo "  ✅ Updated symlink: $dst → $src"
    else
      echo "  ✓  Symlink OK: $dst"
    fi
  elif [[ -f "$dst" ]]; then
    echo "  ⚠️  $dst exists as a real file (not a symlink)"
    echo "     Backing up to ${dst}.bak and replacing with symlink..."
    mv "$dst" "${dst}.bak"
    ln -sf "$src" "$dst"
    echo "  ✅ Symlinked (backup at ${dst}.bak)"
  else
    ln -sf "$src" "$dst"
    echo "  ✅ Symlinked: $dst → $src"
  fi
}

echo "Setting up symlinks..."
symlink "$DOTFILES_PI/AGENTS.md"   "$PI_AGENT/AGENTS.md"
symlink "$DOTFILES_PI/models.json" "$PI_AGENT/models.json"

# ── 4. node_modules ───────────────────────────────────────────────────────────
if [[ -f "$DOTFILES_PI/package.json" && ! -d "$DOTFILES_PI/node_modules" ]]; then
  echo "Installing node_modules..."
  (cd "$DOTFILES_PI" && npm install)
  echo "  ✅ Done"
fi

echo ""
echo "✅ pi setup complete. Run 'pi' to start (or /reload if already running)."
echo ""
echo "Remaining manual steps:"
echo "  • API keys: add DASHSCOPE_API_KEY / TOKEN_PLAN_API_KEY to your shell profile"
echo "  • GitHub Copilot / Anthropic auth: run 'pi' and follow login prompts"
if [[ -z "${ALIDOC_MCP_URL:-}" ]]; then
echo "  • MCP: set ALIDOC_MCP_URL and re-run this script"
fi

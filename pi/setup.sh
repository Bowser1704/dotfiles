#!/usr/env bash
# pi/setup.sh — Bootstrap pi config from dotfiles on a new machine
#
# Usage:
#   cd ~/.dotfiles/pi && ./setup.sh
#
# What it does:
#   1. Generates ~/.pi/agent/settings.json from settings.template.json
#   2. Symlinks AGENTS.md (if exists) and extensions into ~/.pi/agent/
#   3. Installs node_modules if needed
#
# API keys (set in your shell profile, NOT in dotfiles):
#   (GitHub Copilot / Anthropic / OpenAI auth is managed by pi itself via auth.json)

set -euo pipefail

DOTFILES_PI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_ROOT="$(cd "$DOTFILES_PI/.." && pwd)"
PI_AGENT="$HOME/.pi/agent"

echo "dotfiles/pi → $DOTFILES_PI"
echo "~/.pi/agent → $PI_AGENT"
echo ""

# ── 0. ensure ~/.pi/agent exists ──────────────────────────────────────────────
mkdir -p "$PI_AGENT"
mkdir -p "$PI_AGENT/extensions"

# ── 1. settings.json ──────────────────────────────────────────────────────────
SETTINGS="$PI_AGENT/settings.json"
TEMPLATE="$DOTFILES_PI/settings.template.json"

if [[ ! -f "$SETTINGS" ]]; then
  echo "Creating $SETTINGS from template..."
  sed "s|__DOTFILES_PI__|$DOTFILES_PI|g" "$TEMPLATE" > "$SETTINGS"
  echo "  ✅ Created"
else
  echo "Keeping existing $SETTINGS (edit settings.template.json for template changes)"
fi

# ── 2. symlinks ───────────────────────────────────────────────────────────────
symlink() {
  local src="$1" dst="$2"
  if [[ -L "$dst" ]]; then
    if [[ "$(readlink "$dst")" != "$src" ]]; then
      ln -sf "$src" "$dst"
      echo "  ✅ Updated symlink: $dst → $src"
    else
      echo "  ✓  Symlink OK: $dst"
    fi
  elif [[ -f "$dst" ]]; then
    echo "  ⚠️  $dst exists as a real file, skipping"
  elif [[ -e "$src" ]]; then
    ln -sf "$src" "$dst"
    echo "  ✅ Symlinked: $dst → $src"
  else
    echo "  ⚠️  Source not found: $src"
  fi
}

# Extensions
echo "Setting up extension symlinks..."
for ext_file in "$DOTFILES_PI/extensions/"*; do
  [[ -e "$ext_file" ]] || continue
  name=$(basename "$ext_file")
  symlink "$ext_file" "$PI_AGENT/extensions/$name"
done

# AGENTS.md (only if it exists in dotfiles)
if [[ -f "$DOTFILES_PI/AGENTS.md" ]]; then
  symlink "$DOTFILES_PI/AGENTS.md" "$PI_AGENT/AGENTS.md"
fi

# ── 3. node_modules ───────────────────────────────────────────────────────────
if [[ -f "$DOTFILES_PI/package.json" && ! -d "$DOTFILES_PI/node_modules" ]]; then
  echo "Installing node_modules..."
  (cd "$DOTFILES_PI" && npm install)
  echo "  ✅ Done"
fi

echo ""
echo "✅ pi setup complete. Run 'pi' to start (or /reload if already running)."

#!/usr/bin/env bash
# Post-installation setup
# Usage: ./scripts/post-install.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/../lib/common.sh"

# Install Neovim plugins
setup_neovim() {
    if ! command_exists nvim; then
        warn "neovim not found, skipping plugin installation"
        return 0
    fi

    info "Installing Neovim plugins..."

    # Run Lazy.nvim sync in headless mode
    nvim --headless "+Lazy! sync" +qa 2>/dev/null || true

    # Install Mason tools
    nvim --headless "+MasonInstallAll" +qa 2>/dev/null || true

    success "Neovim plugins installed"
}

# Install zinit plugins (trigger first load)
setup_zinit() {
    if [ ! -d "$HOME/.local/share/zinit/zinit.git" ]; then
        info "Zinit not installed yet, will be installed on first shell launch"
        return 0
    fi

    info "Zinit will install plugins on first shell launch"
}

# Setup fzf
setup_fzf() {
    if command_exists fzf; then
        info "Setting up fzf..."

        # Install fzf keybindings if not already installed
        if [ -d "$HOME/.fzf" ]; then
            "$HOME/.fzf/install" --key-bindings --completion --no-update-rc 2>/dev/null || true
        fi

        success "fzf configured"
    fi
}

# Create necessary directories
create_directories() {
    info "Creating necessary directories..."

    mkdir -p "$HOME/.local/bin"
    mkdir -p "$HOME/.local/share"
    mkdir -p "$HOME/.config"

    success "Directories created"
}

# Main
create_directories
setup_neovim
setup_fzf
setup_zinit

echo ""
success "Post-installation complete!"
echo ""
info "Next steps:"
echo "  1. Restart your terminal or run: exec zsh"
echo "  2. (Tmux) Press prefix + I to install plugins"
echo "  3. (Neovim) Run :checkhealth to verify setup"

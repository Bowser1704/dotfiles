#!/usr/bin/env bash
# Post-installation setup
# Usage: ./scripts/post-install.sh [--install-tmux-plugins]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_TMUX_PLUGINS=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --install-tmux-plugins|-t)
            INSTALL_TMUX_PLUGINS=true
            shift
            ;;
        --help|-h)
            echo "Usage: $(basename "$0") [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -t, --install-tmux-plugins  Install tmux plugins via TPM"
            echo "  -h, --help                  Show this help message"
            exit 0
            ;;
        *)
            warn "Unknown option: $1"
            shift
            ;;
    esac
done

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

# Install tmux plugins via TPM
setup_tmux_plugins() {
    local tpm_path="$HOME/.tmux/plugins/tpm"

    if ! command_exists tmux; then
        warn "tmux not found, skipping plugin installation"
        return 0
    fi

    if [ ! -d "$tpm_path" ]; then
        warn "TPM not found at $tpm_path, skipping plugin installation"
        return 0
    fi

    info "Installing tmux plugins via TPM..."

    # Run TPM install script
    "$tpm_path/bin/install_plugins" 2>/dev/null || {
        warn "Failed to install some tmux plugins"
        return 0
    }

    success "Tmux plugins installed"
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

if [ "$INSTALL_TMUX_PLUGINS" = true ]; then
    setup_tmux_plugins
fi

echo ""
success "Post-installation complete!"
echo ""
info "Next steps:"
echo "  1. Restart your terminal or run: exec zsh"
if [ "$INSTALL_TMUX_PLUGINS" != true ]; then
    echo "  2. (Tmux) Press prefix + I to install plugins, or run: $0 --install-tmux-plugins"
fi
echo "  3. (Neovim) Run :checkhealth to verify setup"

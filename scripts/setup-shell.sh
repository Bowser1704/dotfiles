#!/usr/bin/env bash
# Configure shell (zsh as default)
# Usage: ./scripts/setup-shell.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions
source "$SCRIPT_DIR/../lib/common.sh"

setup_zsh() {
    # Check if zsh is installed
    if ! command_exists zsh; then
        error "zsh is not installed"
        return 1
    fi

    # Get zsh path
    local zsh_path
    zsh_path=$(which zsh)

    # Check if zsh is already the default shell
    if [ "$SHELL" = "$zsh_path" ]; then
        info "zsh is already the default shell"
        return 0
    fi

    # Add zsh to /etc/shells if not present
    if ! grep -q "^${zsh_path}$" /etc/shells 2>/dev/null; then
        info "Adding zsh to /etc/shells..."
        if [ -w /etc/shells ]; then
            echo "$zsh_path" >> /etc/shells
        else
            echo "$zsh_path" | run_sudo tee -a /etc/shells > /dev/null
        fi
    fi

    # Change default shell
    info "Changing default shell to zsh..."
    chsh -s "$zsh_path" 2>/dev/null || {
        # May need sudo on some systems
        run_sudo chsh -s "$zsh_path" "$USER"
    }

    success "Default shell changed to zsh"
}

setup_tmux_plugins() {
    local tpm_dir="$HOME/.tmux/plugins/tpm"

    if [ -d "$tpm_dir" ]; then
        info "TPM already installed"
        return 0
    fi

    info "Installing TPM (Tmux Plugin Manager)..."
    git clone https://github.com/tmux-plugins/tpm "$tpm_dir"

    success "TPM installed"
}

# Main
setup_zsh
setup_tmux_plugins

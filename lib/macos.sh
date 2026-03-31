#!/usr/bin/env bash
# macOS specific installation functions

source "${BASH_SOURCE[0]%/*}/common.sh"

# Install Xcode Command Line Tools
install_xcode_cli() {
    if xcode-select -p &> /dev/null; then
        info "Xcode Command Line Tools already installed"
        return 0
    fi

    info "Installing Xcode Command Line Tools..."

    # This will prompt user to install
    xcode-select --install 2>/dev/null || true

    # Wait for installation
    info "Please complete Xcode Command Line Tools installation and press Enter to continue..."
    read -r

    success "Xcode Command Line Tools installed"
}

# Install Homebrew
install_homebrew() {
    if command_exists brew; then
        info "Homebrew already installed"
        return 0
    fi

    info "Installing Homebrew..."

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add to PATH for Apple Silicon Macs
    if [ -d "/opt/homebrew" ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif [ -d "/usr/local/Homebrew" ]; then
        eval "$(/usr/local/Homebrew/bin/brew shellenv)"
    fi

    success "Homebrew installed"
}

# Install packages via Brewfile
install_brew_packages() {
    if ! command_exists brew; then
        error "Homebrew not found"
        return 1
    fi

    info "Installing packages from Brewfile..."

    local brewfile="${BASH_SOURCE[0]%/*}/../packages/Brewfile"

    if [ ! -f "$brewfile" ]; then
        warn "Brewfile not found at $brewfile"
        return 1
    fi

    brew bundle --file "$brewfile"

    success "Brewfile packages installed"
}

# Install tools that are in tool-versions via brew
# This is for tools not in Brewfile but in tool-versions
install_additional_tools() {
    info "Checking for additional tools from tool-versions..."

    local tool_versions_file="${BASH_SOURCE[0]%/*}/../tool-versions"

    if [ ! -f "$tool_versions_file" ]; then
        return 0
    fi

    # Map asdf tool names to brew names
    declare -A tool_map=(
        ["nodejs"]="node"
        ["golang"]="go"
        ["neovim"]="neovim"
        ["python"]="python@3"
        ["kubectl"]="kubectl"
        ["k9s"]="k9s"
        ["fd"]="fd"
        ["lazygit"]="lazygit"
        ["fzf"]="fzf"
        ["helm"]="helm"
        ["terraform"]="terraform"
        ["github-cli"]="gh"
        ["stern"]="stern"
        ["yq"]="yq"
        ["exa"]="eza"
    )

    while IFS= read -r line || [ -n "$line" ]; do
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

        local tool version brew_name
        read -r tool version <<< "$line"

        # Get brew name
        brew_name="${tool_map[$tool]:-$tool}"

        # Check if already installed
        if brew list "$brew_name" &> /dev/null; then
            continue
        fi

        info "Installing $tool via brew..."
        brew install "$brew_name" 2>/dev/null || true
    done < "$tool_versions_file"

    success "Additional tools installed"
}

#!/usr/bin/env bash
# Linux (Ubuntu) specific installation functions

source "${BASH_SOURCE[0]%/*}/common.sh"

# Install apt packages
install_apt_packages() {
    info "Updating apt cache..."
    run_sudo apt update

    info "Installing apt packages..."

    local packages_file="${BASH_SOURCE[0]%/*}/../packages/apt-packages.txt"
    local packages=()

    if [ -f "$packages_file" ]; then
        while IFS= read -r line || [ -n "$line" ]; do
            # Skip empty lines and comments
            [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
            packages+=("$line")
        done < "$packages_file"
    fi

    if [ ${#packages[@]} -gt 0 ]; then
        run_sudo apt install -y "${packages[@]}"
    fi

    success "Apt packages installed"
}

# Install asdf
install_asdf() {
    if [ -d "$HOME/.asdf" ]; then
        info "asdf already installed, skipping..."
        return 0
    fi

    info "Installing asdf..."

    # Install asdf dependencies
    run_sudo apt install -y \
        curl git \
        autoconf bison build-essential \
        libssl-dev libreadline-dev \
        zlib1g-dev libffi-dev libgmp-dev \
        2>/dev/null || true

    # Clone asdf
    git clone https://github.com/asdf-vm/asdf.git "$HOME/.asdf" --branch v0.16.1

    success "asdf installed"
}

# Install asdf plugins and tools
install_asdf_tools() {
    if [ ! -d "$HOME/.asdf" ]; then
        error "asdf not found, cannot install tools"
        return 1
    fi

    # Source asdf
    source "$HOME/.asdf/asdf.sh"

    info "Installing asdf plugins and tools..."

    local tool_versions_file="${BASH_SOURCE[0]%/*}/../tool-versions"

    if [ ! -f "$tool_versions_file" ]; then
        warn "tool-versions file not found"
        return 1
    fi

    # Read and install each tool
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip empty lines and comments
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue

        local tool version
        read -r tool version <<< "$line"

        info "Installing $tool $version..."

        # Add plugin if not exists
        if ! asdf plugin list | grep -q "^${tool}$"; then
            asdf plugin add "$tool" 2>/dev/null || {
                # Try common plugin name variations
                case "$tool" in
                    nodejs) asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git ;;
                    golang) asdf plugin add golang https://github.com/asdf-community/asdf-golang.git ;;
                    *) asdf plugin add "$tool" ;;
                esac
            }
        fi

        # Install version
        asdf install "$tool" "$version"
    done < "$tool_versions_file"

    # Set global versions
    asdf install

    success "asdf tools installed"
}

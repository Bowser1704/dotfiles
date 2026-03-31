#!/usr/bin/env bash
# Install asdf and tools from tool-versions
# Usage: ./scripts/install-asdf.sh [--skip-tools] [--proxy URL]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source common functions
source "$SCRIPT_DIR/../lib/common.sh"

# Default proxy for GitHub (can be overridden by --proxy or ASDF_GITHUB_PROXY env)
DEFAULT_PROXY="https://gh-proxy.org/"
GITHUB_PROXY="${ASDF_GITHUB_PROXY:-$DEFAULT_PROXY}"

SKIP_TOOLS=false

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-tools) SKIP_TOOLS=true ;;
        --proxy)
            shift
            GITHUB_PROXY="$1"
            ;;
        --no-proxy) GITHUB_PROXY="" ;;
    esac
    shift
done

# Apply proxy URL to a GitHub URL
proxy_url() {
    local url="$1"
    if [ -n "$GITHUB_PROXY" ] && [[ "$url" == https://github.com/* ]]; then
        echo "${GITHUB_PROXY}${url}"
    else
        echo "$url"
    fi
}

# Install asdf
install_asdf() {
    if [ -d "$HOME/.asdf" ]; then
        info "asdf already installed"
        return 0
    fi

    info "Installing asdf..."

    local asdf_url="https://github.com/asdf-vm/asdf.git"
    local asdf_proxied_url
    asdf_proxied_url=$(proxy_url "$asdf_url")

    # Try with proxy first, fallback to direct
    if ! git clone "$asdf_proxied_url" "$HOME/.asdf" --branch v0.16.1 2>/dev/null; then
        warn "Failed to clone asdf with proxy, trying direct..."
        git clone "$asdf_url" "$HOME/.asdf" --branch v0.16.1
    fi

    success "asdf installed"
}

# Install asdf plugins and tools
install_asdf_tools() {
    if [ ! -d "$HOME/.asdf" ]; then
        error "asdf not found"
        return 1
    fi

    # Source asdf
    if [ -f "$HOME/.asdf/asdf.sh" ]; then
        source "$HOME/.asdf/asdf.sh"
    elif [ -f "$HOME/.asdf/lib/asdf.sh" ]; then
        source "$HOME/.asdf/lib/asdf.sh"
    else
        error "Cannot find asdf.sh"
        return 1
    fi

    info "Installing asdf plugins and tools..."
    [ -n "$GITHUB_PROXY" ] && info "Using GitHub proxy: $GITHUB_PROXY"

    local tool_versions_file="$DOTFILES_DIR/tool-versions"

    if [ ! -f "$tool_versions_file" ]; then
        warn "tool-versions file not found"
        return 1
    fi

    # Add all plugins first using asdf plugin add all (requires asdf 0.15+)
    # This automatically detects plugins from .tool-versions
    info "Adding asdf plugins..."

    # Try 'asdf plugin add all' first (asdf 0.15+)
    if asdf plugin add all 2>/dev/null; then
        success "All plugins added via 'asdf plugin add all'"
    else
        # Fallback: manually add plugins from tool-versions
        warn "'asdf plugin add all' not available, adding plugins manually..."
        while IFS= read -r line || [ -n "$line" ]; do
            [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
            local tool
            read -r tool _ <<< "$line"

            if ! asdf plugin list 2>/dev/null | grep -q "^${tool}$"; then
                info "Adding plugin: $tool"
                if ! asdf plugin add "$tool" 2>/dev/null; then
                    warn "Failed to add plugin $tool, will try to continue..."
                fi
            fi
        done < "$tool_versions_file"
    fi

    # Install all tools from tool-versions
    info "Installing tools from tool-versions..."
    if ! asdf install 2>/dev/null; then
        # Fallback: install each tool individually
        warn "'asdf install' failed, trying individual installations..."
        while IFS= read -r line || [ -n "$line" ]; do
            [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
            local tool version
            read -r tool version <<< "$line"

            info "Installing $tool $version..."
            if ! asdf install "$tool" "$version" 2>/dev/null; then
                warn "Failed to install $tool $version, continuing..."
            fi
        done < "$tool_versions_file"
    fi

    # Set global versions
    asdf reshim

    success "asdf tools installed"
}

# Main
info "ASDF_GITHUB_PROXY=${GITHUB_PROXY:-'(none)'}"
install_asdf

if [ "$SKIP_TOOLS" = false ]; then
    install_asdf_tools
fi

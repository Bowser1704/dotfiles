#!/usr/bin/env bash
# Install Neovim from GitHub releases
# Usage: ./scripts/install-neovim.sh [--version VERSION] [--proxy URL]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Source common functions
source "$SCRIPT_DIR/../lib/common.sh"

# Default proxy for GitHub (can be overridden by --proxy or ASDF_GITHUB_PROXY env)
DEFAULT_PROXY="https://gh-proxy.org/"
GITHUB_PROXY="${ASDF_GITHUB_PROXY:-$DEFAULT_PROXY}"
NEOVIM_VERSION=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --version)
            shift
            NEOVIM_VERSION="$1"
            ;;
        --proxy)
            shift
            GITHUB_PROXY="$1"
            ;;
        --no-proxy) GITHUB_PROXY="" ;;
    esac
    shift
done

# Get Neovim version from tool-versions if not specified
get_version() {
    if [ -n "$NEOVIM_VERSION" ]; then
        echo "$NEOVIM_VERSION"
        return
    fi

    local tool_versions="$DOTFILES_DIR/tools/tool-versions"
    if [ -f "$tool_versions" ]; then
        while IFS= read -r line || [ -n "$line" ]; do
            [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
            local tool version
            read -r tool version <<< "$line"
            if [ "$tool" = "neovim" ]; then
                echo "$version"
                return
            fi
        done < "$tool_versions"
    fi

    error "Could not determine Neovim version"
    exit 1
}

# Detect architecture for download
detect_arch() {
    local os
    os=$(detect_os)

    case "$os" in
        macos)
            # Check if Apple Silicon
            if [ "$(uname -m)" = "arm64" ]; then
                echo "nvim-macos-arm64"
            else
                echo "nvim-macos-x86_64"
            fi
            ;;
        linux)
            echo "nvim-linux-x86_64"
            ;;
        *)
            error "Unsupported OS: $os"
            exit 1
            ;;
    esac
}

# Apply proxy URL to a GitHub URL
proxy_url() {
    local url="$1"
    if [ -n "$GITHUB_PROXY" ] && [[ "$url" == https://github.com/* ]]; then
        echo "${GITHUB_PROXY}${url}"
    else
        echo "$url"
    fi
}

# Install Neovim
install_neovim() {
    local version
    version=$(get_version)
    local arch
    arch=$(detect_arch)
    local download_url="https://github.com/neovim/neovim/releases/download/v${version}/${arch}.tar.gz"
    local proxied_url
    proxied_url=$(proxy_url "$download_url")

    info "Installing Neovim v${version} for $(detect_os)..."

    # Check if already installed with correct version
    if [ -x "$HOME/.local/bin/nvim" ]; then
        local installed_version
        installed_version=$("$HOME/.local/bin/nvim" --version 2>/dev/null | head -1 | cut -d' ' -f2 | sed 's/v//')
        if [ "$installed_version" = "$version" ]; then
            success "Neovim v${version} already installed"
            return 0
        fi
        info "Updating Neovim from v${installed_version} to v${version}"
    fi

    # Create temp directory
    local tmp_dir
    tmp_dir=$(mktemp -d)
    trap "rm -rf $tmp_dir" EXIT

    # Download
    info "Downloading from $proxied_url..."
    if ! curl -fL --progress-bar -o "$tmp_dir/nvim.tar.gz" "$proxied_url" 2>/dev/null; then
        warn "Failed with proxy, trying direct download..."
        curl -fL --progress-bar -o "$tmp_dir/nvim.tar.gz" "$download_url"
    fi

    # Extract
    info "Extracting..."
    tar xzf "$tmp_dir/nvim.tar.gz" -C "$tmp_dir"

    # Install to ~/.local
    info "Installing to ~/.local/..."
    mkdir -p "$HOME/.local"
    cp -r "$tmp_dir/${arch}/"* "$HOME/.local/"

    # Verify
    if [ -x "$HOME/.local/bin/nvim" ]; then
        local installed_version
        installed_version=$("$HOME/.local/bin/nvim" --version | head -1)
        success "Neovim installed: $installed_version"
    else
        error "Installation failed"
        exit 1
    fi
}

# Main
info "ASDF_GITHUB_PROXY=${GITHUB_PROXY:-'(none)'}"
install_neovim

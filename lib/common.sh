#!/usr/bin/env bash
# Common functions for bootstrap script

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Log functions
info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Detect operating system
detect_os() {
    case "$(uname -s)" in
        Darwin*)
            echo "macos"
            ;;
        Linux*)
            if [ -f /etc/os-release ]; then
                . /etc/os-release
                case "$ID" in
                    ubuntu|debian)
                        echo "ubuntu"
                        ;;
                    arch|manjaro)
                        echo "arch"
                        ;;
                    fedora|rhel|centos)
                        echo "fedora"
                        ;;
                    *)
                        echo "linux"
                        ;;
                esac
            else
                echo "linux"
            fi
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Backup file if exists
backup_file() {
    local file="$1"
    if [ -e "$file" ] && [ ! -L "$file" ]; then
        local backup="${file}.backup.$(date +%Y%m%d%H%M%S)"
        mv "$file" "$backup"
        info "Backed up $file to $backup"
    fi
}

# Get script directory
get_script_dir() {
    cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
}

# Ensure directory exists
ensure_dir() {
    mkdir -p "$1"
}

# Sudo check
has_sudo() {
    if [ "$EUID" -ne 0 ] && command_exists sudo; then
        echo "sudo"
    elif [ "$EUID" -eq 0 ]; then
        echo "root"
    else
        echo ""
    fi
}

# Run with sudo if needed
run_sudo() {
    local sudocmd
    sudocmd=$(has_sudo)
    if [ -n "$sudocmd" ]; then
        if [ "$sudocmd" = "root" ]; then
            "$@"
        else
            sudo "$@"
        fi
    else
        warn "No sudo access, skipping: $*"
        return 1
    fi
}

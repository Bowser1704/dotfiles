# Dotfiles Handover Document

## Overview

This repository contains the dotfiles configuration for a Linux/macOS development environment. It's a comprehensive setup that includes configurations for Neovim, Zsh, Tmux, bspwm (window manager), and various other tools and utilities. The configuration is managed using Dotbot for creating symbolic links.

A `bootstrap` script is provided for one-click setup on new machines, handling system package installation, asdf/Homebrew setup, and configuration linking.

## Project Structure

```
~/.dotfiles/
├── bootstrap              # Main entry point for one-click setup
├── install                # Dotbot installation script
├── install.conf.yaml      # Dotbot configuration file
├── lib/
│   ├── common.sh          # Common utility functions
│   ├── linux.sh           # Linux (Ubuntu) specific installation
│   └── macos.sh           # macOS specific installation
├── packages/
│   ├── Brewfile           # macOS Homebrew package list
│   └── apt-packages.txt   # Ubuntu apt package list
├── scripts/
│   ├── install-asdf.sh    # asdf installation script
│   ├── setup-shell.sh     # Shell configuration script
│   ├── post-install.sh    # Post-installation setup
│   └── yank               # Clipboard helper
├── nvim/                  # Neovim configuration
├── zshrc                  # Zsh shell configuration
├── tmux.conf              # Tmux terminal multiplexer configuration
├── tool-versions          # asdf version manager configuration
├── alacritty/             # Alacritty terminal emulator configuration
├── zellij/                # Zellij terminal multiplexer configuration
├── bspwm/                 # bspwm window manager configuration (Linux only)
├── sxhkd/                 # Simple X hotkey daemon configuration (Linux only)
├── polybar/               # Polybar status bar configuration (Linux only)
├── rofi/                  # Rofi application launcher configuration (Linux only)
├── fontconfig/            # Font configuration
└── ...
```

## Installation

### One-Click Setup (Recommended)

On a new machine, run:

```bash
curl -fsSL https://raw.githubusercontent.com/Bowser1704/dotfiles/master/bootstrap | bash
```

This will:
1. Clone the repository to `~/.dotfiles`
2. Detect the operating system (Ubuntu/macOS)
3. **On Linux (running as root)**: Prompt to create a new user with sudo privileges
4. Install system packages (apt/Homebrew) - build dependencies for asdf tools
5. Install asdf (Linux) or use Homebrew (macOS)
6. Install all tools from `tool-versions` via asdf (Linux) or `Brewfile` (macOS)
7. Link configuration files via Dotbot
8. Configure zsh as the default shell
9. Run post-installation setup (Neovim plugins, Tmux plugins)

### User Creation (Linux Only)

When running bootstrap as root on Linux, the script will:
1. Prompt for a new username
2. Prompt for a password (with confirmation)
3. Create the user with a home directory
4. Add the user to the `sudo` group
5. Optionally enable passwordless sudo
6. Switch to the new user and continue the setup

If the user already exists, you can choose to use the existing user.

### Manual Setup

1. Clone the repository to `~/.dotfiles`:
   ```bash
   git clone git@github.com:Bowser1704/dotfiles.git ~/.dotfiles
   ```

2. Run the bootstrap script:
   ```bash
   cd ~/.dotfiles
   ./bootstrap
   ```

### Dotbot Only (Config Linking)

If you only want to link configuration files without installing packages:

```bash
cd ~/.dotfiles
./install
```

### Bootstrap Options

```bash
./bootstrap --help              # Show help message
./bootstrap --dry-run           # Preview mode, no changes made
./bootstrap --no-root           # Skip operations requiring sudo
./bootstrap --skip-packages     # Skip system package installation
./bootstrap --skip-asdf         # Skip asdf installation (Linux only)
./bootstrap --skip-shell        # Skip shell configuration
./bootstrap --skip-user-create  # Skip user creation (used internally)
./bootstrap --proxy URL         # Use proxy for GitHub (default: https://gh-proxy.org/)
./bootstrap --no-proxy          # Disable GitHub proxy
```

### GitHub Proxy (China Network)

By default, the script uses `https://gh-proxy.org/` as a proxy for GitHub URLs to improve accessibility in China. You can:

- Use a custom proxy: `./bootstrap --proxy https://your-proxy.com/`
- Disable proxy: `./bootstrap --no-proxy`
- Set via environment variable: `ASDF_GITHUB_PROXY=https://your-proxy.com/ ./bootstrap`

## Platform Support

| Platform | System Packages | Tool Management | GUI Tools | User Creation |
|----------|-----------------|-----------------|-----------|---------------|
| Ubuntu   | apt (build deps) | asdf | ❌ No | ✅ Yes (if root) |
| macOS    | Homebrew | Homebrew | ✅ Optional | ❌ No |

### Ubuntu Package Strategy

On Ubuntu, the bootstrap script:
- Uses **apt** only for installing build dependencies (gcc, make, libssl-dev, etc.)
- Uses **asdf** for all development tools (nodejs, go, python, kubectl, neovim, etc.)
- This ensures consistent tool versions across different Ubuntu releases

### Linux-specific Configurations

The following configurations are only linked on Linux:
- `~/.config/bspwm` - Window manager
- `~/.config/sxhkd` - Hotkey daemon
- `~/.config/polybar` - Status bar
- `~/.config/rofi` - Application launcher

## Core Components

### Shell Environment (Zsh)

- **Shell**: Zsh with Zinit as plugin manager
- **Prompt**: Powerlevel10k theme
- **Plugins**: 
  - fast-syntax-highlighting
  - zsh-autosuggestions
  - zsh-completions
  - zsh-autopair
  - kubectl prompt
  - fzf integration
  - zsh-vi-mode
  - asdf integration
- **Aliases**: Various aliases for modern tools like `eza` (as `ls`), `batcat` (as `cat`), `fd` (as `find`), etc.
- **Environment**: Uses asdf for managing multiple versions of programming languages and tools

### Terminal Multiplexer (Tmux)

- **Prefix Key**: `Ctrl-a` (instead of default `Ctrl-b`)
- **Plugins**:
  - tpm (Tmux Plugin Manager)
  - tmux-prefix-highlight
  - tmux-yank
  - tmux-network-bandwidth
  - tmux-mem-cpu-load
  - tmux-resurrect
- **Features**: 
  - Vi-style key bindings for copy mode
  - Custom status bar with system resource monitoring
  - Automatic restoration of sessions

### Window Manager (bspwm) - Linux Only

- **Window Manager**: bspwm (binary space partitioning window manager)
- **Hotkey Daemon**: sxhkd for key bindings
- **Status Bar**: Polybar
- **Key Bindings** (Super key as main modifier):
  - `Super + Enter`: Launch terminal (Alacritty)
  - `Super + Space`: Application launcher (Rofi)
  - `Super + h/j/k/l`: Focus windows in direction
  - `Super + Shift + h/j/k/l`: Move windows in direction
  - `Super + 1-9`: Switch to desktop 1-9
  - `Super + Shift + 1-9`: Move window to desktop 1-9

### Text Editor (Neovim)

- **Plugin Manager**: Lazy.nvim
- **Base**: LazyVim (opinionated Neovim distribution)
- **Configuration**: Lua-based
- **LSP Support**: Multiple language servers via mason.nvim
- **Key Features**:
  - Built-in LSP with code actions, references, definitions
  - Fuzzy finder (FzfLua)
  - Git integration
  - Formatting and linting
  - Debugging support (DAP)

### Development Environment

- **Version Manager (Linux)**: asdf for managing multiple versions of programming languages
- **Version Manager (macOS)**: Homebrew for package management
- **Supported Languages/Tools** (from tool-versions):
  - Node.js: 24.12.0
  - Go: 1.24.6
  - Neovim: 0.11.5
  - Python: 3.11.8
  - kubectl: 1.29.3
  - And many more (see tool-versions file)

### Terminal Emulator (Alacritty)

- **Configuration**: Located in `alacritty/` directory
- **Features**: Fast, cross-platform terminal emulator

## Key Scripts

- `bootstrap`: Main entry point for one-click setup on new machines
- `scripts/install-asdf.sh`: Installs asdf and all tools from tool-versions
- `scripts/setup-shell.sh`: Configures zsh as default shell, installs TPM
- `scripts/post-install.sh`: Post-installation setup (Neovim plugins, directories)
- `scripts/yank`: Handles copying to clipboard using OSC 52 escape sequences
- `bspwm/bspwmrc`: bspwm startup script that configures monitors, rules, and starts related services
- `sxhkd/sxhkdrc`: Key bindings for the system

## Configuration Files

- `install.conf.yaml`: Defines which files/directories should be symlinked where
- `zshrc`: Comprehensive shell configuration with plugin management
- `tmux.conf`: Tmux configuration with plugins and custom key bindings
- `tool-versions`: Defines default versions for development tools managed by asdf
- `packages/Brewfile`: macOS Homebrew package list
- `packages/apt-packages.txt`: Ubuntu apt package list

## Development Workflows

### Environment Setup
The dotfiles provide a consistent development environment across machines with:
- One-click setup via bootstrap script
- Automatic installation of development tools (asdf on Linux, Homebrew on macOS)
- Consistent shell experience with Zsh and Powerlevel10k
- Terminal multiplexing with Tmux
- Modern text editing with Neovim and LSP support
- Tiling window management with bspwm (Linux only)

### Code Formatting and Linting
- Lua: stylua (configured in stylua.toml)
- Python: ruff (LSP integration in Neovim)
- Other languages: Various LSP servers managed by mason.nvim

## Important Notes

1. **Dependencies**: The bootstrap script handles all dependencies automatically. If running manually, ensure you have:
   - Git
   - curl
   - Root/sudo access (Linux)

2. **Customization**: The configurations are tailored to the original author's workflow and preferences. New users may need to adjust:
   - Key bindings in sxhkd
   - Visual themes in Neovim, Alacritty, Polybar
   - Shell aliases and functions
   - Development tools in tool-versions or Brewfile

3. **Security**: The zshrc file contains placeholder API keys that should be updated or removed:
   - `OPENAI_API_KEY="xxx"`

4. **Platform Specific**: 
   - Linux-specific configs (bspwm, sxhkd, polybar, rofi) are only linked on Linux
   - macOS uses Homebrew instead of asdf for tool management

## Troubleshooting

- If bootstrap fails, try running with `--dry-run` first to preview changes
- If installation fails, ensure all submodules are properly initialized
- For Neovim plugins not loading, run `:Lazy` to check plugin status
- For key bindings not working, verify sxhkd is running (`pgrep sxhkd`)
- For terminal colors not appearing correctly, check terminal emulator compatibility
- On macOS, if Homebrew packages fail, try `brew doctor`

## Maintenance

- To update plugins: Use the respective plugin managers (zinit for zsh, lazy.nvim for neovim)
- To add new dotfiles: Update install.conf.yaml with the new file mapping
- To update tool versions: Modify the tool-versions file (Linux) or Brewfile (macOS)
- To add new system packages: Update packages/apt-packages.txt or packages/Brewfile

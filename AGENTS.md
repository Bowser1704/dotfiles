# Dotfiles Handover Document

## Overview

This repository contains the dotfiles configuration for a Linux development environment. It's a comprehensive setup that includes configurations for Neovim, Zsh, Tmux, bspwm (window manager), and various other tools and utilities. The configuration is managed using Dotbot for creating symbolic links.

## Project Structure

```
/home/hongqi/.dotfiles/
├── .ruff_cache/          # Cache directory for ruff
├── alacritty/            # Alacritty terminal emulator configuration
├── bspwm/                # bspwm window manager configuration
├── dotbot/               # Dotbot submodule for managing symlinks
├── fontconfig/           # Font configuration
├── nvim/                 # Neovim configuration
├── polybar/              # Polybar status bar configuration
├── rofi/                 # Rofi application launcher configuration
├── scripts/              # Custom shell scripts
├── sxhkd/                # Simple X hotkey daemon configuration
├── zellij/               # Zellij terminal multiplexer configuration
├── install               # Installation script using Dotbot
├── install.conf.yaml     # Dotbot configuration file
├── README.md             # Project documentation
├── stylua.toml           # Lua code formatter configuration
├── tmux.conf             # Tmux terminal multiplexer configuration
├── tool-versions         # asdf version manager configuration
├── zshrc                 # Zsh shell configuration
└── ...
```

## Installation

1. Clone the repository to `~/.dotfiles`:
   ```bash
   git clone git@github.com:Bowser1704/dotfiles.git ~/.dotfiles
   ```

2. Run the installation script:
   ```bash
   cd ~/.dotfiles
   ./install
   ```

The installation script uses Dotbot to create symbolic links from the files in the repository to their appropriate locations in the home directory and config directory.

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
- **Aliases**: Various aliases for modern tools like `exa` (as `ls`), `batcat` (as `cat`), `fd` (as `find`), etc.
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

### Window Manager (bspwm)

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

- **Version Manager**: asdf for managing multiple versions of programming languages
- **Supported Languages/Tools** (from tool-versions):
  - Node.js: 21.6.2
  - Go: 1.24.6
  - Neovim: 0.10.0
  - Python: 3.11.8
  - Java: OpenJDK 18.0.2.1
  - And many more (see tool-versions file)

### Terminal Emulator (Alacritty)

- **Configuration**: Located in `alacritty/` directory
- **Features**: Fast, cross-platform terminal emulator

### Application Launcher (Rofi)

- **Configuration**: Located in `rofi/` directory
- **Usage**: Launched with `Super + Space`

## Key Scripts

- `scripts/yank`: Handles copying to clipboard using OSC 52 escape sequences
- `bspwm/bspwmrc`: bspwm startup script that configures monitors, rules, and starts related services
- `sxhkd/sxhkdrc`: Key bindings for the system
- `scripts/xidlehook.sh`: Screen locking script (not shown but referenced in bspwmrc)

## Configuration Files

- `install.conf.yaml`: Defines which files/directories should be symlinked where
- `zshrc`: Comprehensive shell configuration with plugin management
- `tmux.conf`: Tmux configuration with plugins and custom key bindings
- `tool-versions`: Defines default versions for development tools managed by asdf

## Development Workflows

### Environment Setup
The dotfiles provide a consistent development environment across machines with:
- Automatic installation of development tools via asdf
- Consistent shell experience with Zsh and Powerlevel10k
- Terminal multiplexing with Tmux
- Modern text editing with Neovim and LSP support
- Tiling window management with bspwm

### Code Formatting and Linting
- Lua: stylua (configured in stylua.toml)
- Python: ruff (LSP integration in Neovim)
- Other languages: Various LSP servers managed by mason.nvim

## Important Notes

1. **Dependencies**: Before using these dotfiles, ensure you have installed the required tools:
   - asdf version manager
   - Git
   - The specific tools listed in tool-versions (or install them as needed)

2. **Customization**: The configurations are tailored to the original author's workflow and preferences. New users may need to adjust:
   - Key bindings in sxhkd
   - Visual themes in Neovim, Alacritty, Polybar
   - Shell aliases and functions
   - Development tools in tool-versions

3. **Security**: The zshrc file contains placeholder API keys that should be updated or removed:
   - `OPENAI_API_KEY="xxx"`

4. **Platform Specific**: Some configurations may be Linux-specific (X11 related features, bspwm, etc.)

## Troubleshooting

- If installation fails, ensure all submodules are properly initialized
- For Neovim plugins not loading, run `:Lazy` to check plugin status
- For key bindings not working, verify sxhkd is running (`pgrep sxhkd`)
- For terminal colors not appearing correctly, check terminal emulator compatibility

## Maintenance

- To update plugins: Use the respective plugin managers (zinit for zsh, lazy.nvim for neovim)
- To add new dotfiles: Update install.conf.yaml with the new file mapping
- To update tool versions: Modify the tool-versions file

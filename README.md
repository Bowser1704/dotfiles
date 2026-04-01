# dotfiles

A comprehensive dotfiles configuration for Linux/macOS development environment, managed by Dotbot with one-click bootstrap setup.

## Features

- **One-click setup** - Bootstrap script handles everything from system packages to configuration linking
- **Cross-platform** - Supports Ubuntu (apt + asdf) and macOS (Homebrew)
- **Smart linking** - GUI configs only linked when display server is available
- **Modular structure** - Clean separation of tools, GUI configs, and platform-specific settings

## Quick Start

```bash
curl -fsSL https://raw.githubusercontent.com/Bowser1704/dotfiles/master/bootstrap | bash
```

Or manually:

```bash
git clone git@github.com:Bowser1704/dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./bootstrap
```

## Tools Included

### Editor & Shell
- **Neovim** - LazyVim-based configuration with LSP, DAP, and completion
- **Zsh** - Zinit plugin manager with Powerlevel10k theme
- **Tmux** - Terminal multiplexer with vi keybindings and plugins

### Terminal
- **Ghostty** - Fast, GPU-accelerated terminal emulator (default)
- **Alacritty** - Deprecated, moved to `deprecated/` directory

### Linux GUI (bspwm stack)
- **bspwm** - Tiling window manager
- **sxhkd** - Hotkey daemon
- **polybar** - Status bar
- **rofi** - Application launcher

### Development Tools
- Node.js, Go, Python, Java (via asdf on Linux, Homebrew on macOS)
- kubectl, k9s, terraform, vault
- git, gh, lazygit, delta, direnv
- ripgrep, fd, bat, fzf, yq

## Project Structure

```
~/.dotfiles/
├── bootstrap              # Main setup script
├── install.conf.yaml      # Dotbot symlink configuration
├── tools/                 # Cross-platform CLI configs
│   ├── nvim/, zshrc, tmux.conf, tool-versions
├── default-gui/           # GUI configs for both platforms
│   └── ghostty/
├── linux-gui/             # Linux-only GUI configs
│   └── bspwm/, sxhkd/, polybar/, rofi/
├── macos-gui/             # macOS-only GUI configs
├── deprecated/            # Old configs (not linked)
└── packages/              # Brewfile, apt-packages.txt
```

## Bootstrap Options

```bash
./bootstrap --help              # Show all options
./bootstrap --dry-run           # Preview without changes
./bootstrap --skip-packages     # Skip system packages
./bootstrap --proxy URL         # Use GitHub proxy
./bootstrap --no-proxy          # Disable proxy
```

## Platform Support

| Platform | Package Manager | GUI Tools | User Creation |
|----------|-----------------|-----------|---------------|
| Ubuntu   | apt + asdf      | bspwm, ghostty | Yes (if root) |
| macOS    | Homebrew        | ghostty, rectangle, flashspace | No |

## After Installation

1. Restart terminal: `exec zsh`
2. Install Tmux plugins: `Ctrl-a + I`
3. Verify Neovim: `:checkhealth`

## Customization

- Key bindings: `linux-gui/sxhkd/sxhkdrc`
- Shell aliases: `tools/zshrc`
- Neovim: `tools/nvim/`
- Tool versions: `tools/tool-versions` (Linux) or `packages/Brewfile` (macOS)

## License

MIT

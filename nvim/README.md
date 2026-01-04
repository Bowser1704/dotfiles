# Neovim Configuration

This is a clean and minimal Neovim configuration built on top of [lazy.nvim](https://github.com/folke/lazy.nvim) plugin manager. It's compatible with Neovim v0.11+.

## 📁 Structure

```
nvim/
├── init.lua                    # Main entry point - bootstraps lazy.nvim and loads config
├── lua/
│   ├── config/                 # Core Neovim configuration
│   │   ├── autocmds.lua       # Auto commands (helm, terraform, go, SSH clipboard)
│   │   ├── keymaps.lua        # Key mappings for navigation and editing
│   │   └── options.lua        # Neovim options (line numbers, tabs, folding, etc.)
│   ├── plugins/               # Plugin specifications
│   │   ├── lsp/              # LSP-related plugins
│   │   │   ├── lsp.lua       # LSP server configuration (Mason, LSP keymaps)
│   │   │   ├── cmp.lua       # Completion engine setup
│   │   │   ├── none-ls.lua   # Formatters and linters (none-ls)
│   │   │   └── inlayhints.lua # Inlay hints configuration
│   │   ├── copilot.lua       # GitHub Copilot integration
│   │   ├── editor.lua        # Editor enhancements (pairs, surround, gitsigns, etc.)
│   │   ├── format.lua        # Code formatting with conform.nvim
│   │   ├── lualine.lua       # Status line configuration
│   │   ├── nvim-tree.lua     # File explorer
│   │   ├── telescope.lua     # Fuzzy finder
│   │   ├── treesitter.lua    # Syntax highlighting
│   │   └── ui.lua            # UI plugins (theme, bufferline, noice, etc.)
│   └── utils/                 # Utility modules
│       ├── init.lua          # Utility functions and icons
│       └── toggle.lua        # Toggle functions for options/diagnostics
├── ftdetect/                  # Filetype detection
├── ftplugin/                  # Filetype-specific settings
├── spell/                     # Spell check dictionaries
└── lazy-lock.json            # Plugin version lock file
```

## ⚙️ Configuration Files Explained

### init.lua
The main entry point that:
1. Loads core options and autocmds
2. Bootstraps lazy.nvim if not installed
3. Loads all plugins from `lua/plugins/` and `lua/plugins/lsp/`
4. Loads keymaps after plugins

### lua/config/options.lua
Sets up Neovim options including:
- Leader key: `,`
- Line numbers: enabled with relative numbers
- Tabs: 2 spaces, expandtab
- Folding: using Treesitter expressions (disabled by default)
- Spell checking: enabled for English with camel case support
- Color column at 160 characters

### lua/config/keymaps.lua
Key mappings for:
- `<leader>q` / `<leader>qq` - Quit window/all
- `<leader>w` / `<C-s>` - Save file
- `<leader>yy` / `<leader>y` - Copy to system clipboard
- `<leader>p` - Paste from system clipboard
- `<C-j>` / `<C-k>` - Navigate between buffers
- `<S-h>` / `<S-l>` - Navigate buffers (if bufferline installed)
- `<leader>h` / `<esc>` - Clear search highlights
- `<A-j>` / `<A-k>` - Move lines up/down
- Arrow keys with `<C->` - Resize windows

### lua/config/autocmds.lua
Auto commands for:
- **Helm files**: Detect Chart.yaml, templates, gotmpl files
- **Terraform files**: Detect .tf files
- **Go files**: Disable expandtab (use tabs instead of spaces)
- **SSH clipboard**: OSC52 integration for copying over SSH

## 🔌 Plugins Overview

### LSP & Completion
- **nvim-lspconfig**: LSP server configuration
- **mason.nvim**: LSP/DAP/linter installer
- **nvim-cmp**: Completion engine with various sources
- **SchemaStore.nvim**: JSON schemas for validation
- Configured servers: rust_analyzer, jsonls, lua_ls, gopls, clangd, ruff, basedpyright

### Editor Enhancements
- **nvim-treesitter**: Syntax highlighting and code understanding
- **gitsigns.nvim**: Git integration (blame, diff, stage hunks)
- **mini.pairs**: Auto-close brackets/quotes
- **mini.surround**: Add/delete/change surrounding characters
- **indent-blankline.nvim**: Show indent guides
- **todo-comments.nvim**: Highlight TODO/FIXME/NOTE comments

### UI
- **sonokai**: Color scheme
- **lualine.nvim**: Status line
- **bufferline.nvim**: Buffer tabs
- **which-key.nvim**: Show available keybindings
- **noice.nvim**: Better UI for messages, cmdline, and popups
- **nvim-notify**: Notification manager

### Tools
- **telescope.nvim**: Fuzzy finder for files/buffers/grep
- **fzf-lua**: Fast fuzzy finder (used for LSP pickers)
- **nvim-tree.lua**: File explorer (`<leader>e`)
- **FTerm.nvim**: Floating terminal (`<A-o>`)
- **copilot.lua**: GitHub Copilot integration
- **conform.nvim**: Code formatting
- **none-ls.nvim**: Additional formatters and linters

## 🚀 Getting Started

1. **Prerequisites**: Neovim v0.11+ (uses `vim.uv` API)

2. **Installation**: The config will auto-install lazy.nvim on first launch

3. **Installing plugins**: Open Neovim and lazy.nvim will install all plugins automatically, or run `:Lazy sync`

4. **Installing LSP servers**: Open a file and the relevant LSP server will be installed via Mason, or run `:Mason` to manage servers

## 🔑 Key LSP Keybindings

When an LSP server is attached to a buffer:
- `K` - Hover documentation
- `gd` - Go to definition
- `gD` - Go to declaration
- `gi` - Go to implementation
- `gr` - Go to references
- `gt` - Go to type definition
- `gs` - Signature help
- `<leader>f` - Format code
- `<leader>ca` - Code actions
- `<leader>rn` - Rename symbol
- `fd` - Show diagnostics for current line
- `[d` / `]d` - Previous/next diagnostic

## 📝 Notes

### Neovim 0.11 Compatibility
This configuration has been updated for Neovim v0.11 with the following changes:
- `vim.loop` → `vim.uv` (new Lua event loop API)
- `vim.diagnostic.enable()` API updated (no longer takes boolean as first parameter)
- Inlay hints API uses `vim.lsp.inlay_hint` (moved from `vim.lsp.buf.inlay_hint`)

### Customization
- Leader key is `,` (can be changed in `lua/config/options.lua`)
- Color scheme is Sonokai (can be changed in `lua/plugins/ui.lua`)
- LSP servers are auto-installed via Mason (configured in `lua/plugins/lsp/lsp.lua`)

### File Types
Special handling for:
- **Go**: Uses tabs instead of spaces
- **Helm**: Charts and templates with Go template support
- **Terraform**: .tf files
- **Ansible**: Auto-detected via ftdetect

## 🛠️ Maintenance

- **Update plugins**: `:Lazy sync`
- **Check plugin status**: `:Lazy`
- **Update LSP servers**: `:Mason`
- **Check LSP status**: `:LspInfo`
- **View key mappings**: `<leader>?` (which-key)

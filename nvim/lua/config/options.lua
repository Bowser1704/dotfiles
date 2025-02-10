-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.cmd("filetype plugin on")

vim.g.mapleader = ","
vim.g.maplocalleader = ","
vim.g.have_nerd_font = true

local opt = vim.opt

opt.clipboard = "" -- unnamed means primary clipboard (unnamedstar register)
opt.cc = "160" -- set an 160 column border for good coding style
opt.mouse = "vc" -- Enable mouse to copy
opt.number = true -- Print line number
opt.pumblend = 10 -- Popup blend
opt.pumheight = 10 -- Maximum number of entries in a popup
opt.relativenumber = true -- Relative line numbers
opt.scrolloff = 4 -- Lines of context
opt.sessionoptions = { "buffers", "curdir", "tabpages", "winsize" }
opt.shiftround = true -- Round indent
opt.shiftwidth = 2 -- Size of an indent
opt.shortmess:append({ W = true, I = true, c = true })
opt.showmode = false -- Dont show mode since we have a statusline
opt.sidescrolloff = 8 -- Columns of context
opt.signcolumn = "yes" -- Always show the signcolumn, otherwise it would shift the text each time
opt.smartcase = true -- Don't ignore case with capitals
opt.smartindent = true -- Insert indents automatically
opt.spelllang = { "en" }
opt.splitbelow = true -- Put new windows below current
opt.splitright = true -- Put new windows right of current
opt.tabstop = 2 -- Number of spaces tabs count for
opt.termguicolors = true -- True color support
opt.timeoutlen = 300
opt.undofile = true
opt.undolevels = 10000
opt.updatetime = 200 -- Save swap file and trigger CursorHold
opt.wildmode = "longest:full,full" -- Command-line completion mode
opt.winminwidth = 5 -- Minimum window width
opt.foldmethod = "expr"
opt.foldexpr = "nvim_treesitter#foldexpr()"
opt.foldenable = false -- Disable folding at startup.
opt.expandtab = true
opt.breakindent = true
opt.undofile = true

-- Fix markdown indentation settings
vim.g.markdown_recommended_style = 0

-- system clipboard
vim.opt.clipboard:append("unnamedplus")
-- Fix "waiting for osc52 response from terminal" message
-- https://github.com/neovim/neovim/issues/28611
if vim.env.SSH_TTY ~= nil then
  -- Set up clipboard for ssh
  local function my_paste(_)
    return function(_)
      local content = vim.fn.getreg('"')
      return vim.split(content, "\n")
    end
  end
  vim.g.clipboard = {
    name = "OSC 52",
    copy = {
      ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
      ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
    },
    paste = {
      -- No OSC52 paste action since wezterm doesn't support it
      -- Should still paste from nvim
      ["+"] = my_paste("+"),
      ["*"] = my_paste("*"),
    },
  }
end

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  -- bootstrap lazy.nvim
  -- stylua: ignore
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(vim.env.LAZY or lazypath)

require("lazy").setup({
  dev = {
    path = "~/codebase/nvim-plugins/",
    patterns = { "neochat.nvim", "codeium.nvim" },
    fallback = true,
  },
  spec = {
    -- add LazyVim and import its plugins
    {
      "LazyVim/LazyVim",
      import = "lazyvim.plugins",
      opts = {
        colorscheme = "sonokai",
        defaults = {
          autocmds = true, -- lazyvim.config.autocmds
          keymaps = false, -- lazyvim.config.keymaps
          options = false, -- lazyvim.config.options
        },
      },
    },
    -- { import = "lazyvim.plugins.extras.ui.mini-animate" },
    -- import/override with your plugins
    { import = "lazyvim.plugins.extras.lsp.none-ls" },
    { import = "plugins" },
    { import = "plugins/lsp" },
    { import = "plugins/lsp/lang" },
  },
  defaults = {
    -- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
    -- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
    lazy = false,
    -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
    -- have outdated releases, which may break your Neovim install.
    version = false, -- always use the latest git commit
    -- version = "*", -- try installing the latest stable version for plugins that support semver
  },
  install = { colorscheme = { "sonokai" } },
  checker = { enabled = false }, -- automatically check for plugin updates
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        "gzip",
        -- "matchit",
        -- "matchparen",
        -- "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})

local status_ok, configs = pcall(require, "nvim-treesitter.configs")
if not status_ok then
  return
end

local vim = vim
local opt = vim.opt

opt.foldmethod = "expr"
opt.foldexpr = "nvim_treesitter#foldexpr()"

configs.setup {
  ensure_installed = {"go", "python", "vim", "lua"}, -- one of "all", "maintained" (parsers with maintainers), or a list of languages
  sync_install = false, -- install languages synchronously (only applied to `ensure_installed`)
  ignore_install = { "" }, -- List of parsers to ignore installing
  autopairs = {
    enable = true,
  },
  highlight = {
    enable = true, -- false will disable the whole extension
    disable = { "" }, -- list of language that will be disabled
    -- additional_vim_regex_highlighting = true,
  },
  indent = { enable = true, disable = { "yaml", "helm" } },
  context_commentstring = {
    enable = true,
    enable_autocmd = false,
  },
}

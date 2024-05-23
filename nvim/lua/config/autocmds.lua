-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

local function augroup(name)
  return vim.api.nvim_create_augroup("basic_" .. name, { clear = true })
end

vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead", "BufAdd", "BufEnter" }, {
  group = augroup("helm-ft"),
  pattern = { "Chart.yaml", "*/templates/*.yaml", "*/templates/*.tpl", "*.gotmpl", "helmfile*.yaml" },
  callback = function()
    vim.bo.filetype = "helm"
    vim.opt_local.commentstring = "{{/* %s */}}"
  end,
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  group = augroup("terraform-ft"),
  pattern = { "*.tf" },
  callback = function()
    vim.bo.filetype = "terraform"
  end,
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("enable-tab"),
  pattern = "go",
  callback = function()
    vim.bo.expandtab = false
  end,
})

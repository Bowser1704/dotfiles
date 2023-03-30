-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
-- Add any additional autocmds here

local function augroup(name)
  return vim.api.nvim_create_augroup("lazyvim_" .. name, { clear = true })
end

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  group = augroup("helm-ft"),
  pattern = { "Chart.yaml", "*/templates/*.yaml", "*/templates/*.tpl", "*.gotmpl", "helmfile*.yaml" },
  callback = function()
    vim.bo.filetype = "helm"
  end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("osc52"),
  callback = function()
    if vim.v.event.regname == "+" then
      require("osc52").copy_register("+")
    end
  end,
})

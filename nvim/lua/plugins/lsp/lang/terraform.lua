return {

  -- add json to treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "terraform", "hcl" })
      end
    end,
  },

  -- correctly setup lspconfig
  {
    "neovim/nvim-lspconfig",
    ft = { "tf", "terraform", "terraform-vars" },
    opts = {
      -- make sure mason installs the server
      servers = {
        terraformls = {},
      },
    },
  },
}

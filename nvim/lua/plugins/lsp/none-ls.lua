return {
  {
    "jay-babu/mason-null-ls.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "nvimtools/none-ls.nvim",
    },
    config = function()
      require("mason").setup()
      require("null-ls").setup()

      require("mason-null-ls").setup({
        ensure_installed = { "stylua", "prettierd", "buf", "yamlfmt" },
        automatic_installation = true,
        handlers = {},
        methods = {
          diagnostics = true,
          formatting = true,
          code_actions = true,
          completion = true,
          hover = true,
        },
      })
    end,
  },
}

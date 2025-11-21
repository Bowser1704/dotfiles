return {
  {
    "jay-babu/mason-null-ls.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      "williamboman/mason.nvim",
      "nvimtools/none-ls.nvim",
      "nvim-lua/plenary.nvim",
    },
    config = function()
      require("mason").setup()
      local nls = require("null-ls")
      nls.setup({
        update_in_insert = true,
        debug = true,
      })

      require("mason-null-ls").setup({
        ensure_installed = { "stylua", "buf", "yamlfmt", "shellcheck" },
        automatic_installation = true,
        handlers = {
          function(source_name, methods)
            require("mason-null-ls").default_setup(source_name, methods) -- to maintain default behavior
          end,
        },
      })
    end,
  },
}

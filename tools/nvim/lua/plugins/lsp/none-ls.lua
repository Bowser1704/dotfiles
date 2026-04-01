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
                -- Add explicit on_attach function for Neovim 0.11.5 compatibility
        on_attach = function(client, _)
          -- Disable formatting capability to avoid conflicts with conform.nvim
          if client.server_capabilities then
            client.server_capabilities.documentFormattingProvider = false
            client.server_capabilities.documentRangeFormattingProvider = false
          end
        end,
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

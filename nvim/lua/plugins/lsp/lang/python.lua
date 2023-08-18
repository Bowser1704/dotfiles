return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      setup = {
        ruff_lsp = function()
          require("lazyvim.util").on_attach(function(client)
            if client.name == "ruff_lsp" then
              client.server_capabilities.hoverProvider = false
            end
          end)
        end,
      },
    },
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      ft = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
      servers = {
        volar = {
          filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
        },
        rome = {
          filetypes = { "javascript", "javascriptreact", "typescriptreact", "typescript" },
        },
        clangd = {
          filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
        },
      },
    },
  },
}

local util = require("utils")

return {
  {
    "neovim/nvim-lspconfig",
    ft = { "python" },
    opts = {
      servers = {
        basedpyright = {
          enabled = true,
          settings = {
            basedpyright = {
              analysis = {
                autoSearchPaths = true,
                diagnosticMode = "openFilesOnly",
                useLibraryCodeForTypes = true,
                typeCheckingMode = "basic",
              },
            },
          },
        },
        ruff = {
          keys = {
            {
              "<leader>ca",
              function()
                vim.lsp.buf.code_action({
                  apply = true,
                  context = {
                    only = { "source.organizeImports" },
                    diagnostics = {},
                  },
                })
              end,
              desc = "Organize Imports",
            },
          },
        },
      },
      setup = {
        ruff = function()
          util.on_attach(function(client, _)
            if client.name == "ruff" then
              -- Disable hover in favor of Pyright
              client.server_capabilities.hoverProvider = false
            end
          end)
        end,
      },
    },
  },
}

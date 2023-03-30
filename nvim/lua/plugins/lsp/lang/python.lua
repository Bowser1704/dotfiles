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
}

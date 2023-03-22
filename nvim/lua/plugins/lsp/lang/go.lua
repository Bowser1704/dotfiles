return {

  -- add json to treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "go", "gomod", "gosum", "gowork" })
      end
    end,
  },

  -- correctly setup lspconfig
  {
    "neovim/nvim-lspconfig",
    opts = {
      -- make sure mason installs the server
      servers = {
        gopls = {
          filetypes = { "go", "gomod", "gotmpl", "helm" },
          settings = {
            gopls = {
              usePlaceholders = false,
              gofumpt = true,
              templateExtensions = { "tpl", "yaml" },
              codelenses = {
                generate = true,
                test = true,
                tidy = true,
                upgrade_dependency = true,
              },
              analyses = {
                fieldaligment = true,
                nilness = true,
                shadow = true,
                unusedwrite = true,
              },
              hints = {
                assignVariableTypes = true,
                compositeLiteralFields = true,
                constantValues = true,
                functionTypeParameters = true,
                parameterNames = true,
                rangeVariableTypes = true,
              },
            },
          },
        },
      },
    },
  },
}

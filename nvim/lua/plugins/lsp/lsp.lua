return {
  {
    "b0o/SchemaStore.nvim",
    lazy = true,
    version = false, -- last release is way too old
  },
  {
    "smjonas/inc-rename.nvim",
    dependencies = {
      "folke/trouble.nvim",
    },
    cmd = "IncRename",
    config = function()
      require("inc_rename").setup()
    end,
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPost", "BufNewFile", "BufEnter" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
      "nvim-telescope/telescope.nvim",
    },
    config = function(_, _)
      vim.keymap.set("n", "fd", "<cmd>lua vim.diagnostic.open_float()<cr>")
      vim.keymap.set("n", "[d", "<cmd>lua vim.diagnostic.goto_prev()<cr>")
      vim.keymap.set("n", "]d", "<cmd>lua vim.diagnostic.goto_next()<cr>")
      vim.keymap.set("n", "<leader>cl", "<cmd>LspInfo<cr>")

      vim.api.nvim_create_autocmd("LspAttach", {
        desc = "LSP actions",
        callback = function(event)
          local opts = { buffer = event.buf }

          -- these will be buffer-local keybindings
          -- because they only work if you have an active language server

          vim.keymap.set("n", "K", "<cmd>lua vim.lsp.buf.hover()<cr>", opts)
          vim.keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<cr>", opts)
          vim.keymap.set("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<cr>", opts)
          vim.keymap.set("n", "gi", "<cmd>Telescope lsp_implementations<cr>", opts)
          vim.keymap.set("n", "gr", "<cmd>Telescope lsp_references<cr>", opts)
          vim.keymap.set("n", "gt", "<cmd>lua vim.lsp.buf.type_definition()<cr>", opts)
          vim.keymap.set("n", "gs", "<cmd>lua vim.lsp.buf.signature_help()<cr>", opts)
          vim.keymap.set({ "n", "x" }, "<leader>f", "<cmd>lua vim.lsp.buf.format({async = true})<cr>", opts)
          vim.keymap.set("n", "<leader>ca", "<cmd>lua vim.lsp.buf.code_action()<cr>", opts)
          -- vim.keymap.set('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<cr>', opts)
          vim.keymap.set("n", "<leader>rn", function()
            return ":IncRename " .. vim.fn.expand("<cword>")
          end, { expr = true })

          -- vim.keymap.set('n', '<leader>th',
          --   '<cmd>lua vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({})) <cr>', opts)
        end,
      })

      -- default lsp inlayhints is ugly
      -- vim.api.nvim_create_autocmd("LspAttach", {
      --   desc = "lsp inlayhints",
      --   callback = function(args)
      --     if not (args.data and args.data.client_id) then
      --       return
      --     end
      --
      --     local client = vim.lsp.get_client_by_id(args.data.client_id)
      --
      --     if client and client.name == "rust_analyzer" then
      --       vim.lsp.inlay_hint.enable(false)
      --       return
      --     end
      --     vim.lsp.inlay_hint.enable(true)
      --   end,
      -- })

      local lsp_capabilities = require("cmp_nvim_lsp").default_capabilities()
      -- to learn how to use mason.nvim
      -- read this: https://github.com/VonHeikemen/lsp-zero.nvim/blob/v3.x/doc/md/guide/integrate-with-mason-nvim.md
      require("mason").setup({})
      require("mason-lspconfig").setup({
        ensure_installed = { "rust_analyzer" },
      })
      require("mason-lspconfig").setup_handlers({
        function(server_name)
          require("lspconfig")[server_name].setup({
            capabilities = lsp_capabilities,
          })
        end,

        ["lua_ls"] = function()
          require("lspconfig").lua_ls.setup({
            on_init = function(client)
              local path = client.workspace_folders[1].name
              if vim.loop.fs_stat(path .. "/.luarc.json") or vim.loop.fs_stat(path .. "/.luarc.jsonc") then
                return
              end

              client.config.settings.Lua = vim.tbl_deep_extend("force", client.config.settings.Lua, {
                runtime = {
                  -- Tell the language server which version of Lua you're using
                  -- (most likely LuaJIT in the case of Neovim)
                  version = "LuaJIT",
                },
                -- Make the server aware of Neovim runtime files
                workspace = {
                  checkThirdParty = false,
                  library = {
                    vim.env.VIMRUNTIME,
                  },
                },
              })
            end,
            settings = {
              Lua = {},
            },
          })
        end,

        ["gopls"] = function()
          require("lspconfig").gopls.setup({
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
          })
        end,

        ["clangd"] = function()
          require("lspconfig").clangd.setup({
            filetypes = { "c", "cpp", "objc", "objcpp" },
          })
        end,

        ["basedpyright"] = function()
          require("lspconfig").basedpyright.setup({
            settings = {
              basedpyright = {
                analysis = {
                  autoSearchPaths = true,
                  diagnosticMode = "openFilesOnly", -- workspace mode is too slow
                  useLibraryCodeForTypes = true,
                  typeCheckingMode = "basic",
                },
              },
            },
          })
        end,
      })
    end,
  },
}

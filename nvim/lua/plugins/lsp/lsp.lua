return {
  {
    "b0o/SchemaStore.nvim",
    lazy = true,
    version = false, -- last release is way too old
  },
  {
    "saecki/live-rename.nvim",
    dependencies = {
      "folke/trouble.nvim",
    },
  },
  {
    "chrisgrieser/nvim-lsp-endhints",
    event = "LspAttach",
    opts = {}, -- required, even if empty
  },
  {
    "neovim/nvim-lspconfig",
    event = { "BufReadPost", "BufNewFile", "BufEnter" },
    dependencies = {
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "hrsh7th/cmp-nvim-lsp",
      "ibhagwan/fzf-lua",
    },
    config = function(_, _)
      require("fzf-lua").register_ui_select()

      vim.diagnostic.config({ virtualext = true, virtual_lines = { current_line = true } })

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
          vim.keymap.set("n", "gd", "<cmd>FzfLua lsp_definitions<cr>", opts)
          vim.keymap.set("n", "gD", "<cmd>lua vim.lsp.buf.declaration()<cr>", opts)
          vim.keymap.set("n", "gi", "<cmd>FzfLua lsp_implementations<cr>", opts)
          vim.keymap.set("n", "gr", "<cmd>FzfLua lsp_references<cr>", opts)
          vim.keymap.set("n", "gt", "<cmd>lua vim.lsp.buf.type_definition()<cr>", opts)
          vim.keymap.set("n", "gs", "<cmd>lua vim.lsp.buf.signature_help()<cr>", opts)
          vim.keymap.set({ "n", "x" }, "<leader>f", "<cmd>lua vim.lsp.buf.format({async = true})<cr>", opts)
          vim.keymap.set("n", "<leader>ca", "<cmd>FzfLua lsp_code_actions<cr>", opts)
          vim.keymap.set(
            "n",
            "<leader>rn",
            require("live-rename").map({ insert = false, cursorpos = -1 }),
            { desc = "LSP rename" }
          )
        end,
      })

      vim.lsp.config.gopls = {
        filetypes = { "go", "gotempl", "gowork", "gomod" },
        root_markers = { ".git", "go.mod", "go.work", vim.uv.cwd() },
        settings = {
          gopls = {
            completeUnimported = true,
            usePlaceholders = true,
            analyses = {
              unusedparams = true,
            },
            ["ui.inlayhint.hints"] = {
              assignVariableTypes = true,
              functionTypeParameters = true,
              compositeLiteralFields = true,
              constantValues = true,
              parameterNames = true,
              rangeVariableTypes = true,
            },
          },
        },
      }

      -- Lua {{{
      vim.lsp.config.lua_ls = {
        cmd = { "lua-language-server" },
        filetypes = { "lua" },
        root_markers = { ".luarc.json", ".git", vim.uv.cwd() },
        settings = {
          Lua = {
            telemetry = {
              enable = false,
            },
            hint = { enable = true },
          },
        },
      }

      vim.lsp.config.basedpyright = {
        name = "basedpyright",
        filetypes = { "python" },
        cmd = { "basedpyright-langserver", "--stdio" },
        settings = {
          python = {
            venvPath = vim.fn.expand("~") .. "/.virtualenvs",
          },
          basedpyright = {
            disableOrganizeImports = true,
            analysis = {
              autoSearchPaths = true,
              autoImportCompletions = true,
              useLibraryCodeForTypes = true,
              diagnosticMode = "openFilesOnly",
              typeCheckingMode = "strict",
              inlayHints = {
                variableTypes = true,
                callArgumentNames = true,
                functionReturnTypes = true,
                genericTypes = false,
              },
            },
          },
        },
      }
      vim.lsp.enable("basedpyright")

      vim.lsp.config.jsonls = {
        settings = {
          json = {
            schemas = require("schemastore").json.schemas(),
            validate = { enable = true },
          },
        },
      }

      vim.lsp.enable("gopls")

      -- to learn how to use mason.nvim
      -- read this: https://github.com/VonHeikemen/lsp-zero.nvim/blob/v3.x/doc/md/guide/integrate-with-mason-nvim.md
      require("mason").setup({})
      require("mason-lspconfig").setup({
        ensure_installed = { "rust_analyzer", "jsonls", "gopls" },
        automatic_enable = { "jsonls", "lua_ls", "gopls" },
      })
    end,
  },
}

return {
  {
    "williamboman/mason-lspconfig.nvim",
    event = "VeryLazy",
    init = function(_, opts)
      require("mason").setup()
    end
  },
  {

    "williamboman/mason.nvim",
    cmd = "Mason",
    keys = { { "<leader>cm", "<cmd>Mason<cr>", desc = "Mason" } },
    build = ":MasonUpdate",
    opts = {
      ensure_installed = {
        "stylua",
        "shfmt",
        -- "flake8",
      },
    },
    ---@param opts MasonSettings | {ensure_installed: string[]}
    config = function(_, opts)
      require("mason").setup(opts)
      local mr = require("mason-registry")
      mr:on("package:install:success", function()
        vim.defer_fn(function()
          -- trigger FileType event to possibly load this newly installed LSP server
          require("lazy.core.handler.event").trigger({
            event = "FileType",
            buf = vim.api.nvim_get_current_buf(),
          })
        end, 100)
      end)
      local function ensure_installed()
        for _, tool in ipairs(opts.ensure_installed) do
          local p = mr.get_package(tool)
          if not p:is_installed() then
            p:install()
          end
        end
      end
      if mr.refresh then
        mr.refresh(ensure_installed)
      else
        ensure_installed()
      end
    end,
  },
  -- add json to treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      if type(opts.ensure_installed) == "table" then
        vim.list_extend(opts.ensure_installed, { "json", "json5", "jsonc" })
      end
    end,
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      ft = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
      servers = {
        volar = {
          filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue" },
        },
        clangd = {
          filetypes = { "c", "cpp", "objc", "objcpp", "cuda" },
        },
      },
    },
  },

  -- correctly setup lspconfig
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "b0o/SchemaStore.nvim",
      version = false, -- last release is way too old
    },
    opts = {
      -- make sure mason installs the server
      servers = {
        jsonls = {
          -- lazy-load schemastore when needed
          on_new_config = function(new_config)
            new_config.settings.json.schemas = new_config.settings.json.schemas or {}
            vim.list_extend(new_config.settings.json.schemas, require("schemastore").json.schemas())
          end,
          settings = {
            json = {
              format = {
                enable = true,
              },
              validate = { enable = true },
            },
          },
        },
      },
    },
  },

  {
    "nvimtools/none-ls.nvim",
    event = { "BufReadPre", "BufNewFile", "BufReadPost" },
    dependencies = { "mason.nvim" },
    opts = function()
      local nls = require("null-ls")
      return {
        root_dir = require("null-ls.utils").root_pattern(".null-ls-root", ".neoconf.json", "Makefile", ".git"),
        sources = {
          nls.builtins.formatting.fish_indent,
          nls.builtins.formatting.stylua,
          nls.builtins.formatting.shfmt,

          nls.builtins.diagnostics.buf,
          nls.builtins.formatting.buf,

          nls.builtins.diagnostics.terraform_validate,
          nls.builtins.diagnostics.tfsec,
          nls.builtins.formatting.terraform_fmt,
          nls.builtins.formatting.hclfmt,

          nls.builtins.formatting.gofumpt,
          nls.builtins.diagnostics.golangci_lint.with({
            -- extra_args = { "--fix" },
          }),

          nls.builtins.diagnostics.sqlfluff.with({
            extra_args = { "--dialect", "postgres" }, -- change to your dialect
          }),
          nls.builtins.formatting.sqlfluff.with({
            extra_args = { "--dialect", "postgres" }, -- change to your dialect
          }),

          nls.builtins.formatting.prettierd,
        },
      }
    end,
  },
}

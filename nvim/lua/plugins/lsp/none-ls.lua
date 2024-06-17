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
  -- {
  --   "nvimtools/none-ls.nvim",
  --   -- dir = "/home/hongqi/codebase/none-ls.nvim",
  --   event = { "BufReadPre", "BufNewFile", "BufReadPost" },
  --   dependencies = { "mason.nvim" },
  --   opts = function()
  --     local nls = require("null-ls")
  --     return {
  --       debug = true,
  --       root_dir = require("null-ls.utils").root_pattern(".null-ls-root", ".neoconf.json", "Makefile", ".git"),
  --       sources = {
  --         nls.builtins.formatting.fish_indent,
  --         nls.builtins.formatting.stylua,
  --         nls.builtins.formatting.shfmt,
  --
  --         nls.builtins.diagnostics.buf,
  --         nls.builtins.formatting.buf,
  --
  --         nls.builtins.diagnostics.terraform_validate,
  --         nls.builtins.diagnostics.tfsec,
  --         nls.builtins.formatting.terraform_fmt,
  --         nls.builtins.formatting.hclfmt,
  --
  --         nls.builtins.formatting.gofumpt,
  --         nls.builtins.diagnostics.golangci_lint.with({
  --           -- extra_args = { "--fix" },
  --         }),
  --
  --         nls.builtins.diagnostics.sqlfluff.with({
  --           extra_args = { "--dialect", "postgres" }, -- change to your dialect
  --         }),
  --         nls.builtins.formatting.sqlfluff.with({
  --           extra_args = { "--dialect", "postgres" }, -- change to your dialect
  --         }),
  --       },
  --     }
  --   end,
  -- },
}

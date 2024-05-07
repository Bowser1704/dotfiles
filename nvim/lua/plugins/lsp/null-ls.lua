return {
  -- formatters
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

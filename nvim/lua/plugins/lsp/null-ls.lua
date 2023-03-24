return {
  -- formatters
  {
    "jose-elias-alvarez/null-ls.nvim",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "mason.nvim" },
    opts = function()
      local nls = require("null-ls")
      return {
        root_dir = require("null-ls.utils").root_pattern(".null-ls-root", ".neoconf.json", "Makefile", ".git"),
        sources = {
          nls.builtins.diagnostics.fish,
          nls.builtins.diagnostics.flake8,

          nls.builtins.formatting.fish_indent,
          nls.builtins.formatting.stylua,
          nls.builtins.formatting.shfmt,
          nls.builtins.formatting.buf,

          nls.builtins.diagnostics.terraform_validate,
          nls.builtins.diagnostics.tfsec,
          nls.builtins.formatting.terraform_fmt,
          nls.builtins.formatting.hclfmt,
        },
      }
    end,
  },
}
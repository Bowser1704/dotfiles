return {
  -- LSP keymaps
  {
    "neovim/nvim-lspconfig",
    init = function()
      local keys = require("lazyvim.plugins.lsp.keymaps").get()
      -- add fd keymap
      keys[#keys + 1] = { "<leader>fd", vim.diagnostic.open_float, desc = "Float Diagnostics" }
      -- disable default keymap
      keys[#keys + 1] = { "<leader>fd", false }
      -- add rename keymap
      if require("lazyvim.util").has("inc-rename.nvim") then
        keys[#keys + 1] = {
          "<leader>rn",
          function()
            require("inc_rename")
            return ":IncRename " .. vim.fn.expand("<cword>")
          end,
          expr = true,
          desc = "Rename",
          has = "rename",
        }
      else
        keys[#keys + 1] = { "<leader>rn", vim.lsp.buf.rename, desc = "Rename", has = "rename" }
      end
    end,
  },
}

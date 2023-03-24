return {
  {
    "nvim-tree/nvim-tree.lua",
    cmd = "NvimTreeToggle",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons", -- not strictly required, but recommended
    },
    keys = {
      { "<leader>e", "<cmd>NvimTreeToggle<CR>", desc = "Explorer NvimTree", remap = true },
    },
    deactivate = function()
      vim.cmd([[NvimTreeToggle]])
    end,
    -- init = function()
    --   vim.g.neo_tree_remove_legacy_commands = 1
    --   if vim.fn.argc() == 1 then
    --     local stat = vim.loop.fs_stat(vim.fn.argv(0))
    --     if stat and stat.type == "directory" then
    --       require("neo-tree")
    --     end
    --   end
    -- end,
    opts = {
      sync_root_with_cwd = false,
      respect_buf_cwd = false,
      diagnostics = {
        enable = true,
      },
      renderer = {
        highlight_git = true,
        indent_markers = {
          enable = true,
          icons = {
            corner = "└",
            edge = "│ ",
            none = " ",
          },
        },
        icons = {
          webdev_colors = true,
          git_placement = "before",
        },
      },
      update_focused_file = {
        enable = true,
        update_root = true,
        ignore_list = {},
      },
      view = {
        width = 30,
      },
      git = {
        ignore = true,
      },
    },
  },
}

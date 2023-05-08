return {
  -- add extra telescope keymaps
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "folke/noice.nvim",
    },
    init = function()
      require("telescope").load_extension("noice")
    end,
    opts = {
      defaults = {
        layout_strategy = "horizontal",
        wrap_results = true,
        initial_mode = "insert",
        path_display = {
          "smart",
        },
        layout_config = {
          horizontal = {
            preview_width = 90,
          },
        },
        dynamic_preview_title = true,
        file_sorter = require("telescope.sorters").get_fuzzy_file,
        file_ignore_patterns = {},
        generic_sorter = require("telescope.sorters").get_generic_fuzzy_sorter,
        shorten_path = true,
        file_previewer = require("telescope.previewers").vim_buffer_cat.new,
      },
    },
    keys = {
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "live grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files (root dir)" },
      { "<leader>hh", "<cmd>Telescope help_tags<cr>", desc = "Help Pages" },
      { "<leader>fn", "<cmd>Telescope noice<cr>", desc = "Find Noice" },
      -- add a keymap to browse plugin files
      -- stylua: ignore
      {
        "<leader>fp",
        function() require("telescope.builtin").find_files({ cwd = require("lazy.core.config").options.root }) end,
        desc = "Find Plugin File",
      },
    },
  },
}

return {
  -- add extra telescope keymaps
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "folke/noice.nvim",
      "nvim-telescope/telescope-ui-select.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim", -- https://github.com/nvim-telescope/telescope-fzf-native.nvim
        build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build",
      },
      {
        "nvim-telescope/telescope-file-browser.nvim",
        dependencies = {
          "nvim-telescope/telescope.nvim",
          "nvim-lua/plenary.nvim",
          "nvim-tree/nvim-web-devicons",
        },
      },
      "nvim-telescope/telescope-live-grep-args.nvim",
    },
    event = "VeryLazy",
    init = function()
      local telescope = require("telescope")
      telescope.load_extension("noice")
      telescope.load_extension("ui-select")
      telescope.load_extension("file_browser")
      telescope.load_extension("live_grep_args")
    end,
    opts = function()
      local lga_actions = require("telescope-live-grep-args.actions")
      return {
        defaults = {
          file_ignore_patterns = { ".git/", "node_modules", "poetry.lock" },
          layout_strategy = "horizontal",
          wrap_results = true,
          initial_mode = "insert",
          path_display = {
            "smart",
          },
          layout_config = {
            horizontal = {
              preview_width = 80,
            },
          },
          dynamic_preview_title = true,
          shorten_path = true,
          -- generic_sorter = require("telescope.sorters").get_generic_fuzzy_sorter,
          -- file_sorter = require("telescope.sorters").get_fuzzy_file,
          -- file_previewer = require("telescope.previewers").vim_buffer_cat.new,
        },
        extensions = {
          ["ui-select"] = {},
          file_browser = {
            dir_icon = "",
            theme = "ivy",
            -- disables netrw and use telescope-file-browser in its place
            hijack_netrw = true,
            mappings = {},
          },
          live_grep_args = {
            auto_quoting = true, -- enable/disable auto-quoting
            -- define mappings, e.g.
            mappings = { -- extend mappings
              i = {
                ["<C-k>"] = lga_actions.quote_prompt(),
                ["<C-i>"] = lga_actions.quote_prompt({ postfix = " --iglob " }),
                -- freeze the current list and start a fuzzy search in the frozen list
                ["<C-f>"] = lga_actions.to_fuzzy_refine,
              },
            },
          },
        },
      }
    end,
    keys = {
      { "<leader>:", "<cmd>Telescope command_history<cr>", desc = "Command History" },
      -- find
      { "<leader>fg", "<cmd>Telescope live_grep_args<cr>", desc = "live grep" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Find Files (root dir)" },
      { "<leader>hh", "<cmd>Telescope help_tags<cr>", desc = "Help Pages" },
      { "<leader>fn", "<cmd>Telescope noice<cr>", desc = "Find Noice" },
      { "<leader>ft", "<cmd>Telescope file_browser<cr>", desc = "File Browsers" },
      {
        "<leader>fp",
        function()
          require("telescope.builtin").find_files({ cwd = require("lazy.core.config").options.root })
        end,
        desc = "Find Plugin File",
      },
      -- git
      { "<leader>gc", "<cmd>Telescope git_commits<CR>", desc = "Commits" },
      { "<leader>gs", "<cmd>Telescope git_status<CR>", desc = "Status" },
      -- search
      { '<leader>s"', "<cmd>Telescope registers<cr>", desc = "Registers" },
      { "<leader>sk", "<cmd>Telescope keymaps<cr>", desc = "Key Maps" },
      { "<leader>so", "<cmd>Telescope vim_options<cr>", desc = "Options" },
      { "<leader>sd", "<cmd>Telescope diagnostics bufnr=0<cr>", desc = "Document Diagnostics" },
      { "<leader>sD", "<cmd>Telescope diagnostics <cr>", desc = "Document Diagnostics" },
      { "<leader>sM", "<cmd>Telescope man_pages<cr>", desc = "Man Pages" },
    },
  },
}

return {
  {
    "windwp/nvim-spectre",
    -- stylua: ignore
    keys = {
      { "<leader>S", function() require("spectre").open() end, desc = "Replace in files (Spectre)" },
    },
  },
  {
    "numToStr/FTerm.nvim",
    opts = {
      border = "double",
      dimensions = {
        height = 0.9,
        width = 0.9,
      },
      blend = 10,
    },
    keys = {
      {
        "<A-o>",
        function()
          require("FTerm").toggle()
        end,
        desc = "fterm",
        mode = { "i", "n", "v", "t" },
      },
    },
  },
  -- system clipboard
  {
    "ojroques/nvim-osc52",
    opts = {
      max_length = 0,
      silent = false,
      trim = false,
    },
  },

  -- folds
  { "pedrohdz/vim-yaml-folds", ft = { "yaml", "helm" } },
  "mg979/vim-visual-multi",
  "mboughaba/vim-lessmess",
}

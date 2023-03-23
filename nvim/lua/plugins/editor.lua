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
  },
  -- system clipboard
  {
    "EtiamNullam/deferred-clipboard.nvim",
    event = {
      "FocusGained",
      "FocusLost",
    },
    opts = {
      fallback = "unnamedplus",
      force_init_unnamed = true,
    },
  },
  "ojroques/vim-oscyank",

  -- folds
  "pedrohdz/vim-yaml-folds",
  "mg979/vim-visual-multi",
  "mboughaba/vim-lessmess",
  "lukas-reineke/indent-blankline.nvim",
}

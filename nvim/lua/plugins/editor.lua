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
  "pedrohdz/vim-yaml-folds",
  "mg979/vim-visual-multi",
  "ojroques/vim-oscyank",
  "mboughaba/vim-lessmess",
  "lukas-reineke/indent-blankline.nvim",
}

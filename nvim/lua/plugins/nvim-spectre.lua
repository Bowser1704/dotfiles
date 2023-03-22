return {
  {
    "windwp/nvim-spectre",
  -- stylua: ignore
  keys = {
    { "<leader>S", function() require("spectre").open() end, desc = "Replace in files (Spectre)" },
  },
  },
}

return {
  {
    "Xuyuanp/neochat.nvim",
    build = function()
      vim.fn.system({ "pip", "install", "-U", "openai" })
    end,
    dependencies = {
      "MunifTanjim/nui.nvim",
      -- optional
      "nvim-telescope/telescope.nvim",
      "f/awesome-chatgpt-prompts",
    },
    config = function()
      require("neochat").setup({
        layout_opts = {
          relative = "editor",
          position = "50%",
          size = {
            width = "80%",
            height = "80%",
          },
        },
      })
    end,
    keys = {
      {
        "<A-c>",
        function()
          require("neochat").toggle()
        end,
        desc = "neochat",
        mode = { "i", "n", "v", "t" },
      },
    },
  },
}

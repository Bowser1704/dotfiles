return {
  {
    "Xuyuanp/neochat.nvim",
    build = function()
      vim.fn.system({ "pip", "install", "-U", "openai" })
    end,
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("neochat").setup({
        -- no config yet
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

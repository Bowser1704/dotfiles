return {
  "milanglacier/minuet-ai.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "hrsh7th/nvim-cmp",
  },
  config = function()
    require("minuet").setup({
      provider = "openai_fim_compatible",
      provider_options = {
        openai_fim_compatible = {
          model = "qwen3.6-plus",
          end_point = "https://dashscope.aliyuncs.com/compatible-mode/v1",
          api_key = "DASHSCOPE_API_KEY",
          name = "Bailian",
          stream = true,
          optional = {
            max_tokens = 256,
          },
        },
      },
      throttle = 1000,
      debounce = 400,
      context_window = 16000,
      context_ratio = 0.75,
      notify = "warn",
    })
  end,
}

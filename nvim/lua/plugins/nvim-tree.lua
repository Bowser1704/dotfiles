-- Global options
local status_ok, nvim_tree = pcall(require, "nvim-tree")
if not status_ok then
  return
end

nvim_tree.setup({
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
    width = 25,
  },
  git = {
    ignore = false,
  },
})

local vim = vim

local M = {}

function M.on_lsp_attach(on_attach, opts)
  opts = opts or {}
  opts.callback = function(args)
    local bufnr = args.buf
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    on_attach(client, bufnr)
  end
end

return M

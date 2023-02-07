local lsp_installer = require("nvim-lsp-installer")
local api = vim.api

lsp_installer.setup({
  automatic_installation = true, -- automatically detect which servers to install (based on which servers are set up via lspconfig)
  ui = {
    icons = {
      server_installed = "✓",
      server_pending = "➜",
      server_uninstalled = "✗",
    },
  },
})

local set_lsp_keymaps = function(_, bufnr)
  local key_opts = { remap = true, silent = false, buffer = bufnr }
  local set_keymap = vim.keymap.set
  local telescope = require("telescope.builtin")

  local mappings = {
    K = vim.lsp.buf.hover,
    gd = telescope.lsp_definitions,
    gD = telescope.lsp_type_definitions,
    gi = telescope.lsp_implementations,
    gr = telescope.lsp_references,
    fd = vim.diagnostic.open_float,
    nd = vim.diagnostic.goto_next,
    Nd = vim.diagnostic.goto_prev,
    ["<leader>rn"] = vim.lsp.buf.rename,
    ["<leader>ca"] = vim.lsp.buf.code_action,
    ["<space>f"] = vim.lsp.buf.format({ async = false }),
    ["<leader>cl"] = vim.lsp.codelens.run(),
  }

  for lhs, rhs in pairs(mappings) do
    set_keymap("n", lhs, rhs, key_opts)
  end
end

local group_id = api.nvim_create_augroup("lsp_autocmds", { clear = true })
local function set_lsp_autocmd(client, bufnr)
  if client.supports_method("textDocument/formating") then
    api.nvim_create_autocmd({ "BufWritePre" }, {
      group = group_id,
      buffer = bufnr,
      desc = "[lsp] auto format",
      callback = function()
        if not vim.g.lsp_disable_auto_format then
          vim.lsp.buf.format({ async = false })
        end
      end,
    })
  end

  if client.supports_method("textDocument/documentHighlight") and client.name ~= "rust_analyzer" then
    api.nvim_create_autocmd({ "CursorHold" }, {
      group = group_id,
      buffer = bufnr,
      callback = function()
        vim.lsp.buf.document_highlight()
      end,
    })
    api.nvim_create_autocmd({ "CursorMoved" }, {
      group = group_id,
      buffer = bufnr,
      callback = function()
        vim.lsp.buf.clear_references()
      end,
    })
  end
end

local on_attach = function(client, bufnr)
  set_lsp_keymaps(client, bufnr)
  set_lsp_autocmd(client, bufnr)
end

local lspconfig = require("lspconfig")

-- gopls
lspconfig.gopls.setup({
  on_attach = on_attach,
  settings = {
    filetypes = { "go", "gomod", "gotmpl", "helm" },
    gopls = {
      usePlaceholders = false,
      gofumpt = true,
      templateExtensions = { "tpl", "yaml" },
      codelenses = {
        generate = true,
        test = true,
        tidy = true,
        upgrade_dependency = true,
      },
      analyses = {
        fieldaligment = true,
        nilness = true,
        shadow = true,
        unusedwrite = true,
      },
    },
  },
})

-- lua
local function get_runtime_path()
  local runtime_path = vim.split(package.path, ";")
  table.insert(runtime_path, "lua/?.lua")
  table.insert(runtime_path, "lua/?/init.lua")
  table.insert(runtime_path, vim.env.VIM .. "/sysinit.lua")
  return runtime_path
end

lspconfig.sumneko_lua.setup({
  on_attach = on_attach,
  settings = {
    Lua = {
      diagnostics = {
        enable = true,
        globals = {
          "vim",
          "pprint",
        },
        disable = {
          "unused-vararg",
          "unused-local",
          "redefined-local",
        },
      },
      format = {
        enable = false,
      },
      runtime = {
        version = "LuaJIT",
        path = get_runtime_path(),
      },
      workspace = {
        library = vim.api.nvim_get_runtime_file("", true),
        ignoreDir = {
          ".cache",
        },
      },
    },
  },
})

-- pyright
lspconfig.pyright.setup({
  on_attach = function(client, bufnr)
    client.server_capabilities.hover = false
    on_attach(client, bufnr)
  end,
  settings = {
    cmd = { "pyright-langserver", "--stdio" },
    filetypes = { "python" },
    --root_dir = function(startpath)
    --       return M.search_ancestors(startpath, matcher)
    --  end,
    settings = {
      python = {
        analysis = {
          autoSearchPaths = true,
          diagnosticMode = "workspace",
          useLibraryCodeForTypes = true,
        },
      },
    },
    single_file_support = true,
    pythonPath = "python3",
  },
})

lspconfig.jedi_language_server.setup({
  on_attach = on_attach,
})

-- jsonls
lspconfig.jsonls.setup({
  on_attach = on_attach,
})

-- rust
local rt = require("rust-tools")
rt.setup({
  server = {
    on_attach = on_attach,
  },
})

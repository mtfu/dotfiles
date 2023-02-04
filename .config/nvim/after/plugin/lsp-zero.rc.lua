-- Learn the keybindings, see :help lsp-zero-keybindings
-- Learn to configure LSP servers, see :help lsp-zero-api-showcase
local status, bufferline = pcall(require, "lsp-zero")
if (not status) then return end

local lsp = require('lsp-zero')
lsp.preset('recommended')

lsp.ensure_installed({
  'tsserver',
  'eslint',
  'sumneko_lua',
  'angularls'
})

lsp.configure('tsserver', {
  on_attach = function(client, bufnr)
  end,
  settings = {
    completions = {
      completeFunctionCalls = true
    }
  }
})

-- Configure language server for neomvim
lsp.nvim_workspace()

lsp.setup()

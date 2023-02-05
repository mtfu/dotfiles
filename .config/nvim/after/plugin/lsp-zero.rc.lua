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

lsp.on_attach(function(client, bufnr)
    print("help")
  local opts = {buffer = bufnr, remap = false}

  vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, opts)
  vim.keymap.set("n", "K", function() vim.lsp.buf.hover() end, opts)
  vim.keymap.set("n", "<leader>vws", function() vim.lsp.buf.workspace_symbol() end, opts)
  vim.keymap.set("n", "<leader>vd", function() vim.diagnostic.open_float() end, opts)
  vim.keymap.set("n", "[d", function() vim.diagnostic.goto_next() end, opts)
  vim.keymap.set("n", "]d", function() vim.diagnostic.goto_prev() end, opts)
  vim.keymap.set("n", "<leader>vca", function() vim.lsp.buf.code_action() end, opts)
  vim.keymap.set("n", "<leader>vrr", function() vim.lsp.buf.references() end, opts)
  vim.keymap.set("n", "<leader>re", function() vim.lsp.buf.rename() end, opts)
  vim.keymap.set("i", "<C-H>", function() vim.lsp.buf.signature_help() end, opts)
end)

lsp.setup()



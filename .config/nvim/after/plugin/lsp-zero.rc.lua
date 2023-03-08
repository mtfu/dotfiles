-- Learn the keybindings, see :help lsp-zero-keybindings
-- Learn to configure LSP servers, see :help lsp-zero-api-showcase
local status, lsp = pcall(require, "lsp-zero")
if (not status) then return end

lsp.preset('recommended')

lsp.ensure_installed({
  'tsserver',
  'eslint',
  'sumneko_lua',
  'angularls'
})

lsp.configure('tsserver', {
  on_attach = function(_, _)
  end,
  settings = {
    completions = {
      completeFunctionCalls = true
    }
  }
})

-- Configure language server for neomvim
lsp.nvim_workspace()

lsp.on_attach(function(_, bufnr)

  local opts = {buffer = bufnr, remap = false}
  local bind = vim.keymap.set

  bind("n", "<leader>re", function() vim.lsp.buf.rename() end, opts)
  bind("n", "<leader>ca", function() vim.lsp.buf.code_action() end, opts)
  bind("n", "<leader>u", require('telescope.builtin').lsp_references, {})
  bind("n", "<leader>gi", function() vim.lsp.buf.implementation() end, opts)

end)

lsp.setup()



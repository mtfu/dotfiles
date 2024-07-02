-- Learn the keybindings, see :help lsp-zero-keybindings
-- Learn to configure LSP servers, see :help lsp-zero-api-showcase
local status, lsp = pcall(require, "lsp-zero")
if (not status) then return end

lsp.preset('recommended')

lsp.ensure_installed({
    'lua_ls'
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
--
-- Configure language server for neomvim
lsp.nvim_workspace()

lsp.on_attach(function(_, bufnr)
    local opts = { buffer = bufnr, remap = false }
    local bind = vim.keymap.set

    bind("n", "<leader>re", function() vim.lsp.buf.rename() end, opts)
    bind("n", "<F2>", function() vim.lsp.buf.rename() end, opts)
    bind("n", "<leader>ca", function() vim.lsp.buf.code_action() end, opts)
    bind("n", "<leader>U", require('telescope.builtin').lsp_references, {})
    bind("n", "<leader>gi", function() vim.lsp.buf.implementation() end, opts)
    bind("n", "<leader>ge", function() vim.diagnostic.goto_next() end, opts)
    bind("n", "<leader>gE", function() vim.diagnostic.goto_prev() end, opts)
    bind("n", "<leader><leader>", function() vim.lsp.buf.format { async = true } end, opts)
end)

lsp.setup()

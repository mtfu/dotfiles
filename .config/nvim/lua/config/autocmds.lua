
-- Highlight on yank
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.hl.on_yank({ higroup = 'Visual', timeout = 100 })
  end,
})

-- WSL clipboard via clip.exe
if vim.fn.has('wsl') == 1 then
  vim.api.nvim_create_autocmd('TextYankPost', {
    callback = function()
      vim.fn.system('/mnt/c/windows/system32/clip.exe', vim.fn.getreg('"'))
    end,
  })
end

-- Close quickfix / location list with q
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'qf',
  callback = function(args)
    vim.keymap.set('n', 'q', '<cmd>close<CR>', { buffer = args.buf, silent = true })
  end,
})

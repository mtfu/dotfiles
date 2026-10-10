
-- Highlight on yank
vim.api.nvim_create_autocmd('TextYankPost', {
  callback = function()
    vim.hl.on_yank({ higroup = 'Visual', timeout = 100 })
  end,
})

-- Pick up edits made outside nvim (Copilot CLI, git, etc.)
vim.o.autoread = true
vim.api.nvim_create_autocmd({ 'FocusGained', 'BufEnter', 'CursorHold', 'TermLeave' }, {
  callback = function()
    if vim.fn.mode() ~= 'c' and vim.bo.buftype == '' then
      vim.cmd('checktime')
    end
  end,
})
vim.api.nvim_create_autocmd('FileChangedShellPost', {
  callback = function()
    vim.notify('Buffer reloaded from disk', vim.log.levels.INFO)
    pcall(function()
      require('gitsigns').refresh()
    end)
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

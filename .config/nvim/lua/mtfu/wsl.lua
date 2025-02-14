vim.opt.clipboard:prepend { 'unnamed', 'unnamedplus' }

vim.cmd [[
  augroup Yank
  autocmd!
  autocmd TextYankPost * :call system('/mnt/c/windows/system32/clip.exe ',@")
  augroup END
]]

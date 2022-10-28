local status, telescope = pcall(require, "telescope")
if (not status) then return end
local builtin = require('telescope.builtin')
telescope.setup {
  pickers = {
    find_files = {
      find_command = {
        'fd',
        '--type',
        'f',
        '--color=never',
        '--hidden',
        '--follow',
        '-E',
        '.git/*'
      },
    },
  },
  defaults = {
    file_ignore_patterns = {
      "node_modules", "yarn.lock"
    }
  }
}
vim.keymap.set('n', '<c-p>', builtin.find_files, {})
vim.keymap.set('n', '<leader>hh', builtin.oldfiles, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})

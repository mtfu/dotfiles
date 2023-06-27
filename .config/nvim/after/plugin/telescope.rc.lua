local status, telescope = pcall(require, "telescope")
if (not status) then return end
local builtin = require('telescope.builtin')
local actions = require('telescope.actions')

telescope.setup {
  defaults = {
    mappings = {
      i = {
        ["<C-j>"] = actions.move_selection_next,
        ["<C-k>"] = actions.move_selection_previous,
      }
    },
    file_ignore_patterns = {
      "node_modules", "yarn.lock"
    }
  },
  pickers = {
    live_grep = {
        additional_args = function (_)
            return {"--hidden"}
        end
    },
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
}
vim.keymap.set('n', '<c-p>', builtin.find_files, {})
vim.keymap.set('n', '<leader>hh', builtin.oldfiles, {})
vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
vim.keymap.set('n', '<leader>ff', builtin.grep_string, {})
vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
vim.keymap.set('n', '<leader>u', builtin.lsp_references, {})

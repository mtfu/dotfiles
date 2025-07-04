local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable",
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)


require("lazy").setup({
    'tpope/vim-surround',
    'tpope/vim-commentary',
    'tpope/vim-repeat',
    'vim-scripts/ReplaceWithRegister',
    {
        'nvim-lualine/lualine.nvim',
        config = function()
            require("lualine").setup()
        end
    },
    {
        'nvim-telescope/telescope.nvim',
        tag = '0.1.5',
        dependencies = { 'nvim-lua/plenary.nvim', { "kdheepak/lazygit.nvim" } },
        config = function()
            require("telescope").load_extension("lazygit")
        end,
    },
    {
        'windwp/nvim-autopairs',
        event = "InsertEnter",
        config = true
    },
    {
        'windwp/nvim-ts-autotag',
        config = function()
            require('nvim-ts-autotag')
        end
    },
    {
        'lewis6991/gitsigns.nvim',
        config = function()
            require('gitsigns').setup()
        end
    },
    'sainnhe/gruvbox-material',
    'nanotee/zoxide.vim',
    {
        'ThePrimeagen/harpoon',
        branch = "harpoon2",
        dependencies = {
            {
                'nvim-lua/plenary.nvim'
            }
        }
    },
    'mbbill/undotree',
    {
        'nvim-tree/nvim-tree.lua',
        branch = 'master',
        dependencies = { 'nvim-tree/nvim-web-devicons' },
    },
    'VonHeikemen/lsp-zero.nvim',
    branch = 'v1.x',
    'nvim-treesitter/nvim-treesitter',
    {
        'VonHeikemen/lsp-zero.nvim',
        branch = 'v1.x',
        dependencies = {
            -- LSP Support
            { 'neovim/nvim-lspconfig' },             -- Required
            { 'williamboman/mason.nvim' },           -- Optional
            { 'williamboman/mason-lspconfig.nvim' }, -- Optional

            -- Autocompletion
            { 'hrsh7th/nvim-cmp' },         -- Required
            { 'hrsh7th/cmp-nvim-lsp' },     -- Required
            { 'hrsh7th/cmp-buffer' },       -- Optional
            { 'hrsh7th/cmp-path' },         -- Optional
            { 'saadparwaiz1/cmp_luasnip' }, -- Optional
            { 'hrsh7th/cmp-nvim-lua' },     -- Optional

            -- Snippets
            { 'L3MON4D3/LuaSnip' },             -- Required
            { 'rafamadriz/friendly-snippets' }, -- Optional
        }
    },
    -- Make 
    'nvim-treesitter/nvim-treesitter-context',
 {
    'akinsho/toggleterm.nvim',
    version = '*', -- Use the latest stable version
    config = function()
      require("toggleterm").setup{
        size = 20,                    -- Terminal size (height for horizontal, width for vertical)
        open_mapping = [[<C-\>]],      -- Keybinding to toggle the terminal (Ctrl + \)
        hide_numbers = true,          -- Hide the number column in toggleterm buffers
        shade_filetypes = {},
        shade_terminals = true,       -- Shade terminal to distinguish from other windows
        shading_factor = '1',         -- Shading intensity (1-3)
        start_in_insert = true,       -- Start in insert mode
        insert_mappings = true,       -- Enable key mappings in insert mode
        persist_size = true,          -- Persist terminal size across toggles
        direction = 'float',          -- 'float' | 'vertical' | 'horizontal' | 'tab'
        close_on_exit = true,         -- Close terminal window when process exits
        shell = 'pwsh.exe',           -- Use PowerShell Core
      }

      -- Optional: Set a keybinding to toggle the terminal (redundant if open_mapping is set)
      -- vim.api.nvim_set_keymap("n", "<C-\\>", "<cmd>ToggleTerm<CR>", {noremap = true, silent = true})
    end
  },
},
{
    -- This runs after all plugins are loaded
    config = function()
        vim.api.nvim_create_autocmd('LspAttach', {
            callback = function(args)
                vim.defer_fn(function()
                    pcall(vim.keymap.del, 'n', 'grn', { buffer = args.buf })
                    pcall(vim.keymap.del, 'n', 'gra', { buffer = args.buf })
                    pcall(vim.keymap.del, 'n', 'grr', { buffer = args.buf })
                    pcall(vim.keymap.del, 'n', 'gri', { buffer = args.buf })
                    pcall(vim.keymap.del, 'n', 'grt', { buffer = args.buf })
                    pcall(vim.keymap.del, 'v', 'gra', { buffer = args.buf })
                end, 100)
            end,
        })
    end
}
)

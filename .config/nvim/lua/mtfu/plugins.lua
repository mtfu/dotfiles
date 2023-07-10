local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
    vim.fn.system({
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/folke/lazy.nvim.git",
        "--branch=stable", -- latest stable release
        lazypath,
    })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
    'tpope/vim-fugitive',
    'tpope/vim-surround',
    'tpope/vim-commentary',
    'tpope/vim-repeat',
    'tommcdo/vim-exchange',
    'vim-scripts/ReplaceWithRegister',
    'nvim-lualine/lualine.nvim',
    {
        'nvim-telescope/telescope.nvim',
        tag = '0.1.1',
        dependencies = { 'nvim-lua/plenary.nvim', { "kdheepak/lazygit.nvim" } },
        config = function()
            require("telescope").load_extension("lazygit")
        end,
    },
    'windwp/nvim-autopairs',
    'windwp/nvim-ts-autotag',
    {
        'lewis6991/gitsigns.nvim',
        config = function()
            require('gitsigns').setup()
        end
    },
    'dstein64/vim-startuptime',
    'sainnhe/gruvbox-material',
    'nanotee/zoxide.vim',
    {
        'ThePrimeagen/harpoon',
        branch = 'master',
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
    {
        "iamcco/markdown-preview.nvim",
        config = function()
            vim.fn["mkdp#util#install"]()
        end,
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
    -- Make methods stay pinned to the top
    'nvim-treesitter/nvim-treesitter-context',
    'mg979/vim-visual-multi'
})

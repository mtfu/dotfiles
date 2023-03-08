"BASE SETTINGS -------------------------------------------------------------------------

"Use vim settings instead of vi, do not move this line
set nocompatible
let mapleader=" "
set clipboard^=unnamed,unnamedplus

set number relativenumber
set hidden
set autoindent
set smartindent
set ignorecase
set smartcase
set nohlsearch
set incsearch                   
set noerrorbells               
set visualbell
set history=100         
set tabstop=4 
set softtabstop=4       
set scrolloff=10
set shiftwidth=2
set smartindent
set nowrap
set noswapfile

set fileformat=unix
set fileencoding=utf-8
set encoding=utf-8
scriptencoding utf-8
set title
set showcmd
set cmdheight=1
set laststatus=2
set expandtab
set backupskip=/tmp/*,/private/tmp/*
set smarttab
set breakindent
set backspace=indent,eol,start

set termguicolors
set cursorline
set winblend=0
set wildoptions=pum
set pumblend=5
set background=dark
set inccommand=split

let &shell = executable('pwsh') ? 'pwsh' : 'powershell'
let &shellcmdflag = '-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;'
let &shellredir = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'
let &shellpipe = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'
set shellquote= shellxquote=
"
"Autotically insert the current comment leader after hitting <Enter> in Insert Mode.
set formatoptions-=r

"Do not move signs (icons in the left)
set signcolumn=yes

"Find files, Search down into subfolders with :find <fileName>
set path+=** 
set wildignore+=*/node_modules/*
let g:clipboard = {
  \   'name': 'win32yank-wsl',
  \   'copy': {
  \      '+': 'win32yank.exe -i --crlf',
  \      '*': 'win32yank.exe -i --crlf',
  \    },
  \   'paste': {
  \      '+': 'win32yank.exe -o --lf',
  \      '*': 'win32yank.exe -o --lf',
  \   },
  \   'cache_enabled': 0,
  \ }

"Use persistent history. (U)
if !isdirectory("/tmp/.vim-undo-dir")
    call mkdir("/tmp/.vim-undo-dir", "", 0700)
endif
set undodir=/tmp/.vim-undo-dir
set undofile


"MAPS -------------------------------------------------------------------------
"Make tab not drop selectin
vnoremap < <gv
vnoremap > >gv

"Move lines down and up
nnoremap <s-m-j> :m .+1<CR>==
nnoremap <s-m-k> :m .-2<CR>==
inoremap <s-m-j> <Esc>:m .+1<CR>==gi
inoremap <s-m-k> <Esc>:m .-2<CR>==gi
vnoremap <s-m-j> :m '>+1<CR>gv=gv
vnoremap <s-m-k> :m '<-2<CR>gv=gv

"Use repgrip search for files with FZF.vim
set grepprg=rg 

nnoremap x "_x
nnoremap dw vb"_d

"New Tab
nnoremap <silent> te :tabedit<Return>

"Split Window
nnoremap <silent> ss :split<Return><C-w>w
nnoremap <silent> sv :vsplit<Return><C-w>w

"Move Window
nnoremap <leader> <C-w>w
noremap sh <C-w>h
noremap sk <C-w>k
noremap sj <C-w>j
noremap sl <C-w>l

"Resize Window
map <leader><left> <c-w><
map <leader><right> <c-w>>
map <leader><up> <c-w>+
map <leader><down> <c-w>-

"Commands
nmap <silent> <leader>cd :cd %:p:h<cr>:pwd<cr>

call plug#begin()
  Plug 'easymotion/vim-easymotion'
  Plug 'preservim/nerdtree'
  Plug 'tpope/vim-surround'
  Plug 'terryma/vim-multiple-cursors'
  Plug 'tpope/vim-commentary'
  Plug 'vim-scripts/ReplaceWithRegister'
  Plug 'tommcdo/vim-exchange'
  Plug 'ryanoasis/vim-devicons'
 
"Neovim setup only
  Plug 'nvim-lua/plenary.nvim'
  Plug 'tpope/vim-fugitive'
  Plug 'nvim-lualine/lualine.nvim'
  Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.0' }
  Plug 'windwp/nvim-autopairs'
  Plug 'windwp/nvim-ts-autotag'
  Plug 'kdheepak/lazygit.nvim'
  Plug 'unblevable/quick-scope'
  Plug 'gruvbox-community/gruvbox'		
 
":Z {query}: cd to the highest ranked directory matching your query. If {query} is omitted, cd to the home directory
":Lz {query}: same as :Z, but local to the current window
":Tz {query}: same as :Z, but local to the current tab
":Zi {query}: cd to one of your highest ranking directories using fzf
":Lzi {query}: same as :Zi, but local to the current window
":Tzi {query}: same as :Zi, but local to the current tab
  Plug 'nanotee/zoxide.vim'
  Plug 'mbbill/undotree'

"LSP Support with help of lsp-zero.nvim
  Plug 'neovim/nvim-lspconfig'             " Required
  Plug 'williamboman/mason.nvim'           " Optional
  Plug 'williamboman/mason-lspconfig.nvim' " Optional

"Autocompletion Engine
  Plug 'hrsh7th/nvim-cmp'         " Required
  Plug 'hrsh7th/cmp-nvim-lsp'     " Required
  Plug 'hrsh7th/cmp-buffer'       " Optional
  Plug 'hrsh7th/cmp-path'         " Optional
  Plug 'saadparwaiz1/cmp_luasnip' " Optional
  Plug 'hrsh7th/cmp-nvim-lua'     " Optional

"Snippets
  Plug 'L3MON4D3/LuaSnip'             " Required
  Plug 'rafamadriz/friendly-snippets' " Optional

  Plug 'VonHeikemen/lsp-zero.nvim', {'branch': 'v1.x'} 
  Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
call plug#end()

"Plugin Settings 
colorscheme gruvbox

"Quick scope
let g:qs_highlight_on_keys = ['f', 'F', 't', 'T']

"Lazy-git
nnoremap <silent> <leader>gg :LazyGit<CR>

"vim-fugitive
nnoremap <silent> <leader>gs :Git<CR>

"UndoTree
nnoremap <F5> :UndotreeToggle<CR>

"Nerdtree
nnoremap <S-M-l> :NERDTreeFind<CR>
let NERDTreeShowHidden=1
let g:NERDTreeMapOpenVSplit='v'
let g:NERDTreeMapOpenSplit='h'
let NERDTreeCustomOpenArgs = {'file':{'keepopen': 0}}


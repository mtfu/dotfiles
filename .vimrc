" BASE SETTINGS -------------------------------------------------------------------------

"Use vim settings instead of vi, do not move this line
set nocompatible
let mapleader=" "
let $LANG='en'
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
" Is used by bufferline (Neovim plugin)
set termguicolors
set cursorline
set winblend=0
set wildoptions=pum
set pumblend=5
set background=dark

set inccommand=split

" Autotically insert the current comment leader after hitting <Enter> in Insert Mode.
set formatoptions-=r

" Find files, Search down into subfolders with :find <fileName>
set path+=** 
set wildignore+=*/node_modules/*

"Set powershell as shell
if has("win32")
  let &shell = executable('pwsh') ? 'pwsh' : 'powershell'
  let &shellcmdflag = '-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;'
  let &shellredir = '-RedirectStandardOutput %s -NoNewWindow -Wait'
  let &shellpipe = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'
  set shellquote= shellxquote=
endif

" Use persistent history. (U)
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

"System clipboard
vnoremap <C-c> "+y
map <C-v> "+P

nnoremap <A-a> <C-a>
nnoremap <A-x> <C-x>

nnoremap x "_x
nnoremap dw vb"_d

nnoremap <C-a> gg<S-v>G

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

call plug#begin()
Plug 'easymotion/vim-easymotion'
  Plug 'preservim/nerdtree'
  Plug 'tpope/vim-surround'
  Plug 'terryma/vim-multiple-cursors'
  Plug 'tpope/vim-commentary'
  Plug 'vim-scripts/ReplaceWithRegister'
  Plug 'tommcdo/vim-exchange'
  Plug 'gruvbox-community/gruvbox'		
  Plug 'machakann/vim-highlightedyank'
" Neovim setup only
  Plug 'tpope/vim-fugitive'
  Plug 'nvim-lualine/lualine.nvim'
  Plug 'onsails/lspkind-nvim'
  Plug 'hrsh7th/cmp-nvim-lsp'
  Plug 'hrsh7th/cmp-buffer'
  Plug 'hrsh7th/nvim-cmp'
  Plug 'neovim/nvim-lspconfig'
  Plug 'jose-elias-alvarez/null-ls.nvim'
  Plug 'MunifTanjim/prettier.nvim'
  Plug 'williamboman/mason.nvim'
  Plug 'williamboman/mason-lspconfig.nvim'
  Plug 'glepnir/lspsaga.nvim', { 'branch': 'main' }
  Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
  Plug 'kyazdani42/nvim-web-devicons'
  Plug 'nvim-telescope/telescope.nvim', { 'tag': '0.1.0' }
  Plug 'nvim-lua/plenary.nvim'
  Plug 'windwp/nvim-autopairs'
  Plug 'windwp/nvim-ts-autotag'
  Plug 'norcalli/nvim-colorizer.lua'
  Plug 'akinsho/nvim-bufferline.lua'
  Plug 'lewis6991/gitsigns.nvim'
  Plug 'dinhhuy258/git.nvim'
  Plug 'folke/zen-mode.nvim'
call plug#end()


"PLUGIN SETTINGS -------------------------------------------------------------------------
colorscheme gruvbox

let g:argtextobj_pairs="[:],(:),<:>"

"Fzf
noremap <silent> <C-p> :Files<CR>
nnoremap <silent> <Leader>b :Buffers<CR>
nnoremap <silent> <Leader>f :Rg<CR>
nnoremap <silent> <Leader>/ :BLines<CR>
nnoremap <silent> <Leader>' :Marks<CR>
nnoremap <silent> <Leader>g :Commits<CR>
nnoremap <silent> <Leader>H :Helptags<CR>
nnoremap <silent> <Leader>hh :History<CR>
nnoremap <silent> <Leader>h: :History:<CR>
nnoremap <silent> <Leader>h/ :History/<CR>

let g:fzf_preview_window = []

let NERDTreeShowHidden=1
nnoremap <S-M-l> :NERDTreeFind<CR>
let g:NERDTreeMapOpenVSplit='v'
let g:NERDTreeMapOpenSplit='h'

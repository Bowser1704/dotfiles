" basic settings
let mapleader = "," " map leader to comma

syntax on                   " syntax highlighting.
set showmatch               " show matching brackets.
set autowrite
set number
set relativenumber
set ignorecase              " case insensitive matching.
set smartcase               " but don't ignore it, when search string contains uppercase letters
set hlsearch                " highlight search results.
set tabstop=4               " number of columns occupied by a tab character
set softtabstop=4           " see multiple spaces as tabstops so <BS> the right thing
set expandtab               " converts tabs to white space
set smarttab
set shiftwidth=4            " width for autoindents
set autoindent              " indent a new line the same amount as the line just typed
set mouse=v                 " middle-click paste with mouse
set cc=160                  " set an 120 column border for good coding style
set clipboard+=unnamedplus  " copy/paste with middle-click
set ai                      " auto indent
set si                      " smart indent
set wrap                    " wrap lines
set showcmd
set guioptions+=a
set updatetime=100          "async updatetime
set nofoldenable

let g:indentLine_enabled = 1
let g:indentLine_faster = 1
let g:indentLine_char = '⦙'
let g:python3_host_prog="~/.pyenv/shims/python3"
let g:python_host_prog="~/.pyenv/shims/python3"
let g:python2_host_prog="~/.pyenv/shims/python"

" blamer
let g:blamer_enabled = 1
let g:blamer_delay = 500

" vim plug
" let g:plug_window = "FloatermNew"

" Disable quote concealing in JSON files
let g:vim_json_conceal=0

" Remove unuse space
let g:enable_lessmess_onsave = 1

" vim airline
let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1

" lua require("telescope").setup()
" Using Lua functions
nnoremap <leader>ff <cmd>lua require('telescope.builtin').find_files()<cr>
nnoremap <leader>fg <cmd>lua require('telescope.builtin').live_grep()<cr>
nnoremap <leader>fb <cmd>lua require('telescope.builtin').buffers()<cr>
nnoremap <leader>fh <cmd>lua require('telescope.builtin').help_tags()<cr>

" vim-oscyank
" vnoremap y :OSCYank<CR>

" map
cmap w!! w !sudo tee > /dev/null %
map <leader>h :noh<CR>
map <leader>n :tabnew<CR>
map <leader>d :SignifyHunkDiff<CR>
map <a-d> :SignifyDiff<CR>
nnoremap <C-h> :tabprevious<CR>
nnoremap <C-l> :tabnext<CR>
nnoremap <C-j> :bprev<CR>
nnoremap <C-k> :bnext<CR>

" vim-bbye to keep layout when close buffer.
nnoremap <Leader>q :Bdelete<CR>
nnoremap <Leader>c :close<CR>
nnoremap <Leader>qa :%bd\|e#<CR>

nnoremap <Leader>w :w<CR>
nnoremap <leader>sv :source $MYVIMRC<CR>
nnoremap <leader>e :NvimTreeToggle<CR>
nnoremap <silent> <a-o> :FloatermToggle<CR>
tnoremap <silent> <a-o> <c-\><c-n>:FloatermToggle<CR>
tnoremap <c-b> <c-\><c-n>

" InsertMode: move
" inoremap <silent> <C-k> <Up>
" inoremap <silent> <C-j> <Down>
" inoremap <silent> <C-h> <Left>
" inoremap <silent> <C-l> <Right>
" inoremap <silent> <C-b> <Home>
" inoremap <silent> <C-e> <End>


call plug#begin()

Plug 'flazz/vim-colorschemes'
Plug 'sainnhe/sonokai'
Plug 'NLKNguyen/papercolor-theme'

Plug 'Yggdroot/indentLine'

Plug 'voldikss/vim-floaterm'

Plug 'mboughaba/vim-lessmess'

Plug 'moll/vim-bbye'

Plug 'mg979/vim-visual-multi'

Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

Plug 'Xuyuanp/scrollbar.nvim'

Plug 'nvim-lua/plenary.nvim'
Plug 'nvim-telescope/telescope.nvim'

" lsp config
Plug 'neovim/nvim-lspconfig'
Plug 'williamboman/nvim-lsp-installer'
Plug 'hrsh7th/nvim-cmp'
Plug 'hrsh7th/cmp-nvim-lsp'
Plug 'hrsh7th/cmp-buffer'
Plug 'hrsh7th/cmp-path'
Plug 'hrsh7th/cmp-cmdline'
" For vsnip users.
Plug 'hrsh7th/cmp-vsnip'
Plug 'hrsh7th/vim-vsnip'

Plug 'folke/lua-dev.nvim'

Plug 'onsails/lspkind-nvim'
Plug 'glepnir/lspsaga.nvim'

Plug 'kyazdani42/nvim-tree.lua'
Plug 'kyazdani42/nvim-web-devicons'

Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

Plug 'APZelos/blamer.nvim'

Plug 'windwp/nvim-autopairs'

Plug 'towolf/vim-helm'

Plug 'lewis6991/gitsigns.nvim'

Plug 'pedrohdz/vim-yaml-folds'

Plug 'mhinz/vim-signify'
Plug 'mhinz/vim-startify'

Plug 'nvim-telescope/telescope-ui-select.nvim'

Plug 'tomtom/tcomment_vim'
Plug 'lukas-reineke/indent-blankline.nvim'

Plug 'ojroques/vim-oscyank', {'branch': 'main'}
Plug 'roxma/vim-tmux-clipboard'

call plug#end()

lua require('lsp/setup')
lua require('lsp/nvim-cmp')
lua require('lsp/ui')
lua require('plugins/nvim-tree')
lua require('plugins/autopairs')
lua require('plugins/gitsigns')
lua require('plugins/nvim-treesitter')
lua require('plugins/telescope-ui')
lua require('plugins/indent-blankline')
lua require('autocmd')


" Important!!
if has('termguicolors')
  set termguicolors
endif
" The configuration options should before colorscheme sonokai
let g:sonokai_style = 'atlantis'
let g:sonokai_better_performance = 1
let g:sonokai_enable_italic = 1
let g:sonokai_diagnostic_text_highlight = 1
let g:sonokai_diagnostic_line_highlight = 1
let g:sonokai_disable_terminal_colors = 1
colorscheme sonokai
let g:airline_theme = 'sonokai'

" search for visually selected text
" copy from https://vim.fandom.com/wiki/Search_for_visually_selected_text
" Search for selected text, forwards or backwards.
vnoremap <silent> * :<C-U>
  \let old_reg=getreg('"')<Bar>let old_regtype=getregtype('"')<CR>
  \gvy/<C-R>=&ic?'\c':'\C'<CR><C-R><C-R>=substitute(
  \escape(@", '/\.*$^~['), '\_s\+', '\\_s\\+', 'g')<CR><CR>
  \gVzv:call setreg('"', old_reg, old_regtype)<CR>
vnoremap <silent> # :<C-U>
  \let old_reg=getreg('"')<Bar>let old_regtype=getregtype('"')<CR>
  \gvy?<C-R>=&ic?'\c':'\C'<CR><C-R><C-R>=substitute(
  \escape(@", '?\.*$^~['), '\_s\+', '\\_s\\+', 'g')<CR><CR>
  \gVzv:call setreg('"', old_reg, old_regtype)<CR>

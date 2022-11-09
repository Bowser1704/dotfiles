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
set smartindent             " smart indent
set mouse=v                 " middle-click paste with mouse
set cc=160                  " set an 120 column border for good coding style
set clipboard+=unnamedplus  " copy/paste with middle-click
set wrap                    " wrap lines
set cursorline
set cursorlineopt=number
set showcmd
set guioptions+=a
set updatetime=100          "async updatetime
set foldlevel=20

" for ilatic font
set t_ZH=^[[3m
set t_ZR=^[[23

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
let g:enable_lessmess_onsave = 0

" vim airline
let g:airline#extensions#tabline#enabled = 1
let g:airline_powerline_fonts = 1

" OSCYank
let g:oscyank_term = 'default'
augroup _oscyank
  autocmd!
  autocmd TextYankPost * if v:event.operator is 'y' && v:event.regname is '' | execute 'OSCYankReg "' | endif
augroup end

" vim-signify
let g:signify_priority = 5

augroup _general_settings
  autocmd!
  autocmd FileType qf,help,man,lspinfo nnoremap <silent> <buffer> q :close<CR>
  autocmd TextYankPost * silent!lua require('vim.highlight').on_yank({higroup = 'Visual', timeout = 200})
  autocmd FileType qf set nobuflisted
augroup end

" lua require("telescope").setup()
" Using Lua functions
nnoremap <leader>ff <cmd>lua require('telescope.builtin').find_files()<cr>
nnoremap <leader>fg <cmd>lua require('telescope.builtin').live_grep()<cr>
nnoremap <leader>fb <cmd>lua require('telescope.builtin').buffers()<cr>
nnoremap <leader>fh <cmd>lua require('telescope.builtin').help_tags()<cr>
" nnoremap <leader>e <cmd>Telescope file_browser<cr>

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

nmap <leader>f :Format<CR>
nmap <leader>F :FormatWrite<CR>
augroup FormatAutogroup
  autocmd!
  autocmd BufWritePost * silent! lua vim.lsp.buf.format({async=true})
  autocmd BufWritePost * FormatWrite
augroup END

nnoremap <leader>S <cmd>lua require('spectre').open()<CR>
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

Plug 'Yggdroot/indentLine'
Plug 'lukas-reineke/indent-blankline.nvim'

Plug 'voldikss/vim-floaterm'

Plug 'mboughaba/vim-lessmess'

Plug 'moll/vim-bbye'

Plug 'mg979/vim-visual-multi'

Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

Plug 'nvim-lua/plenary.nvim'

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
Plug 'j-hui/fidget.nvim'

Plug 'kyazdani42/nvim-tree.lua'
Plug 'kyazdani42/nvim-web-devicons'

Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

Plug 'windwp/nvim-autopairs'

Plug 'towolf/vim-helm'

Plug 'pedrohdz/vim-yaml-folds'

" For git
Plug 'APZelos/blamer.nvim'
Plug 'lewis6991/gitsigns.nvim'
Plug 'mhinz/vim-signify'

" startup page
Plug 'mhinz/vim-startify'

Plug 'nvim-telescope/telescope.nvim'
Plug 'nvim-telescope/telescope-ui-select.nvim'
Plug 'nvim-telescope/telescope-file-browser.nvim'

Plug 'tomtom/tcomment_vim'

Plug 'ojroques/vim-oscyank'

Plug 'mhartington/formatter.nvim'

Plug 'windwp/nvim-spectre'

Plug 'airblade/vim-rooter'
Plug 'buoto/gotests-vim'

Plug 'lvimuser/lsp-inlayhints.nvim'

Plug 'simrat39/rust-tools.nvim'
Plug 'mfussenegger/nvim-dap'
Plug 'leoluz/nvim-dap-go'
Plug 'rcarriga/nvim-dap-ui'

Plug 'rafamadriz/friendly-snippets'


call plug#end()

lua require('lsp/setup')
lua require('lsp/nvim-cmp')
lua require('lsp/ui')
lua require('plugins/nvim-tree')
lua require('plugins/autopairs')
lua require('plugins/gitsigns')
lua require('plugins/nvim-treesitter')
lua require('plugins/telescope')
lua require('plugins/indent-blankline')
lua require('plugins/formatter')
lua require('plugins/fidget')

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

autocmd ColorScheme * highlight CursorLineNr cterm=bold term=NONE gui=NONE
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

" Vundle stuff
set nocompatible              " be iMproved, required
filetype off                  " required

" set the runtime path to include Vundle and initialize
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'Chiel92/vim-autoformat'
Plugin 'rhysd/vim-clang-format'
Plugin 'Vimjas/vim-python-pep8-indent'
Plugin 'Yggdroot/indentLine'
Plugin 'chiphogg/vim-prototxt'
Plugin 'davidhalter/jedi-vim'
Plugin 'dense-analysis/ale'
Plugin 'google/vim-searchindex'
Plugin 'junegunn/fzf'
Plugin 'junegunn/fzf.vim'
Plugin 'nathanaelkane/vim-indent-guides'
Plugin 'tpope/vim-commentary'
Plugin 'tpope/vim-fugitive'
Plugin 'tpope/vim-repeat'
Plugin 'tpope/vim-surround'
Plugin 'vim-airline/vim-airline'
Plugin 'vim-airline/vim-airline-themes'
Plugin 'vim-python/python-syntax'
Plugin 'ycm-core/YouCompleteMe'
call vundle#end()            " required

syntax on
filetype plugin indent on
set ts=4 sts=4 sw=4
set expandtab
set autoindent
set smartindent
set copyindent

autocmd FileType yaml setlocal ts=2 sts=2 sw=2
autocmd FileType python setlocal ts=4 sts=4 sw=4
autocmd FileType cpp setlocal ts=4 sts=4 sw=4
autocmd FileType ispc setlocal ts=4 sts=4 sw=4
set visualbell

colorscheme night-owl
set background=dark
highlight Normal ctermbg=233
highlight nonText ctermbg=248
set ruler

" searching
nnoremap <leader><space> :nohlsearch<CR>
set hlsearch
set incsearch
set showmatch
set ignorecase
set smartcase

" Easily find current cursor, line nums, statusline
set number
set relativenumber
set cursorline
hi CursorLine  term=bold cterm=bold ctermbg=235 ctermfg=NONE
highlight LineNr ctermfg=darkgrey
set laststatus=2
set statusline=%<%f\ %h%m%r%=%-14.(%l,%c%V%)\ %P
set rulerformat=%l,%v
set colorcolumn=100

set backspace=indent,eol,start " Enable backspace on MacOS


" ALE Linting
let g:ale_linters = {
\   'python': ['pylint', 'flake8'],
\}

let g:ale_python_pylint_options = "--rcfile=/Users/akashc/.pylintrc --max-line-length=100"
let g:ale_lint_on_save = 1
let g:ale_lint_on_text_changed = 1
let g:airline#extensions#ale#enabled = 1
nmap <silent> <C-j> :ALENext<cr>
nmap <silent> <C-k> :ALEPrevious<cr>

" copy paste between vim buffers
vmap <silent> ,y :w! ~/.vimsharedbuffer/.vimbuffer<CR>
nmap <silent> ,y :.w! ~/.vimsharedbuffer/.vimbuffer<CR>
" paste from buffer
map <silent> ,y :r ~/.vimsharedbuffer/.vimbuffer<CR>

" Python formatting/highlighting
let g:python_pep8_indent_multiline_string = 2
let g:python_highlight_builtins = 1
let g:python_highlight_indent_errors = 1
let g:python_highlight_space_errors = 1
let g:python_highlight_class_vars = 1
let g:python_highlight_operators = 1
let g:python_highlight_string_formatting = 1
let g:python_highlight_string_format = 1
let g:python_highlight_string_templates = 1

let g:airline_theme='bubblegum'
let g:airline_section_c = '%<%f%m %#__accent_red#%{airline#util#wrap(airline#parts#readonly(),0)}%#__restore__#'
let g:airline_section_y = ''  " Disable displaying file encoding
let g:airline_powerline_fonts = 1

" Easy folding of indented text
set foldmethod=indent
nnoremap <space> za
vnoremap <space> zf
" Unfold everything in the file
nnoremap <C-@> zR
set foldlevelstart=99
set foldnestmax=8

" Make whitespace visible; :set nolist to turn off
:set listchars=trail:· list 


" indent guide settings
let g:indentLine_setColors = 1
let g:indentLine_color_term = 93
let g:indentLine_bgcolor_term = 235 " 235
let g:indentLine_char = ' '

" use vim-python-pep8-indent settings instead of default
let g:pymode_indent = 0

let g:python3_host_prog=system("which python3")
" python autoformat


" Plug  plugin manager

call plug#begin('~/.vim/plugged')
Plug 'Julpikar/night-owl.nvim'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
call plug#end()

" Make FZF run with ctrl+P
nmap <C-P> :FZF<CR>

" Ctags
command! MakeTags !ctags -R .

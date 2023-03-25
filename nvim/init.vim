" Spaces & Tabs {{{
set tabstop=4       " number of visual spaces per TAB
set softtabstop=4   " number of spaces in tab when editing
set shiftwidth=4    " number of spaces to use for autoindent
set noexpandtab     " tabs are tabs
set autoindent
set copyindent      " copy indent from the previous line
" }}} Spaces & Tabs

" Plugin manager {{{
call plug#begin()

" Tag surround replacer by <cs>
Plug 'https://github.com/tpope/vim-surround.git'
Plug 'https://github.com/tpope/vim-repeat.git'

call plug#end()
" }}} Plugin Manager

" Using API
source ~/.config/nvim/.nvimrc

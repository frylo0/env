" Spaces & Tabs {{{
set tabstop=3       " number of visual spaces per TAB
set softtabstop=3   " number of spaces in tab when editing
set shiftwidth=3    " number of spaces to use for autoindent
set expandtab       " tabs are space
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

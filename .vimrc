set nocompatible


filetype off
set rtp+=~/.vim/bundle/Vundle.vim
call vundle#begin()
Plugin 'gmarik/Vundle.vim'
Plugin 'bling/vim-airline'
Plugin 'scrooloose/nerdtree'
Plugin 'jistr/vim-nerdtree-tabs'
Plugin 'scrooloose/syntastic'
Plugin 'kien/ctrlp.vim'
Plugin 'airblade/vim-gitgutter'
Plugin 'Raimondi/delimitMate'
Plugin 'pangloss/vim-javascript'
call vundle#end()
filetype plugin indent on


set background=dark
syntax on               " enable syntax
set hidden
set wildmenu
set tabstop=2           " tab length
set softtabstop=2       " soft tabs
set expandtab           " extend tabs
set number              " show line numbers
set showcmd             " show last command
set cursorline 					" show current line
set showmatch           " highlight matching [{()}]
set backspace=indent,eol,start
set autoindent
set nostartofline
set ruler
set mouse=a
set pastetoggle=<F12>   " Paste mode on F12
set incsearch
set hlsearch

imap ii <Esc>

" ----- bling/vim-airline settings -----
" Always show statusbar
set laststatus=2


" ----- bling/vim-airline settings -----
" Always show statusbar
set laststatus=2

" Show PASTE if in paste mode
let g:airline_detect_paste=1

" Show airline for tabs too
let g:airline#extensions#tabline#enabled = 1

" ----- jistr/vim-nerdtree-tabs -----
" Open/close NERDTree Tabs with \t
nmap ² :NERDTreeTabsToggle<CR>
" To have NERDTree always open on startup
let g:nerdtree_tabs_open_on_console_startup = 0



" ----- scrooloose/syntastic settings -----
let g:syntastic_error_symbol = '✘'
let g:syntastic_warning_symbol = "▲"
augroup mySyntastic
  au!
  au FileType tex let b:syntastic_mode = "passive"
augroup END


" ----- airblade/vim-gitgutter settings ----- 
hi clear SignColumn

" ----- Raimondi/delimitMate settings -----
let delimitMate_expand_cr = 1
augroup mydelimitMate
  au!
  au FileType markdown let b:delimitMate_nesting_quotes = ["`"]
  au FileType tex let b:delimitMate_quotes = ""
  au FileType tex let b:delimitMate_matchpairs = "(:),[:],{:},`:'"
  au FileType python let b:delimitMate_nesting_quotes = ['"', "'"]
augroup END

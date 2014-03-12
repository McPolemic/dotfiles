"Load Pathogen
call pathogen#incubate()

"Set color to koehler
colo koehler

syntax on

" ,cd to cd to current working directory
map ,cd :cd %:p:h<CR>

" Set indentation
set softtabstop=4
set tabstop=4
set shiftwidth=4
set expandtab
set smartindent
set backspace=2

set hlsearch
set incsearch

" Change indentation for Ruby
autocmd FileType ruby set tabstop=2|set shiftwidth=2|set softtabstop=2

noremap <Space> <PageDown>

let mapleader=","
set grepprg=ack\ -k

" Ctrl-P Options
set runtimepath^=~/.vim/bundle/ctrlp.vim
set wildignore+=*/tmp/*,*.so,*.swp,*.zip     " MacOSX/Linux
set wildignore+=*\\tmp\\*,*.swp,*.zip,*.exe  " Windows

" Ctrl-P Bindings
let g:ctrlp_map = '<c-p>'
let g:ctrlp_cmd = 'CtrlP'

let g:ctrlp_custom_ignore = {
    \ 'dir':  '\v[\/]\.(git|hg|svn)$',
    \ 'file': '\v\.(exe|so|dll|pyc|class)$',
    \ 'link': 'some_bad_symbolic_links',
    \ }

" Split sanity http://robots.thoughtbot.com/vim-splits-move-faster-and-more-naturally
set splitbelow
set splitright

nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

" Map :W to :w because I'm not perfect
command! W :w

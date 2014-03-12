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

" Custom status line display from http://www.winterdom.com/weblog/2007/06/26/VimStatusLine.aspx
set ls=2 " Always show status line
if has('statusline')
    " Status line detail:
    " %f        file path
    " %y        file type between braces (if defined)
    " %([%R%M]%)    read-only, modified and modifiable flags between braces
    " %{'!'[&ff=='default_file_format']}
    "           shows a '!' if the file format is not the platform
    "           default
    " %{'$'[!&list]}    shows a '*' if in list mode
    " %{'~'[&pm=='']}   shows a '~' if in patchmode
    " (%{synIDattr(synID(line('.'),col('.'),0),'name')})
    "           only for debug : display the current syntax item name
    " %=        right-align following items
    " #%n       buffer number
    " %l/%L,%c%V    line number, total number of lines, and column number
    function SetStatusLineStyle()
    if &stl == '' || &stl =~ 'synID'
        let &stl="%f %y%([%R%M]%)%{'!'[&ff=='".&ff."']}%{'$'[!&list]}%{'~'[&pm=='']}%=#%n %l/%L,%c%V "
    else
        let &stl="%f %y%([%R%M]%)%{'!'[&ff=='".&ff."']}%{'$'[!&list]} (%{synIDattr(synID(line('.'),col('.'),0),'name')})%=#%n %l/%L,%c%V "
    endif
    endfunc
    " Switch between the normal and vim-debug modes in the status line
    nmap _ds :call SetStatusLineStyle()<CR>
    call SetStatusLineStyle()
    " Window title
    if has('title')
    set titlestring=%t%(\ [%R%M]%)
    endif
endif

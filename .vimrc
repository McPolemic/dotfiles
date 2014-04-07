"Load Pathogen
runtime bundle/vim-pathogen/autoload/pathogen.vim
call pathogen#incubate()

"Set color to koehler
colo koehler

" allow backspacing over everything in insert mode
set backspace=indent,eol,start
syntax on

" Enable file type detection.
" Use the default filetype settings, so that mail gets 'tw' set to 72,
" 'cindent' is on in C files, etc.
" Also load indent files, to automatically do language-dependent indenting.
filetype plugin indent on

" Set indentation
"for ruby, autoindent with two spaces, always expand tabs
autocmd FileType ruby,haml,eruby,yaml,html,javascript,sass,cucumber set ai sw=2 sts=2 et
autocmd FileType python set sw=4 sts=4 et

set hlsearch
set incsearch

" Line numbers
set number
" Easy insert string for escape
inoremap jk <esc>

noremap <Space> <PageDown>

let mapleader=","

" ,cd to cd to current working directory
noremap <leader>cd :cd %:p:h<CR>
" Clear search higlighting
noremap <leader><CR> :nohlsearch<CR>

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

"Load Pathogen
runtime bundle/vim-pathogen/autoload/pathogen.vim
call pathogen#infect('bundle/{}')
call pathogen#helptags()

" Add the fzf vim stuff to the runpath
set rtp+=/opt/homebrew/opt/fzf

"Set default colorscheme
colo molokai

"81 column marker to know when we're running over 80 characters
set colorcolumn=81

" allow backspacing over everything in insert mode
set backspace=indent,eol,start
syntax on

" Ruby support for % jumping on module, class, def, do, and end
runtime macros/matchit.vim

" Enable file type detection.
" Use the default filetype settings, so that mail gets 'tw' set to 72,
" 'cindent' is on in C files, etc.
" Also load indent files, to automatically do language-dependent indenting.
filetype plugin indent on

" Set indentation
" Default indentation is two spaces
set ai sw=2 sts=2 et
" Python should use four
autocmd FileType python set sw=4 sts=4 et

set hlsearch
set incsearch
set nowritebackup
set noswapfile
set nobackup

" N lines of context around the cursor
set scrolloff=7
set sidescrolloff=10

" Set up ultisnips
let g:UltiSnipsExpandTrigger="<tab>"

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
" Paste yanked line over current line
noremap <leader>p pkdd
" Switch to alternate file (test/production code)
noremap <leader>. :A<CR>

" Simpler splits
" `-` and `|` represents the bar that will show up, so
" * `-` is a horizontal split
" * `|` is a vertical split
noremap <leader>- :sp<CR>
noremap <leader>\| :vs<CR>

" Simpler key bindings for iPad use
" Write all
noremap <leader>w :wa<CR>
" Quit current buffer
noremap <leader>q :q<CR>

set grepprg=ack\ -k

" Split sanity http://robots.thoughtbot.com/vim-splits-move-faster-and-more-naturally
set splitbelow
set splitright

nnoremap <C-J> <C-W><C-J>
nnoremap <C-K> <C-W><C-K>
nnoremap <C-L> <C-W><C-L>
nnoremap <C-H> <C-W><C-H>

"######### Command Aliases #########
" Map :W to :w because I'm not perfect
command! W :w

" Remap to older vim-fugitive commands because muscle memory
:command! Gblame Git blame
:command! Gcommit Git commit
:command! Gpull Git pull
:command! Gpush Git push

" Make it a bit easier to work with docker compose
command! -nargs=+ Dc !docker compose <args>
command! -nargs=+ Fhdc !docker compose exec web <args>

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
    function! SetStatusLineStyle()
        if &stl == '' || &stl =~ 'synID'
            let &stl="%f %y%([%R%M]%)%{'!'[&ff=='".&ff."']}%{'$'[!&list]}%{'~'[&pm=='']}%=#%n %l/%L,%c%V "
        else
	    let &stl="%f %y%([%R%M]%)%{'!'[&ff=='".&ff."']}%{'$'[!&list]} (%{synIDattr(synID(line('.'),col('.'),0),'name')})%=#%n %l/%L,%c%V "
        endif
    endfunction
    " Switch between the normal and vim-debug modes in the status line
    nmap _ds :call SetStatusLineStyle()<CR>
    call SetStatusLineStyle()
    " Window title
    if has('title')
    set titlestring=%t%(\ [%R%M]%)
    endif
endif

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Highlight Whitespace
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
:highlight ExtraWhitespace ctermbg=darkgreen guibg=darkgreen
:match ExtraWhitespace /\s\+$\| \+\ze\t/

" Run a given vim command on the results of fuzzy selecting from a given shell
" command. See usage below.
function! FuzzyFindCommand(choice_command, fuzzy_finder_args, vim_command)
  let temp_file = tempname()
  try
    execute("silent !" . a:choice_command . " | fzf " . a:fuzzy_finder_args . " > " . temp_file)

    if !v:shell_error
      execute("silent " . a:vim_command . " " . join(readfile(temp_file), ''))
    endif
    redraw!
  finally
    silent! call delete(temp_file)
    redraw!
  endtry
endfunction

" Find all files in all non-dot directories starting in the working directory.
" Fuzzy select one of those. Open the selected file with :e.
nnoremap <leader>f :Files<cr>

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" RUNNING TESTS
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Test file
nnoremap <leader>tf :call RunTestFile()<cr>
nnoremap <leader>t :call RunTestFile()<cr>
" Test individual test
nnoremap <leader>T :call RunNearestTest()<cr>
" Run all tests
nnoremap <leader>a :call RunTests('')<cr>

function! RunTestFile(...)
  if a:0
    let command_suffix = a:1
  else
    let command_suffix = ""
  endif

  " Run the tests for the previously-marked file.
  let in_test_file = match(expand("%"), '\(.feature\|_spec.rb\|_test.rb\|test_.*\.py\|_test.py\|_test.exs\)$') != -1
  if in_test_file
    call SetTestFile(command_suffix)
  elseif !exists("t:current_test_file")
    return
  end
  call RunTests(t:current_test_file)
endfunction

function! RunNearestTest()
  let spec_line_number = line('.')
  call RunTestFile(":" . spec_line_number)
endfunction

function! SetTestFile(command_suffix)
  " Set the spec file that tests will be run for.
  let t:current_test_file=@% . a:command_suffix
endfunction

function! RunTests(filename)
  " Write the file and run tests for the given filename
  if expand("%") != ""
    :w
  end
  if match(a:filename, '\.feature$') != -1
    exec ":!script/features " . a:filename
  else
    " First choice: project-specific test script
    if filereadable("script/test")
      exec ":!script/test " . a:filename
    " If we find a rails binstub, use rails tests
    elseif filereadable("bin/rails")
      exec ":!bin/rails test " . a:filename
    " If we see a spec directory, assume rspec
    elseif filereadable("spec/")
      exec ":!echo bundle exec rspec --color " . a:filename
      exec ":!bundle exec rspec --color " . a:filename
      " If we see elixir-looking tests, assume they're run with mix
    elseif strlen(glob("test/**/*.exs") . glob("tests/**/*.exs"))
      exec "!mix test " . a:filename
      " If we see python-looking tests, assume they should be run with Nose
    elseif strlen(glob("test/**/*.py") . glob("tests/**/*.py"))
      exec "!nosetests " . a:filename
      " Fall back to a normal blocking test run
    else
      exec ":!echo rspec --color " . a:filename
      exec ":!rspec --color " . a:filename
    end
  end
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" UltiSnips
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
let g:UltiSnipsExpandTrigger="<tab>"
let g:UltiSnipsJumpForwardTrigger="<tab>"
let g:UltiSnipsJumpBackwardTrigger="<s-tab>"

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" Miscellaneous Bindings
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

" Set a session for the current directory and be able to reload it
" http://stackoverflow.com/questions/1416572/vi-vim-restore-opened-files
map <leader>2 :mksession! ~/.vim_session<CR>
map <leader>3 :source ~/.vim_session<CR>

" Tab bindings
map <leader>tn :tabnext<CR>
map <leader>tp :tabprev<CR>
map <leader>to :tabnew<CR>
map <leader>tq :tabclose<CR>

" Buffer bindings
map <leader>bn :bnext<CR>
map <leader>bp :bprevious<CR>

" Quickfix bindings
map <leader>cn :cn<CR>
map <leader>cp :cp<CR>

" Enable tags finding the `.tags` file
set tags+=.tags;

"Set a minimum height for splits so you can see what's going on
set winheight=15

" Enable 256 color
set t_Co=256

" MacVim settings
if has("gui_running")
	set guifont=Fira\ Code:h18
endif

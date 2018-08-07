""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
" SWITCH BETWEEN TEST AND PRODUCTION CODE
""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! ft#elixir_test#OpenTestAlternate()
  let new_file = AlternateForCurrentFile()
  exec ':e ' . new_file
endfunction
function! AlternateForCurrentFile()
  let current_file = expand("%")
  let new_file = current_file
  let in_test = match(current_file, '^\(./\)*test/') != -1
  let going_to_spec = !in_test

  if going_to_spec
    let new_file = substitute(new_file, '\.e\?ex$', '_test.exs', '')
    echom new_file
    let new_file = substitute(new_file, '^\(./\)*lib/', 'test/', '')
    echom new_file
  else
    let new_file = substitute(new_file, '_test\.exs$', '.ex', '')
    let new_file = substitute(new_file, '^\(./\)*test/', 'lib/', '')
  endif
  return new_file
endfunction

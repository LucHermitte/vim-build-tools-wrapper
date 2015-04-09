"=============================================================================
" File:         autoload/lh/btw.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://github.com/LucHermitte/vim-build-tools-wrapper>
" Version:      0.4.1
let s:k_version = 041
" Created:      14th Mar 2014
" Last Update:  09th Apr 2015
"------------------------------------------------------------------------
" Description:
"       API & Internals for BuildToolsWrapper
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#btw#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = 0
function! lh#btw#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Verbose(expr)
  if s:verbose
    echomsg a:expr
  endif
endfunction

function! lh#btw#debug(expr)
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1

" Function: lh#btw#compilation_dir() {{{3
function! lh#btw#compilation_dir()
  return lh#option#get('BTW_compilation_dir', '.')
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1
" # Misc Functions:                        {{{2
" s:getSNR([func_name]) {{{3
function! s:getSNR(...)
  if !exists("s:SNR")
    let s:SNR=matchstr(expand('<sfile>'), '<SNR>\d\+_\zegetSNR$')
  endif
  return s:SNR . (a:0>0 ? (a:1) : '')
endfunction

" Function: lh#btw#_evaluate(expr) {{{3
function! lh#btw#_evaluate(expr)
  if type(a:expr) == type({})
    let res = lh#function#execute(a:expr)
  elseif type(a:expr) == type('')
    let res = a:expr
  else
    throw "Unexpected variable type"
  endif
  return res
endfunction

" # Folding functions                      {{{2
" Function: lh#btw#qf_fold_text() {{{3
" Defines foldtext for each fold built from s:qf_folds
" @param[in] s:qf_folds
function! lh#btw#_qf_fold_text() abort
  let test_nr = s:qf_folds[-1][v:foldstart]
  if !has_key(s:qf_folds[test_nr], 'complement') | return | endif
  let t = foldtext().': '
  let l = (4 - len(test_nr))
  let t.= repeat(' ', l). (s:qf_folds[test_nr].name) .'   '
  let t.= s:qf_folds[test_nr].complement
  return t
endfunction


" # CTest hooks                            {{{2
" Function: lh#btw#_register_fix_ctest() {{{3
" When working with CTest, we need to:
" - translate the name of the files in error from "{test-number}: file:line:
"   message"
" and we can fold the messages from each test.
function! lh#btw#_register_fix_ctest() abort
  let hooks = {
        \ 'pre' : {1: s:getSNR('QuickFixCleanFolds')},
        \ 'post': {2: s:getSNR('FixCTestOutput')},
        \ 'open': {9: s:getSNR('QuickFixDefFolds')}
        \ }
  call lh#btw#filters#register_hooks(hooks)
endfunction

" Function: s:QuickFixCleanFolds() {{{3
function! s:QuickFixCleanFolds()
  " echomsg "Clean QF folds"
  let s:qf_folds = {}
endfunction

" Function: s:FixCTestOutput()       {{{3
" Parse CTest output to fix filenames, and extract forlding information
function! s:FixCTestOutput() abort
  try
    " echomsg "parse CTest output"
    let qf_changed = 0
    let qflist = getqflist()
    let s:qf_folds = {-1: {}}
    let line_nr = 1
    let test_nr = -1
    let test_name = ''
    let test_name_lengths = []
    for qf in qflist
      let qft = qf.text
      " echo '===<'.qft.'>==='
      if      qft =~ '^test \d\+\s*$'
        " Test start line
        let test_nr = matchstr(qft, '^test \zs\d\+\ze\s*$')
        " assert(!has_key(qf_folds, test_nr))
        let s:qf_folds[test_nr] = {'begin': line_nr}
        let s:qf_folds[-1][line_nr] = test_nr
      elseif qft =~ '^\s*\d\+/\d\+ Test\s\+#\d\+:'
        " Test end line
        let test_nr = matchstr(qft, '^\s*\d\+/\d\+ Test\s\+#\zs\d\+\ze:')
        let test_success = matchstr(qft,  '^\s*\d\+/\d\+ Test\s\+#\d\+:\s\+'.test_name.' \.\+\s*\zs\S\+')
        let g:qft = qft
        let s:qf_folds[test_nr].end = line_nr
        let s:qf_folds[test_nr].complement = test_success
        let test_nr = -1
        let test_name = ''
      elseif qft =~ '^\s*Start\s\+\d\+: '
        let test_nr = matchstr(qft,  '^\s*Start\s\+\zs\d\+\ze:')
        if !has_key(s:qf_folds, test_nr)
          let s:qf_folds[test_nr] = {'begin': line_nr}
          let s:qf_folds[-1][line_nr] = test_nr
        endif
        let test_name = matchstr(qft, '^\s*Start\s\+'.test_nr.': \zs\S\+\ze\s*$')
        let s:qf_folds[test_nr].name = test_name
        let test_name_lengths += [ len(test_name) ]
      elseif qf.bufnr != 0
        let b_name = bufname(qf.bufnr)
        let update_bufnr = 0
        if b_name =~ '^'.test_nr.': ' " CTest messing with errors
          let b_name = b_name[len(test_nr.': '):]
          let update_bufnr = 1
            " echomsg test_nr .' -> '. b_name
          " else
            " echomsg test_nr .' != '. b_name
        endif
        if b_name =~ '^\S\+\s\+\S\+$' && qf.text =~ '\c.*Assertion.*'
          let b_name = matchstr(b_name, '^\S\+\s\+\zs.*')
          let update_bufnr = 1
        endif
        if update_bufnr
          let msg = qf.bufnr . ' -> '
          let qf.bufnr = lh#buffer#get_nr(b_name)
          let msg.= qf.bufnr . ' ('.b_name.')'
          " echomsg msg
          let qf_changed = 1
        endif
      endif
      let line_nr += 1
    endfor

    " Find the max length of all test names and align them.
    let l = max(test_name_lengths)
    for [t, pos] in items(s:qf_folds)
      if t != -1
        let pos.name .= ' '.repeat('.', 3 + l-len(pos.name))
      endif
    endfor

    if qf_changed
      call setqflist(qflist)
    endif
  catch /.*/
    call lh#common#error_msg("Error: ".v:exception. " throw at: ".v:throwpoint)
  endtry
endfunction

" Function: s:QuickFixDefFolds()     {{{3
" Defines folds for each test
" @param[in] s:qf_folds
function! s:QuickFixDefFolds() abort
  if !exists('s:qf_folds') | return | endif
  for [t, pos] in items(s:qf_folds)
    if t != -1
      " echomsg t.' -> '.string(pos)
      if has_key(pos, 'begin') && has_key(pos, 'end')
        exe (pos.begin).','.(pos.end).'fold'
      else
        echomsg "Missing " .(has_key(pos, 'begin') ? "" : "-start-").(has_key(pos, 'end') ? "" : "-end-")." fold for test #".t
      endif
    endif
  endfor
  setlocal foldtext=lh#btw#_qf_fold_text()
endfunction

" # Quickfix auto import:                  {{{2
" Some variables need to be imported automatically into quickfix buffer
" Variables:                         {{{3
if !exists('s:qf_options_to_import')
  let s:qf_options_to_import = {}
  augroup QFExportVar
    au!
    au BufWipeout * call s:QuickFixRemoveExports(expand('<afile>'))
  augroup END
endif

" Function: s:QuickFixImport()       {{{3
let s:k_unset = {}
function! s:QuickFixImport() abort
    let bid = g:lh#btw#_last_buffer
    let b:last_buffer = bid
    if !has_key(s:qf_options_to_import, bid)
      echomsg "Import: No variable required for buffer ".bid." (".bufname(bid).")"
      return
    endif
    let variables = keys(s:qf_options_to_import[bid])
    call s:Verbose("importing:".string(variables))
    for var in variables
      let value = getbufvar(bid, var, s:k_unset)
      if value != s:k_unset
        exe 'let '.var.' = '.string(value)
      endif
    endfor
endfunction

" Function: s:QuickFixRemoveExports(fname) {{{3
function! s:QuickFixRemoveExports(fname)
  let bid = bufnr(a:fname)
  silent! unlet s:qf_options_to_import[bid]
endfunction

" Augroup: QFImport                  {{{3
call lh#btw#filters#register_hook(1, s:getSNR('QuickFixImport'), 'open')

" Function: lh#btw#qf_add_var_to_import(varname) {{{3
function! lh#btw#qf_add_var_to_import(varname) abort
  let bid = bufnr('%')
  if !has_key(s:qf_options_to_import, bid)
    let s:qf_options_to_import[bid] = {}
  endif

  " Strip b: / &l:
  let varname = substitute(a:varname, '^b:\|^&\zsl:', '', '')
  let s:qf_options_to_import[bid][varname] = 1
endfunction

" Function: lh#btw#qf_remove_var_to_import(varname)  {{{3
function! lh#btw#qf_remove_var_to_import(varname)
  let bid = bufnr('%')
  silent! unlet s:qf_options_to_import[bid][a:varname]
  if empty(s:qf_options_to_import[bid])
    call s:QuickFixRemoveExports(bid)
  endif
endfunction

" Function: lh#btw#qf_clear_import()   {{{3
function! lh#btw#qf_clear_import()
  let s:qf_options_to_import = {}
endfunction

"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

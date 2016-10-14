"=============================================================================
" File:         autoload/lh/btw.vim                               {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://github.com/LucHermitte/vim-build-tools-wrapper>
" Version:      0.7.0
let s:k_version = 070
" Created:      14th Mar 2014
" Last Update:  26th Aug 2016
"------------------------------------------------------------------------
" Description:
"       API & Internals for BuildToolsWrapper
"
" TODO:
" * :cclose + :Copen + :cnewer clears the variables imported in the previous
" run
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
let s:has_qf_properties = has("patch-7.4.2200")
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#btw#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#btw#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Log(expr, ...)
  call call('lh#log#this',[a:expr]+a:000)
endfunction

function! s:Verbose(expr, ...)
  if s:verbose
    call call('s:Log',[a:expr]+a:000)
  endif
endfunction

function! lh#btw#debug(expr) abort
  return eval(a:expr)
endfunction

"------------------------------------------------------------------------
" ## Exported functions {{{1

" Function: lh#btw#compilation_dir([bufid]) {{{3
function! lh#btw#compilation_dir(...)
  return call('lh#btw#option#_compilation_dir', a:000)
endfunction

" Function: lh#btw#build_mode([default]) {{{3
function! lh#btw#build_mode(...) abort
  let default = a:0 == 0 ? '' : a:1
  if lh#btw#option#_has_project_config()
    let project_config = lh#btw#option#_project_config()
    let config = get(project_config, '_', {})
    let mode   = get(get(config, 'compilation', {}), 'mode', default)
    return mode
  else
    " BTW_project_build_mode is deprecated!
    return lh#option#get('BTW_project_build_mode', default)
  endif
endfunction

" Function: lh#btw#project_name([bufid]) {{{3
function! lh#btw#project_name(...) abort
  let bufid = a:0 > 0 ? a:1 : bufnr('%')
  let project_config = lh#btw#option#_project_config(bufid) " use from_buf version to detect undefined
  " 1- Information set in b:project_config._.name ?
  if lh#option#is_set(project_config)
    let config = get(project_config, '_', {})
    let name   = get(config, 'name', '')
    return name
  else
    " 2- Information set in b:BTW_project_name ?
    let name = lh#btw#option#_project_name(bufid)
    if lh#option#is_set(name)          | return name | endif
    " 3- Is this a qf window ?
    if getbufvar(bufid, '&ft') == 'qf' | return lh#btw#project_name(g:lh#btw#_last_buffer) | endif
    " 4- Information available in repo name ?
    "    TODO: we should decode subdirectories
    let url = lh#vcs#get_url(fnamemodify(bufname(bufid), ':p:h'))
    if lh#option#is_set(url) && !empty(url)
      return matchstr(url, '.*/\zs.*')
    endif
    " N- Return default!
    return fnamemodify(bufname(bufid), ':r')
  endif
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
    if lh#ref#is_bound(a:expr)
      return a:expr.resolve()
    else
      let res = lh#function#execute(a:expr)
    endif
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
      call setqflist(qflist, 'r')
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
  let s:qf_saved_options     = []
endif
augroup QFExportVar
  au!
  au BufWipeout * call s:QuickFixRemoveExports(expand('<afile>'))
augroup END

" Function: s:QuickFixImport()       {{{3
function! s:QuickFixImport() abort
  let bhere = bufnr('%')

  let qf = getqflist()
  if empty(qf) | return | endif
  let qf0 = qf[0]
  if qf0.text =~ '^BTW: '
    " The qf list has already been proccessed, we need to import what it
    " contains
    let idx = - qf0.nr
    let data = s:qf_saved_options[idx]
    let bid = data.bid
    let b:last_buffer = bid
    for [var, value] in items(data)
      if var != 'bid' && lh#option#is_set(value)
        call setbufvar(bhere, var, value)
      endif
      silent! unlet value
    endfor
  else
    " If everyting works fine, this branch of coe should not be executed!
    " It could, when not using BTW function to compile.

    " First call to :copen, things haven't been serialized yet
    if !exists('g:lh#btw#_last_buffer') | return | endif
    let bid = g:lh#btw#_last_buffer

    if !has_key(s:qf_options_to_import, bid)
      echomsg "Import: No variable required for buffer ".bid." (".bufname(bid).")"
      return
    endif
    let variables = keys(s:qf_options_to_import[bid])
    call s:Verbose("Importing: ".string(variables))
    for var in variables
      let value = deepcopy(lh#option#getbufvar(bid, var)) " don't want to be updated if the compilation mode changes
      if lh#option#is_set(value)
        call setbufvar(bhere, var, value)
      endif
      silent! unlet value
    endfor
  endif

  let b:last_buffer = g:lh#btw#_last_buffer

  " This has no effect :( Is it because of the aucommand on QF open ?
  let w:quickfix_title = lh#btw#build_mode(). ' compilation of ' . lh#btw#project_name()
endfunction

" Function: s:QuickFixRemoveExports(fname) {{{3
function! s:QuickFixRemoveExports(fname)
  if empty(a:fname) | return | endif
  let bid = bufnr(a:fname)
  call s:Verbose("Removing exported variables for buffer ".bid)
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

" Function: lh#btw#_save_last_buffer_data() {{{3
function! lh#btw#_save_last_buffer_data() abort
  let bid = bufnr('%')
  let g:lh#btw#_last_buffer = bid

  if !has_key(s:qf_options_to_import, bid)
    echomsg "Import: No variable required for buffer ".bid." (".bufname(bid).")"
    return
  endif
  let variables = keys(s:qf_options_to_import[bid])
  call s:Verbose("Saving: ".string(variables))
  let data = { 'bid': bid }
  for var in variables
    let value = deepcopy(lh#option#getbufvar(bid, var)) " don't want to be updated if the compilation mode changes
    if lh#option#is_set(value)
      let data[var] = value
    endif
    silent! unlet value
  endfor

  " check whether the same data already exist => reuse the index
  let idx  = index(s:qf_saved_options, data)
  if idx == -1
    " Otherwise, add the data
    let idx = len(s:qf_saved_options)
    let s:qf_saved_options += [ data ]
  endif

  " Put local data in the quickfix for later uses
  let qf = getqflist()
  let qf0 = { 'bufnr': 0, 'lnum': 0, 'col': 0, 'vcol': 0, 'pattern': '', 'type': '' }
  let qf0.nr = - idx
  let qf0.text = 'BTW: '. lh#btw#build_mode(). ' compilation of ' . lh#btw#project_name()
  call insert(qf, qf0)
  if s:has_qf_properties
    let title = getqflist({'title':1})
  endif
  " This line messes with the current qfwindow title
  " -> force it back with patch 7.4-2200
  call setqflist(qf, 'r')
  if s:has_qf_properties
    call setqflist([], 'r', title)
  endif
endfunction

"}}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

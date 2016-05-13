"=============================================================================
" File:         autoload/lh/btw/job_build.vim                     {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/vim-build-tools-wrapper>
" Version:      0.5.6.
let s:k_version = '056'
" Created:      10th May 2016
" Last Update:  10th May 2016
"------------------------------------------------------------------------
" Description:
"       Background compilation with latest job_start() API
"
"------------------------------------------------------------------------
" History:      «history»
" TODO:         «missing features»
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#btw#job_build#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#btw#job_build#verbose(...)
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

function! lh#btw#job_build#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Globals private variables {{{1
" - s:buffer
" - s:buffer_nr
" - s:job
" - s:cmd

"------------------------------------------------------------------------
" ## Exported functions {{{1
" Function: lh#btw#job_build#execute(cmd) {{{3
function! lh#btw#job_build#execute(cmd) abort
  let s:job = s:init(a:cmd)
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

" # Compilation {{{2
" TODO: hide function name
function! ExitCB(channel, status)
  call s:Verbose("Background compilation with `%1' %2", s:cmd, job_status(a:channel))
  call lh#btw#build#_copen_bg(s:bid)
  redraw
  if bufnr('%') != s:bid
    silent! exe 'bw! '.s:bid
  endif
  " silent call delete(s:buffer) " unless raw is displayed (TODO)
  redraw
endfunction

" Function: s:init(cmd) {{{3
function! s:init(cmd)
  let winid = lh#window#getid()

  let s:cmd = a:cmd
  let cmd_as_name = lh#string#substitute_unless(a:cmd, '\f', '¤')
  " TODO: don't use "/tmp" directly!
  let s:bid = lh#buffer#scratch('/tmp/'.cmd_as_name, 'below')
  " Remove readonly set by #scratch() function
  setlocal noro
  " Resize with BTW_QF_size
  let nl = lh#btw#build#_get_qf_size()
  exe nl.' wincmd _'
  " TODO: copy BTW project variables here
  redraw
  call s:Verbose("Background compilation with `%1' started", a:cmd)
  try
    let s:job = job_start(['sh', '-c', a:cmd],
          \ {
          \   'out_io': 'buffer', 'out_buf': s:bid
          \ , 'err_io': 'buffer', 'err_buf': s:bid
          \ , 'exit_cb': ('ExitCB')
          \ })
  catch /.*/
    " The operation failed. => clear the buffer
    silent bw
    throw v:exception
  endtry
  " Filling qflist is required because of lh#btw#build#_show_error() in caller
  " function
  call setqflist([{'text': "Background compilation with `".string(a:cmd)."' started"}])
  " Return to the window we come from
  call lh#window#gotoid(winid)
  return s:job
endfunction

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

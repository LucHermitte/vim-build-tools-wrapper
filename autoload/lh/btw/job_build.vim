"=============================================================================
" File:         autoload/lh/btw/job_build.vim                     {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/vim-build-tools-wrapper>
" Version:      0.7.0.
let s:k_version = '070'
" Created:      10th May 2016
" Last Update:  11th Aug 2016
"------------------------------------------------------------------------
" Description:
"       Background compilation with latest job_start() API
"
"       This feature requires patch 7.4.1980 (if I'm not mistaken)
"
"------------------------------------------------------------------------
" TODO:
" - Have a airline/BTW compatible statusline for the background compilation
"   qfwindow
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
" - s:job
" - s:cmd
" - g:lh#btw#auto_cbottom

"------------------------------------------------------------------------
" ## API functions {{{1
" Function: lh#btw#job_build#execute(cmd) {{{2
function! lh#btw#job_build#execute(cmd) abort
  if lh#btw#job_build#is_running()
    let choice = CONFIRM("A background compilation is under way. Do you want to\n-> ", ["&Wait for the current compilation to finish", "&Stop the current compilation and start a new one"])
    if choice == 2
      let s:must_replace_comp = a:cmd
      call lh#btw#job_build#_stop()
    endif
    return
  endif
  let s:job = s:init(a:cmd)
endfunction

" Function: lh#btw#job_build#_stop() {{{2
function! lh#btw#job_build#_stop() abort
  if !lh#btw#job_build#is_running()
    throw "No undergoing background compilation."
  endif
  let st = job_stop(s:job)
  if st == 0
    throw "Cannot stop the background compilation"
  endif
endfunction

" Function: lh#btw#job_build#is_running() {{{3
function! lh#btw#job_build#is_running() abort
  return exists('s:job')
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

" # Compilation {{{2
" TODO: hide function name
function! CloseCB(channel) abort
  " call s:Verbose("Background compilation with `%1' %2", s:cmd, job_status(a:channel))
  try
    call s:Verbose("Background compilation with `%1' finished", s:cmd)
    while ch_status(a:channel) == 'buffered'
      call CallbackCB(a:channel, ch_read(a:channel))
    endwhile
    call setqflist([{'text': "Background compilation with `".(s:cmd)."` finished"}], 'a')
  finally
    unlet s:job
  endtry
  if ! exists('s:must_replace_comp')
    call lh#btw#build#_copen_bg_complete()
    redraw
  else
    call lh#btw#job_build#execute(s:must_replace_comp)
    unlet s:must_replace_comp
  endif
endfunction

function! CallbackCB(channel, msg) abort
  caddexpr a:msg
  if exists(':cbottom') && g:lh#btw#auto_cbottom
    let qf = getqflist()
    call assert_true(!empty(qf))
    cbottom
    if qf[-1].valid
      let g:lh#btw#auto_cbottom = 0
    endif
  endif
endfunction

if exists(':cbottom')
  let g:lh#btw#auto_cbottom = 0
  augroup BTW_stop_cbottom
    au!
    au BufEnter * if &ft=='qf' | let g:lh#btw#auto_cbottom = 0 | endif
  augroup END
endif

" Function: s:init(cmd) {{{3
function! s:init(cmd) abort
  let s:cmd = a:cmd
  if exists(':cbottom')
    let g:lh#btw#auto_cbottom = lh#btw#option#_auto_scroll_in_bg()
  endif
  call s:Verbose("Background compilation with `%1' started", a:cmd)
  " Filling qflist is required because of lh#btw#build#_show_error() in caller
  " function
  call setqflist([{'text': "Background compilation with `".(a:cmd)."` started"}])
  let s:job = job_start(['sh', '-c', a:cmd],
        \ {
        \   'close_cb': ('CloseCB')
        \ , 'callback': ('CallbackCB')
        \ })
  return s:job
endfunction

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

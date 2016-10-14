"=============================================================================
" File:         autoload/lh/btw/job_build.vim                     {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/vim-build-tools-wrapper>
" Version:      0.7.0.
let s:k_version = '070'
" Created:      10th May 2016
" Last Update:  12th Oct 2016
"------------------------------------------------------------------------
" Description:
"       Background compilation with latest job_start() API
"
"       This feature requires patch 7.4.1980 (if I'm not mistaken)
"
"------------------------------------------------------------------------
" TODO:
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

let s:has_qf_properties = has("patch-7.4.2200")

"------------------------------------------------------------------------
" ## API functions {{{1
" Function: lh#btw#job_build#execute(cmd) {{{2
function! lh#btw#job_build#execute(cmd) abort
  " if lh#btw#job_build#is_running()
    " let choice = CONFIRM("A background compilation is under way. Do you want to\n-> ", ["&Wait for the current compilation to finish", "&Stop the current compilation and start a new one"])
    " if choice == 2
      " let s:must_replace_comp = a:cmd
      " call lh#btw#job_build#_stop()
    " endif
    " return
  " endif
  call s:init(a:cmd)
  return
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

" # Compilation {{{2
function! s:job_description(job) abort " {{{3
  let what = a:job.project_name . (!empty(a:job.build_mode) ? ' ('.a:job.build_mode.')' : '')
  return what
endfunction

function! s:closeCB(channel, job_info) abort " {{{3
  echomsg string(a:000)
  " call s:Verbose("Background compilation with `%1' %2", s:cmd, job_status(a:channel))
  try
    let stamp = reltime()
    call s:Verbose("Background compilation with `%1' finished", s:cmd)
    while ch_status(a:channel) == 'buffered'
      call s:callbackCB(a:channel, ch_read(a:channel))
    endwhile
    let time = reltimefloat(reltime(s:job.start_time, stamp))
    call setqflist([{'text': "Background compilation with `".(s:cmd)."` finished in ".string(time)."s with exitval ".a:job_info.exitval}], 'a')
  finally
    call s:Verbose('Job finished %1 -- %2', s:job, a:job_info)
    let what = s:job_description(s:job)
    unlet s:job
  endtry
  if ! exists('s:must_replace_comp')
    call lh#btw#build#_copen_bg_complete(what, a:job_info)
    redraw
  else
    call lh#btw#job_build#execute(s:must_replace_comp)
    unlet s:must_replace_comp
  endif
endfunction

function! s:callbackCB(channel, msg) abort " {{{3
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

function! s:start_fail_cb() dict abort " {{{3
  call setqflist([{'text': "Background compilation with `".(self.cmd)."` finished with exitval ".job_info(self.job).exitval}], 'a')
endfunction

function! s:before_start_cb() dict abort " {{{3
  if exists(':cbottom')
    let g:lh#btw#auto_cbottom = lh#btw#option#_auto_scroll_in_bg()
  endif
  call s:Verbose("Background compilation with `%1' started", self.cmd)
  " Filling qflist is required because of lh#btw#build#_show_error() in caller
  " function
  let what = s:job_description(self)
  echomsg "Compilation of ".what." started."
  call setqflist([{'text': "Background compilation with `".(self.cmd)."` started"}])
  call setqflist([], 'r',
        \ {'title': self.build_mode. ' compilation of ' . self.project_name})
  let self.start_time = reltime()
  let s:job = self
endfunction

if exists(':cbottom') " {{{3
  let g:lh#btw#auto_cbottom = 0
  augroup BTW_stop_cbottom
    au!
    au BufEnter * if &ft=='qf' | let g:lh#btw#auto_cbottom = 0 | endif
  augroup END
endif

" Function: s:init(cmd) {{{3
function! s:init(cmd) abort
  let s:cmd = a:cmd
  let mode = lh#btw#build_mode()
  let job =
        \ { 'txt'            : 'Build '.lh#btw#project_name() . (empty(mode) ? '' : ' ('.mode.')')
        \ , 'cmd'            : a:cmd
        \ , 'close_cb'       : function('s:closeCB')
        \ , 'callback'       : function('s:callbackCB')
        \ , 'start_fail_cb'  : function('s:start_fail_cb')
        \ , 'before_start_cb': function('s:before_start_cb')
        \ , 'build_mode'     : mode
        \ , 'project_name'   : lh#btw#project_name()
        \ }
  call lh#async#queue(job)
  " Cannot return anything yet
endfunction

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

"=============================================================================
" File:         autoload/lh/btw/job_build.vim                     {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/vim-build-tools-wrapper>
" Version:      0.7.0.
let s:k_version = '070'
" Created:      10th May 2016
" Last Update:  19th Nov 2020
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
" Function: lh#btw#job_build#execute(cmd, options) {{{2
function! lh#btw#job_build#execute(cmd, options) abort
  call s:init(a:cmd, a:options)
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1

" # Compilation {{{2
function! s:job_description(job) abort " {{{3
  let what = a:job.project_name . (!empty(a:job.build_mode) ? ' ('.a:job.build_mode.')' : '')
  return what
endfunction

function! s:closeCB(channel, job_info) abort " {{{3
  " call s:Verbose("Background compilation with `%1' %2", s:cmd, job_status(a:channel))
  try
    let stamp = reltime()
    call s:Verbose("Background %1 with `%2' finished", s:action, s:cmd)
    while ch_status(a:channel) == 'buffered'
      call s:callbackCB(a:channel, ch_read(a:channel))
    endwhile
    let time = reltimefloat(reltime(s:job.start_time, stamp))
    call setqflist([{'text': "Background ". s:action ." with `".(s:cmd)."` finished in ".string(time)."s with exitval ".a:job_info.exitval}], 'a')
  finally
    call s:Verbose('Job finished %1 -- %2', s:job, a:job_info)
    let what = s:job_description(s:job)
    unlet s:job
  endtry
  if ! exists('s:must_replace_comp')
    call lh#btw#build#_copen_bg_complete(what, a:job_info)
    redraw
  else
    " ??? How could it be used? s:must_replace_comp is never set...
    call lh#btw#job_build#execute(s:must_replace_comp)
    unlet s:must_replace_comp
  endif
endfunction

function! s:callbackCB(channel, msg) abort " {{{3
  " In case msg has been coloured by gcc/clag options like
  " -fdiagnostics-color=always, we need to clear the Ainsi Escape codes around
  "  filenames.
  " The processing of the escape sequences is left to plugins like AnsiEsc for
  " instance.
  " TODO: to support formats other than "f:(l:(c:))", may be we should alter
  " &efm around "%f"...
  let msg = substitute(a:msg, "^\e\[\\d\\+m\\%(\e\[K\\)\\(\\S\\+:\\)\e\[m\\%(\e\[K\\)\\ze\\%($\\|\\s\\)", '\1', '')
  let g:lh#btw#job_build#qf_need_colours = get(g:, 'lh#btw#job_build#qf_need_colours', 0) || (msg != a:msg)

  " Fix CMake/CTest message on-the-fly
  for hook in get(s:job, 'otf_hooks', [])
    let msg = hook.parse(msg)
  endfor
  " And process the error message with Vim through
  if lh#has#setqflist_lines()
    " The "new" method isn't compatible with QuickFixCmd* Events
    " Seems fine and better this way:
    " - more efficient
    " - don't messes qf-window
    call setqflist([], 'a', {'lines': [msg]})
  else
    " Since a few versions, caddexpr messes qfwindow
    " Fortunately, we can now use setqflist("items") oo'
    caddexpr msg
  endif
  if exists(':cbottom') && g:lh#btw#auto_cbottom
    let qf = getqflist()
    call assert_true(!empty(qf))
    cbottom
    if qf[-1].valid
      call s:Verbose("Error found auto_cbottom disabled (%1)", qf[-1])
      let g:lh#btw#auto_cbottom = 0
    endif
  endif
endfunction

function! s:start_fail_cb() dict abort " {{{3
  call setqflist([{'text': "Background ". self.action ." with `".(self.cmd)."` finished with exitval ".job_info(self.job).exitval}], 'a')
endfunction

function! s:before_start_cb() dict abort " {{{3
  call s:Verbose("Background %1 with `%2' started", self.action, self.cmd)
  if exists(':cbottom')
    let g:lh#btw#auto_cbottom = lh#btw#option#_auto_scroll_in_bg()
    call s:Verbose("Reset auto_cbottom to autoscroll (%1)", g:lh#btw#auto_cbottom)
  endif
  " Filling qflist is required because of lh#btw#build#_show_error() in caller
  " function
  let what = s:job_description(self)
  echomsg substitute(self.action, '.*', '\u&', '') . " of ".what." started."
  call setqflist([{'text': "Background ". self.action ." with `".(self.cmd)."` started"}])
  call setqflist([], 'r',
        \ {'title': self.build_mode. ' '. self.action . ' of ' . self.project_name})
  let self.start_time = reltime()
  let s:job = self
  let g:lh#btw#job_build#qf_need_colours = 0
endfunction

if exists(':cbottom') " {{{3
  let g:lh#btw#auto_cbottom = 0
  augroup BTW_stop_cbottom
    au!
    au BufEnter *
          \   if &ft=='qf' && ! get(g:, 'lh#btw#_ignore_bufenter_qf', 0)
          \ |   call s:Verbose('enter qf => no cbottom')
          \ |   let g:lh#btw#auto_cbottom = 0
          \ | endif
  augroup END
endif

" Function: s:init(cmd, options) {{{3
function! s:init(cmd, options) abort
  " let mode     = lh#btw#build_mode()
  " let prj_name = lh#btw#project_name()
  let mode     = get(a:options, 'mode',     '')
  let prj_name = get(a:options, 'prj_name', '')
  let message  = get(a:options, 'message',  'Build %s%s')
  let action   = get(a:options, 'action',   'compilation')
  let s:action = action
  let s:cmd    = a:cmd
  let job =
        \ { 'txt'            : printf(message, prj_name, empty(mode) ? '' : ' ('.mode.')')
        \ , 'action'         : action
        \ , 'cmd'            : a:cmd
        \ , 'close_cb'       : function('s:closeCB')
        \ , 'callback'       : function('s:callbackCB')
        \ , 'start_fail_cb'  : function('s:start_fail_cb')
        \ , 'before_start_cb': function('s:before_start_cb')
        \ , 'build_mode'     : mode
        \ , 'project_name'   : prj_name
        \ }
  if has_key(a:options, 'on-the-fly-hooks')
    let job.otf_hooks = a:options['on-the-fly-hooks']
  endif
  let queue = lh#async#get_queue('qf', '')
  call queue.push_or_start(job)
  " Cannot return anything yet
endfunction

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

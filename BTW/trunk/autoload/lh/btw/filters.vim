"=============================================================================
" $Id$
" File:         autoload/lh/btw/filters.vim                       {{{1
" Maintainer:	Luc Hermitte <MAIL:hermitte {at} free {dot} fr>
" 		<URL:http://code.google.com/p/lh-vim/>
" Licence:      GPLv3
" Version:      0.3.1
" Created:      13th Mar 2014
" Last Update:  $Date$
"------------------------------------------------------------------------
" Description:
"       Generic way to add on-the-fly filters and hooks on quickfix results
"       (from within vim)
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
let s:k_version = 031
function! lh#btw#filters#version()
  return s:k_version
endfunction

" # Debug   {{{2
if !exists('s:verbose')
  let s:verbose = 0
endif
function! lh#btw#filters#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Verbose(expr)
  if s:verbose
    echomsg a:expr
  endif
endfunction

function! lh#btw#filters#debug(expr)
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1

" # QuickFix Hooks {{{2
" Function: lh#btw#filters#register_hook(Hook, kind) {{{3
function! lh#btw#filters#register_hook(Hook, kind)
  if !exists('s:qf_hooks')
    call lh#btw#filters#_clear_hooks()
    augroup BTW_QF_PreHook
      au!
      " clean folding data before compiling
      au QuickFixCmdPre  make call s:ApplyQuickFixHooks('pre')
      au QuickFixCmdPost make call s:ApplyQuickFixHooks('post') 
      au FileType        qf   call s:ApplyQuickFixHooks('open')
    augroup END
  endif

  let s:qf_hooks[a:kind][a:Hook] = function(a:Hook)
endfunction

" Function: s:ApplyQuickFixHooks(hook_kind) {{{3
function! s:ApplyQuickFixHooks(hook_kind)
  for Hook in values(s:qf_hooks[a:hook_kind])
    if s:verbose > 1
      echomsg a:hook_kind . ' -> ' . string(Hook)
      debug call Hook()
    else
      call Hook()
    endif
  endfor
endfunction

" Function: lh#btw#filters#_clear_hooks() {{{3
function! lh#btw#filters#_clear_hooks()
  let s:qf_hooks = {'pre':{}, 'post':{}, 'open':{}}
endfunction
"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

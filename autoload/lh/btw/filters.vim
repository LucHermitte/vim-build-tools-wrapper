"=============================================================================
" File:         autoload/lh/btw/filters.vim                       {{{1
" Maintainer:	Luc Hermitte <MAIL:hermitte {at} free {dot} fr>
" 		<URL:http://github.com/LucHermitte/vim-build-tools-wrapper>
" Licence:      GPLv3
" Version:      0.4.0
let s:k_version = 040
" Created:      13th Mar 2014
" Last Update:  23rd Mar 2015
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
function! lh#btw#filters#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#btw#filters#verbose(...)
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

function! lh#btw#filters#debug(expr) abort
  return eval(a:expr)
endfunction

"------------------------------------------------------------------------
" ## Exported functions                                           {{{1

" # QuickFix Hooks {{{2
" Function: lh#btw#filters#register_hook(prio, Hook, kind)   {{{3
function! lh#btw#filters#register_hook(prio, Hook, kind)
  if !exists('s:qf_hooks')
    call lh#btw#filters#_clear_hooks()
    augroup BTW_QF_PreHook
      au!
      " clean folding data before compiling
      au QuickFixCmdPre  make call lh#btw#filters#_apply_quick_fix_hooks('pre')
      au QuickFixCmdPost make call lh#btw#filters#_apply_quick_fix_hooks('post')
      au FileType        qf   call lh#btw#filters#_apply_quick_fix_hooks('open')
    augroup END
  endif

  if !has_key(s:qf_hooks[a:kind], a:prio)
    let s:qf_hooks[a:kind][a:prio] = {}
  endif
  let s:qf_hooks[a:kind][a:prio][a:Hook] = function(a:Hook)
endfunction

" Function: lh#btw#filters#register_hooks(Hooks)             {{{3
function! lh#btw#filters#register_hooks(Hooks)
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

  for [kind, prio_hook] in items(a:Hooks)
    for [prio, Hook] in items(prio_hook)
      if !has_key(s:qf_hooks[kind], prio)
        let s:qf_hooks[kind][prio] = {}
      endif
      let s:qf_hooks[kind][prio][Hook] = function(Hook)
    endfor
  endfor
endfunction

" Function: lh#btw#filters#_apply_quick_fix_hooks(hook_kind) {{{3
function! lh#btw#filters#_apply_quick_fix_hooks(hook_kind) abort
  if !exists('s:qf_hooks') | return | endif
  let hooks_by_prio_dict = s:qf_hooks[a:hook_kind]
  let hooks_by_prio = items(hooks_by_prio_dict)
  call sort(hooks_by_prio, 's:SortByFirstNum')
  let hooks = map(copy(hooks_by_prio), 'v:val[1]')

  for hooks_of_prio in hooks
    for Hook in values(hooks_of_prio)
      call s:Verbose(a:hook_kind . ' -> ' . string(Hook))
      if s:verbose >= 2
        debug call Hook()
      else
        call Hook()
      endif
    endfor
  endfor
endfunction

" Function: lh#btw#filters#_clear_hooks()                    {{{3
function! lh#btw#filters#_clear_hooks()
  let s:qf_hooks = {'pre':{}, 'post':{}, 'open':{}, 'syntax':{}}
endfunction

"------------------------------------------------------------------------
" ## Internal functions                                           {{{1
" # Misc functions {{{2
" Function: s:SortByFirstNum(lhs, rhs)                       {{{3
function! s:SortByFirstNum(lhs, rhs)
  let diff = eval(a:lhs[0]) - eval(a:rhs[0])
  return    diff  < 0 ? -1
        \ : diff == 0 ? 0
        \ :             1
endfunction

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

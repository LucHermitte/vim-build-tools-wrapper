"=============================================================================
" File:         autoload/lh/btw/chain/_default.vim                {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/vim-build-tools-wrapper>
" License:      GPLv3 w/ licence exception
"               <URL:http://github.com/LucHermitte/vim-build-tools-wrapper/blob/master/License.md>
" Version:      0.7.0.
let s:k_version = '070'
" Created:      24th Oct 2018
" Last Update:  26th Oct 2018
"------------------------------------------------------------------------
" Description:
"       «description»
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
function! lh#btw#chain#_default#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#btw#chain#_default#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Log(expr, ...) abort
  call call('lh#log#this',[a:expr]+a:000)
endfunction

function! s:Verbose(expr, ...) abort
  if s:verbose
    call call('s:Log',[a:expr]+a:000)
  endif
endfunction

function! lh#btw#chain#_default#debug(expr) abort
  return eval(a:expr)
endfunction

" # Misc    {{{2
function! s:getSID() abort
  return eval(matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_getSID$'))
endfunction
let s:k_script_name      = s:getSID()

"------------------------------------------------------------------------
" ## Exported functions {{{1

"------------------------------------------------------------------------
" ## Internal functions {{{1
" Function: lh#btw#chain#_default#load_config() {{{2
function! lh#btw#chain#_default#load_config() abort
  LetTo p:BTW.project_config = lh#btw#chain#_default#_make()
  return 1
endfunction

" Function: lh#btw#chain#_default#_make(...) {{{2
function! lh#btw#chain#_default#_make(...) abort
  let res = lh#object#make_top_type(get(a:, 1, {}))
  call lh#object#inject_methods(res, s:k_script_name, 'config', 'reconfig')
  let res.type = 'modeline'
  return res
endfunction

function! s:config() dict abort
  if exists(':LetModeLine')
    call lh#btw#build#_add_let_modeline()
  endif
endfunction

function! s:reconfig() dict abort
  if exists(':LetModeLine')
    :LetModeLine
  endif
endfunction

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

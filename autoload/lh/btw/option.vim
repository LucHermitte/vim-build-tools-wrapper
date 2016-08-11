"=============================================================================
" File:         autoload/lh/btw/option.vim                        {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/vim-option-tools-wrapper>
" Version:      0.7.0.
let s:k_version = '070'
" Created:      23rd Mar 2015
" Last Update:  10th Aug 2016
"------------------------------------------------------------------------
" Description:
"       Internal functions relative to BTW options
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#btw#option#version()
  return s:k_version
endfunction

" # Debug   {{{2
if !exists('s:verbose')
  let s:verbose = 0
endif
function! lh#btw#option#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Verbose(expr)
  if s:verbose
    echomsg a:expr
  endif
endfunction

function! lh#btw#option#debug(expr)
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Options            {{{1
" # Compilation options {{{2
" Function: lh#btw#option#_make_in_bg() {{{3
function! lh#btw#option#_make_in_bg() abort
  return lh#option#get('BTW_make_in_background', 0, 'g')
endfunction

" Function: lh#btw#option#_make_mj() {{{3
function! lh#btw#option#_make_mj() abort
  let value = lh#option#get('BTW_make_multijobs', 0, 'g')
  if type(value) != type(0)
    call lh#common#error_msg("option BTW_make_multijobs is not a number")
    return 0
  endif
  return value
endfunction

" Function: lh#btw#option#_auto_scroll_in_bg() {{{3
function! lh#btw#option#_auto_scroll_in_bg() abort
  return get(g:, 'BTW_autoscroll_background_compilation', 1)
endfunction

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

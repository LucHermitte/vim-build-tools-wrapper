"=============================================================================
" File:         autoload/lh/btw/chain/_register_default.vim       {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/vim-build-tools-wrapper>
" License:      GPLv3 w/ licence exception
"               <URL:http://github.com/LucHermitte/vim-build-tools-wrapper/blob/master/License.md>
" Version:      0.7.0.
let s:k_version = '070'
" Created:      24th Oct 2018
" Last Update:  24th Oct 2018
"------------------------------------------------------------------------
" Description:
"       Automatically loaded script to register default chains
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
function! lh#btw#chain#_register_default#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#btw#chain#_register_default#verbose(...)
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

function! lh#btw#chain#_register_default#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1

"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
" }}}1
" ## Always executed code {{{1
" file -- chain -- priority
call lh#btw#chain#register('CMakeLists.txt', 'cmake',     1)
call lh#btw#chain#register('Makefile',       'make',      1)
call lh#btw#chain#register('configure',      'configure', 2)
call lh#btw#chain#register('autogen.sh',     'autogen',   3)
call lh#btw#chain#register('SConstruct',     'scons',     1)
call lh#btw#chain#register('qcg.pro',        'qmake',     1)
call lh#btw#chain#register('build.xml',      'ant',       1)

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

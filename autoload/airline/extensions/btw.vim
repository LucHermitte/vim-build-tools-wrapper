"=============================================================================
" File:         autoload/airline/extensions/btw.vim               {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/vim-build-tools-wrapper>
" Version:      0.4.1.
let s:k_version = '041'
" Created:      09th Apr 2015
" Last Update:  09th Apr 2015
"------------------------------------------------------------------------
" Description:
"       Airline extension for BuildToolsWrapper
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! airline#extensions#btw#version()
  return s:k_version
endfunction

" # Debug   {{{2
if !exists('s:verbose')
  let s:verbose = 0
endif
function! airline#extensions#btw#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Verbose(expr)
  if s:verbose
    echomsg a:expr
  endif
endfunction

function! airline#extensions#btw#debug(expr)
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1
" # Registration {{{2

" Due to some potential rendering issues, the use of the `space` variable is
" recommended.
let s:spc = g:airline_symbols.space

" Function: airline#extensions#btw#init(ext) {{{3
function! airline#extensions#btw#init(ext) abort
  " Here we define a new part for the plugin.  This allows users to place this
  " extension in arbitrary locations.
  call airline#parts#define_raw('cats', '%{airline#extensions#btw#build_mode()}')

  " Next up we add a funcref so that we can run some code prior to the
  " statusline getting modifed.
  call a:ext.add_statusline_func('airline#extensions#btw#apply')

  " You can also add a funcref for inactive statuslines.
  " call a:ext.add_inactive_statusline_func('airline#extensions#btw#unapply')
endfunction

" Function: airline#extensions#btw#apply(...) {{{3
" This function will be invoked just prior to the statusline getting modified.
function! airline#extensions#btw#apply(...) abort
  " First we check this is a compiled file with a compilation mode & al
  if !exists('b:BTW_project_config')
    return
  endif

  if &ft == 'qf'
    let w:airline_section_a = get(w:, 'airline_section_a', g:airline_section_a)
    let w:airline_section_a .= s:spc.g:airline_left_alt_sep.s:spc.'%{airline#extensions#btw#build_mode()}'
  else
    " Let's say we want to append to section_b, first we check if there's
    " already a window-local override, and if not, create it off of the global
    " section_b.
    let w:airline_section_b = get(w:, 'airline_section_b', g:airline_section_b)

    " Then we just append this extenion to it, optionally using separators.
    let w:airline_section_b .= s:spc.g:airline_left_alt_sep.s:spc.'%{airline#extensions#btw#build_mode()}'
  endif
endfunction

" Function: airline#extensions#btw#build_mode() {{{3
function! airline#extensions#btw#build_mode() abort
  if !exists('b:BTW_project_config')
    return ''
  else
    let config = get(b:BTW_project_config, '_', {})
    let mode   = get(get(config, 'compilation', {}), 'mode', '')
    let name   = get(config, 'name', '')
    return name.s:spc.mode
  endif
endfunction
"------------------------------------------------------------------------
" ## Internal functions {{{1

"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

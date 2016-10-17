"=============================================================================
" File:         autoload/airline/extensions/btw.vim               {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/vim-build-tools-wrapper>
" Version:      0.7.0
let s:k_version = '070'
" Created:      09th Apr 2015
" Last Update:  16th Oct 2016
"------------------------------------------------------------------------
" Description:
"       Airline extension for BuildToolsWrapper
" TODO:
" - Display number of errors and warnings
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
" ## Options            {{{1
LetIfUndef g:airline#extensions#btw#section          'b'
LetIfUndef g:airline#extensions#btw#section_qf       'a'

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
  " First, in case this is a qf window, add metrics.
  if &ft ==  'qf'
    let metrics = lh#btw#build#_get_metrics()
    let w:airline_section_error   = metrics.errors
    let w:airline_section_warning = metrics.warnings
  endif

  " Then, we check this is a compiled file with a compilation mode & al
  if !lh#btw#option#_has_project_config()
    return
  endif

  " Get the section to use according to the current filetype
  let section = lh#ft#option#get_postfixed('airline#extensions#btw#section', &ft, 'b', 'g')

  " Let's say we want to append to section_{section}, first we check if there's
  " already a window-local override, and if not, create it off of the global
  " section_{section}.
  let w:airline_section_{section} = get(w:, 'airline_section_'.section, g:airline_section_{section})

  " Then we just append this extenion to it, optionally using separators.
  let fmt    = lh#option#get('airline#extensions#btw#format_section', s:spc.g:airline_left_alt_sep.s:spc.'%s')
  let w:airline_section_{section} .= printf(fmt, '%{airline#extensions#btw#build_mode()}')
endfunction

" Function: airline#extensions#btw#build_mode() {{{3
function! airline#extensions#btw#build_mode() abort
  let mode   = lh#btw#build_mode()
  let name   = lh#btw#project_name()
  let fmt    = lh#option#get('airline#extensions#btw#format_mode', '%s'.s:spc.'%s')
  return printf(fmt, name, mode)
endfunction
"------------------------------------------------------------------------
" ## Internal functions {{{1

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

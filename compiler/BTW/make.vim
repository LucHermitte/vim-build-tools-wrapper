"=============================================================================
" File:		compiler/BTW/make.vim                                           {{{1
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://hermitte.free.fr/vim/>
" URL: http://hermitte.free.fr/vim/ressources/vimfiles/compiler/BTW/make.vim
" Version:	0.0.1
" Created:	01st Dec 2005
" Last Update:	01st Dec 2005
"------------------------------------------------------------------------
" Description:	Make filter for Build-Tools-Wrapper -- a Vim plugin
" 
"------------------------------------------------------------------------
" Rationale:
" - Better 'errorformat'
"
"------------------------------------------------------------------------
" Installation:	
"      -2- Install Perl
"      -1- Install GCC, if not
"	0- Install Build-Tools-Wrapper.
"	1- Drop this file into {rtp}/compiler/BTW/
"	2- Execute the command ":BTW set make" or ":BTW setlocal make" to load
"	   this filter.
"
" History:
"   v0.1: First version of the filter
"
" TODO:		«missing features»
" }}}1
"=============================================================================


"=============================================================================
" Avoid local reinclusion {{{1
if exists("b:loaded_make_vim") 
      \ && !exists('g:force_reload_make_vim')
  finish 
endif
let b:loaded_make_vim = 1
let s:cpo_save=&cpo
set cpo&vim
" Avoid local reinclusion }}}1
"------------------------------------------------------------------------
"
"=============================================================================
" Avoid global reinclusion {{{1
if !exists("g:loaded_make_vim") 
      \ || exists('g:force_reload_make_vim')
  let g:loaded_make_vim = 1
" Avoid global reinclusion }}}1
"------------------------------------------------------------------------
" Functions {{{1

" c- default value for 'efm'           {{{2
function! s:Reset_efm()
  if &efm !~ '%D[^,]*Entering directory'
    let g:BTW_adjust_efm_make =
          \ 'default efm'
          \ . ',' .
          \ "%DEntering directory '%f',%XLeaving directory" 
  endif
endfunction

call s:Reset_efm()
endif

" Functions }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

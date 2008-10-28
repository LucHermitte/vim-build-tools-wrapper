"=============================================================================
" File:		compiler/BTW/aap.vim                                           {{{1
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://hermitte.free.fr/vim/>
" URL: http://hermitte.free.fr/vim/ressources/vimfiles/compiler/BTW/aap.vim
" Version:	0.1
" Created:	28th Nov 2004
" Last Update:	29th Nov 2004
"------------------------------------------------------------------------
" Description:	A-A-P Filter for Build-Tools-Wrapper -- a Vim plugin.
" 
"------------------------------------------------------------------------
" Installation:	
"      -1- Install A-A-P
"	0- Install Build-Tools-Wrapper.
"	1- Drop this file into {rtp}/compiler/BTW/
"	2- Execute the command ":BTW set aap" or ":BTW setlocal aap" to load
"	   this filter.
"
" History:	
"   v0.1: First version of the filter
"	Uses the work done on my (LH speaking) previous compiler-plugin for
"	aap.
" TODO:		
"  * Add the various error messages specific to aap.
" }}}1
"=============================================================================


"=============================================================================
" Avoid global reinclusion {{{1
if exists("g:loaded_aap_vim") 
      \ && !exists('g:force_reload_aap_vim')
  finish 
endif
let g:loaded_aap_vim = 1
let s:cpo_save=&cpo
set cpo&vim
" Avoid global reinclusion }}}1
"------------------------------------------------------------------------
" The definitions                           {{{1

" a- Program to run
" TODO: check if we are using aap or aap.bat
if has('windows')
  let g:BTW_filter_program_aap = 'aap.bat'
else
  let g:BTW_filter_program_aap = 'aap'
endif

" b- default value for 'efm'
"
" %+A is used to accept "Do not know" in the error message
" set efm+=%+EAap:\ Do\ not\ know\ %m
let g:BTW_adjust_efm_aap = '%+EAap: Do not know %m'
      \ . ',' . 'Aap: Error in recipe "%f" line %l: %m'

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

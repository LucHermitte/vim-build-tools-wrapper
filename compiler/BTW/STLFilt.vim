"=============================================================================
" File:		compiler/BTW/STLFilt.vim                                           {{{1
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://code.google.com/p/lh-vim/>
" URL: http://hermitte.free.fr/vim/ressources/vimfiles/compiler/BTW/cygwin.vim
" Version:	0.1
" Created:	01st Jun 2005
" Last Update:	01st Jun 2005
"------------------------------------------------------------------------
" Description:	STLFilt Filter for Build-Tools-Wrapper -- a Vim plugin.
"
"------------------------------------------------------------------------
" Installation:
"      -2- Have Perl installed.
"      -1- Install Appropriate filters from STLFilt
"	0- Install Build-Tools-Wrapper.
"	1- Drop this file into {rtp}/compiler/BTW/
"	2- Execute the command ":BTW add STLFilt" to load this filter.
"
" History:
"   v0.1: First version of the filter
" TODO:		«missing features»
" }}}1
"=============================================================================


"=============================================================================
" Avoid global reinclusion {{{1
if exists("g:loaded_BTW_STLFilt")
      \ && !exists('g:force_reload_BTW_STLFilt')
  finish
endif
let g:loaded_BTW_STLFilt_vim = 1
let s:cpo_save=&cpo
set cpo&vim
" Avoid global reinclusion }}}1
"------------------------------------------------------------------------
" Functions {{{1

" let g:BTW_filter_program_STLFilt = 'dmSTLFilt.pl -width:0'
" let g:BTW_filter_program_STLFilt = 'dmSTLFilt.pl -width:0 -path:l'
let s:path = findfile('gSTLFilt.pl', substitute($PATH, ':', ',', 'g')) " *nix only
let g:BTW_filter_program_STLFilt = 'perl '.s:path.' -width:0 -path:l'

" Functions }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

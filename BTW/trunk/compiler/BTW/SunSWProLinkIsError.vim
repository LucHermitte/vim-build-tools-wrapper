"=============================================================================
" File:		compiler/BTW/SunSWProLinkIsError.vim
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://hermitte.free.fr/vim/>
" URL:
" http://hermitte.free.fr/vim/ressources/vimfiles/compiler/BTW/SunSWProLinkIsError.vim
" Version:	0.1
" Created:	24th Jan 2006
" Last Update:	24th Jan 2006
"------------------------------------------------------------------------
" Description:	SunSWPro CLink Filter for Build-Tools-Wrapper -- a Vim plugin.
"
" 	This filter tells vim that link error are actually link erros that must
" 	result is opening the quickfix window.
"
"------------------------------------------------------------------------
" Installation:	
"      -1- Have Perl installed.
"	0- Install Build-Tools-Wrapper.
"	1- Drop this file into {rtp}/compiler/BTW/
"	2- Execute the command ":BTW add SunSWProLinkIsError" to load this
"	filter.
"
" History:	
"   v0.1: First version of the filter
"	Uses the work done on my (LH speaking) previous compiler-plugin for
"	cygwin.
" TODO:		«missing features»
" }}}1
"=============================================================================


"=============================================================================
" Avoid global reinclusion {{{1
if exists("g:loaded_BTW_SunSWProLinkIsError") 
      \ && !exists('g:force_reload_BTW_SunSWProLinkIsError')
  finish 
endif
let g:loaded_BTW_SunSWProLinkIsError = 1
let s:cpo_save=&cpo
set cpo&vim
" Avoid global reinclusion }}}1
"------------------------------------------------------------------------

"------------------------------------------------------------------------
" The definitions                           {{{1
" a- emplacement of the perl filter
let s:file = substitute(expand('<sfile>:p:h'), ' ', '\\ ', 'g')

" b- filter to apply over `make' outputs: '/' --> {root}
" let &l:makeprg = "make $* 2>&1 \\| ".s:file."/cygwin.pl"
let g:BTW_filter_program_SunSWProLinkIsError = s:file."/SunSWProLinkIsError.pl"

" c- default value for 'efm'
" let g:BTW_adjust_efm_cygwin = ''

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

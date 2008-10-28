"=============================================================================
" File:		cygwin.vim                                           {{{1
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://hermitte.free.fr/vim/>
" URL: http://hermitte.free.fr/vim/ressources/vimfiles/compiler/BTW/cygwin.vim
" Version:	0.1
" Created:	28th Nov 2004
" Last Update:	28th Nov 2004
"------------------------------------------------------------------------
" Description:	Filter for Build-Tools-Wrapper -- a Vim plugin.
"
" 	This filter is useful with Cygwin tools when the version of Vim used is
" 	the win32 native version.
" 	In other environments, Vim default settings are perfect.
"
" Reason: the filenames (e.g. thoses for whom GCC reports errors) are expressed
"       in the UNIX form, while win32-Vim is unable to open them from the
"       quickfix window. Hence the filtering used to replace '/' (root) by
"       {cygpath -m /}.
"
"	In order to correctly recognize Cygwin, 
" 	
" 
"------------------------------------------------------------------------
" Installation:	
"      -1- Install Cygwin. Make sure $TERM or $OSTYPE value "cygwin", or that
"          Cygwin is in the $PATH -- the filter is testing that cygpath weither
"          cygpath is visible. 
"	0- Install Build-Tools-Wrapper.
"	1- Drop this file into {rtp}/compiler/BTW/
"	2- Execute the command ":BTW add cygwin" to load this filter.
"	   Loading this particular filter can be done any time Vim-win32 is
"	   launched, provided Cygwin tools may be used.
"	   -> Useless on other systems.
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
if exists("g:loaded_cygwin_vim") 
      \ && !exists('g:force_reload_cygwin_vim')
  finish 
endif
let g:loaded_cygwin_vim = 1
let s:cpo_save=&cpo
set cpo&vim
" Avoid global reinclusion }}}1
"------------------------------------------------------------------------
" Check we are using cygwin                 {{{1
if !has('win32') 
      \ || !( ($TERM=='cygwin') || ($OSTYPE=='cygwin') || executable('cygpath'))
  echoerr "Cygwin not detected..."
  finish
endif
"------------------------------------------------------------------------
" The definitions                           {{{1
" a- emplacement of the perl filter
let s:file = substitute(expand('<sfile>:p:h'), ' ', '\\ ', 'g')

" b- filter to apply over `make' outputs: '/' --> {root}
" let &l:makeprg = "make $* 2>&1 \\| ".s:file."/cygwin.pl"
let g:BTW_filter_program_cygwin = s:file."/cygwin.pl"

" c- default value for 'efm'
" let g:BTW_adjust_efm_cygwin = ''

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

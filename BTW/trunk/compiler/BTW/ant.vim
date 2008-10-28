"=============================================================================
" $Id$
" File:		ant.vim                                           {{{1
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://hermitte.free.fr/vim/>
" Version:	«version»
" Created:	22nd May 2006
" Last Update:	$Date$
"------------------------------------------------------------------------
" Description:	«description»
" 
"------------------------------------------------------------------------
" Installation:	«install details»
" History:	«history»
" TODO:		«missing features»
" }}}1
"=============================================================================


"=============================================================================
" Avoid global reinclusion {{{1
let s:cpo_save=&cpo
set cpo&vim
if exists("g:loaded_BTW_ant") 
      \ && !exists('g:force_reload_BTW_ant')
  let &cpo=s:cpo_save
  finish 
endif
let g:loaded_BTW_ant = 1
" Avoid global reinclusion }}}1
"------------------------------------------------------------------------
" Functions {{{1

" a- emplacement of the perl filter
let s:file = substitute(expand('<sfile>:p:h'), ' ', '\\ ', 'g')

" b- filter to apply over `ant' outputs: '/' --> {root}
let g:BTW_filter_program_ant = s:file."/ant.pl"

" Functions }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

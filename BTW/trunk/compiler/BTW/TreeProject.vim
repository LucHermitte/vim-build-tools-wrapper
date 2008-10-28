"=============================================================================
" File:		compiler/BTW/TreeProject.vim                              {{{1
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://hermitte.free.fr/vim/>
" URL: http://hermitte.free.fr/vim/ressources/vimfiles/compiler/BTW/TreeProject.vim
" Version:	0.1
" Created:	12th Jan 2005
" Last Update:	12th Jan 2005
"------------------------------------------------------------------------
" Description:	Example BTW-Filter for project organized in trees:
"
" $PROJECT_HOME/
" +-> {Sub-Project1}/
" |   +-> gen/
" |   |   +-> {Sub-Project1}.mk  <-- makefile for the sub project1
" |   +-> ...
" |   +-> ...
" +-> ....
" +-> {Sub-Projectn}/
" |   +-> gen/
" |   |   +-> {Sub-Projectn}.mk  <-- makefile for the sub projectn
" |   +-> ...
" |   +-> ...
" 
" Rationale:
" - The project composed as a set of makefiles, one for each
"   component/sub-project.
"
"------------------------------------------------------------------------
" Installation:	
"	0- Install Build-Tools-Wrapper.
"	1- Drop this file into {rtp}/compiler/BTW/
"	2- Execute the command ":BTW set TreeProject" or 
"	   ":BTW setlocal TreeProject" to load this filter.
"
" History:	
"   v0.1: First version of the filter
"	Uses the work done on my (LH speaking) previous compiler-plugin for
"	GCC.
" TODO:		«»
" }}}1
"=============================================================================


"=============================================================================
" Avoid local reinclusion {{{1
if exists("b:loaded_TreeProject_vim") 
      \ && !exists('g:force_reload_TreeProject_vim')
  finish 
endif
let b:loaded_TreeProject_vim = 1
let s:cpo_save=&cpo
set cpo&vim
" Avoid local reinclusion }}}1
"------------------------------------------------------------------------

"=============================================================================
" Global Definitions {{{1
if !exists("g:loaded_TreeProject_vim") 
      \ || exists('g:force_reload_TreeProject_vim')
  let g:loaded_TreeProject_vim = 1
  " Avoid global reinclusion }}}1
  "------------------------------------------------------------------------

  " Options:                                  {{{1
  " - Factorize Link error
  "   -> :substitute rule to found where a translation unit is 
  "   -> color for the «||(.text+0xa42)»
  " - Cliquable link error
  " - Fold link errors, and the compilation of every translation unit

  function! s:Option(name, key)
    let name = 'g:BTW_TreeProject_'.a:name
    if exists(name)
      if strlen({name})
	return ' ' . a:key . '=' . {name}
      else
	return ' ' . a:key
      endif
    else
      return ''
    endif
  endfunction

  " The definitions                           {{{1

  " Path to TreeProject's makefiles            {{{2
  let s:TreeProject_REP = $TREEPROJECT_ROOT

  " Program to run                     {{{2
  function! s:Find_Makefile()
    let component_path = matchstr(expand('%:p'), s:TreeProject_REP.'/[^/]\+')
    if 0 == strlen(component_path)
      call confirm('You are not editing a file from the project TreeProject!!', '&Ok', 1, 'Error')
      finish
    endif

    let component = fnamemodify(component_path, ':t') 
    let makefile  = 'make -f '.component.'.mk'
    let full_makefile = component_path.'/gen/'.component.'.mk'
    if !filereadable(full_makefile)
      call confirm('No makefile named <<'.full_makefile.'>>', '&Ok', 1, 'Error')
      return
    endif

    let b:BTW_filter_program_TreeProject = 'cd '.component_path.'/gen ; ' . makefile 
  endfunction

  " default value for 'efm'            {{{2
  " }}}2
endif
" }}}1

"------------------------------------------------------------------------
" Dependent local definitions
call s:Find_Makefile()

"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

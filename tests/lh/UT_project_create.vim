"=============================================================================
" $Id$
" File:         tests/lh/UT_project_create.vim                    {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://code.google.com/p/lh-vim/>
" Version:      0..3..4.
let s:k_version = '0.3.4'
" Created:      15th Jan 2015
" Last Update:  $Date$
"------------------------------------------------------------------------
" Description:
"       Unit tests for lh#btw#project functions.
" }}}1
"=============================================================================

UTSuite [BTW] Testing lh#btw#project

runtime autoload/lh/btw/project.vim

let s:cpo_save=&cpo
set cpo&vim

"------------------------------------------------------------------------
function! s:Test_analyse_params()
  let ref = {'project_kind': {'c':1,'cmake':1}, '_prj_name': 'toto', '_prj_config': 'titi', '_prj_src_dir': 'dir'}
  Assert ref == lh#btw#project#_analyse_params('c' , 'cmake', 'name', 'toto', 'config:', 'titi', 'src_dir=dir')
endfunction

"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

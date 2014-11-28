"=============================================================================
" File:		compiler/BTW/gcc.vim                                           {{{1
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://code.google.com/p/lh-vim/>
" URL: http://hermitte.free.fr/vim/ressources/vimfiles/compiler/BTW/gcc.vim
" Version:	0.1
" Created:	28th Nov 2004
" Last Update:	09th Dec 2004
"------------------------------------------------------------------------
" Description:	GCC Filter for Build-Tools-Wrapper -- a Vim plugin.
" 
" Rationale:
" - Better 'errorformat'
"   Default filter does not handle correctly link errors 
" - Enhanced syntax highlighting
" - folding
"
"------------------------------------------------------------------------
" Installation:	
"      -2- Install Perl
"      -1- Install GCC, if not
"	0- Install Build-Tools-Wrapper.
"	1- Drop this file into {rtp}/compiler/BTW/
"	2- Execute the command ":BTW set gcc" or ":BTW setlocal gcc" to load
"	   this filter.
"
" History:	
"   v0.1: First version of the filter
"	Uses the work done on my (LH speaking) previous compiler-plugin for
"	aap!
" TODO:		
"  * Add various levels of options ; see LaTeXSuite
"  * Change the options with «:BTW gcc set {opt}={value}»
"  * gcc.pl: If the transl. unit does not exist, do no make it clickable
"  * Something odd: all the link error from GCC appear before the other
"    messages like the commands executed.
"  * «:BTW gcc rebuild»
"  * Apply c++filt
" }}}1
"=============================================================================


"=============================================================================
" Avoid global reinclusion {{{1
if exists("g:loaded_gcc") 
      \ && !exists('g:force_reload_gcc')
  finish 
endif
let g:loaded_gcc = 1
let s:cpo_save=&cpo
set cpo&vim
" Avoid global reinclusion }}}1
"------------------------------------------------------------------------

" Options:                                  {{{1
" - Factorize Link error
"   -> :substitute rule to found where a translation unit is 
"   -> color for the «||(.text+0xa42)»
" - Cliquable link error
" - Fold link errors, and the compilation of every translation unit

function! s:Option(name, key)
  let name = 'g:BTW_gcc_'.a:name
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
" a- emplacement of the perl filter    {{{2
let s:file = substitute(expand('<sfile>:p:h'), ' ', '\\ ', 'g')

" b- filter to apply over outputs:     {{{2
function! s:Reset_program()
  let g:BTW_filter_program_gcc = 'perl '.s:file."/gcc.pl"
	\ . s:Option('group_lnk', '-grp-lnk')
	\ . s:Option('click_lnk', '-clk-lnk')
	\ . s:Option('obj_dir', '-obj')
	\ . s:Option('src_dir', '-tu')
endfunction

call s:Reset_program()

" c- default value for 'efm'           {{{2
function! s:Reset_efm()
  let g:BTW_adjust_efm_gcc = '%f:%l: %m'
  " - GCC link errors (undefined reference to..., etc.)
  if lh#option#get('g:BTW_gcc_click_lnk', 0, 'g')
    let g:BTW_adjust_efm_gcc = 
	  \ '%f:1: %m'
	  \ .','.
	  \ .'In file included from %f:%l:'
	  \ .','.
	  \ ."\t\tfrom %f:%l%m'"
	  \ .','.
	  \ g:BTW_adjust_efm_gcc  
  endif
endfunction

call s:Reset_efm()

" for GCC with gmake (concat the lines!)
" %f:%l:\ %m,%Dgmake[%*\\d]:\ Entering\ directory\ `%f',
" %Dgmake[%*\\d]:\ Leaving\ directory\ `%f'

" for GCC, with some extras
" %f:%l:\ %m,In\ file\ included\ from\ %f:%l:,\^I\^Ifrom\ %f:%l%m


" Enhance syntax highlighting		         {{{1
function! s:EnhanceHighlight()
  syn match	qfLnkFileName	"^|| \f*"hs=s+2 nextgroup=qfLnkSepOp
  syn match	qfLnkSepOp 	"(" nextgroup=qfLnkObjFile contained
  syn match	qfLnkObjFile	"\f*" nextgroup=qfLnkSepCl contained
  " ¿ \f\+ ? 
  syn match	qfLnkSepCl	") " contained nextgroup=qfLnkTransUnit
  syn match	qfLnkTransUnit	"\f\f\+: "he=e-2 contained 

  " The default highlighting.
  hi def link qfLnkFileName	Directory
  hi def link qfLnkTransUnit	Directory
  hi def link qfLnkObjFile	LineNr
endfunction

aug Qf_GCC
  au!
  au Syntax qf :call <sid>EnhanceHighlight()
aug END

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

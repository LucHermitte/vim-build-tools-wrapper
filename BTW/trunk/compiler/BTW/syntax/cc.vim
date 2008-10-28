"=============================================================================
" File:		compiler/BTW/syntax/cc.vim                                {{{1
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://hermitte.free.fr/vim/>
" Version:	0.0.1
" Created:	17th Nov 2005
" Last Update:	01st Dec 2005
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
" Avoid reinclusion {{{1
if exists("b:loaded_BTW_syntax_cc_vim") 
      \ && !exists('g:force_reload_BTW_syntax_cc_vim')
  finish 
endif
let b:loaded_BTW_syntax_cc_vim = 1
let s:cpo_save=&cpo
set cpo&vim
" Avoid reinclusion }}}1
"------------------------------------------------------------------------
" Definitions {{{1


syn match  qfMakeLine	/^|| .*\<\(g\=make\|b\=jam\|aap\|scons\)\>[^:].*$/ nextgroup=qfMake transparent contains=qfMake,qfOption
syn keyword qfMake gmake make aap bjam jam scons contained nextgroup=qfOptions skipwhite
syn match  qfOptions	/\<-\S\+\>/ contained nextgroup=qfMakefile skipwhite
syn match  qfMakefile   #/\<\f\+\># contained skipwhite nextgroup=NONE



syn region qfCCLine	start="^|| \S\+g\=\(cc\|CC\|++\)\|tao_idl\|mkdir\>" end="\<-o\(\_s\+||\s*\)\= \S\+" contains=qfTool,qfTarget

syn match  qfTool	"^|| \S\+g\=\(cc\|CC\|++\|CClink\|tao_idl\|mkdir\)\>"hs=s+3 contained
syn match  qfTarget	"-o\(\_s\+||\s*\)\= \S\+"ms=s+2 contained


" reset
hi! def link qfMake	Comment
hi! def link qfMakefile	Special
hi! def link qfOptions	NONE
hi! def link qfTool	Comment
hi! def link qfTarget	WarningMsg

" Fold groups: 
" @todo: move into a compiler/BTW/syntax/ATV.vim file
" vim7 only ?
syn match  qfGroupStart "^|| Generation: \S\+"hs=s+3

" The syn-fold must be done *after* the other :syn- definitions
syn region qfGroup	start="^|| Generation: \z(\S\+\)" end="^|| \z1 Generation successful" transparent fold
hi! BlackOnCyan  ctermbg=Cyan     ctermfg=Black  guibg=#99C6ff    guifg=Black
hi! def link qfGroupStart BlackOnCyan

set foldmethod=syntax

" Definitions }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

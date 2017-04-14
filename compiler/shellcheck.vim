"=============================================================================
" File:         compiler/shellcheck.vim                           {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/vim-build-tools-wrapper>
" Licence:      GPLv3
" Version:      0.7.0.
let s:k_version = '070'
" Created:      12th Apr 2017
" Last Update:  14th Apr 2017
"------------------------------------------------------------------------
" Description:
"       Compiler plugin for shellcheck
"       https://github.com/koalaman/shellcheck
"
"------------------------------------------------------------------------
" History:      «history»
" Options: They are dynamically applied with build-tools-wrapper
" - (bpg):shellcheck_options -- suppl options like -x
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
let s:shellcheck_options = lh#option#get('shellcheck.options', '')
let &l:makeprg=join(['shellcheck -f gcc', s:shellcheck_options, '$*'], ' ')
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

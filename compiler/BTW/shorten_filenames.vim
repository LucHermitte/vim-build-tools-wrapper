"=============================================================================
" File:         compiler/BTW/shorten_filenames.vim                {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/vim-build-tools-wrapper>
" Version:      0.4.0.
let s:k_version = '040'
" Created:      22nd Mar 2015
" Last Update:  $Date$
"------------------------------------------------------------------------
" Description:
"       BTW filter to shorter filenames (with conceal feature)
"
" Parameters:
"   - (bg):{ft_}BTW_shorten_names: [ pattern, [pattern,cchar], ...]
"
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" Main {{{1
function! BTW_Shorten_Filenames() abort
  echomsg bufnr('%')
  " We cannot apply s:Tranform (from substitute_filenames) to shorten filename.
  " Indeed the qf.text won't contain the filename. Filenames have already
  " been decoded and replaced by a bufnr.
  " At best, we can conceal
  syn match qfFileName /^[^|]*/  nextgroup=qfSeparator contains=qfShortenFile
  let list = lh#dev#option#get('BTW_shorten_names', &ft, [])
  for pat in list
    if type(pat)==type([])
      let expr  = pat[0]
      let cchar = pat[1]
    else
      let expr  = pat
      let cchar = '&'
    endif

    exe 'syn match qfShortenFile #'.expr.'# conceal contained cchar='.cchar
  endfor
  setlocal conceallevel=1
endfunction

call lh#btw#filters#register_hook(8, 'BTW_Shorten_Filenames', 'syntax')

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

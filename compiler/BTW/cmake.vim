"=============================================================================
" File:         compiler/BTW/cmake.vim                            {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://github.com/LucHermitte/vim-build-tools-wrapper>
" Version:      0.7.0
" Created:      21st Feb 2012
" Last Update:  16th Feb 2017
"------------------------------------------------------------------------
" Description:
"       BTW cmake compilation toolchain
"       $ cmake --build <build_dir> --config <Release|Debug|...> [--target <target>]
"       $ ctest <build_dir>
"
" Options:
"       [bg]:BTW_project_build_dir
"       [bg]:BTW_project_config._.compilation.mode/[bg]:BTW_project_build_mode
"
" TODO:
"       * Use the internal lh#btw#_register_fix_ctest()
"       * Have a option function instead of [bg]:BTW_project_build_dir in order
"       to be able to peek into the unique (to be) [bg]:BTW_project_config.
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim

"=============================================================================
" ## Helper functions {{{1
"------------------------------------------------------------------------
" s:getSNR([func_name]) {{{2
function! s:getSNR(...)
  if !exists("s:SNR")
    let s:SNR=matchstr(expand('<sfile>'), '<SNR>\d\+_\zegetSNR$')
  endif
  return s:SNR . (a:0>0 ? (a:1) : '')
endfunction

"=============================================================================
" ## &makeprg {{{1
"------------------------------------------------------------------------
" How to invoke cmake to compile with it
function! s:compile_cmake(...)
  let target = a:0 ? (' --target '.a:1) : ''
  let build_dir = lh#btw#option#_compilation_dir()
  let config    = lh#btw#build_mode('Release')
  let res = 'cmake --build '.lh#path#fix(build_dir).' --config '.config.target
  return res
endfunction

let b:BTW_filter_program_cmake = function(s:getSNR('compile_cmake'))

"=============================================================================
" ## &efm {{{1
"------------------------------------------------------------------------
" cmake messes up with the error format as it prepends the error lines with
" "%d>"
" => tell BTW to fix efm by prepending what other tools add
function! s:fix_efm_cmake(efm)
  let efm = split(a:efm, ',')
  call map(efm, '"%\\d%\\+>".v:val')

  " Other  CMake adjustments inspired by Fernando Castillo unmerged contibution
  " to compiler/gcc.vim, 2016 May 19, Vim licence
  " See https://github.com/vim/vim/pull/821
  call lh#list#push_if_new_elements(efm,
        \ [ '%E%.%#CMake Error at %f:%l%.%#'
        \ , '%E%.%#CMake Error in %f:%.%#'
        \ , '%Z%.%#CMake Error:%.%#'
        \ , '%Z-- Configuring incomplete%.%#'
        \ , '%C%.%#:%l%.%#'
        \ , '%C%m'
        \ , '%C%.%#'
        \ ])
  return join(efm, ',')
endfunction

let b:BTW_adjust_efm_cmake = {
      \ 'post': function(s:getSNR('fix_efm_cmake')),
      \ 'value': 'default efm'
      \}

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

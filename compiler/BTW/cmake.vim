"=============================================================================
" File:         compiler/BTW/cmake.vim                            {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://github.com/LucHermitte/vim-build-tools-wrapper>
" Version:      0.7.0
" Created:      21st Feb 2012
" Last Update:  10th Jun 2022
"------------------------------------------------------------------------
" Description:
"       BTW cmake compilation toolchain
"       $ cmake --build <build_dir> --config <Release|Debug|...> [--target <target>]
"       $ ctest <build_dir>
"
" Options:
"       [bpg]:BTW.compilation_dir
"       [bpg]:BTW.compilation.mode
"       [bpg]:BTW.build.mode.current
"       p:paths.sources
"
" TODO:
"       * Use the internal lh#btw#_register_fix_ctest()
"       * Check with non lhvl-project enabled projects
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
" How to invoke cmake to compile with it...
if 1 == get(g:, 'lh#btw#chain#__loading_main_tool', 0)
  " ... only if cmake filter has been loaded with `:BTW set(local)`, not with
  " `:BTW add(local)`
  function! s:compile_cmake(...)
    let target = (a:0 && a:1 != '$*') ? (' --target '.a:1) : ''
    let build_dir = lh#btw#option#_compilation_dir()
    let config    = lh#btw#build_mode('Release')
    let res = 'cmake --build '.lh#path#fix(build_dir).' --config '.config.target
    return res
  endfunction

  call lh#let#to('g:BTW.filter.program.cmake', function(s:getSNR('compile_cmake')))
endif

"=============================================================================
" ## &efm {{{1
"------------------------------------------------------------------------
" cmake messes up with the error format as it prepends the error lines with
" "%d>"
" => tell BTW to fix efm by prepending what other tools add
function! s:fix_efm(efm) abort
  let efm = a:efm

  if 1 == get(g:, 'lh#btw#chain#__loading_main_tool', 0)
    " ... only if cmake filter has been loaded with `:BTW set(local)`, not with
    " `:BTW add(local)`
    call map(efm, '"%\\d%\\+>".v:val')
  endif

  " Other CMake adjustments inspired by Fernando Castillo unmerged contibution
  " to compiler/gcc.vim, 2016 May 19, Vim licence
  " See https://github.com/vim/vim/pull/821
  " TODO: This efm adjustment doesn't work that well as messages are lost. Improvements are required.
  call lh#list#push_if_new_elements(efm,
        \ [ '%E%>%.%#CMake Error at %f:%l%.%#'
        \ , '%E%>%.%#CMake Error in %f:%.%#'
        \ , '%E%>%.%#CMake Error:%.%#'
        \ , '%W%>%.%#CMake Warning at %f:%l%.%#'
        \ , '%W%>%.%#CMake Warning in %f:%.%#'
        \ , '%W%>%.%#CMake Warning:%.%#'
        \ , '%Z  %m'
        \ , '%Z-- Configuring incomplete%.%#'
        \ , '%C%.%#:%l%.%#'
        \ , '%C%m'
        \ , '%C%.%#'
        \ ])
  return efm
endfunction

let prefix = lh#project#is_in_a_project() ? 'p:' : 'b:'
let s:efm = {
      \ 'post': function(s:getSNR('fix_efm')),
      \ 'value': 'default efm'
      \}
call lh#let#to(prefix.'BTW._filter.efm.use.cmake', s:efm)
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

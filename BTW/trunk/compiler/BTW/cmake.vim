"=============================================================================
" $Id$
" File:         compiler/BTW/cmake.vim                            {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://code.google.com/p/lh-vim/>
" Version:      001
" Created:      21st Feb 2012
" Last Update:  $Date$
"------------------------------------------------------------------------
" Description:
"       BTW cmake compilation toolchain
"       $ cmake --build <build_dir> --config <Release|Debug|...> [--target <target>]
"       $ ctest <build_dir>
"
" Options:
"       [bg]:BTW_project_build_dir
"       [bg]:BTW_project_build_mode
" 
"------------------------------------------------------------------------
" Installation:
"       Drop this file into {rtp}/compiler/BTW
"       Requires Vim7+
" History:      «history»
" TODO:         «missing features»
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" How to invoke cmake to compile with it
function! BTW_compile_cmake(...)
  let target = a:0 ? (' --target '.a:1) : ''
  let build_dir = lh#option#get('BTW_project_build_dir', '.')
  let config    = lh#option#get('BTW_project_build_mode', 'Release')
  let res = 'cmake --build '.FixPathName(build_dir).' --config '.config.target
  return res
endfunction

let b:BTW_filter_program_cmake = function('BTW_compile_cmake')
"------------------------------------------------------------------------
" cmake messes up with the error format as it prepends the error lines with
" "%d>"
" => tell BTW to fix efm by prepending what other tools add
function! BTW_fix_efm_cmake(efm)
  let efm = split(a:efm, ',')
  call map(efm, '"%\\d%\\+>".v:val')
  return join(efm, ',')
endfunction

let b:BTW_adjust_efm_cmake = {
      \ 'post': function('BTW_fix_efm_cmake'),
      \ 'value': 'default efm'
      \}

"------------------------------------------------------------------------

"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

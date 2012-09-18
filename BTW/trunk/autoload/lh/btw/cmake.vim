"=============================================================================
" $Id$
" File:         autoload/lh/btw/cmake.vim                         {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://code.google.com/p/lh-vim/>
" Version:      021
" Created:      12th Sep 2012
" Last Update:  $Date$
"------------------------------------------------------------------------
" Description:
"       Simplifies the defintion of CMake based projects
" Example:
"    let s:menu_priority = '50.120.'
"    let s:menu_name     = '&Project.&FooBar.'
"    
"    let g:foorbar_config_menu = {
"          \ '_project': 'project_config',
"          \ 'menu': {'priority': s:menu_priority, 'name': s:menu_name}
"          \ }
"    call lh#btw#cmake#def_options(g:sea_config_menu, [
"          \ 'def_toggable_compil_mode',
"          \ 'def_toggable_ctest_verbosity',
"          \ 'def_ctest_targets'])
" And then, through the menu (gvim), or:
" - :Toggle ProjectFooBarMode
" - :Toggle ProjectCTestVerbosity
" - :Set ProjectCTestTargetTests {regex}
" we can change the compilation mode (used by :Make/<F7>), of the arguments to
" ctest (<C-F5>)
"
"------------------------------------------------------------------------
" Installation:
"       Drop this file into {rtp}/autoload/lh/btw
"       Requires Vim7+, lh-vim-lib
"       «install details»
" History:      «history»
" TODO:         
"       Simplify the definition of the "_project" sub-dictionary as it requires
"       many options.
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
let s:k_version = 021
function! lh#btw#cmake#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = 0
function! lh#btw#cmake#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Verbose(expr)
  if s:verbose
    echomsg a:expr
  endif
endfunction

function! lh#btw#cmake#debug(expr)
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1
" Function: lh#btw#cmake#def_options(config, options) {{{2
" {config} shall contain:
" - menu.priority and menu.name
" - _project settings
" {options} is the list of lh#btw#cmake functions to call
function! lh#btw#cmake#def_options(config, options)
  for option in a:options
    " deepcopy of menu, shallow copy of _project
    let menu_def = {
          \ 'menu': copy(a:config.menu),
          \ '_project': a:config._project
          \ }
    call lh#btw#cmake#{option}(menu_def)
    " save the menu in order to make hooks and other stuff accessible
    let a:config[option] = menu_def
  endfor
endfunction

" Function: lh#btw#cmake#def_toggable_compil_mode(menu_def) {{{2
" {menu_def} shall contain:
" - menu.priority and menu.name
" - _project settings
function! lh#btw#cmake#def_toggable_compil_mode(menu_def)
  function! a:menu_def.project() dict " dereference _project
    return eval('g:'.self._project)
  endfunction
  " Automatically set variables for lh#btw#project_options#add_toggle_option,
  " and lh#menu#def_toggle_item
  let a:menu_def.idx_crt_value = 0
  let a:menu_def.values        = ['Debug', 'Release']
  " "variable" is a variable name, hence _project being a string
  let a:menu_def.variable      = a:menu_def._project.'.compilation.mode'
  let a:menu_def._root         = a:menu_def.project().paths.trunk
  let a:menu_def.menu.priority .= '20'
  let a:menu_def.menu.name     .= 'M&ode'
  " Default (polymorphic) functions for determining the current project
  " executable, and the current compilation directory
  if !has_key(a:menu_def, 'set_project_executable')
    let a:menu_def.set_project_executable = function(s:getSNR('SetProjectExecutable'))
  endif
  if !has_key(a:menu_def, 'update_compil_dir')
    let a:menu_def.update_compil_dir = function(s:getSNR('UpdateCompilDir'))
  endif
  function! a:menu_def.do_update() dict
    let b:BTW_project_build_mode = self.eval()
    call self.update_compil_dir()
    BTW rebuild
    call self.set_project_executable()
  endfunction
  call lh#btw#project_options#add_toggle_option(a:menu_def)
endfunction

" Function: lh#btw#cmake#def_toggable_ctest_verbosity(menu_def) {{{2
" {menu_def} shall contain:
" - menu.priority and menu.name
" - _project settings
function! lh#btw#cmake#def_toggable_ctest_verbosity(menu_def)
  function! a:menu_def.project() dict " dereference _project
    return eval('g:'.self._project)
  endfunction
  " Automatically set variables for lh#btw#project_options#add_toggle_option,
  " and lh#menu#def_toggle_item
  let a:menu_def.idx_crt_value = 0
  let a:menu_def.values        = ['', '-V', '-VV']
  " "variable" is a variable name, hence _project being a string
  let a:menu_def.variable      = a:menu_def._project.'.tests.verbosity'
  let a:menu_def._root         = a:menu_def.project().paths.trunk
  let a:menu_def.menu.priority .= '30'
  let a:menu_def.menu.name     .= 'CTest &Verbosity'
  " Default (polymorphic) functions for determining the current project
  " executable, and the current compilation directory
  if !has_key(a:menu_def, 'set_ctest_argument')
    let a:menu_def.set_ctest_argument = function(s:getSNR('SetCTestArgument'))
  endif
  function! a:menu_def.do_update() dict
    call self.set_ctest_argument()
  endfunction
  call lh#btw#project_options#add_toggle_option(a:menu_def)
endfunction

" Function: lh#btw#cmake#def_ctest_targets(menu_def) {{{2
" {menu_def} shall contain:
" - menu.priority and menu.name
" - _project settings
function! lh#btw#cmake#def_ctest_targets(menu_def)
  function! a:menu_def.project() dict " dereference _project
    return eval('g:'.self._project)
  endfunction
  " Automatically set variables for lh#btw#project_options#add_toggle_option,
  " and lh#menu#def_toggle_item
  let a:menu_def.values        = ''
  " "variable" is a variable name, hence _project being a string
  let a:menu_def.variable      = a:menu_def._project.'.tests.which_tests'
  let a:menu_def._root         = a:menu_def.project().paths.trunk
  let a:menu_def.menu.priority .= '40'
  let a:menu_def.menu.name     .= 'CTest &Target Test(s)'
  " Default (polymorphic) functions for determining the current project
  " executable, and the current compilation directory
  if !has_key(a:menu_def, 'set_ctest_argument')
    let a:menu_def.set_ctest_argument = function(s:getSNR('SetCTestArgument'))
  endif
  function! a:menu_def.do_update() dict
    call self.set_ctest_argument()
  endfunction
  call lh#btw#project_options#add_string_option(a:menu_def)
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1
" # s:getSNR() {{{2
function! s:getSNR(...)
  if !exists("s:SNR")
    let s:SNR=matchstr(expand('<sfile>'), '<SNR>\d\+_\zegetSNR$')
  endif
  return s:SNR . (a:0>0 ? (a:1) : '')
endfunction

" # s:UpdateCompilDir() dict {{{2
function! s:UpdateCompilDir() dict
  " "let self.project().paths = value" is refused by viml interpreter => hence
  " the auxiliary reference
  let paths = self.project().paths
  let paths.build = self.project().paths.project.'/'.self.project().build[self.project().compilation.mode]
  let b:BTW_compilation_dir    = paths.build
  " echoerr "Compiling ".expand('%')." in ".b:BTW_compilation_dir
endfunction

" # s:SetProjectExecutable() dict {{{2
function! s:SetProjectExecutable() dict
endfunction

" # s:SetCTestArgument() dict {{{2
function! s:SetCTestArgument() dict
    LetIfUndef b:BTW_project_executable.type 'ctest'
    let which = self.project().tests.which_tests
    let b:BTW_project_executable.rule = self.project().tests.verbosity
          \ . (empty(which) ? ('') : (' -R '.which))
endfunction

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

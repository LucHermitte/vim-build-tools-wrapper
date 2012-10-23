"=============================================================================
" $Id$
" File:         autoload/lh/btw/cmake.vim                         {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://code.google.com/p/lh-vim/>
" Version:      026
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
"       For multiple tests, we need to use -I <coma-sep-list> and not -R
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
let s:k_version = 027
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
"   - paths
"     - trunk
"     - project
"     - doxyfile
"     - sources
"     - _build          // internal, points to the compilation dir used
"                       // to set b:BTW_compilation_dir
"   - build
"     - Debug
"     - Release
"   - compilation (optional)
"     - mode            'Debug' from ['Debug', 'Release'] " matches the subdirs from build/
"   - tests (all optional)
"     - verbosity       ''   from ['', '-V', '-VV']
"     - checking_memory 'no' from ['no', 'yes']
"     - test_regex      ''
"     - active_list     []
" {options} is the list of lh#btw#cmake functions to call
if !exists('s:config')
  let s:config = {}
endif
function! lh#btw#cmake#def_options(config, options)
  let s:config[a:config._project] = a:config " in case it is required to access other config stuff
  " Set default values
  call lh#let#if_undef('g:'.a:config._project.'.compilation.mode',      string('Release'))
  call lh#let#if_undef('g:'.a:config._project.'.tests.checking_memory', string('no'))
  call lh#let#if_undef('g:'.a:config._project.'.tests.checking_memory', string('no'))
  call lh#let#if_undef('g:'.a:config._project.'.tests.test_regex',      string(''))
  call lh#let#if_undef('g:'.a:config._project.'.tests.active_list',     string([]))

  " Add all selected options to menu
  for option in a:options
    " deepcopy of menu, shallow copy of _project
    let menu_def = {
          \ 'menu': copy(a:config.menu),
          \ '_project': a:config._project
          \ }
    " save the menu in order to make hooks and other stuff accessible
    let a:config[option] = menu_def
    " execute the action to initialize everything
    call lh#btw#cmake#{option}(menu_def)
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
  let a:menu_def.values        = ['', '-V', '-VV']
  " "variable" is a variable name, hence _project being a string
  let a:menu_def.variable      = a:menu_def._project.'.tests.verbosity'
  let actual_variable_name = (a:menu_def.variable[0]=='$' ? '' : 'g:') . a:menu_def.variable
  if !exists(actual_variable_name)
    let a:menu_def.idx_crt_value = 0
  endif
  let a:menu_def._root         = a:menu_def.project().paths.trunk
  let a:menu_def.menu.priority .= '30.10'
  let a:menu_def.menu.name     .= 'C&Test.&Verbosity'
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
  let a:menu_def.variable      = a:menu_def._project.'.tests.test_regex'
  let a:menu_def._root         = a:menu_def.project().paths.trunk
  let a:menu_def.menu.priority .= '30.20'
  let a:menu_def.menu.name     .= 'C&Test.&Target Test(s)'
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

" Function: lh#btw#cmake#def_toggable_ctest_checkmem(menu_def) {{{2
" {menu_def} shall contain:
" - menu.priority and menu.name
" - _project settings
function! lh#btw#cmake#def_toggable_ctest_checkmem(menu_def)
  function! a:menu_def.project() dict " dereference _project
    return eval('g:'.self._project)
  endfunction
  " Automatically set variables for lh#btw#project_options#add_toggle_option,
  " and lh#menu#def_toggle_item
  let a:menu_def.idx_crt_value = 0
  let a:menu_def.values        = ['no', 'yes']
  " "variable" is a variable name, hence _project being a string
  let a:menu_def.variable      = a:menu_def._project.'.tests.checking_memory'
  let a:menu_def._root         = a:menu_def.project().paths.trunk
  let a:menu_def.menu.priority .= '30.30'
  let a:menu_def.menu.name     .= 'C&Test.Check &Memory'
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

" Function: lh#btw#cmake#update_list(menu_def) {{{2
function! lh#btw#cmake#update_list(menu_def)
  if type(a:menu_def) == type({})
    let proj_id = a:menu_def._project
    function! a:menu_def.project() dict " dereference _project
      return eval('g:'.self._project)
    endfunction
  else
    let proj_id = a:menu_def
  endif
  let menu_def = s:config[proj_id].update_list
  let tests = lh#os#system('cd '.b:BTW_compilation_dir. ' && ctest -N')
  let menu_def.menu.priority .= '30.900'
  let menu_def.menu.name     .= 'C&Test.&List'
  silent! exe 'aunmenu! '. menu_def.menu.name
  exe "amenu ".(menu_def.menu.priority).'.89 '.(menu_def.menu.name).'.-<Sep>- Nop '
  exe "amenu <silent> ".(menu_def.menu.priority).'.90 '.(menu_def.menu.name).'.&Update'
        \ .' :call lh#btw#cmake#update_list('.string(menu_def._project).')<cr>'

  let l_tests = split(tests, "\n")
  call filter(l_tests, "v:val =~ 'Test\\s\\+#'")
  call map(l_tests, 'substitute(v:val, "^\\s*Test\\s\\+#\\d\\+:\\s\\+", "", "")')
  let i = 1
  for test in l_tests
    let menu = {
          \ '_project': (menu_def._project),
          \ 'project' : (menu_def.project),
          \ 'menu'    : {
          \              'priority': (menu_def.menu.priority).'.'.i,
          \              'name'    : (menu_def.menu.name).'.'.test}
          \ }
    " function! menu.project() dict " dereference _project
      " return eval('g:'.self._project)
    " endfunction
    let menu.idx_crt_value = 0
    let menu.values        = [0, 1]
    let menu.texts         = [' ', 'X']
    call lh#let#if_undef('g:'.menu_def._project.'.tests.list.'.test, 0)
    let menu.variable      = menu_def._project.'.tests.list.'.test
    let menu._root         = menu_def.project().paths.trunk
    let menu._testname     = test
    let menu._testnr       = i
    let menu.set_ctest_argument = function(s:getSNR('SetCTestArgument'))
    function! menu.do_update() dict
      " This part affects a global setting
      let l_tests = self.project().tests.active_list
      let updated = 0
      if self.val_id()
        " add test name
        if match(l_tests, self._testnr) < 0
          let updated = 1
          let l_tests += [self._testnr]
        endif
      else
        " remove test name
        let idx = match(l_tests, self._testnr)
        if idx >= 0
          let updated = 1
          call remove(l_tests, idx)
        endif
      endif
      if updated
        let project = self.project()
        let g:self = self
        let project.tests.active_list = l_tests
      endif
      " This part affects a buffer-local setting => always update
      if s:verbose
        debug call self.set_ctest_argument()
      else
        call self.set_ctest_argument()
      endif
    endfunction
    call lh#btw#project_options#add_toggle_option(menu)

    let i+=1
  endfor
  call lh#common#warning_msg('List of (C)Tests updated: '.len(l_tests).' tests have been found.')
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
  let paths._build = self.project().paths.project.'/'.self.project().build[self.project().compilation.mode]
  let b:BTW_compilation_dir    = paths._build
  " echoerr "Compiling ".expand('%')." in ".b:BTW_compilation_dir
endfunction

" # s:SetProjectExecutable() dict {{{2
function! s:SetProjectExecutable() dict
endfunction

" # s:IndicesListToCTestIArgument() dict {{{2
function! s:IndicesListToCTestIArgument(list)
  " Converts the list of tests to run to a list that CTest will
  " understand
  " -> first test repeated, coma, then list of remaining tests
  let list = sort(a:list)
  let res = ' -I '.list[0].','.list[0]
  let remaining_tests = list[1:]
  if !empty(remaining_tests)
    let res .= ',,'.join(remaining_tests, ',')
  endif
  return res
endfunction

function! s:SetCTestArgument() dict
  " -R have precedence over arguments to -I ; like with ctest
  LetIfUndef b:BTW_project_executable.type 'ctest'
  let test_regex  = self.project().tests.test_regex
  let which       = self.project().tests.active_list
  let checkmem    = self.project().tests.checking_memory
  " call confirm('regex type: '.type(test_regex) . "\nwhich type: ".type(which), '&Ok', 1)
  let b:BTW_project_executable.rule = self.project().tests.verbosity
        \ . (checkmem=='yes' ? (' -D ExperimentalMemCheck') : (''))
  let b:BTW_project_executable.rule
        \ .= (! empty(test_regex)) ? (' -R '.test_regex)
        \  : (! empty(which))      ? s:IndicesListToCTestIArgument(which)
        \  : ''
  call s:Verbose(expand('%').": b:BTW_project_executable.rule <- ".string(b:BTW_project_executable.rule))
endfunction

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

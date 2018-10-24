"=============================================================================
" File:         autoload/lh/btw/old/cmake.vim                     {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/vim-build-tools-wrapper>
" License:      GPLv3 with exceptions
"               <URL:http://github.com/LucHermitte/vim-build-tools-wrapper/blob/master/License.md>
" Version:      0.7.0.
let s:k_version = '070'
" Created:      24th Oct 2018
" Last Update:  24th Oct 2018
"------------------------------------------------------------------------
" Description:
"       Old functions oriented to the definition of CMake based project
"
"------------------------------------------------------------------------
" History:
"       v0.7.0  Old functions moved in autoload/lh/btw/old/cmake.vim
" TODO:         «missing features»
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#btw#old#cmake#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#btw#old#cmake#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Log(expr, ...) abort
  call call('lh#log#this',[a:expr]+a:000)
endfunction

function! s:Verbose(expr, ...) abort
  if s:verbose
    call call('s:Log',[a:expr]+a:000)
  endif
endfunction

function! lh#btw#old#cmake#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1

"------------------------------------------------------------------------
" ## Internal functions {{{1
" # s:getSNR() {{{2
function! s:getSNR(funcname)
  if !exists("s:SNR")
    let s:SNR=matchstr(expand('<sfile>'), '<SNR>\d\+_\zegetSNR$')
  endif
  return s:SNR . a:funcname
endfunction

" # s:function() {{{2
function! s:function(funcname) abort
  return function(s:getSNR(a:funcname))
endfunction

" # s:project() {{{2
function! s:project() dict abort " dereference _project
  return eval('g:'.self._project)
endfunction

" # s:SetCTestArgument() dict {{{2
function! s:SetCTestArgument() dict
  " -R have precedence over arguments to -I ; like with ctest
  LetIfUndef P:BTW.executable.type 'ctest'
  let test_regex  = self.project().tests.test_regex
  let which       = self.project().tests.active_list
  let checkmem    = self.project().tests.checking_memory
  " call confirm('regex type: '.type(test_regex) . "\nwhich type: ".type(which), '&Ok', 1)
  let rule = self.project().tests.verbosity
        \ . (checkmem=='yes' ? (' -D ExperimentalMemCheck') : (''))
  let rule
        \ .= (! empty(test_regex)) ? (' -R '.test_regex)
        \  : (! empty(which))      ? s:IndicesListToCTestIArgument(which)
        \  : ''
  call lh#let#to('P:BTW.executable.rule', rule)
  call s:Verbose('%1: P:BTW.project_executable.rule <- %2', expand('%'), rule)
endfunction

"------------------------------------------------------------------------
" ## Exported functions {{{1
" Function: lh#btw#old#cmake#def_options(config, options) {{{2
" {config} shall contain:
" - menu.priority and menu.name
" - _project settings
"   - paths
"     - trunk           // It's important to tune this variable to distinguish between subprojects
"     - project         // Root path of the project
"     - doxyfile
"     - sources         // This matches all the trunk => complete even with test files
"     - build_root_dir  // Points to the root (/list of root) directory(/ies)
"                       // where build directories are stored. Meant to be used with `auto_detect_compil_modes`.
"     - _build          // Internal, points to the compilation dir used
"                       // to set b:BTW_compilation_dir
"                       TODO: merge into p:BTW.compilation_dir
"     - _clic           // Subpath where clang indexer DB is stored from _build
"                       // defaults to ".clic/index.bd"
"                       TODO: move to paths._clic
"     - clic()          // Returns _build + _clic (by default)
"                       TODO: move to paths.clic()
"   - build
"     - Debug
"     - Release
"                       TODO: move to build.mode.list
"   - compilation (optional)
"     - mode            'Debug' from ['Debug', 'Release'] " matches the subdirs from build/
"                       TODO: move to build.mode.current
"   - tests (all optional)
"     - verbosity       ''   from ['', '-V', '-VV']
"     - checking_memory 'no' from ['no', 'yes']
"     - test_regex      ''
"     - active_list     []
" {options} is the list of lh#btw#old#cmake functions to call
if !exists('s:config')
  let s:config = {}
endif
" @deprecated, use lh#btw#old#cmake#define_options
function! lh#btw#old#cmake#def_options(config, options) abort
  let s:config[a:config._project] = a:config " in case it is required to access other config stuff
  " Set default values
  call lh#let#if_undef('g:'.a:config._project.'.compilation.mode',      'Release')
  call lh#let#if_undef('g:'.a:config._project.'.paths._clic',           '.clic/index.db')
  call lh#let#if_undef('g:'.a:config._project.'.paths.clic',            function('lh#btw#cmake#__get_clic'))
  call lh#let#if_undef('g:'.a:config._project.'.tests.verbosity',       '')
  call lh#let#if_undef('g:'.a:config._project.'.tests.checking_memory', 'no')
  call lh#let#if_undef('g:'.a:config._project.'.tests.test_regex',      '')
  call lh#let#if_undef('g:'.a:config._project.'.tests.active_list',     [])

  " Add all selected options to menu
  for option in a:options
    " deepcopy of menu, shallow copy of _project
    let menu_def = {
          \ 'menu': copy(a:config.menu),
          \ '_project': a:config._project
          \ }
    " save the menu in order to make hooks and other stuff accessible
    if has_key(a:config, option)
      let a:config[option].menu = menu_def.menu
      let a:config[option]._project = menu_def._project
      let menu_def = a:config[option]
    else
      let a:config[option] = menu_def
    endif

    " execute the action to initialize everything
    call lh#btw#old#cmake#{option}(menu_def)
  endfor
endfunction

" Function: lh#btw#old#cmake#auto_detect_compil_modes(menu_def) {{{2
" This function will automaticall fill _config.build dict, AND execute
" def_toggable_compil_mode
function! lh#btw#old#cmake#auto_detect_compil_modes(...) abort
  let menu_def = a:1
  let menu_def.project = s:function('project')
  let project = menu_def.project()
  let paths = project.paths
  " It may be a list of directories actually...
  " but relative to `project`
  let build_root = get(paths, 'build_root_dir', lh#option#unset())
  if lh#option#is_unset(build_root)
    throw "Please set `g:".menu_def._project.".paths.build_root_dir` in order to autodetect compilation modes"
  endif
  let project_root = project.paths.project

  let subs = lh#path#glob_as_list(project_root.'/'.build_root, '*')
  call filter(subs, 'isdirectory(v:val)')
  if empty(subs)
    throw "No subdirectories found in `".build_root."`: cannot deduce compilations modes"
  endif

  " Check directories without Makefiles
  let without_makefile = filter(copy(subs), '! filereadable(v:val."/Makefile")')
  " Check directories without CMakeLists
  let without_cmakecache = filter(copy(subs), '! filereadable(v:val."/CMakeCache.txt")')

  let msg = ''
  if !empty(without_makefile)
    let msg .= "\nThe following build directories have no Makefile: ".join(without_makefile, ', ')
  endif
  if !empty(without_cmakecache)
    let msg .= "\nThe following build directories have no CMakeCache.txt file ".join(without_cmakecache, ', ')
  endif
  if !empty(msg)
    let msg = "Warning:" . msg
    call lh#common#echomsg_multilines(msg)
  endif

  for sub in subs
    call lh#let#if_undef('g:'.menu_def._project.'.build.'.fnamemodify(sub, ':t'), lh#path#strip_start(sub, project_root))
  endfor

  " And finally, prepare everything
  call call('lh#btw#old#cmake#def_toggable_compil_mode', a:000)
endfunction

" Function: lh#btw#old#cmake#def_toggable_compil_mode(menu_def) {{{2
" {menu_def} shall contain:
" - menu.priority and menu.name
" - _project settings
function! lh#btw#old#cmake#def_toggable_compil_mode(menu_def) abort
  function! a:menu_def.project() dict abort " dereference _project
    return eval('g:'.self._project)
  endfunction
  " Automatically set variables for lh#btw#project_options#add_toggle_option,
  " and lh#menu#def_toggle_item
  let a:menu_def.values        = keys(a:menu_def.project().build)
  " "variable" is a variable name, hence _project being a string
  let a:menu_def.variable      = a:menu_def._project.'.compilation.mode'
  let a:menu_def._root         = a:menu_def.project().paths.trunk
  let a:menu_def.menu.priority .= '20'
  let a:menu_def.menu.name     .= 'M&ode'
  " Default (polymorphic) functions for determining the current project
  " executable, and the current compilation directory
  if !has_key(a:menu_def, 'set_project_executable')
    let a:menu_def.set_project_executable = function('lh#btw#cmake#__set_project_executable')
  endif
  if !has_key(a:menu_def, 'update_compil_dir')
    let a:menu_def.update_compil_dir = function('lh#btw#cmake#__update_compil_dir')
  endif
  function! a:menu_def.do_update() dict abort
    " let b:BTW_project_build_mode = self.eval()
    call self.update_compil_dir()
    BTW rebuild
    call self.set_project_executable()
  endfunction
  call lh#btw#project_options#add_toggle_option(a:menu_def)
endfunction

" Function: lh#btw#old#cmake#def_toggable_ctest_verbosity(menu_def) {{{2
" {menu_def} shall contain:
" - menu.priority and menu.name
" - _project settings
function! lh#btw#old#cmake#def_toggable_ctest_verbosity(menu_def) abort
  function! a:menu_def.project() dict abort " dereference _project
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
  " let a:menu_def._root         = a:menu_def.project().paths.trunk
  let a:menu_def.menu.priority .= '30.10'
  let a:menu_def.menu.name     .= 'C&Test.&Verbosity'
  " Default (polymorphic) functions for determining the current project
  " executable, and the current compilation directory
  if !has_key(a:menu_def, 'set_ctest_argument')
    let a:menu_def.set_ctest_argument = s:function('SetCTestArgument')
  endif
  function! a:menu_def.do_update() dict abort
    call self.set_ctest_argument()
  endfunction
  call lh#btw#project_options#add_toggle_option(a:menu_def)
endfunction

" Function: lh#btw#old#cmake#def_ctest_targets(menu_def) {{{2
" {menu_def} shall contain:
" - menu.priority and menu.name
" - _project settings
function! lh#btw#old#cmake#def_ctest_targets(menu_def) abort
  function! a:menu_def.project() dict abort " dereference _project
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
    let a:menu_def.set_ctest_argument = s:function('SetCTestArgument')
  endif
  function! a:menu_def.do_update() dict abort
    call self.set_ctest_argument()
  endfunction
  call lh#btw#project_options#add_string_option(a:menu_def)
endfunction

" Function: lh#btw#old#cmake#def_toggable_ctest_checkmem(menu_def) {{{2
" {menu_def} shall contain:
" - menu.priority and menu.name
" - _project settings
function! lh#btw#old#cmake#def_toggable_ctest_checkmem(menu_def) abort
  function! a:menu_def.project() dict abort " dereference _project
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
    let a:menu_def.set_ctest_argument = s:function('SetCTestArgument')
  endif
  function! a:menu_def.do_update() dict abort
    call self.set_ctest_argument()
  endfunction
  call lh#btw#project_options#add_toggle_option(a:menu_def)
endfunction

" Function: lh#btw#old#cmake#update_list(menu_def) {{{2
function! lh#btw#old#cmake#update_list(menu_def) abort
  if type(a:menu_def) == type({})
    let proj_id = a:menu_def._project
    function! a:menu_def.project() dict " dereference _project
      return eval('g:'.self._project)
    endfunction
  else
    let proj_id = a:menu_def
  endif
  let p = expand('%:p')
  " a:menu_def.project().paths.trunk
  if empty(p) || lh#path#is_in(p, a:menu_def.project().paths.trunk) != 0
    return
  endif

  let menu_def = s:config[proj_id].update_list
  let tests = lh#os#system('cd '.lh#btw#option#_compilation_dir(). ' && ctest -N')
  if type(a:menu_def) == type({})
    " let's say that the first call is an initialization with a dictionary, and
    " that the following calls are made with a string naming the
    " menu_definition to use.
    let menu_def.menu.priority .= '30.900'
    let menu_def.menu.name     .= 'C&Test.&List'
  endif
  silent! exe 'aunmenu! '. menu_def.menu.name
  exe "amenu ".(menu_def.menu.priority).'.89 '.(menu_def.menu.name).'.-<Sep>- Nop '
  exe "amenu <silent> ".(menu_def.menu.priority).'.90 '.(menu_def.menu.name).'.&Update'
        \ .' :call lh#btw#old#cmake#update_list('.string(menu_def._project).')<cr>'

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
    " Initialize to: not active, by default
    let testvar = substitute(test, '\W', '_', 'g')
    call lh#let#if_undef('g:'.menu_def._project.'.tests.list.'.testvar, 0)
    let menu.variable      = menu_def._project.'.tests.list.'.testvar
    let menu._root         = menu_def.project().paths.trunk
    let menu._testname     = test
    let menu._testnr       = i
    let menu.set_ctest_argument = s:function('SetCTestArgument')
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
    let menu = lh#btw#project_options#add_toggle_option(menu)
    " not all keys are updated => force the new _testnr value
    let menu._root         = menu_def.project().paths.trunk
    let menu._testname     = test
    let menu._testnr       = i

    let i+=1
  endfor
  call lh#common#warning_msg('List of (C)Tests updated: '.len(l_tests).' tests have been found.')
endfunction

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

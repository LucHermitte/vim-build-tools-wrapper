"=============================================================================
" File:         autoload/lh/btw/cmake.vim                         {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://github.com/LucHermitte/vim-build-tools-wrapper>
" Version:      0.7.0
let s:k_version = 0700
" Created:      12th Sep 2012
" Last Update:  26th Oct 2018
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
" TODO:
"       * Simplify the definition of the "_project" sub-dictionary as it
"       requires many options.
"       * For multiple tests, we need to use -I <coma-sep-list> and not -R
"       * Get rid of b:BTW_compilation_dir and rely only on
"       b:BTW_project_config._
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#btw#cmake#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#btw#cmake#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Log(expr, ...)
  call call('lh#log#this',[a:expr]+a:000)
endfunction

function! s:Verbose(expr, ...)
  if s:verbose
    call call('s:Log',[a:expr]+a:000)
  endif
endfunction

function! lh#btw#cmake#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1
" Function: lh#btw#cmake#def_options(config, options) {{{2
" @deprecated, use lh#btw#cmake#define_options
function! lh#btw#cmake#def_options(config, options) abort
  return lh#btw#old#cmake#def_options(a:config, a:options)
endfunction

" Function: lh#btw#cmake#define_options(options) {{{2
" @since v0.8.0, deprecates lh#btw#cmake#def_options
" This time, we use p:variables!
function! lh#btw#cmake#define_options(options) abort
  if !lh#project#is_in_a_project()
    throw "lh#btw#cmake#define_options() cannot be used outside projects!"
  endif
  " Set default values
  if 0
    " TODO: don't do it if modes autodetection is required
    call lh#let#if_undef('p:BTW.build.mode.current',      'Release')
  endif
  call lh#let#to('p:BTW.is_using_project', 1)
  call lh#let#if_undef('p:BTW.paths._clic',           '.clic/index.db')
  call lh#let#if_undef('p:BTW.paths.clic',            function('lh#btw#cmake#__get_clic'))
  call lh#let#if_undef('p:BTW.tests.verbosity',       '')
  call lh#let#if_undef('p:BTW.tests.checking_memory', 'no')
  call lh#let#if_undef('p:BTW.tests.test_regex',      '')
  call lh#let#if_undef('p:BTW.tests.active_list',     [])

  " Add all selected options to menu
  for option in a:options
    " save the menu in order to make hooks and other stuff accessible
    let menu_def = lh#let#if_undef('p:BTW.'.option, {})
    call extend(menu_def, copy(lh#option#get('menu')), 'keep')
    " let menu_def.menu = copy(lh#option#get('menu'))
    let menu_def.project = lh#project#crt()
    call lh#assert#true(lh#option#is_set(menu_def.project), 'lh#btw#cmake#define_options requires working with lhvl projects')

    " execute the action to initialize everything
    call lh#btw#cmake#{option}(menu_def)
  endfor

  call lh#btw#cmake#_add_menus()
endfunction

" Function: lh#btw#cmake#_build_root_dir() {{{3
function! lh#btw#cmake#_build_root_dir() abort
  " It may be a list of directories actually...
  " but relative to `project`
  let build_root = lh#option#get('paths.build_root_dir', lh#option#unset(), 'p')
  if lh#option#is_unset(build_root)
    throw "Please set `p:paths.build_root_dir` in order to prepare compilation modes."
  endif
  " Path to which every build diretory is relative
  let project_root = lh#option#get('paths.project')
  if lh#option#is_unset(project_root)
    throw "Please set `p:paths.project` to project root directory (that contains sources and build directories)"
  endif
  let build_root_path = project_root.'/'.build_root
  return build_root_path
endfunction

" Function: lh#btw#cmake#auto_detect_compil_modes(menu_def) {{{2
" This function will automaticall fill p:BTW.build.mode.list dict, AND execute
" def_toggable_compil_mode
function! lh#btw#cmake#auto_detect_compil_modes(menu_def) abort
  " It may be a list of directories actually...
  " but relative to `project`
  let build_root = lh#option#get('paths.build_root_dir', lh#option#unset(), 'p')
  if lh#option#is_unset(build_root)
    throw "Please set `p:paths.build_root_dir` in order to autodetect compilation modes."
  endif
  " Path to which every build directory is relative
  let project_root = a:menu_def.project.get('paths.project')
  if lh#option#is_unset(project_root)
    throw "Please set `p:paths.project` to project root directory (that contains sources and build directories)"
  endif
  let build_root_path = project_root.'/'.build_root

  let subs = lh#path#glob_as_list(build_root_path, '*')
  call filter(subs, 'isdirectory(v:val)')
  let g:subs = subs
  if empty(subs)
    call lh#common#warning_msg("No build directories detected in `".build_root."`.\nCompilation won't be possible for now.")
    return
    " throw "No subdirectories found in `".build_root."`: cannot deduce compilations modes"
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

  let list = lh#let#if_undef('p:BTW.build.mode.list', {})
  for sub in subs
    " In case the {sub}  contains a dot => don't interpret it as a new subkey
    let list[fnamemodify(sub, ':t')] = lh#path#strip_start(sub, project_root)
  endfor

  " And finally, prepare everything
  call lh#btw#cmake#def_toggable_compil_mode(a:menu_def)
endfunction

" Function: lh#btw#cmake#def_toggable_compil_mode(menu_def) {{{2
" {menu_def} shall contain:
" - menu.priority and menu.name
" - _project settings
function! lh#btw#cmake#def_toggable_compil_mode(menu_def) abort
  " Automatically set variables for lh#btw#project_options#add_toggle_option,
  " and lh#menu#def_toggle_item
  call lh#assert#true(has_key(a:menu_def, 'project'))
  let menu_def = lh#let#if_undef('p:BTW._menu.compil_mode', lh#object#make_top_type({}))
  let menu_def.values         = keys(lh#option#get('BTW.build.mode.list'))
  " "variable" is a variable name, hence _project being a string
  let menu_def.variable       = lh#ref#bind(a:menu_def.project.variables, 'BTW.build.mode.current')
        \.print_with_fmt('p('.(a:menu_def.project.name).'):%{1.key}')
  let menu_def._root          = lh#option#get('paths.sources')
  if ! has_key(menu_def, 'menu')
    call extend(menu_def, a:menu_def, 'keep')
    let menu_def.menu.priority .= '20'
    let menu_def.menu.name     .= 'M&ode'
  endif
  " Default (polymorphic) functions for determining the current project
  " executable, and the current compilation directory
  let menu_def.set_project_executable = function('lh#btw#cmake#__set_project_executable')
  let menu_def.update_compil_dir      = function('lh#btw#cmake#__update_compil_dir')
  function! menu_def.do_update() dict abort
    call self.update_compil_dir()
    " Only the directory changes. No need to update everything w/ `BTW rebuild`
    call lh#btw#chain#_resolve_makeprg(self.project)
    call self.set_project_executable()
  endfunction
  call lh#btw#project_options#add_toggle_option(menu_def)
endfunction

" Function: lh#btw#cmake#def_toggable_ctest_verbosity(menu_def) {{{2
" {menu_def} shall contain:
" - menu.priority and menu.name
" - _project settings
function! lh#btw#cmake#def_toggable_ctest_verbosity(menu_def) abort
  " Automatically set variables for lh#btw#project_options#add_toggle_option,
  " and lh#menu#def_toggle_item
  let menu_def = lh#let#if_undef('p:BTW._menu.ctest.verbosity', lh#object#make_top_type({}))

  let menu_def.values        = ['', '-V', '-VV']
  " "variable" is a variable name, hence _project being a string
  let menu_def.variable      = lh#ref#bind(a:menu_def.project.variables, 'BTW.tests.verbosity')
  let menu_def._root         = lh#option#get('paths.sources')
  if ! has_key(menu_def, 'menu')
    call extend(menu_def, a:menu_def, 'keep')
    let menu_def.menu.priority .= '30.10'
    let menu_def.menu.name     .= 'C&Test.&Verbosity'
  endif
  " Default (polymorphic) functions for determining the current project
  " executable, and the current compilation directory
  if !has_key(menu_def, 'set_ctest_argument')
    let menu_def.set_ctest_argument = s:function('SetCTestArgument')
  endif
  function! menu_def.do_update() dict abort
    call self.set_ctest_argument()
  endfunction
  call lh#btw#project_options#add_toggle_option(menu_def)
endfunction

" Function: lh#btw#cmake#def_ctest_targets(menu_def) {{{2
" {menu_def} shall contain:
" - menu.priority and menu.name
" - _project settings
function! lh#btw#cmake#def_ctest_targets(menu_def) abort
  " Automatically set variables for lh#btw#project_options#add_toggle_option,
  " and lh#menu#def_toggle_item
  let menu_def = lh#let#if_undef('p:BTW._menu.ctest.target', lh#object#make_top_type({}))
  let menu_def.values        = ''
  " "variable" is a variable name, hence _project being a string
  " LetIfUndef p:BTW.tests.test_regex = ''
  let menu_def.variable      = lh#ref#bind(a:menu_def.project.variables, 'BTW.tests.test_regex')
  let menu_def._root         = lh#option#get('paths.sources')
  if ! has_key(menu_def, 'menu')
    call extend(menu_def, a:menu_def, 'keep')
    let menu_def.menu.priority .= '30.20'
    let menu_def.menu.name     .= 'C&Test.&Target Test(s)'
  endif
  " Default (polymorphic) functions for determining the current project
  " executable, and the current compilation directory
  if !has_key(menu_def, 'set_ctest_argument')
    let menu_def.set_ctest_argument = s:function('SetCTestArgument')
  endif
  function! menu_def.do_update() dict abort
    call self.set_ctest_argument()
  endfunction
  call lh#btw#project_options#add_string_option(menu_def)
endfunction

" Function: lh#btw#cmake#def_toggable_ctest_checkmem(menu_def) {{{2
" {menu_def} shall contain:
" - menu.priority and menu.name
" - _project settings
function! lh#btw#cmake#def_toggable_ctest_checkmem(menu_def) abort
  " Automatically set variables for lh#btw#project_options#add_toggle_option,
  " and lh#menu#def_toggle_item
  let menu_def = lh#let#if_undef('p:BTW._menu.ctest.checkmem', lh#object#make_top_type({}))
  " let menu_def.idx_crt_value = 0
  let menu_def.values        = ['no', 'yes']
  " "variable" is a variable name, hence _project being a string
  let menu_def.variable      = lh#ref#bind(a:menu_def.project.variables, 'BTW.tests.checking_memory')
  " TODO: This is not just 'p:' & all, but a very specific variable in the
  " project scope
  let menu_def._root         = lh#option#get('paths.sources')
  if ! has_key(menu_def, 'menu')
    call extend(menu_def, a:menu_def, 'keep')
    let menu_def.menu.priority .= '30.30'
    let menu_def.menu.name     .= 'C&Test.Check &Memory'
  endif
  " Default (polymorphic) functions for determining the current project
  " executable, and the current compilation directory
  if !has_key(menu_def, 'set_ctest_argument')
    let menu_def.set_ctest_argument = s:function('SetCTestArgument')
  endif
  function! menu_def.do_update() dict abort
    call self.set_ctest_argument()
  endfunction
  call lh#btw#project_options#add_toggle_option(menu_def)
endfunction

" Function: lh#btw#cmake#add_gen_clic_DB(menu_def) {{{2
" {menu_def} shall contain:
" - menu.priority and menu.name
" - _project settings
function! lh#btw#cmake#add_gen_clic_DB(menu_def)
  " let a:menu_def.menu.priority .= '90'
  " let a:menu_def.menu.name     .= '&Update\ Clang\ Complete\ compilation\ settings'
  " silent! exe 'aunmenu! '. a:menu_def.menu.name
  " exe "amenu ".(a:menu_def.menu.priority).'.89 '.(a:menu_def.menu.name).'.-<Sep>- Nop '
  call lh#menu#make('nic',
        \ a:menu_def.menu.priority.'90', a:menu_def.menu.name.'Update Clang &Complete compilation settings',
        \ '<localleader>tc', '', ':call lh#btw#cmake#_gen_clang_complete()<cr>' )
  call lh#menu#make('nic',
        \ a:menu_def.menu.priority.'91', a:menu_def.menu.name.'Update Code &Index Base',
        \ '<localleader>ti', '', ':call clang#update_clic('.string(a:menu_def._project).')<cr>' )
endfunction

" Function: lh#btw#cmake#_add_menus() {{{2
function! lh#btw#cmake#_add_menus() abort
  call lh#project#menu#make('nic', '11', 'Edit local &CMake file', '<localleader><F7>', '<buffer>', ':call lh#project#crt().get("BTW.config.functions").EditLocalCMakeFile()<cr>')
  call lh#project#menu#make('nic', '12', 'Edit local &CMake file (vertical)', '<localleader>v<F7>', '<buffer>', ':call lh#project#crt().get("BTW.config.functions").EditLocalCMakeFile("vert")<cr>')
endfunction

" Function: lh#btw#cmake#bootstrap() {{{3
function! lh#btw#cmake#bootstrap() abort
  let compil_mode = lh#option#get('BTW.build.mode.current')
  call s:Verbose("bootstrapping CMake for compil_mode: %1", compil_mode)
  if lh#option#is_unset(compil_mode)
    call lh#common#error_msg('(bpg):BTW.build.mode.current is not set. Impossible to bootstrap cmake')
    return 0
  endif
  let
  let compil_subpath = lh#option#get('BTW.build.mode.list['.compil_mode.']')
  call lh#assert#type(compil_subpath).is('')
  let project_dir = lh#option#get('paths.project')
  call lh#assert#type(project_dir).is('')
  call s:Verbose("Use compilation dir: '%1/%2'", project_dir, compil_subpath)
  let dir = project_dir.'/'.compil_subpath

  let opts = lh#option#get('BTW.build.mode.bootstrap['.compil_mode.']')
  if lh#option#is_unset(opts)
    call lh#common#error_msg('BTW.build.mode.bootstrap['.compil_mode.'] is not set. Impossible to bootstrap cmake for '.compil_mode.' mode.')
    return 0
  endif

  let config = lh#let#to('p:BTW.project_config')
  call lh#assert#value(config).is_set()
  return config.do_bootstrap(dir, opts)
endfunction

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

" # lh#btw#cmake#__update_compil_dir() dict {{{2
function! lh#btw#cmake#__update_compil_dir() dict
  call s:Verbose("Updating compil dir in buffer %1 (%2) -- prj: %2",bufnr('%'), bufname('%'), get(self.project, 'name', '(none)'))
  " "let self.project().paths = value" is refused by viml interpreter => hence
  " the auxiliary reference
  if has_key(self, 'project') && (type(self.project) == type(function('has')))
    let paths = self.project().paths
    let dir = paths.project.'/'.self.project().build[self.project().compilation.mode]
    let paths._build = dir
    call lh#let#to('b:BTW.compilation_dir', dir)
  else
    let compil_mode = self.project.get('BTW.build.mode.current') " variable
    call s:Verbose("New compil_mode: %1", compil_mode)
    call lh#assert#true(lh#option#is_set(compil_mode))
    let project_dir = self.project.get('paths.project')
    call lh#assert#type(project_dir).is('')
    let compil_subpath = self.project.get('BTW.build.mode.list['.compil_mode.']')
    call lh#assert#type(compil_subpath).is('')
    call s:Verbose("Set compilation dir to %1/%2", project_dir, compil_subpath)
    let dir = project_dir.'/'.compil_subpath
    " call lh#let#to('p:paths._build', dir)
    call self.project.set('BTW.compilation_dir', dir)
  endif
  " echoerr "Compiling ".expand('%')." in ".lh#btw#option#_compilation_dir()
  if has_key(self, '_update_compil_dir_hook')
    " Can be used to update things like LD_LIBRARY_PATH, ...
    call self._update_compil_dir_hook()
  endif
endfunction

" # lh#btw#cmake#__get_clic() dict {{{2
function! lh#btw#cmake#__get_clic() dict
  return self._build . '/' . self._clic
endfunction

" # lh#btw#cmake#__set_project_executable() dict {{{2
" TODO: Check why I no longer do anything here...
function! lh#btw#cmake#__set_project_executable() dict
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

" # s:SetCTestArgument() dict {{{2
function! s:SetCTestArgument() dict
  " -R have precedence over arguments to -I ; like with ctest
  LetIfUndef p:BTW.executable.type 'ctest'
  let test_regex  = self.project.get('BTW.tests.test_regex')
  let which       = self.project.get('BTW.tests.active_list')
  let checkmem    = self.project.get('BTW.tests.checking_memory')
  " call confirm('regex type: '.type(test_regex) . "\nwhich type: ".type(which), '&Ok', 1)
  let rule = self.project.get('BTW.tests.verbosity')
        \ . (checkmem=='yes' ? (' -D ExperimentalMemCheck') : (''))
  let rule
        \ .= (! empty(test_regex)) ? (' -R '.test_regex)
        \  : (! empty(which))      ? s:IndicesListToCTestIArgument(which)
        \  : ''
  call self.project.set('BTW.executable.rule', rule)
  call s:Verbose('%1: p:BTW.executable.rule <- %2', expand('%'), rule)
endfunction

" Function: lh#btw#cmake#_gen_clang_complete() {{{2
function! lh#btw#cmake#_gen_clang_complete()
  let cmd = 'cd '.lh#btw#option#_compilation_dir(). ' && cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=ON .'
  let res = lh#os#system(cmd)
  if v:shell_error != 0
    call lh#common#error_msg("Cannot execute ``".cmd."'': ".res)
    return
  endif
  let filename = lh#btw#option#_compilation_dir().'/compile_commands.json'
  if !file_readable(filename)
    call lh#common#error_msg(filename ." hasn't been generated by ``".cmd."''")
    return
  endif
  let json = join(readfile(filename), "")
  let data = json_encoding#Decode(json) " from vim-addon-json-encoding
  let merged_options = {}
  for file in data
    let options = ''
    let file_options = split(file.command)
    let use_next = 0
    for option in file_options
      if use_next
        let options .= option.' '
        let use_next = 0
      elseif option =~ '^-[DI]\|^-std\|-no' " first draft
        let options .= option.' '
      elseif option =~ '^-i'
        let options .= option.' '
        let use_next = 1
      endif
    endfor
    for option in split(options, '\s\+\zs\ze-')
      if !empty(option)
        let merged_options[option] = '1'
      endif
    endfor
  endfor
  let clang_complete_path = lh#btw#option#_compilation_dir().'/.clang_complete'
  if filewritable( clang_complete_path)
    call writefile(keys(merged_options), clang_complete_path)
    call lh#common#warning_msg(lh#btw#option#_compilation_dir().'/.clang_complete updated.')
  else
    call lh#common#error_msg("[BTW] Cannot write to ". clang_complete_path)
  endif
endfunction

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

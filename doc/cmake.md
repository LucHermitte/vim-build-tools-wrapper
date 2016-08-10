# Introduction

BTW is able to support CMake based projects and to handle multiple builds.


  * [Features](#features)
    * [Multiple builds](#multiple-builds)
    * [CTest support](#ctest-support)
      * [Verbosity](#verbosity)
      * [Memory checking](#memory-checking)
      * [Test selection](#test-selection)
    * [Code database (experimental)](#code-database-experimental)
    * [UI](#ui)
      * [With menus](#with-menus)
      * [With commands](#with-commands)
        * [`:Toggle`](#toggle)
        * [`:Set`](#set)
    * [Project information](#project-information)
      * [`_config`](#_config)
      * [`_config_menu`](#_config_menu)
  * [Configuration](#configuration)
    * [How to organize a project?](#how-to-organize-a-project)
    * [Project files](#project-files)
      * [Simple projects](#simple-projects)
        * [`_vimrc_local_global_defs.vim`](#_vimrc_local_global_defsvim)
        * [`_vimrc_local.vim`](#_vimrc_localvim)
      * [Projects with modules](#projects-with-modules)
        * [`_vimrc_local_global_defs.vim`](#_vimrc_local_global_defsvim)
        * [`_vimrc_local.vim`](#_vimrc_localvim)

# Features

## Multiple builds

As you know, the right way to build a CMake based project is to create a new
directory somewhere, run `ccmake path/to/sources`, ajust the options (paths to
3rd party libraries, Testing ON/OFF, Build Mode, Compiling Options, etc.), and
then compile.

With BTW, we can register any compilation directory (where `ccmake` has already
ran) as a _build mode_. Actually this is not restricted to CMake based
project as long as compilation is done ouside the sources directory.

For now, build _modes_ have to be registered manually. This is likelly to
improve in the future.

## CTest support
BTW can run CTest tests and import their result into the quickfix-window.

### Verbosity
Test verbosity can be set (nothing, `-V`, or `-VV`)

### Memory checking
Tests can be run through valgrind

### Test selection
Either all tests (default), or tests matching a regex, or selected tests
(bugged feature) can [be run on `CTRL-F5`](make_run.md#execute).

## Code database (experimental)
BTW can maintain the path to the code database, and it can trigger the update
of the code database.

By code database, I mean
[clang-indexer](http://github.com/LucHermitte/clang-indexer) wrapped by
[vim-clang](http://github.com/LucHermitte/vim-clang). Note: this feature is
extremly experimental.

## UI
Once a project configured, BTW permits to change the project build mode, tests
verbosity, etc.

This can be done through several ways.

### With menus
Their use should be quite explicit. You'll found everything under `Project` ->
_YourProjectName_ -- as long as you're using gvim instead of vim and that you
haven't disabled the menu.

### With commands

#### `:Toggle`
The value of toggable options can be changed thanks to
```
:Toggle {OptionName} [{NewOptionValue}]
```

The option name is generated automatically from the complete path of the menu
item. For instance, given your project is named `FooBar`

| ...to change the option | ... type the command                   |
|-------------------------|----------------------------------------|
| Compilation mode        | `:Toggle ProjectFooBarMode`            |
| Test verbosity          | `:Toggle ProjectFooBarCTestVerbosity`  |
| Use valgrind            | `:Toggle ProjectFooBarCTestCheckMemory`|


__Warning:__ do not try to find the global variables associated to these
options and change them directly. Otherwise hooks that maintain compilation
directories, and so on, won't be triggerred.

#### `:Set`
The value of other options can be changed thanks to
```
:Set {OptionName} {OptionValue}
```

Again, the option name is generated from the complete path of the menu item.
For instance, given your project is named `FooBar`

| ...to change the option   | ... type the command                   |
|---------------------------|----------------------------------------|
| Tests to execute  (regex) | `:Set ProjectFooBarCTestTargetTests`   |

__Note:__ this time you can change the associated global variable directly (if
you find it :p). `:Set` is just a helper command that supports command-line
completion.

## Project information

Various information about the current project can be obtained. Some are set by
you when you configure the project, other are maintained up to date after each
modification (current build mode, build path, installation path (if you like), selected tests, ...)

The entry points are:
 * `g:`_ProjectName_`_config`
 * `g:`_ProjectName_`_config_menu`

They contain:

### `_config`
 * `name`: project name
 * `paths`:
    * `project`: Root path of the project
    * `trunk`: Where the sources are -- important to tune to distinguish
      between subprojects
    * `sources`: this matches all the trunk => complete even with test files
    * `build_root_dir`: points to the root (/list of root) directory(/ies)
      where build directories are stored. Meant to be used with `auto_detect_compil_modes`.
      This option is relative to `paths.project` key. 
    * `doxyfile`: where the doxyfile is
    * `_build`: internal, points to the current compilation directory at any
      time
    * `_clic`: subpath from `_build` that tells where clang-indexer DB is
      stored
    * `clic()`: Returns `_build` + `_clic` (by default)
 * `build`: path relative from `paths.project` -- the following are not
   mandatory, any name, and any number of modes can be used.  
   Filling this key is not mandatory. Instead we can fill
   `paths.build_root_dir` and use `auto_detect_compil_modes`.
    * `Debug`:  tells where to find the debug mode directory
    * `Release`: tells where to find the release mode directory
    *  ...
 * `compilation`
    *  `mode`: The current compilation mode: any name from `build`
 * `tests`
    * `verbosity`: any string from `''` (default), `'-V'`, and `'-VV'`
    * `checking_memory`: any string from `'no'` (default) and `'yes'`
    * `test_regex`: regex passed to `ctest -R`
    * `active_list`: `[]` test numbers to pass to `ctest -I`
 * `functions`: dictionary of {_FunctionName_: function reference (obtained
   from `function()`) }

### `_config_menu`

 * `_project`: name (without the scope) of the previous variable, for instance
   `'foobar_config'`.
 * `project()`: return a reference to the previous variable
 * `menu`: `{'priority': value, 'name': menu-name}`

Other information will be stored in:

 * `def_toggable_compil_mode`: which is useful to set
    * `update_compil_dir`
    * `_update_compil_dir_hook`: hook that is called (if defined), from the
      previous hook, everytime the compilation mode is updated (it can be used
      to change the `$LD_LIBRARY_PATH`, to update a new `path._install`
      directory, ...) and let the default behaviour update the compilation
      directory.
    * `set_project_executable`
 * `def_toggable_test_verbosity`
    * variable name can be a `$something`
 * `set_ctest_argument`

# Configuration

## How to organize a project?

Usually I organize a project this way:

```
$HOME/dev/
    +-> ProjectName/
        +-> sources/
        +-> build/
            +-> debug/
            +-> release/
            +-> reldeb/
            +-> sanitize/
        +-> install/
            +-> debug/
            +-> release/
            ...
```
I store in `sources/` the root `CMakeLists.txt` file (when I have one/when it
makes sense), and all project configuration files `_vimrc_local.vim`,
`_vimrc_local_global_defs.vim` and `_vimrc_cpp_style`.

Sometimes, a project can have different modules like a core library, and 42
executables. For each module, I like to have a dedicated subdirectory in all
the leaf directories presented above. When I can have a same set of project
configuration files, for all modules or a group of related things (like ITK
and OTB when I'm working on them), I do it.

## Project files
I generate automatically the project files with `:BTW new_project`.

I usually start a new C++ project with:
```
:BTW new_project cpp cmake name=ProjectName config=project_name -src_dir=/./
```

After a few questions from the wizard, I finish to tune the project options.

### Simple projects

In this project, `.h`, `.hxx`, `.txx`, and `.cxx` extension may be used

#### `_vimrc_local_global_defs.vim`
```vim
let s:cpo_save=&cpo
set cpo&vim

" ======================[ Global project configuration {{{2
let s:sources_dir = '.'

" echo expand("<sfile>:p:h")
" unlet g:project_name_config
" Mandatory Project options
call lh#let#if_undef('g:project_name_config.paths.trunk', string(expand("<sfile>:p:h")))
LetIfUndef g:project_name_config.name                       'project_name'
LetIfUndef g:project_name_config.paths.project    fnamemodify(g:project_name_config.paths.trunk,':h:h')
LetIfUndef g:project_name_config.paths.doxyfile   g:project_name_config.paths.project
" Note: this could be anything like: MyProject_config.build.ARM-release

" Two options to Fill the build Modes:
" *  Option 1: manually
LetIfUndef g:project_name_config.build.Debug                  'build/debug'
LetIfUndef g:project_name_config.build.Release                'build/release'
LetIfUndef g:project_name_config.build.ReleaseWithDebugInfo   'build/reldeb'
LetIfUndef g:project_name_config.build.Sanitize               'build/sanitize'
" * Option 2: automatically
LetIfUndef g:project_name_config.paths.build_root_dir         'build'

" Stuff that I've added
LetIfUndef g:project_name_config.install.Debug                'install/debug'
LetIfUndef g:project_name_config.install.Release              'install/release'
LetIfUndef g:project_name_config.install.ReleaseWithDebugInfo 'install/reldeb'
LetIfUndef g:project_name_config.install.Sanitize             'install/sanitize'

" Here, this matches all the trunk => complete even with test files
LetIfUndef g:project_name_config.paths.sources    (g:project_name_config.paths.project).'/src'
" Optional Project options
LetIfUndef g:project_name_config.compilation.mode 'ReleaseWithDebugInfo'
LetIfUndef g:project_name_config.tests.verbosity '-VV'

" ======================[ Menus {{{2
let s:menu_priority = '50.120.'
let s:menu_name     = '&Project.&ProjectName'

" Function: s:getSNR([func_name]) {{{3
function! s:getSNR(...)
  if !exists("s:SNR")
    let s:SNR=matchstr(expand('<sfile>'), '<SNR>\d\+_\zegetSNR$')
  endif
  return s:SNR . (a:0>0 ? (a:1) : '')
endfunction

" Function: s:EditLocalCMakeFile() {{{3
function! s:EditLocalCMakeFile(...)
  let where = a:0==0 ? '' : a:1.' '
  let file = lh#path#to_relative(expand('%:p:h').'/CMakeLists.txt')
  call lh#buffer#jump(file, where.'sp')
endfunction

call lh#let#if_undef ('g:project_name_config.functions',
      \ string({'EditLocalCMakeFile': function(s:getSNR('EditLocalCMakeFile'))}))

"------------------------------------------------------------------------
" ======================[ Compilation mode, & CTest options {{{2
" Another thing that I've added: in this project,
" LD_LIBRARY_PATH needs to be tune for each compilation mode.
let s:save_LD_LIBRARY_PATH = $LD_LIBRARY_PATH
function! s:_update_compil_dir_hook() dict abort
  let prj = self.project()
  let build_mode = prj.compilation.mode
  let paths = prj.paths
  let paths._install = paths.project.'/'.prj.install[build_mode]
  let base = paths._install . '/3rdparty'
  let $LD_LIBRARY_PATH =
        \        base.'/hdf/lib'
        \. ':' . base.'/libxml2/lib'
        \. ':' . base.'/expat/lib'
        \. ':' . base.'/openjpeg/lib'
        \. ':' . base.'/gdal/lib'
        \. ':' . base.'/itk/lib'
        \. ':' . base.'/otb/lib/otb'
        \. ':' . s:save_LD_LIBRARY_PATH
endfunction

let g:project_name_config_menu = {
      \ '_project': 'project_name_config',
      \ 'menu': {'priority': s:menu_priority, 'name': s:menu_name},
      \ 'def_toggable_compil_mode': { '_update_compil_dir_hook': function(s:getSNR('_update_compil_dir_hook'))}
      \ }

let s:cmake_integration = []
" Back to adding compilation modes
let s:cmake_integration += [ 'def_toggable_compil_mode' ] " Option 1
" or
let s:cmake_integration += [ 'auto_detect_compil_modes' ] " Option 2
let s:cmake_integration += [ 'def_toggable_ctest_verbosity' ]
let s:cmake_integration += [ 'def_toggable_ctest_checkmem' ]
let s:cmake_integration += [ 'def_ctest_targets' ]
let s:cmake_integration += [ 'add_gen_clic_DB' ]
let s:cmake_integration += [ 'update_list' ]
call lh#btw#cmake#def_options(g:project_name_config_menu, s:cmake_integration)

" ======================[ Misc functions {{{2

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
```

#### `_vimrc_local.vim`
```vim
" Always loaded {{{1

" Alternate configuration {{{2
" .h and .cpp are in the same directory
let g:alternateSearchPath = 'sfr:.'
let g:alternateExtensions_txx = "hxx,h"
let g:alternateExtensions_hxx = "txx,cxx"

" Buffer-local Definitions {{{1
" Avoid local reinclusion {{{2
if &cp || (exists("b:loaded__vimrc_local")
      \ && (b:loaded__vimrc_local >= s:k_version)
      \ && !exists('g:force_reload__vimrc_local'))
  finish
endif
let b:loaded__vimrc_local = s:k_version
let s:cpo_save=&cpo
set cpo&vim
" Avoid local reinclusion }}}2

let s:script = expand("<sfile>:p")

" ======================[ Project config {{{2
if ! (exists("g:loaded__vimrc_local")
      \ && (g:loaded__vimrc_local >= s:k_version)
      \ && !exists('g:force_reload__vimrc_local'))
  source <sfile>:p:h/_vimrc_local_global_defs.vim
endif

" ======================[ &path {{{2
" don't search into included file how to complete
setlocal complete-=i

" Tells BTW the compilation directory
let b:BTW_compilation_dir = g:project_name_config.paths._build
" Local vimrc variable for source dir
let b:project_sources_dir = g:project_name_config.paths.sources
" Option for Mu-Template-> |s:path_from_root()|
let b:sources_root = g:project_name_config.paths.sources

" Used by mu-template to generate file headers and header-gates.
let b:cpp_included_paths = [b:project_sources_dir]
" If the project has .h.in files that are generated in the build
" directory, uncomment the next line
" let b:cpp_included_paths += [b:BTW_compilation_dir]

" Configures lh-cpp complete includes sub-plugin -> ftplugin/c/c_AddInclude.vim
let b:includes = [ b:project_sources_dir . '/**']
" For config.h.in files and alike
" todo: adapt it automatically to the current compilation dir
let b:includes += [b:BTW_compilation_dir . '/**']
" Add your 3rd party libraries used in the project here
call lh#path#add_path_if_exists('b:includes', '/home/lhermitte/dev/boost/1_51_0/install/include/')
call lh#path#add_path_if_exists('b:includes', '/usr/local/include/**')
call lh#path#add_path_if_exists('b:includes', '/usr/include/**')

" Fetch INCLUDED paths from cmake cache configuration, and merge every thing
" into b:includes
try
  let included_paths = lh#cmake#get_variables('INCLUDE')
  call filter(included_paths, 'v:val.value!~"NOTFOUND"')
  let uniq_included = {}
  silent! unlet incl
  for incl in values(included_paths)
    let uniq_included[incl.value] = 1
  endfor
  silent! unlet incl
  for incl in b:includes
    let uniq_included[incl] = 1
  endfor
  let b:includes = keys(uniq_included)
catch /.*/
  call lh#common#warning_msg(v:exception)
endtry

" Setting &path
exe 'set path+='.lh#path#fix(b:BTW_compilation_dir).'/**'
" If the project has .h.in files that are generated in the build
" directory, uncomment the next line
exe 'setlocal path+='.lh#path#fix(b:project_sources_dir).'/**'
for p in b:includes
  if p !~ '^/usr'
    exe 'setlocal path+='.lh#path#fix(p)
  endif
endfor

" ======================[ tags generation {{{2
let b:tags_dirname = lh#path#fix(b:project_sources_dir)
let b:tags_options = ' --exclude="*.dox" --exclude="html" --exclude="*.xml" --exclude="*.xsd" --exclude=".*sw*"'
let b:tags_options .= ' --exclude="*.txt" --exclude="cmake" --exclude="*.cmake" --exclude="*.o" --exclude="*.os" --exclude="*.tags" --exclude=tags --exclude=buttons --exclude="*.png" --exclude="*.tar"'
let b:tags_options .= ' --exclude="ref" --exclude="*.bin" --exclude="*.lum"'
let b:tags_options .= ' --exclude="Data" --exclude="*.dat" --exclude="*.tif" --exclude="*.ttf"'
exe 'setlocal tags+='.(b:tags_dirname).'/tags'
" You'll have to generate thoses files for your system...
let &l:tags=lh#path#munge(&l:tags, $HOME.'/dev/tags/stl.tags')
let &l:tags=lh#path#munge(&l:tags, $HOME.'/dev/tags/boost.tags')
" let BTW_make_in_background_in = 'xterm -e'

" ======================[ Settings for compil_hints {{{2
let b:compil_hints_autostart = 1

" ======================[ Settings for BTW {{{2
if SystemDetected() == 'msdos'
  :BTW setlocal cmake
  " echomsg SystemDetected()
  if SystemDetected() == 'unix' " cygwin
    " then cygwin's cmake does not work -> use win32 cmake
    let $PATH=substitute($PATH, '\(.*\);\([^;]*CMake[^;]*\)', '\2;\1', '')
    BTW addlocal cygwin
  endif
endif
:BTW addlocal STLFilt

" silent! unlet b:BTW_project_executable
LetIfUndef b:BTW_project_executable.type 'ctest'
" sets b:BTW_project_executable.rule
call g:project_name_config_menu.def_ctest_targets.set_ctest_argument()

let b:BTW_project_target = ''
let b:BTW_project_config = {
      \ 'type': 'ccmake',
      \ 'arg': (b:project_sources_dir),
      \ 'wd' : lh#function#bind('b:BTW_compilation_dir'),
      \ '_'  : g:project_name_config
      \ }

" ======================[ Project's style {{{2
silent! source <sfile>:p:h/_vimrc_cpp_style.vim
let b:ProjectVersion        = '4.2'
let b:cpp_project_namespace = 'project_namespace'
" Where templates related to the project will be stored. You'll have to
" adjust the number of ':h', -> :h expand()
let b:mt_templates_paths = fnamemodify(b:project_sources_dir, ":h").'/templates'
let b:exception_type = b:cpp_project_namespace.'::Exception'
silent! unlet b:exception_args
" let b:exception_args = 'v:1_.'.string(lh#marker#txt(', '.b:cpp_project_namespace.'::ExitCode::'))
let b:exception_args = lh#marker#txt('text')
let b:project_name_version = '4.2'
if expand('%:p') =~ b:project_sources_dir.'/Testing'
  let b:project_name_dox_group = 'gTests'
  let b:is_unit_test = 1
endif

" ======================[ Settings for searchfile and gf {{{2
let b:searchfile_ext = 'h,H,C,cpp,cxx,hxx,txx'
setlocal suffixesadd+=.h,.H,.C,.cpp,.cxx,.hxx,.txx'

" ======================[ Menus {{{2
call lh#menu#make('nic', '50.11', '&Project.Edit local &CMake file', '<localleader><F7>', '<buffer>', ':call g:project_name_config.functions.EditLocalCMakeFile()<cr>')
call lh#menu#make('nic', '50.12', '&Project.Edit local &CMake file (vertical)', '<localleader>v<F7>', '<buffer>', ':call g:project_name_config.functions.EditLocalCMakeFile("vert")<cr>')
call lh#menu#make('nic', '50.76', '&Project.Edit local &vimrc', '<localleader>le', '<buffer>', ':call lh#buffer#jump('.string(s:script).', "sp")<cr>' )

" ======================[ Local variables to automagically import in QuickFix buffer {{{2
QFImport tags_select
QFImport &path
QFImport BTW_project_target
QFImport BTW_compilation_dir
QFImport BTW_project_config
QFImport includes

" ======================[ Other commands {{{2
command! -b -nargs=* LVEcho echo <sid>Echo(<args>)

"=============================================================================
" Global Definitions {{{1
" Avoid global reinclusion {{{2
if &cp || (exists("g:loaded__project_name_src_vimrc_local")
      \ && (g:loaded__MILO1_luc_dev_project_name_benchs_src_vimrc_local >= s:k_version)
      \ && !exists('g:force_reload__MILO1_luc_dev_project_name_benchs_src_vimrc_local'))
  let &cpo=s:cpo_save
  finish
endif
let g:loaded__vimrc_local = s:k_version
" Avoid global reinclusion }}}2
"------------------------------------------------------------------------

" ======================[ YCM {{{2
" let g:ycm_extra_conf_vim_data = ['b:BTW_compilation_dir']
" at this point, btw shall have already been loaded
let g:ycm_extra_conf_vim_data = ['lh#btw#compilation_dir()']
if !exists('g:ycm_extra_conf_globlist')
    let g:ycm_extra_conf_globlist = []
endif
call lh#path#munge(g:ycm_extra_conf_globlist, fnamemodify(b:project_sources_dir, ':h').'/*')

" ======================[ Misc function {{{2
" Function: s:Echo(expr) {{{3
function! s:Echo(expr)
  return a:expr
  " return eval(a:expr)
endfunction
"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:sw=2:
```

### Projects with modules

I'll try to only give what really changes. In this case, in `src/` I have two
subdirectories: `ITK/` and `OTB/`, one for each FOSS.

#### `_vimrc_local_global_defs.vim`

```vim
" ======================[ Global project configuration {{{2
let s:script_dir = expand('<sfile>:p:h')
let s:sources_dir = s:script_dir.'/'.b:component_name

" Mandatory Project options
call lh#let#if_undef('g:'.b:component_varname.'_config.paths.trunk', string(s:sources_dir))
call lh#let#if_undef('g:'.b:component_varname.'_config.name',        string(b:component_varname))
call lh#let#if_undef('g:'.b:component_varname.'_config.paths.project', string(fnamemodify(g:{b:component_varname}_config.paths.trunk,':h:h')))
" call lh#let#if_undef('g:'.b:component_varname.'_config.paths.doxyfile', string(g:{b:component_varname}_config.paths.project))
" Note: this could be anything like: MyProject_config.build.ARM-release
call lh#let#if_undef('g:'.b:component_varname.'_config.build.Debug', string('build/'.b:component_name.'/debug'))
call lh#let#if_undef('g:'.b:component_varname.'_config.build.Release', string('build/'.b:component_name.'/release'))
call lh#let#if_undef('g:'.b:component_varname.'_config.build.ReleaseWithDebugInfo', string('build/'.b:component_name.'/reldeb'))
call lh#let#if_undef('g:'.b:component_varname.'_config.build.Cpp11', string('build/'.b:component_name.'/rd-cpp11'))
call lh#let#if_undef('g:'.b:component_varname.'_config.build.Clang14', string('build/'.b:component_name.'/rd-clang14'))
call lh#let#if_undef('g:'.b:component_varname.'_config.build.Clang98', string('build/'.b:component_name.'/rd-clang98'))

" Here, this matches all the trunk => complete even with test files
call lh#let#if_undef('g:'.b:component_varname.'_config.paths.sources', string((g:{b:component_varname}_config.paths.project).'/src/'.b:component_name))
" Optional Project options
call lh#let#if_undef('g:'.b:component_varname.'_config.compilation.mode', string('ReleaseWithDebugInfo'))
call lh#let#if_undef('g:'.b:component_varname.'_config.tests.verbosity', string('-VV'))

" ======================[ Menus {{{2
let s:menu_priority = '50.120.'
let s:menu_name     = '&Project.&'.matchstr(b:component_name, 'OTB\|ITK').'.'

" Function: s:getSNR([func_name]) {{{3
...

" Function: s:EditLocalCMakeFile([pos]) {{{3
...

call lh#let#if_undef ('g:'.b:component_varname.'_config.functions',
      \ string({'EditLocalCMakeFile': function(s:getSNR('EditLocalCMakeFile'))}))

"------------------------------------------------------------------------
" ======================[ Compilation mode, & CTest options {{{2
let g:{b:component_varname}_config_menu = {
      \ '_project': b:component_varname.'_config',
      \ 'menu': {'priority': s:menu_priority, 'name': s:menu_name}
      \ }
let s:cmake_integration = []
let s:cmake_integration += [ 'def_toggable_compil_mode' ]
let s:cmake_integration += [ 'def_toggable_ctest_verbosity' ]
" let s:cmake_integration += [ 'def_toggable_ctest_checkmem' ]
let s:cmake_integration += [ 'def_ctest_targets' ]
" let s:cmake_integration += [ 'add_gen_clic_DB' ]
" let s:cmake_integration += [ 'update_list' ]
call lh#btw#cmake#def_options(g:{b:component_varname}_config_menu, s:cmake_integration)

```

#### `_vimrc_local.vim`
```vim
" Always loaded {{{1

" Alternate configuration {{{2
" let g:alternateSearchPath = 'reg:#\<src\>$#inc,reg:#\<inc\>$#src#'
" .h and .cpp are in the same directory
let g:alternateSearchPath = 'sfr:.'
let g:alternateExtensions_cxx = "h,hxx"
let g:alternateExtensions_h   = "cxx,hxx"
let g:alternateExtensions_hxx = "h,cxx"

" Buffer-local Definitions {{{1
" Avoid local reinclusion {{{2
if &cp || (exists("b:loaded_ITKnOTB_vimrc_local")
      \ && (b:loaded_ITKnOTB_vimrc_local >= s:k_version)
      \ && !exists('g:force_reload_ITKnOTB_vimrc_local'))
  finish
endif
let b:loaded_ITKnOTB_vimrc_local = s:k_version
let s:cpo_save=&cpo
set cpo&vim
" Avoid local reinclusion }}}2

" ======================[ Check Path/Component {{{2
let s:script                = expand("<sfile>:p")
let s:script_dir            = expand('<sfile>:p:h')
let s:currently_edited_file = expand('%:p')
if empty(s:currently_edited_file)
    let s:currently_edited_file = getcwd()
endif
" If this is a buffer generated by fugitive, abort!
if s:currently_edited_file =~ '^fugitive://'
  finish
endif
let s:rel_path_to_current = lh#path#strip_start(s:currently_edited_file, [s:script_dir])
if s:rel_path_to_current !~ 'ITK\|OTB'
    " Not ITK/OTB, aborting
    finish
endif
let b:component_name = matchstr(s:rel_path_to_current, '[^/\\]*')
let b:component_varname = substitute(b:component_name, '[^a-zA-Z0-9_]', '_', 'g')
let s:sources_dir = s:script_dir.'/'.b:component_name

" ======================[ Project config {{{2
if ! (exists("g:loaded_ITKnOTB_vimrc_local")
      \ && (g:loaded_ITKnOTB_vimrc_local >= s:k_version)
      \ && !exists('g:force_reload_ITKnOTB_vimrc_local'))
  source <sfile>:p:h/_vimrc_local_global_defs.vim
endif

" ======================[ &path {{{2
" don't search into included file how to complete
setlocal complete-=i

" let b:project_crt_sub_project = matchstr(lh#path#strip_common([g:{b:component_varname}_config.paths.trunk, expand('%:p:h')])[1], '[^/\\]*[/\\][^/\\]*')

" Tells BTW the compilation directory
let b:BTW_compilation_dir = g:{b:component_varname}_config.paths._build
" Local vimrc variable for source dir
let b:project_sources_dir = g:{b:component_varname}_config.paths.sources
" Option for Mu-Template-> |s:path_from_root()|
let b:sources_root = g:{b:component_varname}_config.paths.sources

" Used by mu-template to generate file headers and header-gates.
let b:cpp_included_paths = [b:project_sources_dir]
" If the project has .h.in files that are generated in the build
" directory, uncomment the next line
" let b:cpp_included_paths += [b:BTW_compilation_dir]

" Configures lh-cpp complete includes sub-plugin -> ftplugin/c/c_AddInclude.vim
let b:includes = [ b:project_sources_dir . '/**']
" For config.h.in files and alike
" todo: adapt it automatically to the current compilation dir
let b:includes += [b:BTW_compilation_dir . '/**']
" Add your 3rd party libraries used in the project here
call lh#path#add_path_if_exists('b:includes', '/usr/local/include/**')
call lh#path#add_path_if_exists('b:includes', '/usr/include/**')

...
" ======================[ tags generation {{{2
...

" ======================[ Settings for compil_hints {{{2
...

" ======================[ Settings for BTW {{{2
let b:BTW_substitute_names = [
      \     ['VariableLengthVector<', 'VLV<'],
      \     ['VariableLengthVectorExpression', 'VLVEB'],
      \     ['VariableLengthVectorUnaryExpression', 'VLVEU']
      \ ]
QFImport BTW_substitute_names
BTW addlocal substitute_filenames
let b:BTW_shorten_names = [
      \     ['VariableLengthVector<', 'VLV<'],
      \     ['VariableLengthVectorExpression', 'VLVEB'],
      \     ['VariableLengthVectorUnaryExpression', 'VLVEU']
      \ ]
QFImport BTW_shorten_names
BTW addlocal shorten_filenames

if SystemDetected() == 'msdos'
  :BTW setlocal cmake
  " echomsg SystemDetected()
  if SystemDetected() == 'unix' " cygwin
    " then cygwin's cmake does not work -> use win32 cmake
    let $PATH=substitute($PATH, '\(.*\);\([^;]*CMake[^;]*\)', '\2;\1', '')
    BTW addlocal cygwin
  endif
endif
:BTW addlocal STLFilt
" silent! unlet b:BTW_project_executable
LetIfUndef b:BTW_project_executable.type 'ctest'
" sets b:BTW_project_executable.rule
call g:{b:component_varname}_config_menu.def_ctest_targets.set_ctest_argument()

let b:BTW_project_target = ''
let b:BTW_project_config = {
      \ 'type': 'ccmake',
      \ 'arg': (b:project_sources_dir),
      \ 'wd' : lh#function#bind('b:BTW_compilation_dir'),
      \ '_'  : g:{b:component_varname}_config
      \ }

" ======================[ Project's style {{{2
silent! source <sfile>:p:h/_vimrc_cpp_style.vim
let b:cpp_project_namespace = tolower(b:component_name)
" Where templates related to the project will be stored. You'll have to
" adjust the number of ':h', -> :h expand()
let b:mt_templates_paths = fnamemodify(b:project_sources_dir, ":h").'/templates'
" Expecting your project has a «project_ns»::Exception type
let b:exception_type = b:cpp_project_namespace.'::Exception'

" Special management of tests and unit tests
if expand('%:p') =~ b:project_sources_dir.'/Testing'
  let b:itkotb_dox_group = 'Test'
  let b:is_unit_test = 1
endif

" ======================[ Settings for searchfile {{{2
let b:searchfile_ext = 'h,H,C,cpp,cxx,hxx,txx'

" ======================[ Menus {{{2
call lh#menu#make('nic', '50.11', '&Project.Edit local &CMake file', '<localleader><F7>', '<buffer>', ':call g:{b:component_varname}_config.functions.EditLocalCMakeFile()<cr>')
call lh#menu#make('nic', '50.12', '&Project.Edit local &CMake file (vertical)', '<localleader>v<F7>', '<buffer>', ':call g:{b:component_varname}_config.functions.EditLocalCMakeFile("vert")<cr>')
call lh#menu#make('nic', '50.76', '&Project.Edit local &vimrc', '<localleader>le', '<buffer>', ':call lh#buffer#jump('.string(s:script).', "sp")<cr>' )

" ======================[ Local variables to automagically import in QuickFix buffer {{{2
...

" ======================[ Other commands {{{2
...

"=============================================================================
" Global Definitions {{{1
...
```

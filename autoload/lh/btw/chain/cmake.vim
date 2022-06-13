"=============================================================================
" File:         autoload/lh/btw/chain/cmake.vim                   {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/vim-build-tools-wrapper>
" License:      GPLv3 w/ licence exception
"               <URL:http://github.com/LucHermitte/vim-build-tools-wrapper/blob/master/License.md>
" Version:      0.7.0.
let s:k_version = '070'
" Created:      24th Oct 2018
" Last Update:  14th Jun 2022
"------------------------------------------------------------------------
" Description:
"       «description»
"
"------------------------------------------------------------------------
" History:      «history»
" TODO:         «missing features»
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#btw#chain#cmake#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#btw#chain#cmake#verbose(...)
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

function! lh#btw#chain#cmake#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" # Misc    {{{2
function! s:getSID() abort
  return eval(matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_getSID$'))
endfunction
let s:k_script_name      = s:getSID()

" ## Exported functions {{{1

"------------------------------------------------------------------------
" ## Internal functions {{{1
" # Misc functions {{{2
function! s:ensure_directory(dir) abort " {{{3
  if !isdirectory(a:dir)
    if exists('*mkdir')
      call mkdir(a:dir, 'p')
    else
      let cmd = lh#os#SystemCmd('mkdir')
      call system(cmd. ' '.lh#path#fix(a:dir))
    endif
    if !isdirectory(a:dir)
      throw "BTW: Cannot bootstrap ccmake in '".a:dir."': Impossible to create directory"
    endif
  endif
endfunction

" ## Configure related options {{{2
" Configure Options {{{3
let s:k_boolean_choices = ['On', 'Off']
let s:k_defaults = {}
let s:k_defaults.CMAKE_EXPORT_COMPILE_COMMANDS = { 'default': 'On', 'choices': s:k_boolean_choices}
let s:k_defaults.BUILD_TESTING                 = { 'default': 'ignore', 'choices': s:k_boolean_choices}
let s:k_defaults.BUILD_SHARED_LIBS             = { 'default': 'ignore', 'choices': s:k_boolean_choices}
let s:k_defaults.CMAKE_BUILD_TYPE              = { 'default': 'Release',
      \ 'choices': ['Release', 'Debug', 'RelWithDebInfo', 'MinSizeRel']}

function! s:get_option(name, cmdline, ...) abort " {{{3
  if match(a:cmdline, '^-D'.a:name.'=.*$') >= 0
    " Option already explicit in cmdline => use it
    return []
  endif
  let is_option = get(a:, 1, 0)

  " Else, priority is
  " 1. option set as (bpg):BTW.cmake.options[a:name]
  " 2. hard coded default values
  "
  " If value
  " - is 'ignored' => return ''
  " - is 'ask' => ask end-user amond possible values (hardcoded, or special
  "   default for booleans, or user input)
  " - else return the default choice
  if has_key(s:k_defaults, a:name)
    let default_choice   = s:k_defaults[a:name].default
    let possible_choices = s:k_defaults[a:name].choices
  elseif is_option
    if a:name =~ '^ENABLE_.*'
      let default_choice   = 'ask'
    else
      let default_choice   = 'ignore'
    endif
    let possible_choices = s:k_boolean_choices
  else
    let default_choice   = 'ask'
    let possible_choices = ''
  endif

  " Override BTW default choice with user preferences
  let default_choice = lh#option#get('BTW.cmake.options.'.a:name, default_choice)

  if     default_choice ==? 'ignore'
    return []
  elseif default_choice ==? 'ask'
    if empty(possible_choices)
      let value = lh#ui#input('Value for '.a:name.'? ')
    else
      let cmakelists_default = get(a:, 2, '')
      let default_idx = max([index(possible_choices, cmakelists_default, 0, 1), 0])
      call s:Verbose("Ask default for %1 should be %2", a:name, cmakelists_default)
      let value = lh#ui#which('lh#ui#combo', 'Value for '.a:name.'? ', possible_choices + ['Ignore'], default_idx+1)
    endif
  else
    let value = default_choice
  endif

  if empty(value) || value == 'Ignore'
    return []
  else
    return [printf('-D%s=%s', a:name, value)]
  endif
endfunction

function! s:find_root_cmakelists(root_dir) abort " {{{3
  " Search the CMakeLists closer to the project root directory
  " If several are at the same depth, ask end-user which one to choose
  " TODO: cache the information!
  let cmakefiles = findfile('CMakeLists.txt', a:root_dir.'/**', -1)
  call s:Verbose('all cmakefiles: %1', cmakefiles)
  " try to determine the files which is closest to source dir root.
  let depths = map(copy(cmakefiles), 'count(v:val, "/")')
  call s:Verbose('cmakefiles depths: %1', depths)
  let min_depth = min(map(copy(depths), 'v:val'))
  call s:Verbose('min depths: %1', min_depth)
  let cmakefiles = filter(cmakefiles, 'depths[v:key] == min_depth')
  call s:Verbose('kepts cmakefiles: %1', cmakefiles)
  if len(cmakefiles) > 1
    return lh#path#select_one(cmakefiles, 'Which CMakeLists file is the project root one?')
  elseif len(cmakefiles) == 1
    return cmakefiles[0]
  else
    return ''
  endif
endfunction

function! s:find_options_in_cmakelists(root_dir) abort " {{{3
  let cmakefile = s:find_root_cmakelists(a:root_dir)
  if  empty(cmakefile) | return [] | endif

  let lines = readfile(cmakefile)
  call filter(lines, 'v:val =~ "\\c^\\s*option("')
  let options = map(lines, { _, v
        \ -> matchlist(v, '\c^\s*option(\zs\(\k\+\).\{-}\%(\(on\|off\)\s*)\s*\)\=$')[1:2]})

  call s:Verbose("Options are: %1", options)
  return options
endfunction

function! s:get_generator(args) abort " {{{3
  " Ignore the option if alredy set
  if index(a:args, '-G') >= 0 | return [] | endif

  " Don't know how to detect MSVC++ generators...
  let generators = {
        \ 'ninja' : 'Ninja'
        \, 'make' : 'Unix Makefiles'
        \ }
  let gen_exes = filter(keys(generators), { _, v -> executable(v)})
  let gen_names = map(copy(gen_exes), 'generators[v:val]')
  if     empty(gen_names)    | return []
  elseif len(gen_names) == 1 | return ['-G', gen_names[0]]
  else
    let gen = lh#ui#which('lh#ui#combo', 'Which generator shall be used?', gen_names)
    return empty(gen) ? [] : ['-G', gen]
  endif
endfunction


" Function: lh#btw#chain#cmake#load_config() {{{2
" Beware: at this time, the CWD may not be the final project WD
function! lh#btw#chain#cmake#load_config(...) abort
  if lh#project#is_in_a_project()
    LetIfUndef p:BTW.target = ''
  endif
  " Use CMake as the main compilation tool!
  :BTW setlocal cmake

  let config = lh#btw#chain#cmake#_make()
  if call(config.analyse, lh#list#flatten(a:000), config)
    return config
  else
    return lh#option#unset('Failed to bootstrap a CMake environment')
  endif
endfunction

" # Access to cmake/ccmake executables {{{2
function! s:cmake() abort " {{{3
  if executable('cmake')
    return 'cmake %s'
  elseif has(':Module') && exists(':Module')
    " :Module wraps Lmod `module` command, and comes from
    " https://github.com/LucHermitte/lh-misc/blob/master/plugin/lmod.vim
    " (don't forget the autoload file!)
    call lh#common#warning_msg("CMake cannot be found in your environment. Let's try to load it")
    Module load cmake
    if v:shell_error
      throw "BTW: Sorry it seems than `module load cmake`  failed..."
    endif
    return 'cmake %s'
  else
    throw "BTW: CMake cannot be found in your environment"
  endif
endfunction

function! s:ccmake_interactive() abort " {{{3
  if executable('cmake-gui') && 0
    return 'cmake-gui %s &'
  elseif executable('ccmake')
    return 'ccmake %s'
  elseif has(':Module') && exists(':Module')
    " :Module wraps Lmod `module` command, and comes from
    " https://github.com/LucHermitte/lh-misc/blob/master/plugin/lmod.vim
    " (don't forget the autoload file!)
    call lh#common#warning_msg("CMake cannot be found in your environment. Let's try to load it")
    Module load cmake
    if v:shell_error
      throw "BTW: Sorry it seems than `module load cmake`  failed..."
    endif
    return 'ccmake %s'
  else
    throw "BTW: CMake cannot be found in your environment"
  endif
endfunction

" Function: lh#btw#chain#cmake#_make(...) {{{2
function! lh#btw#chain#cmake#_make(...) abort "{{{3
  let prefix = lh#project#is_in_a_project() ? 'p:' : 'b:'

  let res = lh#object#make_top_type(get(a:, 1, {}))
  let res.type = 'ccmake'
  let res.arg  = lh#option#get('paths.sources')
  let res.wd   = lh#ref#bind(prefix.'BTW.compilation_dir')
  call lh#object#inject_methods(res, s:k_script_name, 'config', 'reconfig', 'analyse', 'bootstrap',
        \ 'lazy_bootstrap', 'adapt_parameters')
  return res
endfunction

function! s:config(...) dict abort " {{{3
  " TODO:
  " - the passing of interactive/synchronous/...
  " - cmake over cmake-gui
  "
  " Improve
  " Running modes: interactive, background, synchronous
  let args      = get(a:, 1, {})
  let cmdline   = copy(get(a:, 2, []))  " A list
  call lh#assert#type(cmdline).is([])
  let mode      = get(args, 'mode', 'interactive')
  " FIXME: Actually cmake-gui will ignore "-G 'generator'" parameter... :-(
  let generator = s:get_generator(cmdline)

  " Build directory
  let idx_build_dir = index(cmdline, '-B')
  if idx_build_dir >= 0
    let wd = remove(cmdline, idx_build_dir, idx_build_dir+1)[-1]
  else
    let wd = lh#btw#_evaluate(self.wd)
  endif
  call s:Verbose('CMake configuration will be generated in %1', wd)
  call s:ensure_directory(wd)

  " Typicals options
  let cmdline += s:get_option('CMAKE_BUILD_TYPE',              cmdline)
  let cmdline += s:get_option('CMAKE_EXPORT_COMPILE_COMMANDS', cmdline)
  " let cmdline += s:get_option('BUILD_TESTING',                 cmdline)
  let cmdline += s:get_option('BUILD_SHARED_LIBS',             cmdline)

  " call s:Verbose('cmake.config(%1, %2)', args, cmdline)

  " Other options found in CMakeLists.txt
  let options = s:find_options_in_cmakelists(self.arg)
  for [opt, def] in options
    let cmdline += s:get_option(opt, cmdline, 1, def)
  endfor

  let opts = generator + get(args, 'opts', []) + cmdline
  let all_opts = printf('-S %s -B %s %s',
        \ lh#path#fix(self.arg), lh#path#fix(wd), join(opts, ' '))
  call s:Verbose('cmake.config(%1, %2)', args, all_opts)

  if lh#os#OnDOSWindows()
    " TODO: support all modes on Windows

    " - the first ":!start" runs a windows command
    " - "cmd /c" is used to define the second "start" command (see "start /?")
    " - the second "start" is used to set the current directory and run the
    " execution.
    let prg = 'start /b cmd /c start /D '.lh#path#fix(wd, 0, '"')
          \.' /B cmake-gui '.lh#path#fix(how.arg, 0, '"')
  else
    " Modes
    " - "interactive" -> ccmake(-gui)
    " - "background"  -> use BTW Make on cmake
    " - "synchronous" -> direct call to system() on cmake
    if mode == 'interactive'
      let ccmake = s:ccmake_interactive()
      if ccmake !~ '&$' && exists(':term')
        let prg = printf(ccmake, all_opts)
        call lh#common#warning_msg('Running: '.prg)
        let crt_prj = lh#project#crt()
        if &buftype == 'terminal' && term_getstatus('%') == 'finished'
          " reuse!
        else
          vnew
        endif
        call lh#path#cd_without_sideeffects(wd)
        exe 'term ++curwin '.prg
        if lh#option#is_set(crt_prj)
          " When ccmake has finished, we are in a new and empty buffer, this is
          " the one that need to be registered
          call crt_prj._register_buffer()
        endif
      else
        let prg = printf(s:ccmake_interactive(), all_opts)
        call s:Verbose(":!".prg)
        exe ':silent !'.prg
      endif
    else
      let prg = printf(s:cmake(), all_opts)
      let d_opts = {'background': (mode=='background')}
      if mode == 'synchronous'
        call lh#common#warning_msg('Running: '.prg."\nPlease wait...")
      endif
      call lh#btw#build#_do_compile(prg, '', "CMake execution terminated", d_opts)
    endif
  endif

  " Register new build directory, when configuration is detected to have
  " proceeded far enough... (for a CMakeCache.txt to exist or the command to
  " return "success"???)
  " TODO: ...
endfunction

function! s:reconfig() dict abort " {{{3
  let wd = lh#btw#_evaluate(self.wd)
  if lh#os#OnDOSWindows()
    " - the first ":!start" runs a windows command
    " - "cmd /c" is used to define the second "start" command (see "start /?")
    " - the second "start" is used to set the current directory and run the
    " execution.
    let prg = 'start /b cmd /c start /D '.lh#path#fix(wd, 0, '"')
          \.' /B cmake .'
  else
    let prg = lh#os#sys_cd(wd).' && '
    let prg .= printf(s:cmake(), self.arg)
    call lh#btw#build#_do_compile(prg, '', "CMake execution terminated")
  endif
endfunction

function! s:search_build_dirs(prefix, sources_dir) abort " {{{3
  let prefix      = a:prefix
  let sources_dir = a:sources_dir

  call lh#assert#value(sources_dir).is_set() "Can we also expect sources_dir to always exist here?
  let prj_root_dir = lh#option#get('paths.project')
  if lh#option#is_set(prj_root_dir)
    call s:Verbose("BTW: Bootstrapping CMake chain, using (bpg):paths.project = '%1'", prj_root_dir)
    let updir_cmakelists = [sources_dir]
  else
    unlet prj_root_dir
    " Sometimes, the paths.sources is artifically changed, in that case search
    " for the last up-directory with a CMakeLists.txt
    let updir_cmakelists = findfile('CMakeLists.txt', sources_dir.";", -1)
    " If we're here, it's because a CMakeLists.txt has been found
    call lh#assert#value(updir_cmakelists).not().empty()

    let prj_root_dir = lh#let#to(prefix.'paths.project', fnamemodify(updir_cmakelists[-1], ':p:h:h'))
    call s:Verbose("BTW: Bootstrapping CMake chain, deducing (bpg):paths.project='%1'", prj_root_dir)
  endif

  " 1.2- Find the build root directory
  "      i.e. files would be in {build_root_dir}/{mode}/CMakeCache.txt
  "      Or the build_dir
  let build_dir      = lh#option#get('BTW.compilation_dir')
  let build_root_dir = lh#option#get('paths.build_root_dir')
  if lh#option#is_set(build_dir) && isdirectory(build_dir)
    call s:Verbose("(bpg):BTW.compilation_dir already set as %1 => abort", build_dir)
    return build_root_dir
  elseif lh#option#is_set(build_root_dir) && isdirectory(build_root_dir)
    call s:Verbose("BTW: Bootstrapping CMake chain, using (bpg):paths.build_root_dir='%1'", build_root_dir)
    return build_root_dir
  else
    " unlet build_root_dir
    " 1.2.1- there is a symbolic link named compile_commands.json
    let db = sources_dir.'/compile_commands.json'
    call s:Verbose('BTW: Bootstrapping CMake chain, Testing whether "%1" is a symbolic link...', db)
    if filereadable(db) && getftype(db) == 'link'
      let db_path = fnamemodify(lh#path#readlink(db), ':.:h')
      call s:Verbose("Symbolic link to %2 found as %1", db, db_path)
      let build_dir = fnamemodify(db_path, ':p')
      " then, ../*/CMakeCache.txt, there may be sibling dirs
      let siblings = lh#path#glob_as_list(build_dir, '../*/CMakeCache.txt')
      if  len(siblings) >= 2
        let build_root_dir = lh#path#simplify(build_dir.'/..')
      endif
    endif

    " 1.2.2- there is {updirs...}/CMakeCache.txt
    if  lh#option#is_unset(build_root_dir) && lh#option#is_unset(build_dir)
      call s:Verbose('BTW: Bootstrapping CMake chain, Searching for CMakeCache.txt under "%1"...', prj_root_dir)
      let files = lh#path#glob_as_list(prj_root_dir, '*/CMakeCache.txt')
      if empty(files)
        let build_dirname = lh#option#get('paths.build_dirname', '*')
        let files = lh#path#glob_as_list(prj_root_dir, build_dirname.'/*/CMakeCache.txt')
        if !empty(files)
          call s:Verbose('BTW: Bootstrapping CMake chain, CMakeCache.txt found in "%1/%2/*" ->  "%3"', prj_root_dir, build_dirname, files)
        endif
      else
        call s:Verbose('BTW: Bootstrapping CMake chain, CMakeCache.txt found in "%1/*" ->  "%2"', prj_root_dir, files)
      endif
      if len(files) == 1
        call s:Verbose('BTW: Bootstrapping CMake chain, a single CMakeCache.txt found in ->  "%1"', files)
        let build_dir = fnamemodify(files[0], ':h')
        " TODO: Add option to avoid asking...
        let build_dir = lh#ui#input("Build directory found.\nDo you confirm? (empty to abort)",  build_dir, 'dir')
        if !empty(build_dir)
          let build_root_dir = fnamemodify(build_dir, ':h')
        endif
      elseif !empty(files)
        let build_root_dir = lh#path#common(files)
      endif
    endif

    " 1.2.3- there is {updirs...}/build => ask
    if  lh#option#is_unset(build_root_dir) && lh#option#is_unset(build_dir)
      " Now if there is a build/ dir in the parent directory, let's say
      let build_dirname = lh#option#get('paths.build_dirname', 'build')
      call s:Verbose('BTW: Bootstrapping CMake chain, Searching for a "%1/" directory name before "%2"...', build_dirname, updir_cmakelists[-1])
      let updir_build = finddir(build_dirname, updir_cmakelists[-1].';', -1)
      if empty(updir_build)
        let build_root_dir = lh#ui#input("No '".build_dirname."/' directory found\nWhere do you want to build? (empty to abort)",
              \ prj_root_dir.'/'.build_dirname, 'dir')
      else
        let build_root_dir = lh#ui#input("'".build_dirname."/' directory found\nDo you confirm? (empty to abort)",
              \ updir_build[-1], 'dir')
      endif
    endif

    if lh#option#is_set(build_dir) && isdirectory(build_dir)
      call s:Verbose("The current compilation dir has been found as %1", build_dir)
      call lh#let#to(prefix.'BTW.compilation_dir', build_dir)
    endif
    if lh#option#is_unset(build_root_dir)
      call s:Verbose("No CMake compilation mode found => abort support for multiple compilation modes")
      return build_root_dir
    endif
    call s:Verbose('BTW: Bootstrapping CMake chain, Making "%1" relative to "%2"...', build_root_dir, prj_root_dir)
    let build_root_dir = lh#path#relative_to(prj_root_dir, build_root_dir)
    call lh#let#to(prefix.'paths.build_root_dir', build_root_dir)
    call s:Verbose("BTW: Bootstrapping CMake chain, deducing (bpg):paths.build_root_dir='%1'", build_root_dir)
  endif

  if count(build_root_dir, '/') == 1
    " We may have sibling directories
    call s:Verbose("The build_root_dir (%1) found is one step away from the prj_root_dir (%2), multiple compilation modes may be used.", build_root_dir, prj_root_dir)
  else
    call s:Verbose("The build_root_dir (%1) found is several steps away from the prj_root_dir (%2), we assume that no multiple compilation modes are used.", build_root_dir, prj_root_dir)
  endif

  return build_root_dir
endfunction

function! s:analyse(...) dict abort " {{{3
  call s:Verbose("CMake analysing(%1)", a:000)
  let prefix = lh#project#is_in_a_project() ? 'p:' : 'b:'

  " 1- Try to autodetect build directory
  " 1.1- Find the project root directory
  let sources_dir  = lh#option#get('paths.sources') " also stored in self.arg...
  if  lh#option#is_unset(sources_dir)
    call s:Verbose("BTW: (bpg):paths.sources is unset, abort CMake detection")
    return 0
  else
    call s:Verbose("BTW: Bootstrapping CMake chain, using (bpg):path.sources = '%1'", sources_dir)
  endif
  let build_root_dir = s:search_build_dirs(prefix, sources_dir)

  " 2- Register the bootstrapped configurations
  " (bpg):BTW.build.mode.bootstrap is meant to store configuration
  " options.
  " With this, we iterate the list of typical modes to define the list
  " of paths where various modes/configurations would be compiled in the
  " case of a root build folder. When only a single compilation folder
  " is used this doesn't make sense
  if lh#option#is_set(build_root_dir)
    let confs = lh#option#get('BTW.build.mode.bootstrap', {})
    let list = lh#let#if_undef(prefix.'BTW.build.mode.list', {})
    for conf in keys(confs)
      let list[conf] = build_root_dir . '/' . conf
    endfor
    let options = [ 'auto_detect_compil_modes' ]
  else
    let options = []
  endif

  let prj = lh#project#crt()
  call lh#let#if_undef('p:menu.menu.priority', lh#project#menu#reserve_id(prj).'.')
  call lh#let#if_undef('p:menu.menu.name'    , prj.name.'.')

  " TODO: avoid to call the following function multiple times
  call lh#btw#cmake#define_options(options + a:000)
  return 1
endfunction

function! s:bootstrap() dict abort " {{{3
  let compil_mode = lh#option#get('BTW.build.mode.current')
  call s:Verbose("bootstrapping CMake for compil_mode: %1", compil_mode)
  if lh#option#is_unset(compil_mode)
    call lh#common#error_msg('(bpg):BTW.build.mode.current is not set. Impossible to bootstrap cmake')
    return 0
  endif
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

  call lh#assert#value(self).has_key('wd')
  call lh#assert#value(self).has_key('arg')
  return self.config({'mode': 'synchronous', 'opts': opts})
endfunction

function! s:lazy_bootstrap() dict abort " {{{3
  let wd = lh#btw#_evaluate(self.wd)
  " TODO: use an option if the make of the CMakeFiles file is different
  if !isdirectory(wd . '/' . 'CMakeFiles')
    return self.bootstrap()
  else
    return 1
  endif
endfunction

function! s:adapt_parameters(rule) dict abort " {{{3
  return !empty(a:rule) ? '--target '.a:rule : ''
endfunction

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

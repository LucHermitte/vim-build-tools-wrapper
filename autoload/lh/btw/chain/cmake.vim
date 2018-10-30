"=============================================================================
" File:         autoload/lh/btw/chain/cmake.vim                   {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/vim-build-tools-wrapper>
" License:      GPLv3 w/ licence exception
"               <URL:http://github.com/LucHermitte/vim-build-tools-wrapper/blob/master/License.md>
" Version:      0.7.0.
let s:k_version = '070'
" Created:      24th Oct 2018
" Last Update:  30th Oct 2018
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

" Function: lh#btw#chain#cmake#load_config() {{{2
function! lh#btw#chain#cmake#load_config() abort
  if lh#project#is_in_a_project()
    LetIfUndef p:BTW.target = ''
  endif
  " TODO: find the best place to do this...
  if SystemDetected() == 'msdos'
    :BTW setlocal cmake
  else
    BTW addlocal cmake
  endif

  let config = lh#btw#chain#cmake#_make()
  if config.analyse()
    return config
  else
    return lh#option#unset('Failed to bootstrap a CMake environment')
  endif
endfunction

" # Access to cmake/ccmake executables {{{2
function! s:cmake() abort " {{{3
  if executable('cmake')
    return 'cmake %s'
  elseif has(':Module')
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
  if executable('cmake-gui')
    return 'cmake-gui %s &'
  elseif executable('ccmake')
    return 'ccmake %s'
  elseif has(':Module')
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
  call lh#object#inject_methods(res, s:k_script_name, 'config', 'reconfig', 'analyse', 'bootstrap', 'lazy_bootstrap')
  return res
endfunction

function! s:config(...) dict abort " {{{3
  " Running modes: interactive, background, synchronous
  let args = get(a:, 1, {})
  let mode = get(args, 'mode', 'interactive')

  let wd = lh#btw#_evaluate(self.wd)
  call s:ensure_directory(wd)
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
    "
    let prg = lh#os#sys_cd(wd).' && '
    if mode == 'interactive'
      let ccmake = s:ccmake_interactive()
      if ccmake !~ '&$' && exists(':term')
        let opts = get(args, 'opts', '')
        let prg = printf(ccmake, self.arg). (empty(opts) ? '' : opts)
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
        let prg .= printf(s:ccmake_interactive(), self.arg). ' '.get(args, 'opts', '')
        call s:Verbose(":!".prg)
        exe ':silent !'.prg
      endif
    else
      let prg .= printf(s:cmake(), self.arg). ' '.get(args, 'opts', '')
      let opts = {'background': (mode=='background')}
      if mode == 'synchronous'
        call lh#common#warning_msg('Running: '.prg."\nPlease wait...")
      endif
      call lh#btw#build#_do_compile(prg, '', "CMake execution terminated", opts)
    endif
  endif
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


function! s:analyse() dict abort " {{{3
  let prefix = lh#project#is_in_a_project() ? 'p:' : 'b:'

  " 1- Try to autodetect build directory
  " 1.1- Find the project root directory
  let prj_root_dir = lh#option#get('paths.project')
  if lh#option#is_set(prj_root_dir)
    call s:Verbose("BTW: Bootstrapping cmake chain, using (bpg):paths.project='%1'", prj_root_dir)
  else
    unlet prj_root_dir
    let sources_dir = lh#option#get('paths.sources')
    call lh#assert#value(sources_dir).is_set()
    " Sometimes, the paths.sources is artifically changed, in that case search
    " for the last up-directory with a CMakeLists.txt
    let updir_cmakelists = findfile('CMakeLists.txt', sources_dir.";", -1)
    " If we're here, it's because a CMakeLists.txt has been found
    call lh#assert#value(updir_cmakelists).not().empty()

    let prj_root_dir = lh#let#to(prefix.'paths.project', fnamemodify(updir_cmakelists[-1], ':p:h:h'))
    call s:Verbose("BTW: Bootstrapping cmake chain, deducing (bpg):paths.project='%1'", prj_root_dir)
  endif

  " 1.2- Find the build root directory
  let build_root_dir = lh#option#get('paths.build_root_dir')
  if lh#option#is_set(build_root_dir)
    call s:Verbose("BTW: Bootstrapping cmake chain, using (bpg):paths.build_root_dir='%1'", build_root_dir)
  else
    unlet build_root_dir
    " Now if there is a build/ dir in the parent directory, let's say
    let build_dirname = lh#option#get('paths.build_dirname', 'build')
    let updir_build = finddir(build_dirname, updir_cmakelists[-1].';', -1)
    if empty(updir_build)
      let build_root_dir = lh#ui#input("No '".build_dirname."/' directory found\nWhere do you want to build? ",
            \ prj_root_dir.'/'.build_dirname)
    else
      let build_root_dir = lh#ui#input("'".build_dirname."/' directory found\nDo you confirm? ",
            \ updir_build[-1])
    endif

    if  empty(build_root_dir)
      return 0
    endif
    let build_root_dir = lh#path#relative_to(prj_root_dir, build_root_dir)
    call lh#let#to(prefix.'paths.build_root_dir', build_root_dir)
    call s:Verbose("BTW: Bootstrapping cmake chain, deducing (bpg):paths.build_root_dir='%1'", build_root_dir)
  endif

  " 2- Register the bootstrapped configurations
  let confs = lh#option#get('BTW.build.mode.bootstrap', {})
  let list = lh#let#if_undef(prefix.'BTW.build.mode.list', {})
  for conf in keys(confs)
    let list[conf] = build_root_dir . '/' . conf
  endfor

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
  " TODO: use an option if the make of the Makefile file is different
  if !filereadable(wd . '/' . 'Makefile')
    return self.bootstrap()
  else
    return 1
  endif
endfunction

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:
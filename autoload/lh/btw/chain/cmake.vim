"=============================================================================
" File:         autoload/lh/btw/chain/cmake.vim                   {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/vim-build-tools-wrapper>
" License:      GPLv3 w/ licence exception
"               <URL:http://github.com/LucHermitte/vim-build-tools-wrapper/blob/master/License.md>
" Version:      0.7.0.
let s:k_version = '070'
" Created:      24th Oct 2018
" Last Update:  26th Oct 2018
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
" Function: lh#btw#chain#cmake#load_config() {{{2
function! lh#btw#chain#cmake#load_config() abort
  LetIfUndef p:BTW.target = ''
  let config = lh#let#to('p:BTW.project_config', lh#btw#chain#cmake#_make())
  return config.bootstrap()
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

function! s:ccmake() abort " {{{3
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
function! lh#btw#chain#cmake#_make(...) abort
  let res = lh#object#make_top_type(get(a:, 1, {}))
  let res.type = 'ccmake'
  let res.args = lh#option#get('paths.sources')
  let res.wd   = lh#ref#bind('p:BTW.compilation_dir')
  call lh#object#inject_methods(res, s:k_script_name, 'config', 'reconfig', 'bootstrap')
  return res
endfunction

function! s:config() dict abort " {{{3
  let wd = self.wd
  if lh#os#OnDOSWindows()
    " - the first ":!start" runs a windows command
    " - "cmd /c" is used to define the second "start" command (see "start /?")
    " - the second "start" is used to set the current directory and run the
    " execution.
    let prg = 'start /b cmd /c start /D '.lh#path#fix(wd, 0, '"')
          \.' /B cmake-gui '.lh#path#fix(how.arg, 0, '"')
  else
    " let's suppose no spaces are used
    " let prg = 'xterm -e "cd '.wd.' && ccmake '.(how.arg).'"'
    let prg = 'cd '.wd.' && '.printf(s:ccmake(), self.arg)
  endif
  " let g:prg = prg
  call s:Verbose(":!".prg)
  exe ':silent !'.prg
endfunction

function! s:reconfig() dict abort " {{{3
  let wd = self.wd
  if lh#os#OnDOSWindows()
    " - the first ":!start" runs a windows command
    " - "cmd /c" is used to define the second "start" command (see "start /?")
    " - the second "start" is used to set the current directory and run the
    " execution.
    let prg = 'start /b cmd /c start /D '.lh#path#fix(wd, 0, '"')
          \.' /B cmake .'
  else
    " let's suppose no spaces are used
    " let prg = 'xterm -e "cd '.wd.' && cmake ."'
    call s:Verbose('Reconfigure with: cd %1 && cmake .', wd)
    let prg = 'cd '.wd.' && '.s:cmake('.')
  endif
  call s:Verbose(":!".prg)
  " TODO: Asynch execution through &makeprg!
  exe ':!'.prg
endfunction

function! s:do_bootstrap(dir, opts) dict abort " {{{3
  let sources_dir = lh#option#get('paths.sources')
  let cmd = lh#os#sys_cd(a:dir).' && '.printf(s:ccmake(), sources_dir). ' '.opts
  return lh#os#system(cmd)
endfunction

function! s:bootstrap() dict abort " {{{3
  " 1- Try to autodetect build directory
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

    let prj_root_dir = lh#let#to('p:paths.project', fnamemodify(updir_cmakelists[-1], ':p:h:h'))
    call s:Verbose("BTW: Bootstrapping cmake chain, deducing (bpg):paths.project='%1'", prj_root_dir)
  endif

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
    call lh#let#to('p:paths.build_root_dir', build_root_dir)
    call s:Verbose("BTW: Bootstrapping cmake chain, deducing (bpg):paths.build_root_dir='%1'", build_root_dir)
  endif

  " 2- Register the bootstrapped configurations
  let confs = lh#option#get('BTW.build.mode.bootstrap', {})
  let list = lh#let#if_undef('p:BTW.build.mode.list', {})
  for conf in keys(confs)
    let list[conf] = build_root_dir . '/' . conf
  endfor

  return 1
endfunction

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

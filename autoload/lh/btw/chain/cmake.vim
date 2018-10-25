"=============================================================================
" File:         autoload/lh/btw/chain/cmake.vim                   {{{1
" Author:       Luc Hermitte <EMAIL:luc {dot} hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/vim-build-tools-wrapper>
" License:      GPLv3 w/ licence exception
"               <URL:http://github.com/LucHermitte/vim-build-tools-wrapper/blob/master/License.md>
" Version:      0.7.0.
let s:k_version = '070'
" Created:      24th Oct 2018
" Last Update:  25th Oct 2018
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
  call config.bootstrap()
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

function! s:bootstrap() dict abort " {{{3
  return
  " Try to autodetect build directory
  " Register the bootstrapped configurations
  let confs = lh#option#get('BTW.build.bootstrap', [])
  let list = lh#let#if_undef('p:BTW.build.list', {})
  let build_root_dir = lh#btw#cmake#_build_root_dir()
  for conf in keys(confs)
    let list[conf] = build_root_dir . '/' . conf
  endfor
endfunction

"------------------------------------------------------------------------
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

"=============================================================================
" File:         autoload/lh/btw/project.vim                       {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://github.com/LucHermitte/vim-build-tools-wrapper>
" Version:      0.7.0.
let s:k_version = 070
" Created:      15th Jan 2015
" Last Update:  14th Oct 2016
"------------------------------------------------------------------------
" Description:
"       Internal functions to generate new project config files from templates.
" Todo:
" * Apply mt_jump_to_first_markers on the 2 other files generated
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#btw#project#version()
  return s:k_version
endfunction

" # Debug   {{{2
let s:verbose = get(s:, 'verbose', 0)
function! lh#btw#project#verbose(...)
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

function! lh#btw#project#debug(expr) abort
  return eval(a:expr)
endfunction

"------------------------------------------------------------------------
" ## Exported functions {{{1
" # New project {{{2
" Function: lh#btw#project#new(...) {{{3
function! lh#btw#project#new(...) abort
  if a:0 == 0
    call lh#common#warning_msg('BTW new_project <kinds>... name=<name> config=<BTW-config-varname> -src_dir=<src_dir> (def=expand("%:p:h"))')
    return
  endif
  let extension_for_configurable_files = ''

  let args = call('lh#btw#project#_analyse_params', a:000)
  if has_key(args, '_prj_config')
    if args._prj_config !~ '^g:'
      let args._prj_config = 'g:'.args._prj_config
    endif
  endif
  let args.description = "Definition of vim's local options for the project ". (args._prj_name)
  let cleanup = lh#on#exit()
        \.restore('g:mt_IDontWantTemplatesAutomaticallyInserted')
        \.restore('g:mt_jump_to_first_markers')
  " mu-template expansion will be done manually in order to inject the precise
  " parameters
  try
    let g:mt_IDontWantTemplatesAutomaticallyInserted = 1
    let g:mt_jump_to_first_markers = 0
    call lh#window#split('_vimrc_local.vim')
    call lh#mut#expand_and_jump(0, 'vim', args)

    if has_key(args.project_kind, 'c') || has_key(args.project_kind, 'cpp')
      call lh#window#split('_vimrc_cpp_style.vim')
      call lh#mut#expand_and_jump(0, 'vim/internals/vim-header', args)
      normal! G
      call lh#mut#expand_and_jump(0, 'vim/internals/vim-rc-local-cpp-style', args)
      normal! G
      call lh#mut#expand_and_jump(0, 'vim/internals/vim-footer', args)
    endif
    let using_cmake = has_key(args.project_kind, 'cmake')
    if using_cmake
      let extension_for_configurable_files = 'in'
      call lh#window#split('_vimrc_local_global_defs.vim')
      call lh#mut#expand_and_jump(0, 'vim/internals/vim-header', args)
      normal! G
      call lh#mut#expand_and_jump(0, 'vim/internals/vim-rc-local-global-cmake-def', args)
      normal! G
      call lh#mut#expand_and_jump(0, 'vim/internals/vim-footer', args)
    endif
  finally
    call cleanup.finalize()
  endtry
  if has_key(args.project_kind, 'doxygen')
    call lh#window#split('Doxyfile'.extension_for_configurable_files)
  endif
  if using_cmake
    call lh#window#split('CMakeLists.txt')
  endif
endfunction

"------------------------------------------------------------------------
" ## Internal functions {{{1
" # Preparations {{{2
let s:ctxs = 'name\|src_dir\|config'
function! lh#btw#project#_analyse_params(...) abort
try
  let isk_save = &isk
  set isk-=:

  let kind = []
  let args = {}
  let ctx = ''
  for opt in a:000
    if ctx == 'kind'
      let kind += split(opt, ',')
      let ctx  = ''
    elseif !empty(ctx)
      let args['_prj_'.ctx] = opt
      let ctx  = ''
    else
      let match = matchstr(opt, '^\('.s:ctxs.'\)\>\ze[=:]\=')
      let lm = len(match)
      let lo = len(opt)
      if lm == 0
        let kind += [opt]
      elseif lo==lm || (lo - lm == 1 && opt[lm] =~ '[:=]')
        let ctx = match
      elseif lo > lm + 1
        if opt[lm] != '='
          throw "'=' expected in ".string(opt)
        endif
        let args['_prj_'.match] = opt[lm+1:]
      endif
    endif
  endfor

  let args.project_kind = eval('extend('.join(map(kind, '{(v:val): 1}'), ',').')')

  return  args
finally
  let &isk = isk_save
endtry
endfunction

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

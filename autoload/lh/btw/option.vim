"=============================================================================
" File:         autoload/lh/btw/option.vim                        {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/vim-option-tools-wrapper>
" Version:      0.7.0.
let s:k_version = '070'
" Created:      23rd Mar 2015
" Last Update:  10th Aug 2016
"------------------------------------------------------------------------
" Description:
"       Centralize BTW option retrieval
"
" List of deprecated variables in v0.7.0:
" - (bpg):BTW_project                       -> (bpg):BTW.project
" - (bpg):BTW_project_target                -> (bpg):BTW.target
" - (bpg):BTW_project_executable            -> (bpg):BTW.executable
" - (bpg):BTW_project_config                -> (bpg):BTW.project_config
"   (bpg):BTW_project_build_mode            -> (bpg):BTW.project_config
" - g:BTW_autoscroll_background_compilation -> g:BTW.autoscroll_background_compilation
" - g:BTW_GotoError                         -> g:BTW.goto_error
" - g:BTW_make_in_background                -> g:BTW.make_in_background
" - g:BTW_make_multijobs                    -> g:BTW.make_multijobs
" - (bpg):BTW_make_in_background_in         -> (bpg):BTW.make_in_background_in
" - (bpg):BTW_use_prio                      -> (bpg):BTW.use_prio
" - g:BTW_qf_position                       -> g:BTW.qf_position
" - g:BTW_QF_size                           -> g:BTW.qf_size
" - (gpb):BTW_qf_syntax                     -> (gpb):BTW.qf_syntax
" - (bpg):BTW_run_parameters                -> (bpg):BTW.run_parameters
" - (bpg):BTW_project_name                  -> (bpg):BTW.project_name
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#btw#option#version()
  return s:k_version
endfunction

" # Debug   {{{2
if !exists('s:verbose')
  let s:verbose = 0
endif
function! lh#btw#option#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Verbose(expr)
  if s:verbose
    echomsg a:expr
  endif
endfunction

function! lh#btw#option#debug(expr)
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Options            {{{1
" # Deprecated compatibility {{{2
function! s:get(name, default, ...) abort " {{{3
  let res = call('lh#option#get', ['BTW.'.a:name, lh#option#unset()] + a:000)
  if lh#option#is_set(res) | return res | endif
  return call('lh#option#get', ['BTW_'.a:name, a:default] + a:000)
endfunction

function! s:old(name, default, ...) abort " {{{3
  return call('lh#option#get', ['BTW_'.a:name, a:default] + a:000)
endfunction

function! s:get_explicit_names(new_name, old_name, default, ...) abort " {{{3
  let res = call('lh#option#get', ['BTW.'.a:new_name, lh#option#unset()] + a:000)
  if lh#option#is_set(res) | return res | endif
  return call('lh#option#get', ['BTW_'.a:old_name, a:default] + a:000)
endfunction

function! s:get_from_buf(bufid, name, default, ...) abort " {{{3
  let res = call('lh#option#get_from_buf', [a:bufid, 'BTW.'.a:name, lh#option#unset()] + a:000)
  if lh#option#is_set(res) | return res | endif
  return call('lh#option#get_from_buf', [a:bufid, 'BTW_'.a:name, a:default] + a:000)
endfunction

" Function: lh#btw#option#_check_deprecated_options() {{{3
let s:has_been_notified = 0
function! lh#btw#option#_check_deprecated_options() abort
  let g = filter(copy(g:), 'v:key =~ "^BTW_"')
  let b = filter(copy(b:), 'v:key =~ "^BTW_"')
  if !s:has_been_notified && (empty(g) || empty(b))
    let s:has_been_notified = 1
    call lh#common#error_msg("It seems you're using old BuildToolsWrappers options. They have been renamed. See :h BTW-deprecated-options")
  endif
endfunction
" # Compilation   options {{{2
" Function: lh#btw#option#_auto_scroll_in_bg() {{{3
function! lh#btw#option#_auto_scroll_in_bg() abort
  return lh#option#get('BTW.autoscroll_background_compilation', 1, 'g')
endfunction
call lh#let#if_undef(
      \ 'g:BTW.autoscroll_background_compilation',
      \ s:old('autoscroll_background_compilation', 1, 'g'))

" Function: lh#btw#option#_goto_error() {{{3
function! lh#btw#option#_goto_error() abort
  return s:get_explicit_names('goto_error', 'GotoError', 1, 'g')
endfunction

" Function: lh#btw#option#_make_in_bg() {{{3
" TODO: Shall we have the option project relative ?
function! lh#btw#option#_make_in_bg() abort
  return lh#option#get('BTW.make_in_background', 0, 'g')
endfunction
call lh#let#if_undef(
      \ 'g:BTW.make_in_background',
      \ s:old('make_in_background', 0, 'g'))

" Function: lh#btw#option#_make_in_bg_in() {{{3
function! lh#btw#option#_make_in_bg_in() abort
  return s:get('make_in_background_in', '')
endfunction

" Function: lh#btw#option#_make_mj() {{{3
function! lh#btw#option#_make_mj() abort
  let value = lh#option#get('BTW.make_multijobs', 0, 'g')
  if type(value) != type(0)
    call lh#common#error_msg("option BTW.make_multijobs is not a number")
    return 0
  endif
  return value
endfunction
call lh#let#if_undef(
      \ 'g:BTW.make_multijobs',
      \ s:old('make_multijobs', 0, 'g'))

" Function: lh#btw#option#_project_config([bufid]) {{{3
function! lh#btw#option#_project_config(...) abort
  if a:0 > 0
    " from buf version => no default to detect undefined option
    let bufid = a:1
    return s:get_from_buf(bufid, 'project_config', lh#option#unset())
  else
    return s:get('project_config', {'type': 'modeline'} )
  endif
endfunction

" Function: lh#btw#option#_has_project_config() {{{3
function! lh#btw#option#_has_project_config() abort
  return     exists('b:BTW_project_config')
        \ || exists('b:BTW.project_config')
        \ || lh#project#exists('p:BTW.project_config')
endfunction


" Function: lh#btw#option#_use_prio() {{{3
function! lh#btw#option#_use_prio() abort
  return s:get('use_prio', 'update')
endfunction


" # Quickfix      options {{{2
" Function: lh#btw#option#_qf_position() {{{3
function! lh#btw#option#_qf_position() abort
  return s:get('qf_position', '', 'g')
endfunction

" Function: lh#btw#option#_qf_size() {{{3
function! lh#btw#option#_qf_size() abort
  " Default: 1/4 of total screen size
  let mx = min([15, &lines / 4])
  let nl = mx > &winfixheight ? mx : &winfixheight
  let nl = s:get_explicit_names('qf_size', 'QF_size', nl, 'g')
  return nl
endfunction

" Function: lh#btw#option#_qf_syntax() {{{3
function! lh#btw#option#_qf_syntax() abort
  " TODO: check why the order has been reversed
  return lh#option#get('BTW_qf_syntax', '', 'gpb')
endfunction

" # Miscellaneous options {{{2
" Function: lh#btw#option#_run_parameters() {{{3
function! lh#btw#option#_run_parameters() abort
  return s:get('run_parameters','')
endfunction

" Function: lh#btw#option#_project_name([bufid]) {{{3
function! lh#btw#option#_project_name(...) abort
  return a:0 > 0
        \ ? s:get_from_buf(a:1, 'project_name', lh#option#unset())
        \ : s:get('project_name')
endfunction

" Function: lh#btw#option#_compilation_dir([bufid]) {{{3
function! lh#btw#option#_compilation_dir(...) abort
  return a:0 > 0
        \ ? s:get_from_buf(a:1, 'compilation_dir', '.')
        \ : s:get('compilation_dir', '.')
endfunction

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

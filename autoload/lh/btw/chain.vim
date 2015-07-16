"=============================================================================
" File:         autoload/lh/btw/chain.vim                         {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/vim-build-tools-wrapper>
" Version:      0.5.0.
let s:k_version = '050'
" Created:      23rd Mar 2015
" Last Update:  09th Jul 2015
"------------------------------------------------------------------------
" Description:
"       Internal functions dedicated to filter chain management.
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version {{{2
function! lh#btw#chain#version()
  return s:k_version
endfunction

" # Debug   {{{2
if !exists('s:verbose')
  let s:verbose = 0
endif
function! lh#btw#chain#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Verbose(expr)
  if s:verbose
    echomsg a:expr
  endif
endfunction

function! lh#btw#chain#debug(expr)
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1

"------------------------------------------------------------------------
" ## Internal functions {{{1

" # Filter list management {{{2
" lh#btw#chain#_filters_list():                  Helper {{{3
function! lh#btw#chain#_filters_list() abort
  return lh#option#get('BTW_filters_list', [])

  " problem: lh#option#get this will ignore empty variables => custom function
  " (I suspect I wrote the previous comment before I wrote
  " lh#option#get_non_empty())
  if     exists('b:BTW_filters_list') | return b:BTW_filters_list
  elseif exists('g:BTW_filters_list') | return g:BTW_filters_list
  else                                | return []
  endif
endfunction

" AddFilter(scope,filter):                       Exposed/public feature {{{3
function! s:AddFilter(scope, filter) abort
  let var = a:scope . ':BTW_filters_list'
  if     !exists(var) || empty({var})
    let {var} = [a:filter]
  elseif ! s:HasFilter(a:filter, var)
    let {var} += [a:filter]
  endif
endfunction

" RemoveFilter(scope,filter):                    Exposed/public feature {{{3
function! s:RemoveFilter(scope, filter) abort
  if 'g' == a:scope
    " Don't try to be smarter than that: we won't remove it from local filter list.
    if ! s:DoRemoveFilter(a:scope, a:filter)
      call lh#common#error_msg('BTW: Error no global filter-plugin named "'
            \ . a:filter . '" to remove')
    endif
  elseif ('b' == a:scope)
    let bnum = bufnr('%')
    let buffers = lh#buffer#list()
    for buffer in buffers
      let var = getbufvar(buffer, 'BTW_filters_list', [])
      let idx = match(var, a:filter)
      if buffer == bnum
            \ || (idx!=-1 && 1==CONFIRM("Do you want to remove ".string(a:filter)." from ".bufname(buffer)." filter list?", "&Yes\n&No", 1))
        if -1 == idx
          call lh#common#error_msg('BTW: Error no global filter-plugin named "'
                \ . a:filter . '" to remove')
        else
          call remove(var, idx)
          " No need to call setbufvar as getbufvar returns a reference
        endif
      endif
    endfor
  endif
  return

  " Old code that was trying to be too smart
  let var = a:scope . ':BTW_filters_list'

  if 'g' == a:scope
    " If global scope: remove it for every buffer
    let bnum = bufnr('%')
    exe 'bufdo call s:DoRemoveFilter("b", "'.a:filter.'")'
    " exe 'bufdo BTW removelocal '.a:filter
    exe ':buffer '.bnum
  elseif ('b' == a:scope) && !exists(var)
        \ && s:HasFilter(a:filter, var)
        " \ && (match(lh#btw#chain#_filters_list(),a:filter) >= 0)
    " Defines a local set of filter-plugins from previous the global list
    let b:BTW_filters_list = g:BTW_filters_list
    " finally: call DoRemove
  else
    call lh#common#error_msg('BTW: Error no such filter-plugin to remove "'
          \ . a:filter . '"')
    " s:DoRemove(): kind of "big" no-op
  endif

  " Do remove it for this scope
  call s:DoRemoveFilter(a:scope, a:filter)
endfunction

function! s:DoRemoveFilter(scope,filter) abort
  let var = a:scope . ':BTW_filters_list'
  if exists(var)
    let idx = match({var}, a:filter)
    if -1 != idx
      call remove({var}, idx)
      return 1
    endif
  endif
  return 0
endfunction

" HasFilterGuessScope(filter):                   {{{3
function! s:HasFilterGuessScope(filter) abort
  if     exists('b:BTW_filters_list')
    return s:HasFilter(a:filter, 'b:BTW_filters_list')
  elseif exists('g:BTW_filters_list')
    return s:HasFilter(a:filter, 'g:BTW_filters_list')
  else
    return 0
  endif
endfunction

" HasFilter(filter, var):                        {{{3
" @pre exists({a:var})
function! s:HasFilter(filter, var) abort
  return -1 != match({a:var}, a:filter)
endfunction

" lh#btw#chain#_find_filter(filter):             Helper {{{3
function! lh#btw#chain#_find_filter(filter) abort
  let filter = a:filter . '.vim'
  let result =globpath(&rtp, "compiler/BTW-".filter) . "\n" .
        \ globpath(&rtp, "compiler/BTW_".filter). "\n" .
        \ globpath(&rtp, "compiler/BTW/".filter)
  let result = substitute(result, '\n\n', '\n', 'g')
  let result = substitute(result, '^\n', '', 'g')
  return result
endfunction


" # Build Chain:                         {{{2
let s:sfile = expand('<sfile>:p')

" lh#btw#chain#_BTW(command [,filter]):          Main function {{{3
if !exists('g:BTW_BTW_in_use')
  function! lh#btw#chain#_BTW(command, ...) abort
    " todo: check a:0 > 1
    if     'set'      == a:command | let g:BTW_build_tool = a:1
      if exists('b:BTW_build_tool')
        let b:BTW_build_tool = a:1
      endif
    elseif 'setlocal'       == a:command | let b:BTW_build_tool = a:1
    elseif 'setoption'      == a:command | call s:SetOption('g', a:000)
    elseif 'setoptionlocal' == a:command | call s:SetOption('b', a:000)
    elseif 'add'            == a:command | call s:AddFilter('g', a:1)
    elseif 'addlocal'       == a:command | call s:AddFilter('b', a:1)
      " if exists('b:BTW_filters_list') " ?????
        " call s:AddFilter('b', a:1)
      " endif
    elseif 'remove'         == a:command | call s:RemoveFilter('g', a:1)
    elseif 'removelocal'    == a:command | call s:RemoveFilter('b', a:1)
    elseif 'rebuild'        == a:command " wait for lh#btw#chain#_reconstruct()
    elseif 'echo'           == a:command | exe "echo s:".a:1
    elseif 'debug'          == a:command | exe "debug echo s:".a:1
      " echo s:{a:f1} ## don't support «echo s:f('foo')»
    elseif 'reloadPlugin'   == a:command
      let cleanup = lh#on#exit()
            \.restore('g:force_reload_BuildToolsWrapper')
            \.restore('g:BTW_BTW_in_use')
      try
        let g:BTW_BTW_in_use = 1
        runtime! autoload/lh/btw/*.vim autoload/lh/btw.vim

        let g:force_reload_BuildToolsWrapper = 1
        runtime plugin/BuildToolsWrapper.vim
      finally
        call cleanup.finalize()
      endtry
      return
    elseif a:command =~ '\%(help\|?\)'
      call s:Usage()
      return
    elseif a:command =~ '\<new\%[_project]\>'
      call call(function('lh#btw#project#new'), a:000)
    endif
    call lh#btw#chain#_reconstruct()
  endfunction
endif

" lh#btw#chain#_reconstruct():                   {{{3
function! lh#btw#chain#_reconstruct() abort
  let efm = {'value': '', 'post':[] }
  let prog = lh#option#get('BTW_build_tool', 'make')
  call s:LoadFilter(prog)
  let Makeprg = lh#option#get('BTW_filter_program_'.prog, prog, 'bg')
  if type(Makeprg) == type(function('has'))
    let makeprg = Makeprg('$*')
  else
    let makeprg = Makeprg . ' $*'
  endif
  call s:AdjustEFM(prog, efm)

  let dir = lh#option#get('BTW_compilation_dir', '')
  if !empty(dir)
    let makeprg = '(cd '.shellescape(dir).' && ' . makeprg . ')'
  endif

  let filters_list = lh#btw#chain#_filters_list()
  for filter in filters_list
    call s:LoadFilter(filter)
    " let efm = efm . ',' . lh#option#get('BTW_adjust_efm_'.filter, '', 'g')
    call s:AdjustEFM(filter, efm)
    let prg = lh#option#get(s:ToVarName('BTW_filter_program_'.filter), '', 'bg')

    if strlen(prg)
      " Faire dans BTW-{filter}.vim
      " let prg = substitute(expand('<sfile>:p:h'), ' ', '\\ ', 'g')
      let makeprg .= " 2>&1 \\| ".prg
    endif
  endfor

  let islocal = exists('b:BTW_build_tool') || exists('b:BTW_filters_list')
  let local = islocal ? 'l:' : ''
  let set   = islocal ? 'setlocal ' : 'set '

  " Set makeprog
  exe 'let &'.local.'makeprg = makeprg'
  " set does not seems to work
  "   exe set . 'makeprg="'. makeprg . '"'
  "   exe set . 'makeprg='. escape(makeprg, '\ ')

  " Set errorformat ; strip redundant commas
  let v_efm = substitute(efm.value, ',\+', ',', "g")
  let v_efm = matchstr(v_efm, '^,*\zs.*')
  for P in efm.post
    let v_efm = P(v_efm)
  endfor
  " default used ... by default
  if strlen(v_efm)
    " Add the new formats
    " exe set . 'efm+="'. efm . '"'
    " exe set . 'efm+='. escape(efm, '\ ')
    " exe 'let &'.local.'efm = &'.local."efm . ',' . efm"
    exe 'let &'.local.'efm = v_efm'
  endif
  " set efm&vim                  " Reset to default value
  " let &efm = &efm . ',' . efm  " Add the new formats
endfunction

" DefaultEFM():                                  {{{3
" @return default value of &efm
function! s:DefaultEFM(wanted_efm) abort
  " call Dfunc('s:DefaultEFM('.a:wanted_efm.')')
  let save_efm = &l:efm
  if a:wanted_efm == 'default efm'
    setlocal efm&vim
  else
    " if exists("current_compiler")
      silent! unlet b:current_compiler
      silent! unlet g:current_compiler
    " endif
    " exe 'compiler '.a:wanted_efm
    exe 'runtime compiler/'.a:wanted_efm.'.vim'
    if strlen(&makeprg) && !exists('g:BTW_filter_program_'.a:wanted_efm) && !exists('b:BTW_filter_program_'.a:wanted_efm)
      " @todo use the correct scope -> b:/g:
      let g:BTW_filter_program_{a:wanted_efm} = &makeprg
    endif
  endif
  let efm = &l:efm
  let &l:efm = save_efm
  " call Dret('s:DefaultEFM '.efm)
  return efm
endfunction

" AdjustEFM(filter, efm):                        {{{3
function! s:AdjustEFM(filter, efm) abort
  let filter_efm = lh#option#get('BTW_adjust_efm_'.a:filter, '', 'bg')
  if type(filter_efm) == type({})
    let added = filter_efm.value
    if has_key(filter_efm, 'post')
      let a:efm.post += [filter_efm.post]
    endif
  else
    let added = filter_efm
  endif
  " if added =~ "default efm"
  " TODO: use split and join
    let added = substitute(added, 'default efm',
          \ escape(s:DefaultEFM('default efm'), '\'), '')
  " endif
  if added =~ 'import:'
    let compiler_plugin_imported = matchstr(added, 'import: \zs[^,]*')
    let added = substitute(added, 'import: \%([^,]\{-}\ze\%(,\|$\)\)',
          \ escape(s:DefaultEFM(compiler_plugin_imported), '\'), '')
  endif
  let a:efm.value =
        \   lh#option#get('BTW_ignore_efm_'.a:filter, '', 'bg')
        \ . a:efm.value
        \ . (strlen(added) ? ','.added : '')
endfunction

" ToVarName(filterName):                         {{{3
function! s:ToVarName(filterName) abort
  let filterName = substitute(a:filterName, '[^A-Za-z0-9_]', '_', 'g')
  return filterName
endfunction

" LoadFilter(filter):                            {{{3
function! s:LoadFilter(filter) abort
  if     0 != strlen(lh#btw#chain#_find_filter(a:filter))
    " First nominal case: there is a BTW-a:filter that will be loaded
    exe  'runtime! compiler/BTW-'.a:filter.'.vim compiler/BTW_'.a:filter.'.vim compiler/BTW/'.a:filter.'.vim'
    " echo 'runtime! compiler/BTW-'.a:filter.'.vim compiler/BTW_'.a:filter.'.vim compiler/BTW/'.a:filter.'.vim'
  elseif 0 != strlen(globpath(&rtp, 'compiler/'.a:filter.'.vim'))
    " Second case: there is a compiler plugin named {a:filter}.vim
    let b:BTW_adjust_efm_{a:filter} = 'import: '.a:filter
  elseif 0 != strlen(globpath(&rtp, 'compiler/BTW/'.a:filter.'.pl'))
    " Third case: there is a perl script compiler/BTW/{a:filter}.pl
    let g:BTW_filter_program_{a:filter} = globpath(&rtp, 'compiler/BTW/'.a:filter.'.vim')
  elseif executable(a:filter)
    let filter = s:ToVarName(a:filter)
    let g:BTW_filter_program_{filter} = a:filter
  else
    " There is no such a:filter
  endif
endfunction

" ToolsChain():                                  Helper {{{3
function! s:ToolsChain() abort
  return join([lh#option#get('BTW_build_tool', 'make')] + lh#btw#chain#_filters_list(), ' | ')
endfunction

" Usage(): {{{3
function! s:Usage()
  echo "Build Tools Wrapper: USAGE"
endfunction

" # Miscelleanous:                       {{{2

" Function: s:SetOption(scope, opts) {{{3
function! s:SetOption(scope, opts) abort
  let a_name = 'BTW_'.a:opts[0]
  if len(a:opts) > 1
    let value = a:opts[1]
    if a:scope == 'g'
      let name = 'b:'.a_name
      if exists(name)
        call lh#common#warning_msg("Warning: ".name." is already set to ".{name})
      endif
    endif
    let name = a:scope.':'.a_name
    let {name} = value
  else " only display the value
    let value = lh#option#get(a_name)
    if lh#option#is_set(value)
      echo "Option " . a_name . " is set to ".string(value)
    else
        call lh#common#warning_msg("Warning: ".a_name." is not set.")
    endif
  endif
endfunction
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

"=============================================================================
" File:         autoload/lh/btw/chain.vim                         {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/vim-build-tools-wrapper>
" Version:      0.7.0.
let s:k_version = '070'
" Created:      23rd Mar 2015
" Last Update:  17th Feb 2017
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
let s:verbose = get(s:, 'verbose', 0)
function! lh#btw#chain#verbose(...)
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

function! lh#btw#chain#debug(expr) abort
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1

"------------------------------------------------------------------------
" ## Internal functions {{{1
let s:filter_list_varname = 'BTW._filter.list'

" # Filter list management {{{2
" lh#btw#chain#_filters_list(scope):             Helper {{{3
function! lh#btw#chain#_filters_list(scope) abort
  return lh#option#get(s:filter_list_varname, [], a:scope)
endfunction

" AddFilter(scope,filter):                       Exposed/public feature {{{3
" @pre a:scope =~ '[pg]'
" but, we may not be within a project context
function! s:AddFilter(scope, filter) abort
  if a:scope == 'p'
    let var = lh#project#_crt_var_name('p:'.s:filter_list_varname)
  else
    let var = a:scope . ':'.s:filter_list_varname
  endif
  if     !exists(var) || empty(eval(var))
    call lh#let#to(var, [a:filter])
  elseif !s:HasFilter(a:filter, var)
    call lh#let#to(var, eval(var) + [a:filter])
  endif
endfunction

" RemoveFilter(scope,filter):                    Exposed/public feature {{{3
" @pre a:scope =~ '[pg]'
" but, we may not be within a project context (TODO: test this case)
function! s:RemoveFilter(scope, filter) abort
  if a:scope != 'p'
    let var = a:scope . ':'.s:filter_list_varname
  elseif lh#project#is_in_a_project()
    let var = lh#project#_crt_var_name('p:'.s:filter_list_varname)
  else
    " we need to purge it from every buffer
    let buffers = lh#buffer#list()
    for buffer in buffers
      let filter_list = getbufvar(buffer, s:filter_list_varname, [])
      let idx = match(filter_list, a:filter)
      if -1 != idx
        call remove(filter_list, idx)
        " No need to call setbufvar as getbufvar returns a reference
      endif
    endfor
    return
  endif

  " Don't try to be smarter than that: we won't remove it from local filter list.
  if exists(var)
    let list = eval(var)
    let idx = match(list, a:filter)
    if -1 != idx
      call remove(list, idx)
      return
    endif
  endif
  call lh#common#error_msg('BTW: Error no '.(a:scope == 'g' ? 'global' : 'project')
        \ .' filter-plugin named "' . a:filter . '" to remove')
endfunction

" HasFilterGuessScope(filter):                   {{{3
function! s:HasFilterGuessScope(filter) abort
  if     exists('b:'.s:filter_list_varname)
    " Case when not whithin a project
    return s:HasFilter(a:filter, 'b:'.s:filter_list_varname)
  elseif exists(lh#project#crt_bufvar_name().'.variables.'.s:filter_list_varname)
    return s:HasFilter(a:filter, lh#project#crt_bufvar_name().'.variables.'.s:filter_list_varname)
  elseif exists('g:'.s:filter_list_varname)
    return s:HasFilter(a:filter, 'g:'.s:filter_list_varname)
  else
    return 0
  endif
endfunction

" HasFilter(filter, var):                        {{{3
" @pre exists({a:var})
function! s:HasFilter(filter, var) abort
  if type(a:var) == type('')
    return -1 != match(eval(a:var), a:filter)
  else
    return -1 != match(a:var, a:filter)
  endif
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
    call s:Verbose(':BTW %1', [a:command]+a:000)
    " todo: check a:0 > 1
    if     'set'      == a:command                    | let g:BTW_build_tool = a:1
      if exists('b:BTW_build_tool')
        let b:BTW_build_tool = a:1
      endif
    elseif 'setlocal'       == a:command              | let b:BTW_build_tool = a:1
    elseif 'setoption'      == a:command              | call s:SetOption('g', a:000)
    elseif 'setoptionlocal' == a:command              | call s:SetOption('p', a:000)
    elseif 'config_out_of_sources_build' == a:command | call s:ConfigOutOfSourcesBuild('p', a:000)
    elseif 'add'            == a:command              | call s:AddFilter('g', a:1)
    elseif 'addlocal'       == a:command              | call s:AddFilter('p', a:1)
      " if exists('b:'.s:filter_list_varname) " ?????
        " call s:AddFilter('b', a:1)
      " endif
    elseif 'remove'         == a:command              | call s:RemoveFilter('g', a:1)
    elseif 'removelocal'    == a:command              | call s:RemoveFilter('p', a:1)
    elseif 'rebuild'        == a:command " wait for lh#btw#chain#_reconstruct()
    elseif 'echo'           == a:command              | exe "echo s:".a:1
    elseif 'debug'          == a:command              | exe "debug echo s:".a:1
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

" Function: lh#btw#chain#_resolve_makeprg(scope) {{{3
function! lh#btw#chain#_resolve_makeprg(scope) abort
  if lh#project#is_a_project(a:scope)
    let pattern = a:scope.get('BTW._makeprg_pattern', &makeprg)
    let dir = lh#btw#option#_compilation_dir(a:scope.buffers[0])
  else
    let pattern = lh#option#get('BTW._makeprg_pattern', &makeprg)
    let dir = lh#btw#option#_compilation_dir()
  endif
  let dir = shellescape(dir)
  let opt = {'dir': dir}
  let makeprg = lh#fmt#printf(pattern, opt)
  if lh#project#is_a_project(a:scope)
    if ! get(a:scope, 'abstract', 0)
      call a:scope.set('&makeprg', '='.makeprg)
    endif
  else
    call lh#let#to('&'.a:scope.'makeprg', makeprg)
  endif
endfunction

" lh#btw#chain#_reconstruct():                   {{{3
"TODO: Take a project into parameter!!!
function! lh#btw#chain#_reconstruct() abort
  let efm = {'value': '', 'post':[] }
  " First filter has a special status:
  " - if not set then it's make.
  " - this is where "$*" is injected
  " - this is where directory is changed
  let prog = lh#btw#option#_build_tool()
  call s:LoadFilter(prog)
  let Makeprg = lh#btw#option#_filter_program(prog)
  if type(Makeprg) == type(function('has'))
    let makeprg_pattern = Makeprg('$*')
  else
    let makeprg_pattern = Makeprg . ' $*'
  endif
  call s:AdjustEFM(prog, efm)

  let dir = lh#btw#option#_compilation_dir()
  call s:Verbose('Compiling with %1 in %2 (bid: %3 - %4)', makeprg_pattern, dir, bufnr('%'), bufname('%'))
  let need_pipefail = 0
  if !empty(dir) && lh#option#is_set(dir)
    let makeprg_pattern = '(cd %{1.dir} && ' . makeprg_pattern . ')'
    " let makeprg = '(cd '.shellescape(dir).' && ' . makeprg . ')'
  endif

  let filters_list = lh#btw#chain#_filters_list('pg')
  for filter in filters_list
    call s:LoadFilter(filter)
    " let efm = efm . ',' . lh#option#get('BTW_adjust_efm_'.filter, '', 'g')
    call s:AdjustEFM(filter, efm)

    " does the filter implies an external script to run
    let prg = lh#btw#option#_filter_program_empty_default(s:ToVarName(filter))
    if !empty(prg)
      " Faire dans BTW-{filter}.vim
      " let prg = substitute(expand('<sfile>:p:h'), ' ', '\\ ', 'g')
      let makeprg_pattern .= ' 2>&1 \| '.prg
      let need_pipefail = 1
    endif
  endfor
  if &shell =~ 'bash' && need_pipefail
    " TODO support other UNIX flavors
    " see http://stackoverflow.com/questions/1221833/bash-pipe-output-and-capture-exit-status
    let makeprg_pattern = 'set -o pipefail ; ' . makeprg_pattern
  endif

  " Set errorformat ; strip redundant commas
  let v_efm = substitute(efm.value, ',\+', ',', "g")
  let v_efm = matchstr(v_efm, '^,*\zs.*')
  for P in efm.post
    let v_efm = P(v_efm)
  endfor

  " and finally set makeprg and efm variables in the right scope
  let islocal = exists('b:BTW_build_tool') || exists('b:BTW') || exists('b:'.s:filter_list_varname)
  if lh#project#is_in_a_project()
    let make_scope = lh#project#crt()
    let scope = 'p:'
  elseif islocal
    let make_scope = 'l:'
    let scope = 'b:'
  else
    let make_scope = ''
    let scope = 'g:'
  endif
  call lh#let#to(scope.'BTW._makeprg_pattern', makeprg_pattern)
  call lh#btw#chain#_resolve_makeprg(make_scope)

  " default used ... by default
  if !empty(v_efm)
    " Add the new formats
    call lh#let#to('&'.scope.'efm', '='.v_efm)
  endif
endfunction

" DefaultEFM():                                  {{{3
" @return default value of &efm
function! s:DefaultEFM(wanted_efm) abort
  let cleanup = lh#on#exit()
        \.restore('&efm')
  try
    call s:Verbose('wanted_efm: %1', a:wanted_efm)
    if a:wanted_efm == 'default efm'
      setlocal efm&vim
    else
      if exists("g:current_compiler")
        unlet g:current_compiler
      endif
      " exe 'compiler '.a:wanted_efm
      exe 'runtime compiler/'.a:wanted_efm.'.vim'
      " TODO: check why did I update BTW._filter.program in s:DefaultEFM() ?
      if !empty(&makeprg) && !empty(lh#btw#option#_filter_program_empty_default(a:wanted_efm))
        " TODO: do we really need to have this option local to a project?
        " -> It's likelly we can share it with anything.
        let varname = lh#btw#option#_best_place_to_write('_filter.program.'.a:wanted_efm)
        call lh#let#to(varname, &makeprg)
      endif
    endif
    let efm = &l:efm
    return efm
  finally
    call cleanup.finalize()
  endtry
endfunction

" AdjustEFM(filter, efm):                        {{{3
function! s:AdjustEFM(filter, efm) abort
  let filter_efm = lh#btw#option#efm(a:filter)
  call lh#assert#true(lh#option#is_set(filter_efm))
  if type(filter_efm) == type({})
    let added = filter_efm.value
    if has_key(filter_efm, 'post')
      let a:efm.post += [filter_efm.post]
    endif
  else
    let added = filter_efm
  endif
  " TODO: use split and join
  let added = substitute(added, 'default efm',
        \ escape(s:DefaultEFM('default efm'), '\'), '')
  if added =~ 'import:'
    " limitation: can import only one filter!
    let compiler_plugin_imported = matchstr(added, 'import: \zs[^,]*')
    let added = substitute(added, 'import: \%([^,]\{-}\ze\%(,\|$\)\)',
          \ escape(s:DefaultEFM(compiler_plugin_imported), '\'), '')
  endif
  let a:efm.value =
        \   lh#btw#option#ignore_efm(a:filter)
        \ . a:efm.value
        \ . (!empty(added) ? ','.added : '')
endfunction

" ToVarName(filterName):                         {{{3
function! s:ToVarName(filterName) abort
  let filterName = substitute(a:filterName, '[^A-Za-z0-9_]', '_', 'g')
  return filterName
endfunction

" LoadFilter(filter):                            {{{3
function! s:LoadFilter(filter) abort
  " TODO: do we really need to have "_filter.program.*" option local to a project?
  " -> It's likelly we can share it with anything.
  if     !empty(lh#btw#chain#_find_filter(a:filter))
    " First nominal case: there is a BTW-a:filter that will be loaded
    call s:Verbose('Load BTW filter -> runtime! compiler/BTW-'.a:filter.'.vim compiler/BTW_'.a:filter.'.vim compiler/BTW/'.a:filter.'.vim')
    exe  'runtime! compiler/BTW-'.a:filter.'.vim compiler/BTW_'.a:filter.'.vim compiler/BTW/'.a:filter.'.vim'
  elseif !empty(globpath(&rtp, 'compiler/'.a:filter.'.vim'))
    " Second case: there is a compiler plugin named {a:filter}.vim
    call s:Verbose("Load compiler plugin %1.vim", a:filter)
    let varname = lh#btw#option#_best_place_to_write('_filter.efm.use.'.a:filter)
    call lh#let#to(varname, 'import: '.a:filter)
    " let b:BTW_adjust_efm_{a:filter} = 'import: '.a:filter
  elseif !empty(globpath(&rtp, 'compiler/BTW/'.a:filter.'.pl'))
    " Third case: there is a perl script compiler/BTW/{a:filter}.pl
    let path = globpath(&rtp, 'compiler/BTW/'.a:filter.'.vim')
    call s:Verbose("Use perl script %1", path)
    let varname = lh#btw#option#_best_place_to_write('_filter.program.'.a:filter)
    call lh#let#to(varname, path)
    " let g:BTW_filter_program_{a:filter} = path
  elseif executable(a:filter)
    " Fourth case: there is a executable with the same name
    let filter = s:ToVarName(a:filter)
    let varname = lh#btw#option#_best_place_to_write('_filter.program.'.a:filter)
    call lh#let#to(varname, a:filter)
    " let g:BTW_filter_program_{filter} = a:filter
  else
    " There is no such a:filter
  endif
endfunction

" ToolsChain():                                  Helper {{{3
function! s:ToolsChain() abort
  return join([lh#btw#option#_build_tool()] + lh#btw#chain#_filters_list('pg'), ' | ')
endfunction

" Usage():                                       {{{3
function! s:Usage()
  echo "Build Tools Wrapper: USAGE"
  echo "  Compilation of current lhvl-project"
  echo "    :BTW setlocal    <filter> -- sets the filter as the main one for compiling current project"
  echo "    :BTW addlocal    <filter> -- adds filter for current project compilation"
  echo "    :BTW removelocal <filter> -- removes filter for current project compilation"
  echo "    :BTW setoptionlocal"
  echo "  Compilation outside lhvl-project context"
  echo "    :BTW set         <filter> -- sets the filter as the main one for compiling outside projects"
  echo "    :BTW add         <filter> -- adds filter for when compiling outside projects"
  echo "    :BTW remove      <filter> -- removes filter for when compiling outside projects"
  echo "    :BTW setoption"
  echo "  Miscelleanous"
  echo "    :BTW echo  <expr>         -- Prints various informations (current toolchain, current target, executable...)"
  echo "    :BTW rebuild              -- Reloads filters used"
  echo "    :BTW new_project          -- Prepare the local_vimrc configuration for a new project using Build Tools Wrapper"
  echo "    :BTW reloadPlugin         -- Maintenance function"
endfunction

" # Command completion                   {{{2
" Constants                                                    {{{3
let s:commands="setlocal\nset\nsetoptionlocal\nsetoption\nconfig_out_of_sources_build\naddlocal\nadd\nremovelocal\nremove\nrebuild\necho\ndebug\nreloadPlugin\nnew_project\n?\nhelp"
let s:functions="ToolsChain()\nHasFilterGuessScope(\nHasFilter(\nFindFilter("
let s:functions=s:functions. "\nProjectName()\nTargetRule()\nExecutable()"
let s:variables="commands\nfunctions\nvariables"
let s:k_new_prj = ['c', 'cpp', 'cmake', 'name=', 'config=', 'src_dir=']
let s:k_options = ['compilation_dir', 'project_config', 'project_name',
      \ 'run_parameters', 'executable', 'target', 'project',
      \ 'autoscroll_background_compilation', 'goto_error' ]

" lh#btw#chain#_BTW_complete(ArgLead, CmdLine, CursorPos):      Auto-complete {{{3
" TODO: detect within a project to reduce commands choices to "setlocal",
" "addlocal", "removelocal"
function! lh#btw#chain#_BTW_complete(ArgLead, CmdLine, CursorPos)
  let tmp = substitute(a:CmdLine, '\s*\S*', 'Z', 'g')
  let pos = strlen(tmp)
  call s:Verbose('complete(lead="%1", cmdline="%2", cursorpos=%3) -- tmp=%4, pos=%5', a:ArgLead, a:CmdLine, a:CursorPos, tmp, pos)

  if     2 == pos
    " First argument: a command
    return s:commands
  elseif 3 == pos
    " Second argument: first arg of the command
    if     -1 != match(a:CmdLine, '^BTW\s\+\%(echo\|debug\)')
      return s:functions . "\n" . s:variables
    elseif -1 != match(a:CmdLine, '^BTW\s\+\%(help\|?\)')
    elseif -1 != match(a:CmdLine, '^BTW\s\+\%(set\|add\)\%(local\)\=\>') " Adds a filter
      let files = lh#btw#chain#_find_filter('*')
      let files = substitute(files,
            \ '\(^\|\n\).\{-}compiler[\\/]BTW[-_\\/]\(.\{-}\)\.vim\>\ze\%(\n\|$\)',
            \ '\1\2', 'g')
      return files
    elseif -1 != match(a:CmdLine, '^BTW\s\+\%(setoption\)\%(local\)\=\>')
      return join(s:k_options, "\n")
    elseif -1 != match(a:CmdLine, '^BTW\s\+\%(config_out_of_sources_build\)\%(_local\)\=\>')
     let paths = filter(split(glob(a:ArgLead.'*'), "\n"), 'isdirectory(v:val)')
     return join(paths, "\n")
   elseif -1 != match(a:CmdLine, '^BTW\s\+removelocal') " Removes a local filter
      return join(lh#btw#chain#_filters_list('p'), "\n")
    elseif -1 != match(a:CmdLine, '^BTW\s\+remove')      " Removes a global filter
      return join(lh#btw#chain#_filters_list('g'), "\n")
    elseif -1 != match(a:CmdLine, '^BTW\s\+\<new\%[_project]\>')
      return "c\ncpp\ncmake\ndoxygen\nname=\nconfig=\nsrc_dir="
    endif
  elseif 4 <= pos
    let p = matchend(a:CmdLine, '^BTW\s\+\<new\%[_project]\>')
    if -1 != p
      let already_there = split(a:CmdLine[p : ])
      " let g:already_there = already_there
      return join(filter(copy(s:k_new_prj), 'match(already_there, "\\<".v:val."\\>")==-1'), "\n")
    endif
  endif
  " finally: unknown
  echoerr 'BTW: unespected parameter ``'. a:ArgLead ."''"
  return ''
endfunction

" # Miscelleanous:                       {{{2

" Function: s:SetOption(scope, opts) {{{3
function! s:SetOption(scope, opts) abort
  let a_name = 'BTW.'.a:opts[0]
  if len(a:opts) > 1
    let value = a:opts[1]
    if a:scope == 'g'
      let name = lh#project#_crt_var_name('p:'.a_name)
      if exists(name)
        call lh#common#warning_msg("Warning: ".name." is already set to ".{name})
      endif
    endif
    let name = a:scope.':'.a_name
    call lh#let#to(name, value)
  else " only display the value
    let value = lh#option#get(a_name)
    if lh#option#is_set(value)
      echo "Option " . a_name . " is set to ".lh#object#to_string(value)
    else
        call lh#common#warning_msg("Warning: ".a_name." is not set.")
    endif
  endif
endfunction

function! s:ConfigOutOfSourcesBuild(scope, opts) " {{{3
  call lh#assert#value(len(a:opts)).is_ge(0) " dir
  let dir = a:opts[0]
  " When dealing with OoSB, the target is usually "all"
  " However, we must not override previous settings
  let target = lh#option#get('BTW.target', get(a:opts, 2, 'all'))
  call s:SetOption(a:scope, ['compilation_dir', fnamemodify(dir, ':p')])
  call s:SetOption(a:scope, ['target', target])
endfunction
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

"=============================================================================
" File:         autoload/lh/btw/build.vim                         {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} gmail {dot} com>
"		<URL:http://github.com/LucHermitte/vim-build-tools-wrapper>
" Version:      0.4.0.
let s:k_version = '040'
" Created:      23rd Mar 2015
" Last Update:  23rd Mar 2015
"------------------------------------------------------------------------
" Description:
"       Internal functions used to build projects
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------
" ## Misc Functions     {{{1
" # Version        {{{2
function! lh#btw#build#version()
  return s:k_version
endfunction

" # Debug          {{{2
if !exists('s:verbose')
  let s:verbose = 0
endif
function! lh#btw#build#verbose(...)
  if a:0 > 0 | let s:verbose = a:1 | endif
  return s:verbose
endfunction

function! s:Verbose(expr)
  if s:verbose
    echomsg a:expr
  endif
endfunction

function! lh#btw#build#debug(expr)
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Exported functions {{{1

"------------------------------------------------------------------------
" ## Internal functions {{{1

" # Options        {{{2
" TODO: distinguish rule-name for the compilation (e.g. ``all'') and the final
" executable

" Function: s:ProjectName()                           {{{3
" This option can be defined:
" - with a _vimrc_local file
" - with a let-modeline
function! s:ProjectName() abort
  if     exists('b:BTW_project') | return b:BTW_project
  elseif exists('g:BTW_project') | return g:BTW_project
  elseif &ft == 'qf'             | cclose | return s:ProjectName()
  else                           | return '%<'
  endif
endfunction

" Function: s:TargetRule()                            {{{3
function! s:TargetRule() abort
  " TODO: find a better name
  " TODO: try to detect available rules in Makefile/main.aap/...,
  " and cache them
  if &ft == 'qf' | cclose | return s:TargetRule() | endif
  if     exists('b:BTW_project_target') | return b:BTW_project_target
  elseif exists('g:BTW_project_target') | return g:BTW_project_target
  else
    let res = s:ProjectName()
    if !strlen(res)
      res = 'all' " just a guess
    endif
    return res
  endif
endfunction

" Function: s:Executable()                            {{{3
function! s:Executable() abort
  " TODO: find a better name
  " TODO: try to detect available rules in Makefile/main.aap/...,
  " and cache them
  " TODO: cclose is not the best way to quit the qf window -> memorize the
  " buffer from which it was compiled last
  if &ft == 'qf' | cclose | return s:Executable() | endif
  if     exists('b:BTW_project_executable') | return b:BTW_project_executable
  elseif exists('g:BTW_project_executable') | return g:BTW_project_executable
  else
    let res = s:ProjectName()
    if !strlen(res)
      " TODO: glob()+executable() -> possible executable in the build
      " directory
    endif
    return res
  endif
endfunction

" # Run (anything) {{{2
" Function: s:RunInBackGround()                       {{{3
if exists('s:run_in_background')
    unlet s:run_in_background
endif

function! s:FetchRunInBackground() abort
  let rib_progname = lh#system#OnDOSWindows()
        \ ? 'run_and_recontact_vim'
        \ : 'run_in_background'

  if     exists('*globpath')
    let s:run_in_background = globpath(&rtp, 'compiler/BTW/'.rib_progname.'.pl')
  elseif exists(':SearchInRuntime')
    SearchInRuntime let\ s:run_in_background=" compiler/BTW/".rib_progname.".pl | "
  else
    call lh#common#error_msg( "Build Tools Wrapper:\n  This plugin requires either a version of Vim that defines |globpath()| or the script searchInRuntime.vim.\n"
          \."  Please upgrade your version of vim, or install searchInRuntime.vim\n"
          \."  Check on <http://hermitte.free.fr/vim/> or <http://vim.sf.net/> script #229")
    finish
  endif

  let s:run_in_background = 'perl '.lh#system#FixPathName(s:run_in_background, !lh#system#OnDOSWindows())
endfunction

function! s:RunInBackground()
  if !exists('s:run_in_background')
    call s:FetchRunInBackground()
  endif
  return s:run_in_background
endfunction


" Function: s:DoRunAndCaptureOutput(program [, args]) {{{3
let s:k_multijobs_options = {
      \ 'make': '-j'
      \}
function! s:DoRunAndCaptureOutput(program, ...) abort
  let bg = has('clientserver') && lh#btw#option#_make_in_bg()
  let cleanup = lh#on#exit()
        \.restore('&makeprg')
  if bg
    let run_in = lh#option#get("BTW_make_in_background_in", '')
    if strlen(run_in)
      " Typically xterm -e
      let run_in = ' --program="'.run_in.'"'
    endif
    let &makeprg = s:RunInBackground()
          \ . ' --vim=' . v:progname
          \ . ' --servername=' . v:servername
          \ . run_in
          \ . ' "' . (a:program) . '"'
  else
    let &makeprg = a:program
  endif
  let args = join(a:000, ' ')
  let nb_jobs = lh#btw#option#_make_mj()
  " if has_key(s:k_multijobs_options, a:program) && type(nb_jobs) == type(0) && nb_jobs > 0
  if type(nb_jobs) == type(0) && nb_jobs > 0
    " let args .= ' '. s:k_multijobs_options[a:program] .nb_jobs
    let args .= ' -j' .nb_jobs
  endif

  try
    if lh#system#OnDOSWindows() && bg
      let cmd = ':!start '.substitute(&makeprg, '\$\*', args, 'g')
      exe cmd
    else
      exe 'make! '. args
    endif
  catch /.*/
    if lh#btw#filters#verbose() > 0
      debug call lh#common#error_msg("Error: ".v:exception. " thrown at: ".v:throwpoint)
    else
      call lh#common#error_msg("Error: ".v:exception. " thrown at: ".v:throwpoint)
    endif
  finally
    call cleanup.finalize()
  endtry

  call lh#btw#build#_show_error()
  return bg
endfunction

" # Compile        {{{2
" Function: lh#btw#build#_compile([target])           {{{3
function! lh#btw#build#_compile(...) abort
  update
  if a:0 > 0 && strlen(a:1)
    let rule = a:1
  else
    let rule = s:TargetRule()
  endif
  " else ... pouvoir avoir s:TargetRule() . a:1 ; si <bang> ?!

  if lh#option#get('BTW_use_prio', 'update') == 'update'
    call lh#btw#chain#_reconstruct()
  endif
  let bg = s:DoRunAndCaptureOutput(&makeprg, rule)
  if !bg
    echomsg "Compilation finished".(len(rule)?" (".rule.")" : "")
    if exists(':CompilHintsUpdate')
      :CompilHintsUpdate
    endif
  endif
endfunction


" Function: lh#btw#build#_show_error([cop|cwin])      {{{3
function! lh#btw#build#_show_error(...) abort
  let qf_position = lh#option#get('BTW_qf_position', '', 'g')

  if a:0 == 1 && a:1 =~ '^\%(cw\%[window]\|copen\)$'
    let open_qf = a:1
  else
    let open_qf = 'cwindow'
  endif

  " --- The following code is borrowed from LaTeXSuite
  " close the quickfix window before trying to open it again, otherwise
  " whether or not we end up in the quickfix window after the :cwindow
  " command is not fixed.
  let winnum = winnr()
  cclose
  " cd . is used to avoid absolutepaths in the quickfix window
  cd .
  exe qf_position . ' ' . open_qf

  setlocal nowrap

  " if we moved to a different window, then it means we had some errors.
  if winnum != winnr()
    " resize the window to just fit in with the number of lines.
    let nl = 15 > &winfixheight ? 15 : &winfixheight
    let nl = lh#option#get('BTW_QF_size', nl, 'g')
    let nl = line('$') < nl ? line('$') : nl
    exe nl.' wincmd _'

    " Apply syntax hooks
    let syn = lh#option#get('BTW_qf_syntax', '', 'gb')
    if strlen(syn)
      silent exe 'runtime compiler/BTW/syntax/'.syn.'.vim'
    endif
    call lh#btw#filters#_apply_quick_fix_hooks('syntax')
  endif
  if lh#option#get('BTW_GotoError', 1, 'g') == 1
  else
    exe origwinnum . 'wincmd w'
  endif
endfunction

" Function: lh#btw#build#_copen_bg(f,[cop|cwin])      {{{3
function! lh#btw#build#_copen_bg(errorfile,...) abort
  " Load a file containing the errors
  :exe ":cgetfile ".a:errorfile
  " delete the temporary file
  if a:errorfile =~ 'tmp-make-bg'
    call delete(a:errorfile)
  endif
  let opt = (a:0>0) ? a:1 : ''
  exe 'call lh#btw#build#_show_error('.opt.')'
  echohl WarningMsg
  echo "Build complete!"
  echohl None
  if exists(':CompilHintsUpdate')
    :CompilHintsUpdate
  endif
endfunction

" # Execute        {{{2
" Function: lh#btw#build#_execute()                   {{{3
let s:ext = (has('win32')||has('win64')||has('win16')) ? '.exe' : ''
function! lh#btw#build#_execute()
  let path = s:Executable()
  if type(path) == type({})
    " Assert(path.type == 'make')
    " Extract environment variables.
    let ctx=''
    for [k,v] in items(path)
      if k[0] == '$'
        let ctx .= k[1:].'='.v.' '
      endif
    endfor
    " Execute the command
    if path.type =~ 'make\|ctest'
      let makeprg = &makeprg
      if path.type == 'ctest'
        let makeprg = substitute(&makeprg, '\<make\>', 'ctest', '')
        call lh#btw#_register_fix_ctest()
      endif
      if !empty(ctx)
        let p = matchend(makeprg, '.*;')
        if -1 == p
          let makeprg = ctx.makeprg
        else
          " several commands => inject the variables on the last command
          let makeprg = makeprg[ : (p-1)].ctx.makeprg[p : ]
        endif
      endif
      call s:DoRunAndCaptureOutput(makeprg, path.rule)
    else
      call lh#common#error_msg( "BTW: unexpected type (".(path.type).") for the command to run")
    endif
  else " normal case: string = command to execute
    if (SystemDetected() == 'unix') && (path[0]!='/') && (path!~'[a-zA-Z]:[/\\]') && (path!~'cd')
      " todo, check executable(split(path)[0])
      let path = './' . path
    endif
    exe ':!'.FixPathName(path . s:ext) . ' ' .lh#option#get('BTW_run_parameters','')
  endif
endfunction

" # Config         {{{2
" Function: lh#btw#build#_config()                    {{{3
function! lh#btw#build#_config() abort
  let how = lh#option#get('BTW_project_config', {'type': 'modeline'} )
  if     how.type == 'modeline'
    call lh#btw#build#_add_let_modeline()
  elseif how.type == 'makefile'
    let wd = lh#btw#_evaluate(how.wd)
    let file = lh#btw#_evaluate(how.file)
    call lh#buffer#jump(wd.'/'.file)
  elseif how.type == 'ccmake'
    let wd = lh#btw#_evaluate(how.wd)
    if lh#system#OnDOSWindows()
      " - the first ":!start" runs a windows command
      " - "cmd /c" is used to define the second "start" command (see "start /?")
      " - the second "start" is used to set the current directory and run the
      " execution.
      let prg = 'start /b cmd /c start /D '.FixPathName(wd, 0, '"')
            \.' /B cmake-gui '.FixPathName(how.arg, 0, '"')
    else
      " let's suppose no spaces are used
      " let prg = 'xterm -e "cd '.wd.' ; ccmake '.(how.arg).'"'
      let prg = 'cd '.wd.' ; cmake-gui '.(how.arg).'&'
    endif
    let g:prg = prg
    echo ":!".prg
    exe ':silent !'.prg
  endif
endfunction

" Function: lh#btw#build#_add_let_modeline()          {{{3
" Meant to be used with let-modeline.vim
function! lh#btw#build#_add_let_modeline() abort
  " TODO: become smart: auto detect makefile, A-A-P, scons, ...

  " Check if there is already a Makefile
  let make_files = glob('Makefile*')
  if strlen(make_files)
    let make_files = substitute("\n".make_files, '\n', '\0Edit \&', 'g')
  elseif !strlen(aap_files)
    let make_files = "\nEdit &Makefile"
  endif

  let which = WHICH('COMBO', 'Which option must be set ?',
        \ "Abort"
        \ . make_files
        \ . "\n$&CFLAGS\n$C&PPFLAGS\n$C&XXFLAGS"
        \ . "\n$L&DFLAGS\n$LD&LIBS"
        \ . "\n&g:BTW_project\n&b:BTW_project"
        \ )
  if which =~ 'Abort\|^$'
    " Nothing to do
  elseif which =~ '^Edit.*$'
    exe 'sp '. matchstr(which, 'Edit\s*\zs.*')
  else
    below split
    let s = search('Vim:\s*let\s\+.*'.which.'\s*=\zs')
    if s <= 0
      let l = '// Vim: let '.which."='".Marker_Txt(which)."'"
      silent $put=l
    endif
  endif
endfunction

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

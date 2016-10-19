"=============================================================================
" File:         autoload/lh/btw/build.vim                         {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} gmail {dot} com>
"               <URL:http://github.com/LucHermitte/vim-build-tools-wrapper>
" Version:      0.7.0.
let s:k_version = '070'
" Created:      23rd Mar 2015
" Last Update:  19th Oct 2016
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
let s:verbose = get(s:, 'verbose', 0)
function! lh#btw#build#verbose(...)
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

function! lh#btw#build#debug(expr)
  return eval(a:expr)
endfunction


"------------------------------------------------------------------------
" ## Internal functions {{{1

" # Options        {{{2
" TODO: distinguish rule-name for the compilation (e.g. ``all'') and the final
" executable

" Function: s:ProjectName()                           {{{3
" This option can be defined:
" - with a _vimrc_local file
" - with a let-modeline
" @todo deprecate this in favour of lh#btw#project_name()
" @deprecated (bg):BTW_project, use (bpg):BTW.project
function! s:ProjectName() abort
  let res = lh#option#get('BTW.project')
  if     lh#option#is_set(res)   | return res
  elseif exists('b:BTW_project') | return b:BTW_project
  elseif exists('g:BTW_project') | return g:BTW_project
  elseif &ft == 'qf'             | cclose | return s:ProjectName()
  elseif lh#ft#is_script()       | return '%'
  else                           | return '%<'
  endif
endfunction

" Function: s:TargetRule()                            {{{3
" @deprecated (bg):BTW_project_target, use (bpg):BTW.target
function! s:TargetRule() abort
  " TODO: find a better name
  " TODO: try to detect available rules in Makefile/main.aap/...,
  " and cache them
  " TODO: cclose is not the best way to quit the qf window -> memorize the
  " buffer from which it was compiled last
  if &ft == 'qf' | cclose | return s:TargetRule() | endif
  let res = lh#option#get('BTW.target')
  if     lh#option#is_set(res)          | return res
  elseif exists('b:BTW_project_target') | return b:BTW_project_target
  elseif exists('g:BTW_project_target') | return g:BTW_project_target
  else
    let res = s:ProjectName()
    if empty(res)
      res = 'all' " just a guess
    endif
    return res
  endif
endfunction

" Function: s:Executable()                            {{{3
" @deprecated (bg):BTW_project_executable, use (bpg):BTW.executable
let s:ext = lh#os#OnDOSWindows() ? '.exe' : ''
function! s:Executable() abort
  " TODO: find a better name
  " TODO: try to detect available rules in Makefile/main.aap/...,
  " and cache them
  " TODO: cclose is not the best way to quit the qf window -> memorize the
  " buffer from which it was compiled last
  if &ft == 'qf' | cclose | return s:Executable() | endif
  let res = lh#option#get('BTW.executable')
  if     lh#option#is_set(res)              | return res
  elseif exists('b:BTW_project_executable') | return b:BTW_project_executable
  elseif exists('g:BTW_project_executable') | return g:BTW_project_executable
  else
    let res = s:ProjectName()
    if empty(res)
      throw "BTW: Sorry, I'm not able to deduce project name in order to know which executable to run. Please see `:h BTW-project-executable`"
      " TODO: glob()+executable() -> possible executable in the build
      " directory
    endif
    let res .= s:ext
    return res
  endif
endfunction

" # Run (anything) {{{2
" Function: s:RunInBackGround()                       {{{3
if exists('s:run_in_background')
    unlet s:run_in_background
endif

function! s:FetchRunInBackground() abort
  " This is a the old background compilation function for vim version < 8
  let rib_progname = lh#os#OnDOSWindows()
        \ ? 'run_and_recontact_vim'
        \ : 'run_in_background'

  if     exists('*globpath')
    let s:run_in_background = globpath(&rtp, 'compiler/BTW/'.rib_progname.'.pl')
  else
    call lh#common#error_msg( "Build Tools Wrapper:\n  This plugin requires either a version of Vim that defines |globpath()|\n"
          \."  Please upgrade your version of vim\n")
    finish
  endif

  let s:run_in_background = 'perl '.lh#path#fix(s:run_in_background, !lh#os#OnDOSWindows())
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
let s:has_jobs = exists('*job_start') && has("patch-7.4.1980")
function! s:DoRunAndCaptureOutput(program, ...) abort
  let bg = (has('clientserver') || s:has_jobs) && lh#btw#option#_make_in_bg()
  let cleanup = lh#on#exit()
        \.restore('&makeprg')
  if bg
    if !s:has_jobs " case handled latter
      let run_in = lh#btw#option#_make_in_bg_in()
      if strlen(run_in)
        " Typically xterm -e
        let run_in = ' --program="'.run_in.'"'
      endif
      let &makeprg = s:RunInBackground()
            \ . ' --vim=' . v:progname
            \ . ' --servername=' . v:servername
            \ . run_in
            \ . ' "' . (a:program) . '"'
    endif
  else " synchronous building
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
    if bg && s:has_jobs
      let args = expand(args)
      call s:Verbose('rpl $* w/ %1', args)
      let cmd = substitute(&makeprg, '\$\*', args, 'g')
      " makeprg escapes pipes, we need to unescape them for job_start
      let cmd = substitute(cmd, '\\|', '|', 'g')
      call lh#btw#job_build#execute(cmd)
    elseif lh#os#OnDOSWindows() && bg
      let cmd = ':!start '.substitute(&makeprg, '\$\*', args, 'g')
      exe cmd
    else
      " lh#os#make will inject p:$ENV on-the-fly, if needed.
      call lh#os#make(args, '!')
    endif
  catch /.*/
    if lh#btw#filters#verbose() > 0
      debug call lh#common#error_msg("Error: ".v:exception. " thrown at: ".v:throwpoint)
    else
      call lh#common#error_msg("Error: ".v:exception. " thrown at: ".v:throwpoint)
    endif
  finally
    " Records which was the last buffer
    if &ft != 'qf'
      call lh#btw#_save_last_buffer_data()
    endif

    call cleanup.finalize()
  endtry

  if bg && s:has_jobs
    call lh#btw#build#_copen_bg()
  else
    call lh#btw#build#_show_error()
  endif
  return bg
endfunction

" # Compile        {{{2
" Function: lh#btw#build#_compile([target])           {{{3
function! lh#btw#build#_compile(...) abort
  update
  call lh#btw#option#_check_deprecated_options()
  if a:0 > 0 && strlen(a:1)
    let rule = a:1
  else
    let rule = s:TargetRule()
  endif
  " else ... pouvoir avoir s:TargetRule() . a:1 ; si <bang> ?!

  if lh#btw#option#_use_prio() == 'update'
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
  let qf_position = lh#btw#option#_qf_position()

  if a:0 == 1 && a:1 =~ '^\%(cw\%[window]\|copen\)$'
    let open_qf = a:1
  else
    let open_qf = 'cwindow'
  endif
  let winid = lh#window#getid()

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
    let nl = lh#btw#option#_qf_size()
    let nl = line('$') < nl ? line('$') : nl
    exe nl.' wincmd _'

    " Apply syntax hooks
    let syn = lh#btw#option#_qf_syntax()
    if !empty(syn)
      silent exe 'runtime compiler/BTW/syntax/'.syn.'.vim'
    endif
    call lh#btw#filters#_apply_quick_fix_hooks('syntax')
  endif
  if lh#btw#option#_goto_error()
    call lh#window#gotoid(winid)
  endif
  " When calling :Copen, restore automatic scroll of qf window
  if exists('g:lh#btw#auto_cbottom')
    let g:lh#btw#auto_cbottom = lh#btw#option#_auto_scroll_in_bg()
    cbottom
  endif
endfunction

" Function: lh#btw#build#_copen_bg_complete(what, job_info, [cop|cwin])      {{{3
function! lh#btw#build#_copen_bg_complete(what, job_info, ...) abort
  let opt = (a:0>0) ? a:1 : ''
  if get(g:, 'lh#btw#auto_cbottom', 1)
    call call('lh#btw#build#_show_error', a:000)
  endif
  let msg
        \ = a:what
        \ . (a:job_info.exitval == 0 ? " successfully built" : " build failed (w/ exitval:".(a:job_info.exitval).")")
  call lh#common#warning_msg("Build complete: ".msg."!")
  if exists(':CompilHintsUpdate')
    :CompilHintsUpdate
  endif
endfunction

" Function: lh#btw#build#_copen_bg([cop|cwin])      {{{3
" lh#btw#build#_show_error overload that does an unconditional opening of the
" qf window
function! lh#btw#build#_copen_bg(...) abort
  let qf_position = lh#btw#option#_qf_position()

  if a:0 == 1 && a:1 =~ '^\%(cw\%[window]\|copen\)$'
    let open_qf = a:1
  else
    let open_qf = 'copen'
  endif
  let winid = lh#window#getid()

  cclose
  " cd . is used to avoid absolutepaths in the quickfix window
  cd .
  exe qf_position . ' ' . open_qf

  setlocal nowrap

  call assert_notequal(winid, lh#window#getid()) " a call to setqflist() should move us to the qfwindow
  call assert_equal(&ft, 'qf')
  " resize the window to have the right number of lines
  let nl = lh#btw#option#_qf_size()
  exe nl.' wincmd _'
  let w:quickfix_title = lh#btw#build_mode(). ' compilation of ' . lh#btw#project_name()

  " Apply syntax hooks
  let syn = lh#btw#option#_qf_syntax()
  if !empty(syn)
    silent exe 'runtime compiler/BTW/syntax/'.syn.'.vim'
  endif
  call lh#btw#filters#_apply_quick_fix_hooks('syntax')
  call lh#window#gotoid(winid)
endfunction

" Function: lh#btw#build#_get_metrics() {{{3
function! lh#btw#build#_get_metrics() abort
  let qf = getqflist()
  let recognized = filter(qf, 'get(v:val, "valid", 1)')
  " TODO: support other locales
  let errors   = filter(copy(recognized), 'v:val.type == "E" || v:val.text =~ "\\v^ *(error|erreur)"')
  let warnings = filter(copy(recognized), 'v:val.type == "W" || v:val.text =~ "\\v^ *(warning|attention)"')
  let res = { 'all': len(qf), 'errors': len(errors), 'warnings': len(warnings) }
  return res
endfunction

" # Execute        {{{2
" Function: lh#btw#build#_execute()                   {{{3
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
    if (lh#os#system_detected() == 'unix') && (path[0]!='/') && (path!~'[a-zA-Z]:[/\\]') && (path!~'cd')
      " todo, check executable(split(path)[0])
      let path = './' . path
    endif
    let cmd = lh#path#fix(path) . ' ' .lh#btw#option#_run_parameters()
    call s:Verbose(':!%1', cmd)
    exe ':!'.cmd
  endif
endfunction

" # Config         {{{2
" Function: lh#btw#build#_config()                    {{{3
function! lh#btw#build#_config() abort
  let how = lh#btw#option#_project_config()
  if     how.type == 'modeline'
    call lh#btw#build#_add_let_modeline()
  elseif how.type == 'makefile'
    let wd = lh#btw#_evaluate(how.wd)
    let file = lh#btw#_evaluate(how.file)
    call lh#buffer#jump(wd.'/'.file)
  elseif how.type == 'ccmake'
    let wd = lh#btw#_evaluate(how.wd)
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
      let prg = 'cd '.wd.' && cmake-gui '.(how.arg).'&'
    endif
    " let g:prg = prg
    call s:Verbose(":!".prg)
    exe ':silent !'.prg
  endif
endfunction

" Function: lh#btw#build#_re_config()                 {{{3
function! lh#btw#build#_re_config() abort
  let how = lh#btw#option#_project_config()
  if     how.type == 'modeline'
    if exists(':FirstModeLine')
      :FirstModeLine
      return
    endif
  elseif how.type == 'makefile'
    " let wd = lh#btw#_evaluate(how.wd)
    " let file = lh#btw#_evaluate(how.file)
    " call lh#buffer#jump(wd.'/'.file)
    return
  elseif how.type == 'ccmake'
    debug let wd = lh#btw#_evaluate(how.wd)
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
      let prg = 'cd '.wd.' && cmake .'
    endif
    call s:Verbose(":!".prg)
    " TODO: Asynch execution through &makeprg!
    exe ':!'.prg
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
  " elseif !strlen(aap_files)
    " let make_files = "\nEdit &Makefile"
  endif

  let opts = ''
  if &ft == 'cpp'
    let opts .= "\nC&XXFLAGS\nC&PPFLAGS"
  elseif &ft == 'c'
    let opts .= "\n&CFLAGS\nC&PPFLAGS"
  endif
  let which = WHICH('COMBO', 'Which option must be set ?',
        \ "Abort"
        \ . make_files
        \ . opts
        \ . "\n$L&DFLAGS\n$LD&LIBS"
        \ . "\n".lh#marker#txt('bpg').":&BTW_project"
        \ )
  if which =~ 'Abort\|^$'
    " Nothing to do
  elseif which =~ '^Edit.*$'
    call lh#window#split(matchstr(which, 'Edit\s*\zs.*'))
  else
    below split
    let s = search('Vim:\s*let\s\+.*'.which.'\s*=\zs')
    if s <= 0
      let l = '// Vim: let '.which."='".lh#marker#txt('option')."'"
      call append('$', l)
    endif
  endif
endfunction

" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

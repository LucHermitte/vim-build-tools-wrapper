"=============================================================================
" File:         autoload/lh/btw/build.vim                         {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} gmail {dot} com>
"               <URL:http://github.com/LucHermitte/vim-build-tools-wrapper>
" Version:      0.7.0.
let s:k_version = '070'
" Created:      23rd Mar 2015
" Last Update:  21st Jun 2020
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
    unlet res
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


" Function: s:DoRunAndCaptureOutput(program, options [, args]) {{{3
let s:k_multijobs_options = {
      \ 'make': '-j'
      \}
let s:has_jobs = exists('*job_start') && has("patch-7.4.1980")
function! s:DoRunAndCaptureOutput(program, options, ...) abort
  let ask_bg = get(a:options, 'background', lh#btw#option#_make_in_bg())
  let bg = (has('clientserver') || s:has_jobs) && ask_bg
  let program = a:program
  if bg && !s:has_jobs
    let run_in = lh#btw#option#_make_in_bg_in()
    if strlen(run_in)
      " Typically xterm -e
      let run_in = ' --program="'.run_in.'"'
    endif
    let program = s:RunInBackground()
          \ . ' --vim=' . v:progname
          \ . ' --servername=' . v:servername
          \ . run_in
          \ . ' "' . program . '"'
  endif
  let args = join(a:000, ' ')
  let nb_jobs = lh#btw#option#_make_mj()
  " if has_key(s:k_multijobs_options, program) && type(nb_jobs) == type(0) && nb_jobs > 0
  if type(nb_jobs) == type(0) && nb_jobs > 0
    " let args .= ' '. s:k_multijobs_options[program] .nb_jobs
    let args .= ' -j' .nb_jobs
  endif

  try
    if bg && s:has_jobs
      let args = expand(args)
      call s:Verbose('rpl $* w/ %1', args)
      let cmd = substitute(program, '\$\*', args, 'g')
      " makeprg escapes pipes, we need to unescape them for job_start
      let cmd = substitute(cmd, '\\|', '|', 'g')
      call lh#btw#job_build#execute(cmd)
    elseif lh#os#OnDOSWindows() && bg
      let cmd = ':!start '.substitute(program, '\$\*', args, 'g')
      exe cmd
    else
      " lh#os#make will inject p:$ENV on-the-fly, if needed.
      call lh#os#make(args, '!', program)
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

  if lh#btw#option#_use_prio() == 'update' && get(b:, 'current_compiler', '') != 'git'
    " fugitive uses :Make to do stuff, let's not update the compiler in
    " these cases
    call lh#btw#chain#_reconstruct()
  endif
  " Make sure the variables are correctly set
  let project_config = lh#btw#option#_project_config()
  " And that the makefile or equivalent files are here.
  if lh#option#is_set(project_config) && !project_config.lazy_bootstrap()
    throw "BTW: Error bootstrapping of the project failed, cannot compile."
  endif

  " Do compile with a current &makeprg
  call lh#btw#build#_do_compile(&makeprg, rule, "Compilation finished")
endfunction

" Function: lh#btw#build#_do_compile(makeprg, rule, msg [, args]) {{{3
function! lh#btw#build#_do_compile(makeprg, rule, msg, ...) abort
  let args = get(a:, 1, {})
  let bg = s:DoRunAndCaptureOutput(a:makeprg, args, a:rule)
  if !bg
    echomsg a:msg.(len(a:rule)?" (".a:rule.")" : "")
  endif
endfunction

" Function: lh#btw#build#_do_copen(default, [cop|cwin])        {{{3
function! lh#btw#build#_do_copen(default, ...) abort
  let qf_position = lh#btw#option#_qf_position()

  " call s:Verbose("lh#btw#build#_do_copen(%1)", a:)
  if a:0 == 1 && a:1 =~ '^\%(cw\%[window]\|copen\)$'
    let open_qf = a:1
  else
    let open_qf = a:default
  endif
  let winid = lh#window#getid()

  " --- The following code is borrowed from LaTeXSuite
  " close the quickfix window before trying to open it again, otherwise
  " whether or not we end up in the quickfix window after the :cwindow
  " command is not fixed.
  let winnum = winnr()

  cclose
  " cd . is used to avoid absolutepaths in the quickfix window
  " :lcd is required to not reset the local directory if in this situation
  call lh#path#cd_without_sideeffects('.')

  call s:Verbose("%1 %2", qf_position, open_qf)
  try
    let g:lh#btw#_ignore_bufenter_qf = 1
    exe qf_position . ' ' . open_qf
  finally
    unlet g:lh#btw#_ignore_bufenter_qf
  endtry

  setlocal nowrap

  return [winid, winnum]
endfunction

" Function: lh#btw#build#_show_error([cop|cwin])      {{{3
function! lh#btw#build#_show_error(...) abort
  let [winid, winnum] = call('lh#btw#build#_do_copen', ['cwindow'] + a:000)

  " --- The following code is borrowed from LaTeXSuite
  " close the quickfix window before trying to open it again, otherwise
  " whether or not we end up in the quickfix window after the :cwindow
  " command is not fixed.
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
  call s:Verbose("_copen_bg_complete start")
  let opt = (a:0>0) ? a:1 : ''
  if get(g:, 'lh#btw#auto_cbottom', 1)
    call call('lh#btw#build#_show_error', a:000)
  endif
  let msg
        \ = a:what
        \ . (a:job_info.exitval == 0 ? " successfully built" : " build failed (w/ exitval:".(a:job_info.exitval).")")
  let hl = a:job_info.exitval == 0
        \ ? lh#option#get('BTW.highlight.success', 'Comment', 'g')
        \ : lh#option#get('BTW.highlight.error', 'Error', 'g')
  call lh#common#warning_msg("Build complete: ".msg."!", hl)

  if get(g:, 'lh#btw#job_build#qf_need_colours', 0) && exists(':AnsiEsc')
    let qf_winnr = lh#qf#get_winnr()
    if qf_winnr
      let crt_winr = winnr()
      exe qf_winnr.'wincmd w'
      " call s:Verbose("qf bufnr?: %1", bufnr('%'))
      try
        " :AnsiEsc, from https://github.com/powerman/vim-plugin-AnsiEsc
        "
        " Unfortunately neither this version nor the official one permits to
        " test whether AnsiEsc needs to be executed, fortunately we can
        " test if any synhl is defined in the current buffer!
        if empty(lh#syntax#list('ansiNone'))
          AnsiEsc
        endif
      finally
        exe crt_winr.'wincmd w'
      endtry

      " TODO: else: what about is the qfwindow has been closed? Is it even possible?
    endif
  endif
  call s:Verbose("_copen_bg_complete end")
endfunction

" Function: lh#btw#build#_copen_bg([cop|cwin])      {{{3
" lh#btw#build#_show_error overload that does an unconditional opening of the
" qf window
function! lh#btw#build#_copen_bg(...) abort
  call s:Verbose("_copen_bg start")
  let [winid, winnum] = call('lh#btw#build#_do_copen', ['copen'] + a:000)

  call lh#assert#not_equal(winid, lh#window#getid()) " a call to setqflist() should move us to the qfwindow
  call lh#assert#equal('qf', &ft)
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
  call s:Verbose("_copen_bg end")
endfunction

" Function: lh#btw#build#_get_metrics() {{{3
function! lh#btw#build#_get_metrics() abort
  call lh#notify#deprecated('lh#btw#build#_get_metrics', 'lh#qf#get_metrics')
  return lh#qf#get_metrics()
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
      call s:DoRunAndCaptureOutput(makeprg, {}, path.rule)
    else
      call lh#common#error_msg( "BTW: unexpected type (".(path.type).") for the command to run")
    endif
  else " normal case: string = command to execute
    if !lh#path#is_absolute_path(path) && path !~ '[/\\]'
      " if (lh#os#system_detected() == 'unix') && (path[0]!='/') && (path!~'[a-zA-Z]:[/\\]') && (path!~'cd')
      " todo, check executable(split(path)[0])
      let path = './' . path
    endif
    let cmd = lh#path#fix(path) . ' ' .lh#btw#option#_run_parameters()
    call s:Verbose(':!%1', cmd)
    let execute_with = lh#option#get('BTW.execute_with', '!')
    exe ':'execute_with.cmd
  endif
endfunction

" # Config         {{{2
" Function: lh#btw#build#_config()                    {{{3
function! lh#btw#build#_config() abort
  let config = lh#btw#option#_project_config()
  call lh#assert#value(config).is_set().has_key('config')
  return config.config({'background': lh#btw#option#_make_in_bg()})
endfunction

" Function: lh#btw#build#_re_config()                 {{{3
function! lh#btw#build#_re_config() abort
  let config = lh#btw#option#_project_config()
  call lh#assert#value(config).is_set().has_key('reconfig')
  return config.reconfig()
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
  if &ft     == 'cpp'
    let opts .= "\n$C&XXFLAGS\n$C&PPFLAGS"
  elseif &ft == 'c'
    let opts .= "\n$&CFLAGS\n$C&PPFLAGS"
  endif
  let which = lh#ui#which('lh#ui#combo', 'Which option must be set ?',
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

" # Completion     {{{2
" Function: lh#btw#build#_make_complete(ArgLead, CmdLine, CursorPos) {{{3
function! lh#btw#build#_make_complete(ArgLead, CmdLine, CursorPos) abort
  let [pos, tokens, ArgLead, CmdLine, CursorPos] = lh#command#analyse_args(a:ArgLead, a:CmdLine, a:CursorPos)
  " TODO: detect -j, etc
  let how = lh#btw#option#_project_config()
  let wd = lh#btw#_evaluate(how.wd)
  call s:Verbose('Project config: %1', how)
  let res = lh#command#matching_make_completion(ArgLead, wd)
  return res
endfunction
" }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

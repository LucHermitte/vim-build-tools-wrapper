"=============================================================================
" File:         plugin/BuildToolsWrapper.vim         {{{1
" Maintainer:   Luc Hermitte <MAIL:hermitte {at} free {dot} fr>
"               <URL:http://github.com/LucHermitte/vim-build-tools-wrapper>
" Licence:      GPLv3
" Version:      0.7.0
let s:k_version = 0700
" Created:      28th Nov 2004
" Last Update:  12th Oct 2016
"------------------------------------------------------------------------
" Description:  Flexible alternative to Vim compiler-plugins.
"
"------------------------------------------------------------------------
" Installation:
"       Drop this plugin into {rtp}/plugin/
"       Requires: lh-vim-lib (v3.1.0+), System_utils, also available on my web site
"       Other Recommended Scripts: menu-maps.vim, local_vimrc.vim
"
" History:                                 {{{2
"  v0.0.1: 28th Nov 2004 : First Version
"       * Focalize on :BTW
"
"  v0.0.2: Merge two related projects.
"       * Integrate the work I've done on the previous C-ftplugin ->
"         c_compile.vim
"
"  v0.0.3:
"       * ?:Make? support an optional list of targets
"       * BTW_filter_prog can be local to a buffer
"         => regarding to the current directory (thanks to local_vimrc.vim) we
"         can use different makefiles, but the same build program.
"         The other solution I haven't considered (yet?) was to use callback
"         functions.
"       * Little bug fix in the ``edit settings'' confirm-box ; some \n were
"         badly handled.
"       * New commands: :Copen and :Cwindow which work like :copen and :cwindow
"         except they show up to BTW_QF_size error lines (default 15), and they
"         jump (or not) to the first error according to BTW_GotoError.
"
"  v0.0.4: 13th Jan 2005
"       * g:BTW_qf_position -> :vert, :lefta, :abo, ...
"       * ?:BTW reloadPlugin? -> To ease plugin test & maintenance
"
"  v0.0.5: 11th Mar 2005
"       * ?:BTW delete?
"       * ?:BTW echo? auto completes the values of various internal functions
"         ProjectName() TargetRule() Executable()
"
"  v0.0.6: 26th May 2005
"       * Do not prepend './' to executable path if, under unix, it starts with
"         '/'
"
"  v0.0.7: 27th May 2005
"       * Use :cclose instead of :bw in s:CompileQF()
"       * Use :cclose as well in s:Executable(), s:ProjectName() and
"         s:TargetRule()
"       * No need to quote the arguments to :Make anymore
"       * Can run :Make in background, if the option
"         [bg]:BTW_make_in_background is set to 1
"         Warning: As those damn pop-ups on the Internet, the quickfix window
"         can be opened at any time. Which may break our current manipulations.
"       * Toggled menu for g:BTW_make_in_background (g(lobal) scope only, not [bg])
"
"  v0.0.8: 30th May 2005
"       * new option for errorformat configuration: g:BTW_ignore_efm_{filter}
"       * We can ask for using the default value of efm by setting
"         g:BTW_adjust_efm_{filter} to "default efm".
"         Default efm: -> ?set efm&vim?
"             %f(%l) : %t%*\D%n: %m
"             %*[^"]"%f"%*\D%l: %m
"             %f(%l) : %m
"             %*[^ ] %f %l: %m
"             %f:%l:%m
"
"  v0.0.9: 22nd Jul 2005
"       * Run in background works with several filters (output piped), and even
"         with filter that expands into "cd path ; make -f file.mk"
"         Tested under Solaris.
"       * The temporary file can be in any directory.
"
"  v0.0.10: 17th Nov 2005 - 06th Nov 2007
"       * First support for syntax additions -> [bg]BTW_qf_syntax_{...}
"         Will be rewritten ...
"       * Better management of efm
"       * Simplification: Use of :cgetfile for build in backgound
"       * Auto detection of where run_in_background.pl is, without the explicit
"         need to searchInRuntime.vim -- as long as Vim supports the function
"         |globpath()|
"       * auto-import of |compiler-plugin| with just "|BTW-add| ant" for
"         instance.
"       * A filter can import definitions from a |compiler-plugin|. e.g.:
"            let g:BTW_adjust_efm_{filter} = 'import: ant,default efm'
"         If the filter does not provide a [bg]:BTW_filter_program_{filter},
"         the one from the compiler plugin will be used.
"       * Executable() programs (in $PATH) can be added as filter
"       * Adapted to the refactorization of MenuMake
"       * run_in_background patched to work under Cygwin -- except perl's fork
"         isn't forking
"       * b:want_buffermenu_or_global_disable is not used as the menus are not
"         limited to the current buffer
"       * Dependency changed from LHOption to lh-vim-lib
" v0.0.11: 22nd Oct 2010
"       * Can run anything and capture its output
"       * Config support let-modeline, ccmake, makefile
" v0.0.12: 21st Mar 2011
"       * New option BTW_make_multijobs to run make with multiple jobs (-j2,
"       etc)
" v0.0.13: 19th Aug 2011
"       * New option BTW_compilation_dir
"       * New feature: :QFImport to import variables into quickfix
" v0.0.14: 21st Feb 2012
"       * New way to easily change settings in the filters used:
"         BTW_filter_program_{filter} can be a |FuncRef|.
"         see compiler/BTW/cmake.vim
"       * BTW_adjust_efm_{filer} may be a dictionary
"         {"value": string, "post": FuncRef} to support post-treatments on &efm
"         value.  see compiler/BTW/cmake.vim
" v0.1.0: 13th Mar 2012
"       * "configure" while the type is "cmake" correctly runs cmake-gui on
"         windows boxes
"       * :Execute works under windows
"       * Try to use lh-compl-hints if installed
" v0.1.1: 08th Jun 2012
"       * running "configure" didn't detect non-Windows correctly
" v0.2.0: 06th Sep 2012
"       * API to help define project options
" v0.2.1: 12th Sep 2012
"       * API to help define CMake/CTest-based project options
" v0.2.2: 18th Sep 2012
"       * CTest outputs are fixed so filenames are correctly recognized
"       * CTest outputs are folded
" v0.2.3: 21st Sep 2012
"       * bug fix: unable to fold CTest tests when test number > 9
"       * using "normal V" to create fold has memory side effect
"       * clean folds before entering QF windows through make
" v0.2.4: 21st Sep 2012
"       * List all (c)tests
"       * first draft to execute selected test (buggged at this point)
" v0.2.5: 25th Sep 2012
"       * Possible to execute selected (C)test
"       * Optional project configuration for btw/project_options
" v0.2.6: 19th Oct 2012
"       * Bugfix in #lh#btw#cmake#update_list()
" v0.2.7: 23rd Oct 2012
"       * bugfix: Toggle *CtestList* now updates the target test
" v0.2.8: 29th Oct 2012
"       * bugfix: updating CTest test lists was made in the wrong menu position
" v0.2.9: 07th Nov 2012
"       * bugix: updating CTest test lists was not updating new test id
" v0.2.10: 21st Nov 2012
"       * enh: g:BTW_make_multijobs default value is lh#os#cpu_number()
" v0.2.11: 08th Jan 2013
"       * enh: Generates .clang_complete file ... but in b:BTW_compilation_dir
"       * enh: Generates clang_indexer DB, in b:BTW_compilation_dir
"       * bug: Don't prevent syntax highlighting & ft detection to be triggered
"         when launching vim with several files
" v0.2.12: 23rd Jan 2013
"       * bug: lh#btw#cmake#update_list() won't fail when executed from a
"         buffer not under the paths.trunk directory.
"       * bug: Generated ctest menu accept test names with non-word "\W"
"         characters.
" v0.2.13: 23rd Jan 2013
"       * enh: Calling ":cd" before opening the quickfix window in order to
"         avoid absolutepaths in the qf window
" v0.2.14: 25th Jul 2013
"       * bug: When the project is organized with symbolic links, settings
"         weren't applied. e.g.
"          $$/
"          +-> repo/branches/B42
"          +-> sources/ -> symlink to $$/repo/branches/B42
"          +-> build/
"       * enh: The compilation mode doesn't need anymore to be "Debug" or
"         "Release", it can be anything now like for instance: "ARM", "80x86",
"         ...
" v0.2.15: 19th Dec 2013
"       * enh: ctest folding now displays the name of the test as well
" v0.3.0: 14th Mar 2014
"       * s:Evaluate() moved to lh/btw.vim autoload plugin
" v0.3.1: 29th Jul 2014
"       * ctest filters now use BTW hooks facility
"       * BTW hooks can be debuged when lh#btw#filter#verbose >= 2
" v0.3.2: 02nd Sep 2014
"       * New option [bg]:BTW_use_prio ("update"|"makeprg") can tells to always
"         update makeprg, or never.
" v0.3.3: 12th Dec 2014
"       * New API function: lh#btw#compilation_dir()
" v0.3.4: 16th Jan 2015
"       * New subcommand to generate local_vimrc files for C&C++ projects and
"         projects managed with CMake -> :BTW new_project
"       * Minor refactoring in lh#btw#filters functions
" v0.4.0: 20th Mar 2015
"       * several functions moved to autoload plugins
"       * filter BTW/sustitute_file supports several substitution lists with
"         (bg):{ft_}BTW_substitute_names: [ [old1, new1], [old2, new2], ...]
"       * filter BTW/shorten_filenames permits to shorten (/conceal part of)
"         filenames with
"         (bg):{ft_}BTW_shorten_names: [ pattern, [pattern,cchar], ...]
"       * New hook group: "syntax"
"       * qf_export_variable rewritten => many tests are required
"       * "BTW remove" & "BTW removelocal" behaviours slightly changed.
" v0.4.1: 09th Apr 2015
"       * QFImport feature reworked: now it has to be executed for each buffer
"         (i.e. in a local vimrc)
"       * Airline extension defined -> "btw".
"         It relies on:
"         - b:BTW_project_config['_'].name and
"         - b:BTW_project_config['_'].compilation.mode.
" v0.4.2: 10th Apr 2015
"       * b:BTW_project_build_mode deprecated in favour of
"         b:BTW_project_config['_'].compilation.mode.
"       * Current project name can be obtained with: lh#btw#project_name()
"       * Current project build mode can be obtained with: lh#btw#build_mode()
" v0.4.3: 13th Apr 2015
"       * QFImported variables are correctly associated to the state of the
"         buffer where the compilation is launched at the moment it is launched.
"       * calls to setqflist() now replace the current qflist (instead of
"         appending a new one)
" v0.4.4: 16th Apr 2015
"       * Fix default value for lh#btw#project_name() to return an empty string
"       * No longer depends on system-tools.
" v0.4.5: 05th May 2015
"       * New feature: :ReConfig that'll reload let-modeline, or execute
"       "cmake ." in the right path.
" v0.5.0: 09th Jul 2015
"       * New feature: :BTW setoption that'll help set BTW options (targets,
"       ...)
" v0.5.1: 24th Sep 2015
"       * ":Execute" on scripts will correctly work. Requires lh-vim-lib 3.3.3.
" v0.5.2: 22nd Oct 2015
"       * Usage message for ":BTW new_project"
" v0.5.3: 30th Oct 2015
"       * Updated to new lh-vim-lib functions that create new splits, ignoring E36
"       * Bug fix in ':BTW new_project' usage feature
" v0.5.5: 26th Apr 2016
"       * On Windows, when `[bg]:BTW_project_executable`  is set, ".exe" won't
"       be appended automatically
" v0.5.5: 03rd May 2016
"       * Fix "No maping found" on plain vim (!= gvim)
" v0.6.0: 20th Jun 2016
"       * Fix incorrect mapping definition
" v0.7.0: 11th Aug 2016 - 11th Oct 2016
"       * Add toggle menu/command from autoscroll bg compilation
"       * Use new logging framework in some places
"       * Background compilation based on lh#async
"       * Take p:$ENV into account to compile programs
"
" TODO:                                    {{{2
"       * &magic
"       * Support priority -> ?:BTW add cygwin 9?
"       * Write doc
"       * ? addlocal when there is already something ?
"         - or, xor,
"         - use local only ?
"       * Folding -> tools names (ld, gcc, g++) + other tools
"         1st lvl: directories
"         2nd lvl: tools <--- use special colors for tools
"         3rd lvl: files
"       * Test if the definition abort (reconstruct). If so, revert to the
"         preceding values of the variables. (-> try-finally ?)
"       * Some way to use the efm values from another filter (we may consider
"         that loading the filter is enough), or directly set:
"             let g:BTW_adjust_efm_foo = g:BTW_adjust_efm_bar
"       * if '$*' is already present in the filter_program, then don't append
"         it.
"       * Is there a real need for ?:LMake?, ?:LOpen? ? I'm not sure that
"         commands like :lmake (et al.) are that useful as long as there is no
"         way  to say that a particular |location-list| is shared between
"         several windows from a same project.
"       * executable() filters should be able to accept arguments
"       * Chain successful compilation with program execution
" }}}1
"=============================================================================


"=============================================================================
" Avoid global reinclusion                           {{{1
let s:cpo_save=&cpo
set cpo&vim

if exists("g:loaded_BuildToolsWrapper")
  if !exists('g:force_reload_BuildToolsWrapper')
    let &cpo=s:cpo_save
    finish
  else
    echomsg "Reloading ".expand('<sfile>')
  endif
endif
let g:loaded_BuildToolsWrapper = s:k_version

" Dependencies                                       {{{1
runtime plugin/compil-hints.vim

" Global options                                     {{{1
let s:key_make       = lh#option#get('BTW.key.make'     , '<F7>', 'g')
let s:key_execute    = lh#option#get('BTW.key.execute'  , '<C-F5>', 'g')
let s:key_config     = lh#option#get('BTW.key.config'   , '<M-F7>', 'g')
let s:key_re_config  = lh#option#get('BTW.key.re_config', '<M-F8>', 'g')

" Options }}}1
"------------------------------------------------------------------------
" ## Commands and mappings                           {{{1

" # Multi-purposes command                 {{{2
command! -nargs=+ -complete=custom,lh#btw#chain#_BTW_complete BTW :call lh#btw#chain#_BTW(<f-args>)

" # Quickfix import variables commands     {{{2
command! -nargs=1 -complete=var QFImport      :call lh#btw#qf_add_var_to_import(<f-args>)
command! -nargs=0               QFClearImport :call lh#btw#qf_clear_import()

" # Build/Make invokation                  {{{2
command! -nargs=* Make                  :call lh#btw#build#_compile("<args>")
command! -nargs=0 Execute               :call lh#btw#build#_execute()
command! -nargs=0 AddLetModeline        :call lh#btw#build#_add_let_modeline()
command! -nargs=0 Config                :call lh#btw#build#_config()
command! -nargs=0 ReConfig              :call lh#btw#build#_re_config()
command! -nargs=0 Copen                 :call lh#btw#build#_show_error('copen')
command! -nargs=0 Cwindow               :call lh#btw#build#_show_error('cwindow')
command! -nargs=+ CopenBG               :call lh#btw#build#_copen_bg(<f-args>)
command! -nargs=0 ToggleMakeMJ          :call s:ToggleMakeMJ()
command! -nargs=0 ToggleMakeBG          :call s:ToggleMakeInBG()

let s:has_jobs = exists('*job_start') && has("patch-7.4.1980")
if s:has_jobs
  if exists(':cbottom')
    command! -nargs=0 ToggleAutoScrollBG    :call s:ToggleAutoScrollInBG()
  endif
endif

" # Menus                                  {{{2

function! s:MenuMakeBG()
  if has('gui_running') && has ('menu')
    let value = lh#btw#option#_make_in_bg()
    amenu 50.99 &Project.---<sep>--- Nop
    let C  = value ? 'X' : "\\ "
    let UC = value ? "\\ " : 'X'
    silent! exe "anoremenu 50.100 &Project.&[" . C . escape("] Make in &background", '\ ') . " :ToggleMakeBG<cr>"
    silent! exe "aunmenu Project.[" . UC . escape ("] Make in background", ' ')
  endif
endfunction

function! s:MenuAutoScrollBG()
  if has('gui_running') && has ('menu')
    let value = lh#btw#option#_auto_scroll_in_bg()
    amenu 50.99 &Project.---<sep>--- Nop
    let C  = value ? 'X' : "\\ "
    let UC = value ? "\\ " : 'X'
    silent! exe "anoremenu 50.100 &Project.&[" . C . escape("] AutoScroll in &background", '\ ') . " :ToggleAutoScrollBG<cr>"
    silent! exe "aunmenu Project.[" . UC . escape ("] AutoScroll in background", ' ')
  endif
endfunction

function! s:MenuMakeMJ()
  if has('gui_running') && has ('menu')
    let value = lh#btw#option#_make_mj()
    " if type(value) != type(0)
    " endif
    if exists('s:old_mj')
      silent! exe "aunmenu Project.[" . s:old_mj . escape ("] Make using multiple jobs", ' ')
    endif
    amenu 50.99 &Project.---<sep>--- Nop
    silent! exe "anoremenu 50.101 &Project.[" . value . escape("] Make using multiple &jobs", '\ ') . " :ToggleMakeMJ<cr>"
    let s:old_mj = value
  endif
endfunction

if has('gui_running') && has ('menu')
      \ && 0!=strlen(globpath(&rtp, 'autoload/lh/menu.vim'))
    " let b:want_buffermenu_or_global_disable = 0
    " 0->no ; 1->yes ; 2->global disable
  call lh#menu#make('n', '50.10', '&Project.&ReConfig', s:key_re_config,
          \ '', ':ReConfig<cr>')
  call lh#menu#make('n', '50.15', '&Project.&Config', s:key_config,
          \ '', ':Config<cr>')
    amenu 50.29 &Project.--<sep>-- Nop
  call lh#menu#make('ni', '50.30', '&Project.&Make project', s:key_make,
          \ '', ':Make<cr>')
  call lh#menu#make('ni', '50.50', '&Project.&Execute', s:key_execute,
          \ '', ':Execute<cr>')

  call s:MenuMakeBG()
  call s:MenuMakeMJ()
else
  exe '  nnoremap '.s:key_make      .' :call lh#btw#build#_compile()<cr>'
  exe '  inoremap '.s:key_make      .' <c-o>:call lh#btw#build#_compile()<cr>'

  exe '  nnoremap '.s:key_execute   .' :call lh#btw#build#_execute()<cr>'
  exe '  inoremap '.s:key_execute   .' <c-o>:call lh#btw#build#_execute()<cr>'

  exe '  nnoremap '.s:key_re_config .' :ReConfig<cr>'
  exe '  nnoremap '.s:key_config    .' :Config<cr>'
endif
" ## Commands and mappings }}}1
"------------------------------------------------------------------------
" ## Internals                                       {{{1

" # Menus (options)                        {{{2
" Function: s:ToggleMakeInBG()                                 {{{3
function! s:ToggleMakeInBG() abort
  let value = lh#btw#option#_make_in_bg()
  let g:BTW.make_in_background = 1 - value
  call lh#common#warning_msg ("Compilation configured to run in "
        \ . (value ? "foreground" : "background"))

  call s:MenuMakeBG()
endfunction

" Function: s:ToggleAutoScrollInBG()                                 {{{3
function! s:ToggleAutoScrollInBG() abort
  let value = lh#btw#option#_auto_scroll_in_bg()
  let g:BTW.autoscroll_background_compilation = 1 - value
  call lh#common#warning_msg ("Autoscrolling in qf window when compiling in background has been "
        \ . (value ? "deactivated" : "activated"))

  call s:MenuAutoScrollBG()
endfunction

" Function: s:ToggleMakeMJ()                                   {{{3
let s:k_cpu_number = lh#os#cpu_number()
function! s:ToggleMakeMJ() abort
  let value = lh#btw#option#_make_mj()
  let g:BTW.make_multijobs = (value==0) ? s:k_cpu_number : 0
  call lh#common#warning_msg("Compling on " .
        \ ((g:BTW.make_multijobs>1) ? (g:BTW.make_multijobs . " cpus") : "1 cpu"))

  call s:MenuMakeMJ()
endfunction

" ## Internals }}}1
"------------------------------------------------------------------------
let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

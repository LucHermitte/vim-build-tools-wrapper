"=============================================================================
" $Id$
" File:         compiler/BTW/substitute_filenames.vim             {{{1
" Author:       Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://code.google.com/p/lh-vim/>
" Licence:      GPLv3
" Version:	0.3.0
" Created:      14th Mar 2014
" Last Update:  $Date$
"------------------------------------------------------------------------
" Description:
"       BTW filter to replace expressions on the fly
"       This kind of filter is useful when the build chain uses configuration
"       files that are instaciated in the build directory.
"       The actual file that needs to be opened in the original file in thoses
"       cases.
"
"------------------------------------------------------------------------
" TODO:
"       Support multiple uses:
"       - this plugin shall replace cygwin filter for instance
"         and we must be able to continue to use it to display the original
"         filenames
" }}}1
"=============================================================================

let s:cpo_save=&cpo
set cpo&vim
"------------------------------------------------------------------------

function! BTW_Substitute_Filenames() abort
  let before = lh#btw#_evaluate(lh#dev#option#get('BTW_old_name', &ft, []))
  let after = lh#btw#_evaluate(lh#dev#option#get('BTW_new_name', &ft, []))
  let g:qfs = []
  try
    let qf_changed = 0
    let qflist = getqflist()

    for qf in qflist
      " 1- Fixing text
      let qft = substitute(qf.text, before, after, 'g')
      if qft != qf.text
        if qf.bufnr == 0
          let till_colon = matchstr(qft, '^[^:]*\ze:') " won't work under windows...
          if filereadable(till_colon) " trick files recognized on the fly
            let qf.bufnr = - lh#buffer#get_nr(till_colon)
          endif
          let qf.text = qft[(len(till_colon)+1) : ]
          let qf.text = substitute(qf.text, '^\s*', '', '')
          let qf.filename = till_colon
        else
          let qf.text = qft
        endif
        let qf_changed = 1
        let g:qfs += [qf]
      endif

      " 2- Fixing buffer loaded
      if qf.bufnr > 0
        let old_bufname = bufname(qf.bufnr)
        let new_bufname = substitute(old_bufname, before, after, 'g')
        if new_bufname != old_bufname
          let msg = qf.bufnr . ' -> '
          let qf.bufnr = lh#buffer#get_nr(new_bufname)
          let msg.= qf.bufnr . ' ('.new_bufname.')'
          " echomsg msg
          let qf_changed = 1
        endif
      elseif qf.bufnr < 0
        let qf.bufnr = - qf.bufnr " trick files recognized on the fly
      endif
    endfor

    if qf_changed
      call setqflist(qflist)
    endif
  catch /.*/
    call lh#common#error_msg("Error: ".v:exception. " throw at: ".v:throwpoint)
  endtry
endfunction

call lh#btw#filters#register_hook('BTW_Substitute_Filenames', 'post')

let &cpo=s:cpo_save
"=============================================================================
" vim600: set fdm=marker:

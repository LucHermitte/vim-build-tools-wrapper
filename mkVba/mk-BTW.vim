"=============================================================================
" $Id$
" File:		mk-BTW.vim
" Maintainer:	Luc Hermitte <MAIL:hermitte {at} free {dot} fr>
" 		<URL:http://code.google.com/p/lh-vim/>
" Licence:      GPLv3
" Version:	0.3.4
let s:version = '0.3.4'
" Created:	06th Nov 2007
" Last Update:	$Date$
"------------------------------------------------------------------------
let s:project = 'lh-BTW'
cd <sfile>:p:h
try
  let save_rtp = &rtp
  let &rtp = expand('<sfile>:p:h:h').','.&rtp
  exe '23,$MkVimball! '.s:project.'-'.s:version
  set modifiable
  set buftype=
finally
  let &rtp = save_rtp
endtry
finish
autoload/lh/btw.vim
autoload/lh/btw/cmake.vim
autoload/lh/btw/filters.vim
autoload/lh/btw/project.vim
autoload/lh/btw/project_options.vim
compiler/BTW/STLFilt.vim
compiler/BTW/SunSWProLinkIsError.pl
compiler/BTW/SunSWProLinkIsError.vim
compiler/BTW/TreeProject.vim
compiler/BTW/aap.vim
compiler/BTW/ant.pl
compiler/BTW/ant.vim
compiler/BTW/cmake.vim
compiler/BTW/cygwin.pl
compiler/BTW/cygwin.vim
compiler/BTW/gcc.pl
compiler/BTW/gcc.vim
compiler/BTW/gmake.vim
compiler/BTW/make.vim
compiler/BTW/run_and_recontact_vim.pl
compiler/BTW/run_in_background.pl
compiler/BTW/substitute_filenames.vim
compiler/BTW/syntax/cc.vim
doc/BuildToolsWrapper.txt
lh-build-tools-wrapper-addon-info.txt
plugin/BuildToolsWrapper.vim
tests/lh/UT_project_create.vim

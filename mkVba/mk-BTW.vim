"=============================================================================
" $Id$
" File:		mk-BTW.vim
" Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
"		<URL:http://hermitte.free.fr/vim/>
" Version:	0.2.3
" Created:	06th Nov 2007
" Last Update:	$Date$
"------------------------------------------------------------------------
let s:version = '0.2.3'
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
autoload/lh/btw/project_options.vim
autoload/lh/btw/cmake.vim
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
compiler/BTW/syntax/cc.vim
doc/BuildToolsWrapper.txt
lh-build-tools-wrapper-addon-info.txt
plugin/BuildToolsWrapper.vim

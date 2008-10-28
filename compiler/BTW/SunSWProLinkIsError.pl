#!/usr/bin/perl
# Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
#		<URL:http://hermitte.free.fr/vim>
# Purpose:	Fiter outputs from SunSWPro CC to tell that link errors are
#               actually errors.
#               Defined as a filter to use on make's result.
#		Meant to be used by Vim.
# Created:	28th Nov 2004
# Last Update:	08th Dec 2004
# ======================================================================

### Code {{{1

use strict                ;

## Main loop: The convertion. {{{2

while (<>) 
{
    chop;
    $_ =~ s/(Undefined first referenced)/--link-error--:0:$1/ ;
    print "$_\n";
}
# ======================================================================
# vim600: set foldmethod=marker:
# vim:et:ts=8:tw=79:

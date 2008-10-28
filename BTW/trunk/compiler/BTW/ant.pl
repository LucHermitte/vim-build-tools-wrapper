#!/usr/bin/perl
# $Id$ 
# Author:	Luc Hermitte <EMAIL:hermitte at free.fr>
#		<URL:http://hermitte.free.fr/vim>
# Purpose:	Get rid of ant format
# Created:	Mon 22 May 2006 08:12:59 PM CEST
# Last Update:  $date$
# ======================================================================

# Main loop: get rid of /^\s*[.*]\s*/
while (<>) 
{
    chop;
    $_ =~ s/^\s*\[.*?\]\s*// ;
    print "$_\n";
}

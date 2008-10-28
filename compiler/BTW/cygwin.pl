#!/usr/bin/perl
# $Id$ 
# Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
#		<URL:http://hermitte.free.fr/vim>
# Purpose:	Convert Cygwin pathames to plain Windows pathnames.
#               Defined as a filter to use on make's result.
#		Meant to be used by Vim.
# Created:	05/29/04 01:12:19
# Last Update:  $date$
# ======================================================================

# cygroot
my $cygroot = `cygpath -m /`;
chomp($cygroot);

# Hash table for the paths already translated with ``realname''
my %paths = () ;

# Proxy function: returns the realname of the path
# This function looks for converted paths into the hastable, if nothing is
# found in the table, the result is built and added into the table
# TODO: follow mounted things
sub WindowsPath 
{
    my ($path) = @_ ;
    if ( exists( $h{$path} ) ) {
	return $h{$path} ;
    } else {
	# Get the real localtion of the file
	$wpath = `realpath "$path"`;
	chomp ($wpath);
	# /cygdrive/c/path -> C:/path
	$wpath =~ s#/cygdrive/(.)#\u\1:#  ;
	# /c/path -> C:/path ; I suppose /cygdrive/c/ is mounted into /c/
	$wpath =~ s#^/([^/])/#\u\1:/#  ;
	# /path -> C:/cygwin/path ; may be F:/cygwin/, ....
	$wpath =~ s#^/#$cygroot/#  ;
	# Add the path into the hash-table
	$h{$path} = $wpath ;
	return $wpath ;
    }
}

# Main loop: convert Cygwin paths into MsWindows paths
while (<>) 
{
    chop;
    if ( m#^( */.*?)(\:\d*\:?.*$)# ) {
	printf WindowsPath($1)."$2\n";
    } else {
	print "$_\n";
    }
}

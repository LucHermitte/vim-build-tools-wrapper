#!/usr/bin/perl
# Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
#		<URL:http://hermitte.free.fr/vim>
# Purpose:	Filter outputs from GCC like the error messages from the
#               link phase.
#               Defined as a filter to use on make's result.
#		Meant to be used by Vim.
# Created:	28th Nov 2004
# Last Update:	08th Dec 2004
# ======================================================================

### Code {{{1

use strict                ;
use Getopt::Long          ; # Getoptions()

## Options                    {{{2
my $grp_lnk   = 1;
my $click_lnk = 0;
my $obj_dir   = "";
my $src_dir   = "";

# check_options() {{{3
sub check_options {
    GetOptions (
        "grp-lnk:i"   => \$grp_lnk
        # ,"no-grp-lnk" => sub { $grp_lnk = 0; }
        ,"clk-lnk:i"  => \$click_lnk
        # ,"no-clk-lnk" => sub { $click_lnk = 0; }
        ,"obj=s"      => \$obj_dir
        ,"tu=s"       => \$src_dir
    ) or die("gcc.pl [-grp-lnk] [-clk-lnk [-obj=dir] [-tu=dir] ]\n");

    # Eat a terminal / at the end of the object-files path
    $obj_dir =~ s#[^\\/]$#$&/# ;
    # Search for / or \ i the object-files path
    $obj_dir =~ s#[\\/]#[\\\\/]#g ;
    # Only use / in the error message -> Vim does not care.
    $src_dir =~ s#\\#/#g ;
    # If non nul, be sure there is a / at the end.
    $src_dir =~ s#[^\\/]$#$&/# ;

}

check_options() ;

## obj2src {{{2
sub obj2src {
    my ($path, $file) = @_ ;
    $path  =~ s#^$obj_dir#$src_dir# ;
    return "$path$file";
}

## check_obj {{{2
# In the :match, the $i are:
# $1: path
# $2: object file
# $3: entry in the object file (?)
# $4: name of the translation unit
# $5: error message

my $last_obj_file ;
sub check_obj {
    my $disp_file ;
    if ( m#^(?:(.*[/\\])([^/\\]*\.o(?:bj)?))(\(.*?\)):([^:]*):(.*)# ) {
        # path/filename to display
        if ($click_lnk)  {
            $disp_file = obj2src($1, $4) . "\:1:" ;
        } else {
            $disp_file = "$1$2\:$4\:" ;
        }

        # if I want to merge these errors
        if ( !$grp_lnk || ("$last_obj_file" ne "$1$4") ) {
            $last_obj_file = "$1$4" ;
            printf "$disp_file" ;
            if ($grp_lnk) {
                printf " Link error(s)\n" ;
            } 
        }
        # Print the current error
        printf "$3$5\n";
        return 1 ;
    } else { return 0 ; }
}

## check_lib {{{2
# In the :match, the $i are:
# $1: path/library(object_file)
# $2: entry in the object file (?)
# $3: name of the translation unit
# $4: error message

sub check_lib {
    return 0 if !$grp_lnk;
    if ( m#^(.*\.a\(.*?\))(\(.*?\)):([^:]*):(.*)# ) {
        if ( "$last_obj_file" ne "$1" ) {
            $last_obj_file = "$1" ;
            printf "$1\:: Link error(s)\n";
        }
        printf "$2 $3\: $4\n";
        return 1 ;
    } else { return 0 ; }
}

## Main loop: The convertion. {{{2

my $do_sthg_on_obj = $grp_lnk || $click_lnk ;

while (<>) 
{
    chop;
    if ( $do_sthg_on_obj && (check_obj($_) || check_lib($_))) {
    } else {
        print "$_\n";
    }
}


# ======================================================================
# vim600: set foldmethod=marker:
# vim:et:ts=8:tw=79:

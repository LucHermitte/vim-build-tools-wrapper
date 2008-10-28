#!/usr/bin/perl
# Author:	Luc Hermitte <EMAIL:hermitte {at} free {dot} fr>
#		<URL:http://hermitte.free.fr/vim>
# Purpose:	Blocking run of make from Vim
#		Meant to be used by and from Vim.
# Created:	03/02/2007 04:50:15
# Last Update:	03rd Feb 2007

# Inspired from run_in_background.pl
# ======================================================================

### Code {{{1

use strict                ;
use Getopt::Long          ; # Getoptions()
use English '-no_match_vars'; # ???
use POSIX ":sys_wait_h"   ; # ???
use POSIX qw(tmpnam)      ; # temporary filename

## If VimDetect supported
# use lib "$ENV{HOME}/lib/perl/";
# use VimDetect             ; # vim_bin(), dollar_vimruntime()
## if not, change to the path to Vim
sub vim_bin {
    return "vim";
}

## Options                    {{{2
my $servername     = "";
my $external_prog  = ""; # for instance: "xterm -e"
my $vim_executable = vim_bin() ;
# If v:progname is received, then it should be in the $PATH, at least under
# windows. => $vim_executable can be used to run vim

# check_options()               {{{3
sub check_options {
    GetOptions (
        "vim=s"             => \$vim_executable
        ,"servername=s"     => \$servername
        ,"program=s"        => \$external_prog
    ) or die("run_in_background.pl -s=servername [-p=program] MAKE-COMMAND\n");
}

sub send_to_vim {
    my ($errorfile) = @_;
    my (@args) = ($vim_executable, 
	"--servername", $servername, 
	"--remote-send", "<C-\\><C-N>:CopenBG $errorfile<cr>"
    );

    system(@args) == 0
        or die "system ``@args'' failed: $?";
}

## Main                       {{{2
check_options();

# Run make                    {{{3
setpgrp( $PROCESS_ID, 0 );

my $temp_dir = -d '/tmp' ? '/tmp' : $ENV{TMP} || $ENV{TEMP};

my $errorfile="$temp_dir/tmp-make-bg-$$" ;

# printf "filling $errorfile\n";
# printf "executing  @ARGV\n";
close STDOUT; close STDERR;
# close STDIN;
# We must not close STDIN!!


open(FH, ">$errorfile")
    or die ("Can not open $errorfile") ;
# print FH "run_in_background.pl:45: testing\n";
print FH "Command(s) executed: @ARGV\n";
close FH;
if ($external_prog =~ /^$/) {
    ## normal execution
    my (@run) = (@ARGV) ;
    # system("(@run) >>$errorfile ". '2>&1') ;
    system("(@run) >>$errorfile ". '2>&1') == 0
        or printf( "Can not execute ``@run''");
} else {
    ## Execution displayed in an xterm/...
    # As some «xterm -e» do not support commands separated by ';' or '|', a
    # temporary shell script is built, and executed in the xterm (or any
    # other "environment".
    my $scriptfile = "$temp_dir/tmp-make-bg-$$.sh" ;
    open(SH, ">$scriptfile")
        or die "Can not create script file $scriptfile";
    print SH "#!/bin/sh\n" ;
    print SH "@ARGV 2>&1 | tee -a $errorfile\n" ;
    close SH;
    chmod 0755, $scriptfile ; # execution rights
    my (@run) = ($external_prog, $scriptfile) ;
    # printf "run= @run\nscriptfile=$scriptfile\n";
    system("@run") == 0 
        or die ("Can not execute @run") ;
    unlink $scriptfile ; 
}

if (`uname` =~ /CYGWIN/) {
    $errorfile = `cygpath -m $errorfile`;
    chomp($errorfile);
}
# Send the errors back to Vim's quickfix window

send_to_vim($errorfile);

# print "(exiting, ppid=" . getppid() . ")\n";

# Perl's getppid() on MSWIN returns "1" from inside Vim.
#kill -9, getppid();


# ======================================================================
# vim600: set foldmethod=marker:
# vim:et:ts=8:tw=79:

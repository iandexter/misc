#!/usr/bin/perl
#
# Parses bash history file.
# 
# Requires the following in .bashrc:
#
#     export WHOAMI=$(who am i | awk '{printf $1}')
#     export HISTFILE=$HOME/.bash_history_$WHOAMI
#     export HISTCONTROL=ignoredups
#     export HISTSIZE=99999
#     export HISTTIMEFORMAT="%D %T "

use strict;
use warnings;

use POSIX qw(strftime);
use Data::Dumper;

$|=1;

if(! @ARGV) {
    print <<EOF;

Parses bash history file.

Usage: $0 history-file

    Format of history file is as follows:

        #[epoch timestamp]
        [command]

EOF
    exit 3;
}

my $history_file = $ARGV[0];
open my $fh, "<", $history_file || die "Cannot open $history_file: $!\n";

my $i = 0;
while(<$fh>) {
    if(/^#/) {
        s/^#//;
        ### printf "%s \t ", convert_time($_);
        printf "%5d %s ", ++$i, strftime("%d/%m/%Y %H:%M:%S", localtime($_));
        next;
    }
    print;
}
close $fh;
exit 0;

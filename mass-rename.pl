#!/usr/bin/perl
#
# Rename a bunch of files using regexp.

use strict;
use warnings;
use Getopt::Std;
use vars qw/$opt_n $opt_v $opt_e/;

if (not getopts("nve:")) {
        usage();
}
if (not defined($opt_e)) {
        usage();
}

foreach my $file_name (@ARGV) {
        my $new_name = $file_name;

        eval "\$new_name =~ s$opt_e";

        if ($file_name ne $new_name) {
                if (-f $new_name) {
                        my $ext = 0;
                        while (-f $new_name.".".$ext) {
                                $ext++;
                        }
                        $new_name = $new_name.".".$ext;
                }
                if ($opt_v) {
                        print "$file_name -> $new_name\n";
                }
                if (not defined($opt_n)) {
                        rename($file_name, $new_name);
                }
        }
}

sub usage {
        print("Usage: $0 -e regexp filenames\n");
        exit 1;
}

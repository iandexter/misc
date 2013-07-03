#!/usr/bin/perl
#
# Generates report summary for check_expired_passwd.


use strict;
use warnings;
use Data::Dumper;

my $fh;
my %expired_hash;
my %expiring_hash;

$|=1;

if(! @ARGV) {
    print <<EOF;
Generates report summary for check_expired_passwd.

Usage: $0 report-file

    Format of report file is as follows:

        server,user,status
EOF
    exit 3;
}

my $report = shift @ARGV;

open $fh, "<", $report || die "Cannot open file: $!\n";
while(<$fh>) {
    chomp;
    $_ =~ tr/[A-Z]/[a-z]/;
    my ($server,$user,$status) = split /,/;
    my $key = $user;
    my $val = $server;
    if($status =~ /expired/) { push @{ $expired_hash{$key} }, $val; }
    if($status =~ /expiring/) { push @{ $expiring_hash{$key} }, $val; }
}
close $fh;

printf "Expired (%d):\n", scalar keys %expired_hash;
foreach my $user (sort keys %expired_hash) {
    printf "%s: %s\n", $user, join(",", sort @{ $expired_hash{$user} });
}
printf "\n---\n\n";
printf "Expiring (%d):\n", scalar keys %expiring_hash;
foreach my $user (sort keys %expiring_hash) {
    printf "%s: %s\n", $user, join(",", sort @{ $expiring_hash{$user} });
}

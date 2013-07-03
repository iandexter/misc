#!/usr/bin/perl
#
# Compare RPMs against a baseline host.

use strict;
use warnings;

use Data::Dumper;
use Net::OpenSSH;
use Getopt::Std;

$|=1;

my $opt_str = 'hsvb:t:';
my %opts;

my $ssh;

sub get_options {
        getopts("$opt_str", \%opts) || usage();
        usage() unless scalar %opts;
        usage() if $opts{h};
        usage() if (! $opts{b} || ! $opts{t});
        usage() if ($opts{s} && $opts{v});
}

sub usage {
        print <<EOF;
Compare RPMs against a baseline host.

Usage: $0 [options] -b baseline_host -t target_host

-h : Print this help message.
-s : Report only when there are differences.
-v : Verbose output.

EOF
        exit 3;
}

sub connect_ssh {
        my ($rhost) = @_;
        $ssh = Net::OpenSSH->new($rhost);
        $ssh->error && die "Unable to connect to $rhost: " . $ssh->error . "\n";
        return $ssh->get_ctl_path;
}

sub remote_command {
        my ($rcmd) = @_;
        my $output = $ssh->capture({stderr_to_stdout => 1}, $rcmd);
        return $output;
}

sub get_list {
        my ($rhost) = @_;

        my $ssh_connect = connect_ssh($rhost);
        my $rpm_cmd = '/bin/rpm -qa --qf "%{NAME}\n" | sort -f | uniq';
        $rpm_cmd = '/bin/rpm -qa --qf "%{NAME}-%{VERSION}-%{RELEASE}\n" | sort -f | uniq' if $opts{v};
        my $rpms = remote_command($rpm_cmd);
        my @list = split(/\n/, $rpms);

        if ($opts{v}) {
                $, = ",";
                print "Host: $rhost\n";
                print @list, "\n";
                print "---\n";
        }

        return @list;
}

sub get_diff {
        my ($baseline_host, $target_host) = @_;

        my @diff = ();
        my @baseline_list = get_list($baseline_host);
        my @target_list = get_list($target_host);

        my %count;
        @count{@baseline_list} = (1) x @baseline_list;
        foreach my $item (@target_list) { push(@diff, $item) unless exists $count{$item}; }

        return @diff;
}

sub print_diff {
        my ($baseline_host, $target_host, @diff) = @_;

        $, = "";
        print "* In $target_host but not in $baseline_host\n";
        foreach (@diff) { print $_, "\n"; }
        print "\n";
}

get_options();
print Dumper \%opts if $opts{v};

my $baseline_host = $opts{b};
my $target_host = $opts{t};

my @baseline_diff = get_diff($target_host, $baseline_host);
my @target_diff = get_diff($baseline_host, $target_host);

if(@baseline_diff || @target_diff) {
        if($opts{s}) {
                print "RPMS in the hosts differ.\n";
        } else {
                print_diff($target_host, $baseline_host, @baseline_diff);
                print_diff($baseline_host, $target_host, @target_diff);
        }
        exit 1;
} else {
        exit 0;
}

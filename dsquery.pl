#!/usr/bin/perl
#
# Search Active Directory and Lotus Domino LDAP objects.
# Uses a configuration file ('dsquery.conf') in the following format:
#
#   ldap_host:adhost.domain
#   ldap_port:389
#   ldap_bind:CN_OF_BIND_ID
#   ldap_pass:PASSWORD_OF_BIND_ID
#   ldap_base:OU=dir,DC=company,DC=com
# 
# ***WARNING***: Having a plaintext file containing directory credentials
#                is unsafe. Better to use Kerberized LDAP + keytabs.


use strict;
use Net::LDAP;
use Net::LDAP::Util qw(ldap_error_text);
use Data::Dumper;

my $debug = 0;

my $ldap_bind = '';
my $ldap_srch = '';
my @ldap_attr;

my $cfg_file = '';
my %ldap_config;

### Functions
sub print_usage {
    print("Usage: $0 [ad|notes] search_query [attr ... attr]\n");
    exit 1;
}

sub get_config {
    my %config;
    open(CONFIG, "$cfg_file") || die("Cannot open $cfg_file: $!\n");
    while (<CONFIG>) {
        chomp;
        s/#.*//; s/^\s+//; s/\s+$//;
        next unless length;
        my ($var, $val) = split('\:',$_);
        $config{$var} = $val;
    }
    close CONFIG;
    return %config;
}

sub display_entry {
    my ($srch, $entry) = @_;

    return if(!defined($entry));

    print("dn: ", $entry->dn, "\n");
    foreach my $attr ($entry->attributes) {
        next if ( $attr =~ /;binary$/ );
        foreach my $value ($entry->get_value($attr)) {
            print($attr, ": ", $value, "\n");
        }
    }
    print("\n");

    $srch->pop_entry;
}

### Main
if($#ARGV < 1) { print_usage; }

if($ARGV[0] =~ /ad/) {
    $cfg_file = '/path/to/dsquery.conf.ad';
} elsif ($ARGV[0] =~ /notes/) {
    $cfg_file = '/path/to/dsquery.conf.notes';
} else {
    print_usage;
}

if($ARGV[1] =~ /=/) {
    $ldap_srch = $ARGV[1];
} else {
    my $uid = $ARGV[1];
    if($ARGV[0] =~ /ad/) {
        $ldap_srch = "sAMAccountName=$uid";
    } elsif($ARGV[0] =~ /notes/) {
        $ldap_srch = "(&(uid=$uid\@adb.local)(cn=$uid))";
    }
}

if($ARGV[2]) {
    foreach my $argnum (2 .. $#ARGV) { push(@ldap_attr, $ARGV[$argnum]); }
} else {
    if($ARGV[0] =~ /ad/) {
        @ldap_attr = ('sAMAccountName','displayName','mail');
        } elsif($ARGV[0] =~ /notes/) {
            @ldap_attr = ('uid','staffname','mail');
        }
}

if($debug) {
    print("---------------------------------------\n");
    print(Dumper(@ldap_attr));
    print("---------------------------------------\n\n");
}

%ldap_config=get_config;
$ldap_bind =  $ldap_config{'ldap_bind'};
$ldap_bind =~ s/\"//g;

my $ldap = Net::LDAP->new($ldap_config{'ldap_host'}) || die("ERROR: $@\n");
my $bind = $ldap->bind($ldap_bind, password => $ldap_config{'ldap_pass'});
die("ERROR: " . ldap_error_text($bind->code) . "\n") if($bind->code);

my $srch = $ldap->search(base => $ldap_config{'ldap_base'}, filter => $ldap_srch, attrs => [@ldap_attr], callback => \&display_entry);
die("ERROR: " . ldap_error_text($bind->code) . "\n") if($srch->code);

exit 0;

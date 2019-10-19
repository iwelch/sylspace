#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

use strict;
use utf8;
use feature ':5.20';
use warnings;

no warnings qw(experimental::signatures);
use warnings FATAL => qw{ uninitialized };
use feature 'signatures';

use autodie;

($> == 0) or die "this script modifies /etc/hosts, so it needs sudo privileges";


#### set up webdomains
my $dmnm= (glob("/var/sylspace/domainname=*"))[0];

if (defined($dmnm)) {
  $dmnm =~ s{^/var/sylspace/domain\=}{};
} else {
  say "Domain not yet in filesystem";
  (@ARGV) or die "  please provide a domain name as argument.\n";
  ($ARGV[0] =~ /^[a-z]+\.[a-z]+$/i)
    or die "need reasonable domainname (with one dot), not '$ARGV[0]'\n";
  $dmnm= $ARGV[0];
  open(my $F, '>', "/var/sylspace/domainname=$dmnm"); close($F);
  say "[saved domain name $dmnm]\n";
}

## we could now check if there is a valid IP in the global DNS and also write this.
## (-e '/var/sylspace/courses/auth') or die "internal error.  no 'auth' course";

my @courses= glob("/var/sylspace/courses/*");
foreach (@courses) { s{^/var/sylspace/courses/(.*)}{$1.$dmnm}; }

push( @courses, $dmnm );
push( @courses, 'auth.'.$dmnm );

say "enabling wildcard domain='$dmnm' for /etc/hosts:\n\t".join("\n\t", @courses)."\n";;



my $phrase= '# written by sylspace wildcardhosts.pl';

my $lastwasnl=0;

open(my $FHOSTS, '<', '/etc/hosts');
open(my $FHOSTSO, '>', '/etc/hosts.new');
while (<$FHOSTS>) {
  (/$phrase/) and next;
  (($lastwasnl) && ($_ eq "\n")) and next;
  print $FHOSTSO $_;
  $lastwasnl= ($_ eq "\n");
}

print $FHOSTSO "127.0.0.1\t".join(' ', @courses)." $phrase ".`date`."\n";
close($FHOSTS);
close($FHOSTSO);

system("cp /etc/hosts /etc/hosts.old ; mv /etc/hosts.new /etc/hosts");

say "done";


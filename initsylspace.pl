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


=pod

=head1 Title

  initsylspace.pl --- set up sylspace on a new computer (possibly again)

=head1 Description

  the above 'use' statements exist to make sure we have everything installed.

=head1 Versions

  0.0: Wed May  3 08:53:04 2017

=cut

system("perl initsylspace.pm") and die "please check all apt and cpan installs";

my $varsyl="/var/sylspace";

################################################################

(`uname` eq "Linux\n") or die "sylspace runs only under Linux, not ".`uname`;
($> eq 0) or die "the initsylspace.pl script requires su privileges (to add to $varsyl to /var)\n";
(-w "/var") or die "internal error: I cannot write to the /var directory.  please run this script as sudo";


(-e "./templates/equiz/starters") or die "internal error: you don't seem to have any starter templates here";
(-e "./Model/Model.pm") or die "internal error: you don't seem to have the Model/ directory";
(-e "./Model/eqbackend/eqbackend.pl") or die "internal error: you don't seem to have the Model/eqbackend";
(-e "./Controller/InstructorIndex.pm") or die "internal error: you don't seem to have the frontend (Controller/InstructorIndex.pm";

if (-e $varsyl) {
  (@ARGV) or die "without -f to erase the old $varsyl, this script refuses to run!\n";
  ($ARGV[0] eq '-f') or die "without -f to erase the old $varsyl, this script refuses to run!\n";
  system("rm -rf $varsyl");
}


#### set up $varsyl

mkdir("$varsyl") or die "internal error: I could not mkdir $varsyl: $!";

chmod(0777, $varsyl) or die "chmod: failed on opening $varsyl to the public: $!\n";
say STDERR "made $varsyl";


use File::Touch;

touch("$varsyl/paypal.log")or die "internal error: I could not touch $varsyl/paypal.log: $!";
chmod(0777, "$varsyl/paypal.log") or die "chmod: failed on opening $varsyl/paypal.log to the public: $!\n";
say STDERR "made $varsyl/paypal.log";
touch("$varsyl/general.log")or die "internal error: I could not touch $varsyl/general.log: $!";
chmod(0777, "$varsyl/general.log") or die "chmod: failed on opening $varsyl/general.log to the public: $!\n";
say STDERR "made $varsyl/general.log";

foreach (qw(users courses tmp templates)) {
  (-e "$varsyl/$_") and next; ## actually should not happen usually
  mkdir("$varsyl/$_") or die "cannot make $varsyl/$_: $!\n";
  chmod(0777, "$varsyl/$_") or die "chmod: failed on chmod-ing $varsyl/$_ to the public: $!\n";
  say STDERR "made $varsyl/$_";
}

system("cp -a templates/equiz/* $varsyl/templates/");
if (!(-e "$varsyl/secrets.txt")) {
  open(my $FO, ">", "$varsyl/secrets.txt"); for (my $i=0; $i<30; ++$i) { print $FO mkrandomstring(32)."\n"; } close($FO);
}
say STDERR "made $varsyl/secrets.txt\n";

say STDERR "\nNow create a nice sample website.

cd Model/
perl mkstartersite.t  ## other tests: Model.t Files.t
perl addsite.pl mysample instructor\@gmail.com

  ## if the domain is fake, please run `wildcardhosts.pl yourfakedomain.com` after you add a site.
";


################################################################

sub mkrandomword {
  my $len= $_[0] || 32;
  my @conson = (split( '', "bcdfghjklmnprstvwxz"."rsn"), "sh", "th");
  my @vowel = split( '', "aeeiou" );
  my $rstring="";
  for (my $i=0; $i<$len; ++$i) {
    $rstring.=  (( $i % 2 ) == 0 ) ? ($conson[rand @conson]) : ($vowel[rand @vowel]);
  }
  return $rstring;
}

sub mkrandomstring {
  my @chars = ("A".."Z", "a".."z", "0".."9");
  my $string;
  $string .= $chars[rand @chars] for 1..($_[0]||32);
  return $string;
}

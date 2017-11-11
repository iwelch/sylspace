#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

use strict;
use common::sense;
use utf8;
use feature ':5.20';
no warnings qw(experimental::signatures);
use feature 'signatures';
no warnings qw(experimental::signatures);

use warnings;
use warnings FATAL => qw{ uninitialized };
use autodie;

use Archive::Zip;
use Crypt::CBC;
use Crypt::DES;
use Crypt::Blowfish;
use Data::Dumper;
use Digest::MD5;
use Digest::MD5::File;
use Email::Valid;
use Encode;
use File::Copy;
use File::Glob;
use File::Path qw(make_path);
use File::Touch;
use FindBin;
use HTML::Entities;
use MIME::Base64;
use Math::Round;
use Perl6::Slurp;
use Safe;
use Scalar::Util;
use Scalar::Util::Numeric;
use Test2::Bundle::Extended;
use Test2::Plugin::DieOnFail;
use YAML::Tiny;

use Class::Inspector;

use Mojolicious::Lite;
use Mojolicious::Plugin::RenderFile;
use Mojolicious::Plugin::Mojolyst;
use Mojolicious::Plugin::BrowserDetect;

## these are used in the authentication module
use Mojo::JWT;
use Mojolicious::Plugin::Web::Auth;
use Email::Sender::Simple;
use Email::Simple::Creator;
use Email::Sender::Transport::SMTP::TLS;

use Mojolicious::Plugin::Web::Auth;

=pod

=head1 Title

  initsylspace.pl --- set up sylspace on a new computer

=head1 Description

  the above 'use' statements exist to make sure we have everything installed.

=head1 Versions

  0.0: Wed May  3 08:53:04 2017

=cut

use File::Grep;

my $var="/var/sylspace";

($> eq 0) or die "the initsylspace script requires su privileges to add to $var to /var\n";

(@ARGV) or die "without -f to erase the old $var, this script refuses to run!\n";
($ARGV[0] eq '-f') or die "without -f to erase the old $var, this script refuses to run!\n";
system("rm -rf $var");

my $samplesites="syllabus.test poster.syllabus.test auth.syllabus.test mfe.welch.syllabus.test mba.welch.syllabus.test ugrad.welch.syllabus.test hs.welch.syllabus.test  mba.daniel.syllabus.test year.course.instructor.university.syllabus.test corpfin.test.syllabus.test syllabus.test.syllabus.test";

(grep { 'auth.test' } "/etc/hosts")  or die "please extend /etc/hosts to contain 'auth.syllabus.test', etc.\n$samplesites\n";

(-e "templates/equiz/starters") or die "internal error: you don't seem to have any starter templates";
(-e "Model/Model.pm") or die "internal error: you don't seem to have the Model";
(-e "Model/eqbackend/eqbackend.pl") or die "internal error: you don't seem to have the eqbackend";
(-e "Controller/InstructorIndex.pm") or die "internal error: you don't seem to have the frontend (Controller/instructorindex.pm";

(-w $var) and die "[$var exists and is writeable, aborting for safety]\n";

(-e "/var") or die "internal error: your computer has no /var directory.  is this windows??";
(-r "/var") or die "internal error: I cannot read the /var directory";
(-w "/var") or die "internal error: I cannot write to the /var directory.  please run this script as sudo";

mkdir("$var") or die "internal error: I could not mkdir $var: $!";
chmod(0777, $var) or die "chmod: failed on opening $var to the public: $!\n";
say STDERR "made $var";

touch("$var/paypal.log")or die "internal error: I could not touch $var/paypal.log: $!";
chmod(0777, "$var/paypal.log") or die "chmod: failed on opening $var/paypal.log to the public: $!\n";
touch("$var/general.log")or die "internal error: I could not touch $var/general.log: $!";
chmod(0777, "$var/general.log") or die "chmod: failed on opening $var/general.log to the public: $!\n";

foreach (qw(users courses tmp templates)) {
  (-e "$var/$_") and next; ## actually should not happen usually
  mkdir("$var/$_") or die "cannot make $var/$_: $!\n";
  chmod(0777, "$var/$_") or die "chmod: failed on chmod-ing $var/$_ to the public: $!\n";
  say STDERR "made $var/$_";
}

system("cp -a templates/equiz/* $var/templates/");
if (!(-e "$var/secrets.txt")) {
  open(my $FO, ">", "$var/secrets.txt"); for (my $i=0; $i<30; ++$i) { print $FO mkrandomstring(32)."\n"; } close($FO);
}

say STDERR "\nNow create a sample website.  First, cd Model/ .  Then\n\t(1) perl mkstartersite.t-- (there is also mkmessysite.t)\n\t(2) mksite.pl mfe.ucla instructor\@gmail.com   --- adds a new specific course site to existing site\n\t  // For more testing, you can also use perl Model.t ; perl Files.t instead.\n";

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

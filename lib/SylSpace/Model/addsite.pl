#!/usr/bin/env perl
use strict;
use common::sense;
use utf8;
use warnings FATAL => qw{ uninitialized };
use autodie;

use feature ':5.20';
use feature 'signatures';
no warnings qw(experimental::signatures);

################################################################

use lib '../..';

use SylSpace::Model::Webcourse qw(_webcoursemake _webcourseremove _webcourseshow );
use SylSpace::Model::Model qw(:DEFAULT instructornewenroll);

my $usage= "usage: $0 sitename instructoremail\n";

(@ARGV) or die $usage;
($#ARGV==1) or die $usage;
my ($subdomain, $iemail) = @ARGV;

_webcoursemake( $subdomain );
instructornewenroll($subdomain, $iemail);

print "successfully created website $subdomain with instructor $iemail\n";

if (`hostname` !~ /syllabus-space/m) {
  print "

IMPORTANT : because you did not execute this on a production site, you probably
need to add $subdomain to map to 127.0.0.1 into /etc/hosts
";
}

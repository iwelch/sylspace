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

use Mojo::File qw(curfile);
use lib curfile->dirname->sibling('lib')->to_string;
use lib curfile->dirname->sibling('local/lib/perl5')->to_string;

use SylSpace::Model::Webcourse qw(_webcoursemake _webcourseremove _webcourseshow );
use SylSpace::Model::Model qw(:DEFAULT instructornewenroll);

my $usage= "usage: $0 sitename [finc3600-2018-risik-webster] instructoremail\n";

die $usage unless @ARGV == 2;

my ($subdomain, $iemail) = @ARGV;

$subdomain= lc($subdomain);
$iemail= lc($iemail);

_webcoursemake( $subdomain );
instructornewenroll($subdomain, $iemail);

print "successfully created website $subdomain with instructor $iemail\n";

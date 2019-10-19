#!/usr/bin/env perl
use strict;
use common::sense;
use utf8;
use warnings FATAL => qw{ uninitialized };
use autodie;

use Data::Dumper;
use Perl6::Slurp;
use Archive::Zip;

use feature ':5.20';
use feature 'signatures';
no warnings qw(experimental::signatures);

use Test2::Bundle::Extended;
use Test2::Plugin::DieOnFail;

use lib '../..';

use SylSpace::Model::Utils qw(_decryptdecode _encodeencrypt);

my $teststring='abc|def|ghi';

ok( my $e= _encodeencrypt($teststring), "encoded" );
ok( my $d= _decryptdecode($e), "decoded" );
ok( $teststring eq $d, "decoded properly" );

my $n= "U2FsdGVkX18xNDE1MTYxNy5FxQRMqUwZKNhE4dgmPeuI6lsm%2BPLxB8hh9GuNh%2BGG1xghQjZqKZQ%3D";
print _decryptdecode($n)."\n";

$n= "ApBHX6qbpxJW-Ll3oP22LSbo0WeuACRjO4sZ08jzh3ePisCPJAj1L0Xw";
print "\nNow the last one: "._decryptdecode($n)."\n";


like( dies { _decryptdecode("please die") }, qr{not begin}, "good death!");

done_testing();


#!/usr/bin/env perl
use SylSpace::Test make_test_site => 1;
use SylSpace::Test::Utils qw(tziserver);

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

## for testing
my $iemail='instructor@gmail.com';
my $s1email='student1@gmail.com';
my $s2email='student2@gmail.com';
my $s3email='noone@gmail.com';

my @course=qw (mfe.welch mba.welch year.course.instructor.university intro.corpfin);


use SylSpace::Model::Grades qw( gradetaskadd gradesave gradesashash );
use SylSpace::Model::Webcourse qw(_webcoursemake _webcourseremove);
use SylSpace::Model::Model qw(instructornewenroll userenroll userexists usernew isenrolled biosave);

SylSpace::Model::Utils::_setsudo();  ## special purpose!

#setup the courses
#TODO- define these test fixtures in yaml, and have them
#autocreated from there. Add as a function to SylSpace::Test::Utils
subtest 'setup and sanity' => sub {
  foreach (@course) {
    ok( _webcoursemake($_), "created $_ site" );
    instructornewenroll($_, $iemail);
  }
  ok isenrolled($course[0], $iemail),
    "$iemail is nicely enrolled in $course[0]";

  my %bioalice = ( uniname => 'ucla', regid => 'na', firstname => 'alice', lastname => 'architect', birthyear => 1963,
                 email2 => $iemail, zip => 90095, country => 'US', cellphone => '(312) 212-3100',
                 email => $iemail, tzi => tziserver(), optional => '' );
  ok( biosave($iemail, \%bioalice), 'written biodata for alice' );

  isnt usernew($s1email), -1, 'new bob';
  my %biobob = ( uniname => 'na', regid => 'na', firstname => 'bob', lastname => 'builder', birthyear => 1975,
                email2 => $s1email, zip => 90049, country => 'US', cellphone => '(312) 212-3200',
                email => $s1email, tzi => tziserver(), optional => '' );
  ok( biosave($s1email, \%biobob), 'written biodata for bob' );


  ok( usernew($s2email), "new user $s2email" );
  my %biocharlie = ( uniname => 'ucla', regid => 'na', firstname => 'charlie', lastname => 'carpenter', birthyear => 2005,
                    email => $s2email, zip => 90049, country => 'US', cellphone => '(312) 212-3300',
                    email2 => $s2email, tzi => tziserver(), optional => '' );
  ok( biosave($s2email, \%biocharlie), 'written biodata for charlie' );

  ok( usernew($s3email), 'new noone user' );

  ok( userenroll($course[0], $s1email), "enrolled $s1email" );
  ok( userenroll($course[0], $s2email), "enrolled $s2email" );
};

### todo: add test that when there is no or one gradetask, gradesashash still functions well.

note '
################ grade center
';

ok( dies { gradeadd($course[0], $s2email, 'hw1', 'fail' ) }, "no hw1 yet registered for new grades");
ok( gradetaskadd($course[0], qw(hw1 hw2 hw3 midterm)), "hw1, hw2 hw3 midterm all allowed now" );

ok( gradesave($course[0], $s2email, 'hw2', 'c-' )>=0, "grade hw2 for $s2email");  ## we change one entry, we had none, so we return -1+1
ok( gradesave($course[0], $s2email, 'hw3', 'pass' )>=0, "grade hw1 for $s2email");

ok( gradesave($course[0], $s2email, 'hw1', 'pass' )>=0, "grade hw1 for $s2email changed");

ok( gradesave($course[0], $s1email, 'hw1', 'pass' )>=0, "grade hw1 for bob fail");
ok( gradesave($course[0], $s1email, 'hw2', 'a-' )>=0, "grade hw2 for bob a-");
ok( gradesave($course[0], $s1email, 'midterm', 'pass' )>=0, "grade midterm for bob");

ok( dies { gradesave($course[0], 'noone12312@gmail.com', 'midterm', 'pass' )>=0 }, "grade midterm for none12312");
ok( dies { gradesave('mfe2', $s2email, 'test5', 'midterm' )>=0 }, "grade midterm for wrong course");

ok( gradetaskadd($course[0], qw(hw5)), "hw5 is now allowed now" );
ok( gradesave($course[0], $iemail, "hw5", " 1/3 ")>=0, "added grade alice for hw5");
ok( gradesave($course[0], $s2email, "hw5", " 2/3 ")>=0, "added grade $s2email for hw5");

my $gah;
my @students;

$gah=gradesashash( $course[0] );  ## instructor call
@students= @{$gah->{uemail}};
is @students + 0, 3, "you have three students", join("|", @students);

ok( $gah->{grade}->{$s1email}->{midterm} eq 'pass', "Sorry, but bob should have passed the midterm, not ".$gah->{grade}->{$s1email}->{midterm});
ok( !defined($gah->{grade}->{$s1email}->{eq1}), "Good. bob has no eq1 grade" );

$gah=gradesashash( $course[0], $s2email );
@students= $gah->{uemail};
ok( $#students==0, "you have exactly one student in$s2email" );
ok( $gah->{grade}->{$s2email}->{hw2} eq 'c-', "good.  $s2email got a c-" );
ok( !defined($gah->{grade}->{$s2email}->{eqz22}), "good.  $s2email has no grade" );

ok( !defined($gah->{grade}->{$s1email}->{midterm}), "Good.  we did not leak bob's grade info to $s2email" );

done_testing();

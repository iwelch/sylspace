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

## for testing
my $iemail='instructor@gmail.com';
my $s1email='student1@gmail.com';
my $s2email='student2@gmail.com';
my $s3email='noone@gmail.com';

my @course=qw (mfe.welch mba.welch year.course.instructor.university intro.corpfin);

use lib '../..';

use SylSpace::Model::Files qw(answercollect cptemplate eqlisti eqwrite hwwrite filewritei filedelete eqsetdue hwsetdue filesetdue filelisti filelists filereads answerlists answerwrite);

################################################################################################################################

SylSpace::Model::Utils::_setsudo();  ## special purpose!

note '
################ file storage and retrieval system
';


ok( cptemplate( 'intro.corpfin', 'corpfinintro' ), "copied all corpfinintro files to course 'intro.corpfin'" );

my $filelist= eqlisti( 'intro.corpfin');
foreach my $onefile (@{$filelist}) {
  ok( eqsetdue( 'intro.corpfin', $onefile->{sfilename}, time()+24*60*60*365*10) , "setdue on equiz $onefile->{sfilename} to much later" );
}

my $e2n= "2medium.equiz"; ok( -e $e2n, "have local test file '2medium.equiz' for use in Model subdir" );
ok( eqwrite($course[0], $e2n, scalar slurp($e2n))>=0, 'writing $e2n' );

ok( hwwrite($course[0], 'hw1.txt', "please do the first homework\n")>=0, 'writing hw1.txt');
ok( hwwrite($course[0], 'hw2.txt', "please do the second homework.  it is longer.\n")>=0, 'writing hw2.txt');

ok( filewritei($course[0], 'syllabus.txt', "<h2>please read this syllabus</h2>\n")>=0, 'writing syllabus.txt' );
ok( filewritei($course[0], 'other.txt', "please do this syllabus\n")>=0, 'writing other.txt' );

####
like( dies { hwsetdue($course[0], 'hw0.txt', time()+10000); }, qr/due/, 'cannot publish non-existing file hw0.txt' );

ok( hwsetdue($course[0], 'hw1.txt', time()+100000), 'published hw1.txt');
like( dies { hwsetdue($course[0], 'hw2.txt', time()-100); }, qr/useless/,  "unpublished hw2 by setting expiry to be behind us" );

ok( filesetdue($course[0], 'other.txt', time()+100000), 'published other.txt' );
ok( filesetdue($course[0], 'syllabus.txt', time()+100000), 'published syllabus.txt' );
ok( filesetdue($course[0], 'other.txt', 0), 'unpublished other.txt' );
ok( filesetdue($course[0], 'other.txt', 0), 'harmless unpublished again' );

my $npub= rlc( my $ilist= filelisti($course[0]));

ok( $npub == 2, "instructor owns $npub files, which should be 2 (other.txt and syllabus.txt)" );

my $publicstruct=filelists($course[0]);

$npub= rlc($publicstruct);
ok( $npub == 1, "student should see 1 published file (syllabus.txt), actually saw $npub" );

(my $publicstring= Dumper( $publicstruct )) =~ s/\n/ /g;
ok( $publicstring !~ m{other.txt}, "published still contains other.txt, even though it is not posted" );
ok( $publicstring =~ m{syllabus\.txt}, "syllabus.txt is still posted.  good" );

ok( filereads( $course[0], 'syllabus.txt'), "student can read syllabus.txt 2" );
like( dies { filereads( $course[0], 'other.txt') }, qr/sorry, /, "student cannnot read unpublished other.txt" );
like( dies { filereads( $course[0], 'blahother.txt') }, qr/cannot read/, "student cannot read unexisting file" );

ok( filesetdue($course[0], 'other.txt', 0), "unpublish 'other.txt' by setdue ");
ok( filesetdue($course[0], 'hw1.txt', time()+100000), "publish 'hw1.txt' by setdue ");

## now we do student responses to homeworks

SylSpace::Model::Utils::_unsetsudo();

my $s2ac= rlc(answerlists( $course[0], $s2email ));
ok( ($s2ac==0)||($s2ac==1), "$s2email has not yet uploaded anything -- correct" );

like(dies { answerlists( $course[0], $s2email, 'hw1.txt' ) }, qr/cannot read due/, "death on bad direct attempt" );

like(dies { answerwrite($course[0], $s2email, 'hwneanswer.txt', "I have done hwne text\n", 'hwne.txt') },
     qr/not posted/, 'charlie cannot answer nonexisting hw hwne.txt');

ok( answerwrite($course[0], $s2email, 'hw1.txt', 'hw1answer.txt', "I have done hw1 text\n")>=0, "$s2email answered hw1.txt");

my $sanswers=answerlists( $course[0], $s2email );
ok( (rlc($sanswers)==1), "$s2email should have submitted exactly one homework!" );

SylSpace::Model::Utils::_setsudo();

my $ofzipname=answercollect($course[0], 'hw1.txt');
ok( $ofzipname =~ /zip/, "collected properly submitted hw1 answer for $s2email" );

ok( filedelete( $course[0], $ofzipname ), "deleted zip file\n" );

done_testing();

################################################################
sub rlc { return scalar @{$_[0]}; }

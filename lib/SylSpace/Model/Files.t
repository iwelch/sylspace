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
my $s2email='student@gmail.com';

use lib '../..';

use SylSpace::Model::Files qw(answerdelete answercollect cptemplate eqlisti eqwrite eqreadi hwwrite filewritei filedelete eqsetdue hwsetdue filesetdue filelisti filelists filereads answerlists answerwrite);

use SylSpace::Model::Webcourse qw( _webcourseremove _webcoursemake _webcourselist );

use SylSpace::Model::Model qw(userexists usernew userenroll);

################################################################################################################################

my $coursenametestfile= 'testfilecourse';

SylSpace::Model::Utils::_setsudo();  ## special purpose!

_webcourseremove($coursenametestfile);
ok( _webcoursemake($coursenametestfile), "fixing up a test course named '$coursenametestfile' for file testing" );
(userexists($s2email)) or usernew($s2email);  ## not tested
ok( userenroll( $coursenametestfile, $s2email ), "enrolled $s2email into $coursenametestfile" );

note '
################ file storage and retrieval system
';

my $templatename= 'tutorials';
my $onequizname='2medium.equiz';


ok( cptemplate( $coursenametestfile, $templatename ), "copied all $templatename files to course '$coursenametestfile'" );

my $filelist= eqlisti( $coursenametestfile );
foreach my $onefile (@{$filelist}) {
  ok( eqsetdue( $coursenametestfile , $onefile->{sfilename}, time()+24*60*60*365*10) , "setdue on equiz $onefile->{sfilename} to much later" );
}

my $eqcontents= eqreadi( $coursenametestfile, $onequizname );
ok( (length($eqcontents)>0), "read a nice file $onequizname with good stuff in it\n" );
open(my $FOUT, ">", $onequizname); print $FOUT $eqcontents; close($FOUT);


ok( -e $onequizname, "have downloaded local equiz test file '$onequizname' for experimentation in local directory now" );

ok( eqwrite($coursenametestfile, $onequizname, scalar slurp($onequizname))>=0, 'writing $onequizname' );

ok( hwwrite($coursenametestfile, 'hw1.txt', "please do the first homework\n")>=0, 'writing hw1.txt');  ## note that all homeworks are fed from here, not from the file system!
ok( hwwrite($coursenametestfile, 'hw2.txt', "please do the second homework.  it is longer.\n")>=0, 'writing hw2.txt');

ok( filewritei($coursenametestfile, 'syllabus.txt', "<h2>please read this syllabus</h2>\n")>=0, 'writing syllabus.txt' );
ok( filewritei($coursenametestfile, 'other.txt', "please do this syllabus\n")>=0, 'writing other.txt' );

####
like( dies { hwsetdue($coursenametestfile, 'hw0.txt', time()+10000); }, qr/due/, 'cannot publish non-existing file hw0.txt' );

ok( hwsetdue($coursenametestfile, 'hw1.txt', time()+100000), 'published hw1.txt');
like( dies { hwsetdue($coursenametestfile, 'hw2.txt', time()-100); }, qr/useless/,  "unpublished hw2 by setting expiry to be behind us" );

ok( filesetdue($coursenametestfile, 'other.txt', time()+100000), 'published other.txt' );
ok( filesetdue($coursenametestfile, 'syllabus.txt', time()+100000), 'published syllabus.txt' );
ok( filesetdue($coursenametestfile, 'other.txt', 0), 'unpublished other.txt' );
ok( filesetdue($coursenametestfile, 'other.txt', 0), 'harmless unpublished again' );

my $npub= rlc( my $ilist= filelisti($coursenametestfile));

ok( $npub == 2, "instructor owns $npub files, which should be 2 (other.txt and syllabus.txt)" );

my $publicstruct=filelists($coursenametestfile);

$npub= rlc($publicstruct);
ok( $npub == 1, "student should see 1 published file (syllabus.txt), actually saw $npub" );

(my $publicstring= Dumper( $publicstruct )) =~ s/\n/ /g;
ok( $publicstring !~ m{other.txt}, "published still contains other.txt, even though it is not posted" );
ok( $publicstring =~ m{syllabus\.txt}, "syllabus.txt is still posted.  good" );

ok( filereads( $coursenametestfile, 'syllabus.txt'), "student can read syllabus.txt 2" );
like( dies { filereads( $coursenametestfile, 'other.txt') }, qr/sorry, /, "student cannnot read unpublished other.txt" );
like( dies { filereads( $coursenametestfile, 'blahother.txt') }, qr/cannot read/, "student cannot read unexisting file" );

ok( filesetdue($coursenametestfile, 'other.txt', 0), "unpublish 'other.txt' by setdue ");
ok( filesetdue($coursenametestfile, 'hw1.txt', time()+100000), "publish 'hw1.txt' by setdue ");

## now we do student responses to homeworks

SylSpace::Model::Utils::_unsetsudo();

my $s2ac= rlc(answerlists( $coursenametestfile, $s2email ));
ok( ($s2ac==0)||($s2ac==1), "$s2email has not yet uploaded anything -- correct" );

like(dies { answerlists( $coursenametestfile, $s2email, 'hw1.txt' ) }, qr/cannot read due/, "death on bad direct attempt" );

like(dies { answerwrite($coursenametestfile, $s2email, 'hwneanswer.txt', "I have done hwne text\n", 'hwne.txt') },
     qr/not posted/, 'charlie cannot answer nonexisting hw hwne.txt');

ok( answerwrite($coursenametestfile, $s2email, 'hw1.txt', 'hw1first.txt', "I have done hw1 text\n")>=0, "$s2email answered hw1.txt");

my $sanswers=answerlists( $coursenametestfile, $s2email );
ok( (rlc($sanswers)==1), "$s2email should have submitted exactly one homework!" );
ok( ($sanswers->[0]->{sfilename} eq 'hw1first.txt'), "checked that student answer hw1first.txt was uploaded." );

like(dies { answerwrite($coursenametestfile, $s2email, 'hw1.txt', 'hw1second.txt', "changed my mind on hw1\n") }, qr/already/, "cannot upload a second answer to same homework" );

like(dies { answerdelete($coursenametestfile, $s2email, 'hw1.txt', 'hwnotexist') }, qr/nonexisting/, "cannot delete a nonexisting homework answer" );

ok( answerdelete($coursenametestfile, $s2email, 'hw1.txt', 'hw1first.txt')==0, "we managed to wipe the old answer");

ok( answerwrite($coursenametestfile, $s2email, 'hw1.txt', 'hw1second.txt', "changed my mind on hw1\n"), "now we could upload a new answer" );

my $sanswers=answerlists( $coursenametestfile, $s2email );
ok( ($sanswers->[0]->{sfilename} eq 'hw1second.txt'), "we have uploaded hw1second.txt!  it is good!" );

#like(dies { answerwrite($coursenametestfile, $s2email, 'hwneanswer.txt', "I have done hwne text\n", 'hwne.txt') },
#     qr/not posted/, 'charlie cannot answer nonexisting hw hwne.txt');


SylSpace::Model::Utils::_setsudo();

my $ofzipname=answercollect($coursenametestfile, 'hw1.txt');
ok( $ofzipname =~ /zip/, "collected properly submitted hw1 answer for $s2email" );

ok( filedelete( $coursenametestfile, $ofzipname ), "deleted zip file\n" );

_webcourseremove($coursenametestfile);

done_testing();

################################################################
sub rlc { return scalar @{$_[0]}; }

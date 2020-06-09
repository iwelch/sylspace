#!/usr/bin/perl 
use strict;
use common::sense;
use utf8;
use warnings FATAL => qw{ uninitialized };
use autodie;

use SylSpace::Test 
  make_test_site => 1;

use SylSpace::Test::Utils qw(tziserver);

use Perl6::Slurp;
use File::Glob qw(bsd_glob);
use SylSpace::Model::Utils qw(_getvar);

my $var = _getvar();

################################################################

use SylSpace::Model::Model qw(:DEFAULT biosave usernew instructornewenroll userenroll courselistenrolled ciosave msgsave ciobuttonsave sudo);

use SylSpace::Model::Webcourse qw(_webcoursemake _webcourseremove );
use SylSpace::Model::Grades qw(gradetaskadd gradesave);
use SylSpace::Model::Files qw(filesetdue filewritei cptemplate);

use Test2::Bundle::Extended;
use Test2::Plugin::DieOnFail;

my %bioinstructor = ( uniname => 'ucla anderson', regid => 'na', firstname => 'ivo', lastname => 'welch', birthyear => 1971,
		      email => 'ivo.welch@gmail.com', zip => 90095, country => 'US', cellphone => '(310) 555-1212',
		      email2 => 'ivo.welch@anderson.ucla.edu', tzi => tziserver(), optional => '' );

my $iemail= $bioinstructor{email};

my @courselist=qw(corpfin syllabus-test);	# in README echo ... there's no syllabus.syllabus.test
subtest 'Creating the site' => sub {
  foreach (@courselist) {  
    ok _webcoursemake($_), "created $_ site" ; 
    ok instructornewenroll($_, $iemail), "created $iemail as instructor for $_";
  }

  my @enrolledcourses= keys %{courselistenrolled($iemail)};
  ok( scalar @enrolledcourses == scalar @courselist, "check info on enrolled courses" );
};

subtest 'Creating users with bios (instructor and student)' => sub {

  ok( biosave( $iemail, \%bioinstructor), 'written biodata for instructor '.$iemail );

  ok( usernew('student@gmail.com'), 'new student' );

  my %biostudent = ( uniname => 'harvard law', regid => 'na', firstname => 'james', lastname => 'hart', birthyear => 1971,
                     email2 => 'james.hart@gmail.com', zip => 90049, country => 'US', cellphone => '(312) 555-1212',
                     email => 'student@gmail.com', tzi => tziserver(), optional => '' );

  ok( biosave('student@gmail.com', \%biostudent), 'written biodata for (largely useless) student' );

  ok( userenroll($courselist[0], 'student@gmail.com'), 'enrolled student' );
};


subtest 'Writing course information' => sub {
  my %ciocorpfin = ( uniname => 'syllabus-ucla', unicode => 'na', coursesecret => '', cemail => 'ivo.welch@gmail.com',
                    anothersite => 'http://ivo-welch.info',
                    department => 'management', subject => 'corporate finance', meetroom => 'internet', meettime => 'MTWRF 9:00-5:00',
                    domainlimit => '', hellomsg => 'enjoy!' );

  my %ciosyllabus = ( uniname => 'syllabus', unicode => 'na', coursesecret => 'learn', cemail => 'ivo.welch@gmail.com',
                    anothersite => 'http://ivo-welch.info',
                    department => 'teaching', subject => 'meta-syllabus itself', meetroom => 'internet', meettime => 'MTWRF 9:00-5:00',
                    domainlimit => '', hellomsg => 'enjoy!' );

  sudo($courselist[0], $iemail);  ## become the instructor
  sudo($courselist[1], $iemail);  ## become the instructor

  ok( ciosave($courselist[0], \%ciocorpfin), 'instructor writes sample cio sample' );
  ok( ciosave($courselist[1], \%ciosyllabus), 'instructor writes sample cio sample' );
};

## buttons

subtest 'Making button lists' => sub {
  my @buttonlist;
  push(@buttonlist, ['http://ivo-welch.info', 'welch', 'go back to root']);
  push(@buttonlist, ['http://book.ivo-welch.info', 'book', 'read book']);
  push(@buttonlist, ['http://gmail.com', 'gmail', 'send email']);

  ok ciobuttonsave( $courselist[0], \@buttonlist ), 'made some buttons'
};

subtest 'Posting initial message' => sub {
  ok( msgsave($courselist[0], { subject => 'Test Welcome', body => 'Welcome to the testing site.  Note that everything is public and nothing stays permanent here.  I often replace this testsite with a similar new one.', priority => 5 }, 1233), 'posting 1233' );
};

subtest 'Making initial files' => sub {
  ok( filewritei($courselist[1], 'hw1.txt', "please do this first homework\n"), 'writing hw1.txt');
  ok( filewritei($courselist[1], 'syllabus.txt', "<h2>please read this simple txt syllabus</h2>\n"), 'writing syllabus.txt' );
};

subtest 'Copying templates' => sub {
  ok( cptemplate($courselist[1], 'starters'), "copy starters template" );
  ok( cptemplate($courselist[1], 'tutorials'), "copy tutorials template" );
};

####
my $MONTH = 60*60*24*30;
#foreach my $fnm (bsd_glob("../../../templates/equiz/corpfinintro/*.equiz")) {
  #$fnm =~ s{.*/}{};
  #ok( filesetdue($courselist[0], $fnm, time()+$MONTH), "publish $fnm");
#}
subtest 'Publishing files' => sub {
  my $ssshtml="syllabus-sophisticated.html";
  my $sshtml= "public/html/ifaq/$ssshtml"; ok( -e $sshtml, "have $ssshtml" );
  ok( filewritei($courselist[0], $ssshtml, scalar slurp($sshtml)), "writing $ssshtml" );
  ok( filesetdue($courselist[0], $ssshtml, time()+$MONTH), "publish $ssshtml");

  ok( filesetdue($courselist[1], 'hw1.txt', time()+$MONTH), "publish hw1.txt open for 1 month");
  ok( filesetdue($courselist[1], 'syllabus.txt', time()+$MONTH), "publish syllabus.txt open for 1 month");
};

subtest 'Add grades' => sub {
  ok( gradetaskadd($courselist[0], qw(hw1 hw2 midterm)), "hw1, hw2 midterm all allowed now" );

  ok( gradesave($courselist[0], 'student@gmail.com', 'midterm', 'badfail' ), "grade midterm for student");
};

done_testing();

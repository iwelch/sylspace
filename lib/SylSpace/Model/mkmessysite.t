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
## not used, but we want to make sure that these modules are installed.
use common::sense;
use File::Copy;
use Perl6::Slurp;
use Archive::Zip;
use FindBin;
use Mojolicious::Plugin::RenderFile;
use Data::Dumper;

################################################################

use lib '../..';

use SylSpace::Model::Webcourse qw(_webcoursemake _webcourseremove _webcourseshow );

use SylSpace::Model::Model qw(:DEFAULT biosave usernew instructornewenroll bioread userenroll courselistenrolled ciosave cioread ciobuttons msgsave msgmarkasread _msglistnotread msgdelete msgread msgshownotread sitebackup isenrolled ciobuttonsave isinstructor sudo);

use Test2::Bundle::Extended;
use Test2::Plugin::DieOnFail;

($> == 0) or die "we need to tinker with the website, so we need su\n";

my $v= _webcourseremove("*");  ## but not users and templates

my $iemail='instructor@gmail.com'; my $iemail2='ivo.welch@gmail.com';
my $s1email='student1@gmail.com';
my $s2email='student2@gmail.com';
my $s3email='noone@gmail.com';

my @course=qw (mfe.welch mba.welch year.course.instructor.university intro.corpfin);

note '
################ website creation, user registration, and user enrollment
';

my $localhostline = `grep '^127.0.0.1' /etc/hosts`; my @missing;
foreach ((@course, 'auth', '')) {
  ($localhostline =~ /$_\.syllabus\.test/) or push(@missing, $_);
}
# (@missing) and die "\n\nplease add '".join(".syllabus.test , ", @missing).".localhost.test to /etc/hosts to facilitate testing\n\n";

foreach (@course) {  ok( _webcoursemake($_), "created $_ site" ); instructornewenroll($_, $iemail); instructornewenroll($_, $iemail2);  }
ok( !eval { _webcoursemake($course[0]) }, 'cannot create mfe a second time' );

my @enrolledcourses= keys %{courselistenrolled($iemail)};

ok( scalar @enrolledcourses == scalar @course, "check enrollment info on $#course+1 existing courses for alice");
ok(  isenrolled($course[0], $iemail), "$iemail is nicely enrolled in $course[0]");
ok( !isenrolled($course[0], 'unknown@gmail.com'), "unknown is not enrolled in $course[0]");



note '
################ auth: user bios
';

my %bioalice = ( uniname => 'ucla', regid => 'na', firstname => 'alice', lastname => 'architect', birthyear => 1963,
	       email2 => $iemail, zip => 90095, country => 'US', cellphone => '(312) 212-3100',
	       email => $iemail, tzi => tziserver(), optional => '' );
ok( biosave($iemail, \%bioalice), 'written biodata for alice' );

ok( usernew($s1email), 'new bob' );
my %biobob = ( uniname => 'na', regid => 'na', firstname => 'bob', lastname => 'builder', birthyear => 1975,
		email2 => $s1email, zip => 90049, country => 'US', cellphone => '(312) 212-3200',
		email => $s1email, tzi => tziserver(), optional => '' );
ok( biosave($s1email, \%biobob), 'written biodata for bob' );


ok( usernew($s2email), "new user $s2email" );
my %biocharlie = ( uniname => 'ucla', regid => 'na', firstname => 'charlie', lastname => 'carpenter', birthyear => 2005,
		  email => $s2email, zip => 90049, country => 'US', cellphone => '(312) 212-3300',
		  email2 => $s2email, tzi => tziserver(), optional => '' );

ok( usernew($s3email), 'new noone user' );


#my $s= Dumper testmodhash(\%biocharlie, 'uniname', '');

sub testmodhash { my ( $h, $k, $v )=@_; my %nh= %$h; $nh{$k}=$v; return \%nh; }

like(dies { biosave($s2email, testmodhash(\%biocharlie, 'uniname', '')) }, qr/required/, 'fail on bad field content for uniname' );
like(dies { biosave($s2email, testmodhash(\%biocharlie, 'uniname', '&^SD')) }, qr/regex/, 'fail on regex for uniname' );
like(dies { biosave($s2email, testmodhash(\%biocharlie, 'uniname', 'ucla' x 50)) }, qr/long/, 'fail on length' );

like(dies { biosave($s2email, testmodhash(\%biocharlie, 'notvalid', 'any')) }, qr/allowed/, 'fail on field that should not be here' );
#delete $biosampledata{'notvalid'};

ok( biosave($s2email, \%biocharlie), 'written biodata for charlie' );

ok(dies { usernew('../..@gmail.com') }, 'bad email new user' );

ok( my $ibio=bioread($iemail), 'reread biodata for alice' );
ok( biosave($iemail, $ibio), 'rewrote it' );

note '
################ enroll users in course
';

ok( isinstructor($course[0],$iemail), "$iemail is an instructor for mfe" );
ok( userenroll($course[0], $s1email), "enrolled $s1email" );
ok( userenroll($course[0], $s2email), "enrolled $s2email" );
like(dies { userenroll($course[0], 'nooneyet@gmail.com') }, qr/no such user/, 'cannot enroll non-existing user nooone' );


note '
################ course validity testing and modification
';

my %ciosample = ( uniname => 'ucla', unicode => 'mfe237', coursesecret => 'judy', cemail => 'corpfin.mfe237@gmail.com', anothersite => 'http://ivo-welch.info',
		  department => 'fin', subject => 'advanced corpfin', meetroom => 'B301', meettime => 'TR 2:00-3:30pm',
		  domainlimit => 'ucla.edu', hellomsg => 'hi friends' );

like(dies { ciosave($course[0], \%ciosample) }, qr/insufficient privileges/, 'student cannot write class info' );

sudo($course[0], $iemail);  ## become the instructor

my $w= testmodhash(\%ciosample, 'coursesecret', '&^SD');

like(dies { ciosave($course[0], testmodhash(\%ciosample, 'coursesecret', '&^SD')) }, qr/regex/, 'fail on regex for coursesecret' );

ok( ciosave($course[0], \%ciosample), 'instructor writes sample cio sample' );
ok( my $icio=cioread($course[0]), 'reread cio' );
ok( SylSpace::Model::Model::_checkvalidagainstschema( $icio, 'c' ), 'is the reread ciodata still valid?' );

## buttons

my @buttonlist;
push(@buttonlist, ['http://ivo-welch.info', 'iaw-web', 'go back to root']);
push(@buttonlist, ['http://book.ivo-welch.info', 'book', 'read book']);
push(@buttonlist, ['http://gmail.com', 'gmail', 'send email']);

ciobuttonsave( $course[0], \@buttonlist );

ok( ciobuttons($course[0])->[1]->[1] eq 'book', 'ok, book button stored right!' );
ok( ciobuttons($course[0])->[2]->[1] eq 'gmail', 'ok, gmail button stored right!' );


my %ciocorpfin = ( uniname => 'generic', unicode => 'na', coursesecret => '', cemail => 'ivo.welch@gmail.com',
		  anothersite => 'http://ivo-welch.info',
		  department => 'management', subject => 'corporate finance', meetroom => 'internet', meettime => 'MTWRF 0:00-24:00',
		  domainlimit => '', hellomsg => 'the generic quizzes' );

ok( ciosave('intro.corpfin', \%ciocorpfin) );
ciobuttonsave( 'intro.corpfin', \@buttonlist );

note '
################ messaging system
';

ok( msgsave('intro.corpfin', { subject => 'warning', body => 'this is a generic testsite, to be used by registered students to test their knowledge of introductory corporate finance.  it is regularly removed and rebuilt.  do not expect permanence in your stored content or answers', priority => 5 }, 12331), 'posting 12331' );

ok( msgsave($course[0], { subject => 'first msg', body => 'the first message contains nothing', priority => 5 }, 1233), 'posting 1233' );
ok( msgsave($course[0], { subject => 'second msg', body => 'die zweite auch nichts', priority => 3 }, 1234), 'posting 1234' );
ok( msgsave($course[0], { subject => 'third msg', body => 'tres nada nada nada', priority => 3 }, 1235), 'posting 1235');
ok( msgsave($course[0], { subject => 'fourth msg', body => 'ze meiyou meiyou meiyou', priority => 3 }, 1236), 'posting 1236');
ok( msgsave($course[0], { subject => 'to be killed', body => 'please die', priority => 3 }, 999), 'posting 999');

ok( msgmarkasread($course[0],$iemail, 1235), 'marking 1235 as read by alice');

my $msglistnotread= _msglistnotread($course[0],$iemail);
ok( scalar @{$msglistnotread} == 4, 'correct n=4 messages unread');
ok( msgdelete($course[0], 999), 'destroying 999');
$msglistnotread= _msglistnotread($course[0],$iemail);
ok( scalar @{$msglistnotread} == 3, 'correct n=3 messages unread');
ok( join(" ",@$msglistnotread) eq join(" ", (1233, 1234, 1236)), 'returned correct list of unread' );
like( (msgread( $course[0], 1235 ))->[0]->{body}, qr/nada nada nada/, 'read 1235 again' );

like( (msgshownotread( $course[0], $iemail ))->[0]->{body}, qr/the first message contains nothing/, 'reading message ok' );


note '
################ backup
';

ok( (sitebackup( $course[0] ) =~ /mfe.*zip/), "sitebackup worked" );
#ok( (sitebackup( $course[0] ) =~ /mfe.*zip/), "second long backup worked" );  should be the same and not contain a zip file

done_testing();

print "\nNow check file writing interface Files.t\n";

print "\n################ website structure now\n"._webcourseshow($course[0])."\n";

# my $g= gradesashash( $course[0], $iemail ); print "glist for instructor: ".(Dumper $g);

sub tziserver {
  my $off_h=1;
  my @local=(localtime(time+$off_h*60*60));
  my @gmt=(gmtime(time+$off_h*60*60));
  return (-1)*($gmt[2]-$local[2] + ($gmt[5] <=> $local[5]
			      ||
			      $gmt[7] <=> $local[7])*24);
}

note '
################ please run Files.t now
';

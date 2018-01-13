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
my $aemail='administrator@sina.com';
my $jemail='junk@junk.com';
my $s1email='student1@gmail.com';
my $s2email='student2@gmail.com';
my $outsider='outsider@gmail.com';


my $course=qw (test.model.course);
my $coursenocio=qw (test.no.cio);
my $nocourse=qw (course.not.exist);

use lib '../..';

use SylSpace::Model::Model qw(
	       sudo tzi tokenmagic

	       isinstructor ismorphed
	       instructorlist instructoradd instructordel

		instructornewenroll

	       usernew userenroll userdisroll isenrolled morphinstructor2student unmorphstudent2instructor userexists getcoursesecret throttle
	       _listallusers

	       sitebackup isvalidsitebackupfile courselistenrolled courselistnotenrolled

	       readschema bioread biosave bioiscomplete cioread ciosave cioiscomplete

	       ciobuttonsave ciobuttons hassyllabus
	       studentlist studentdetailedlist

	       msgsave msgdelete msgread msgmarkasread msglistread msgshownotread

	       tweet showtweets showlasttweet seclog showseclog superseclog

	       equizrender equizgrade equizanswerrender   	       equizrate

	       _msglistnotread

	       paypallog
	    );
use SylSpace::Model::Webcourse qw( _webcoursemake _webcourseshow _webcourseremove );
################################################################################################################################

SylSpace::Model::Utils::_setsudo();  ## special purpose!
my $var=SylSpace::Model::Utils::_getvar();
_webcourseremove($coursenocio);
_webcourseremove($course);

note '
################ Create two test courses : Tests 1-11
';
## test: _webcoursemake _webcourseshow instructornewenroll instructoradd instructordel
ok( _webcoursemake($course), "temporary $course created");
ok( _webcourseshow($course));
ok( instructornewenroll($course,$iemail) && scalar @{instructorlist($course)}==1, "$iemail is now the instructor of $course");
ok( instructornewenroll($course,$iemail) && scalar @{instructorlist($course)}==1, "I know they are the same");
ok( instructoradd($course,$iemail), "can assign $iemail again");
ok( scalar @{instructorlist($course)}==1 && isinstructor($course,$iemail), "and still a unique instructor");

ok( _webcoursemake($coursenocio), "temporary $coursenocio created");
ok( _webcourseshow($coursenocio));
ok( instructornewenroll($coursenocio,$aemail) && scalar @{instructorlist($coursenocio)}==1, "$aemail is now the instructor of $coursenocio");
ok( instructornewenroll($coursenocio,$iemail) && scalar @{instructorlist($coursenocio)}==2, "Instructors of $coursenocio: @{instructorlist($coursenocio)}");
ok( instructordel($coursenocio,$aemail,$iemail) && scalar @{instructorlist($coursenocio)}==1 && isinstructor($coursenocio,$aemail), "Only $aemail is left");


note '
################ New or existing users : Tests 12-18
';
## test: _listallusers usernew userexists
ok( my $usersArrPtr=_listallusers(), "list all users" );
ok( print @$usersArrPtr, " printed\n");
ok( usernew($iemail)==-1, "$iemail already exist");	## -1 actually, number 3 below ummmmm
ok( usernew(@$usersArrPtr[0])==-1,"acceptable error that returns -1");
ok( usernew($jemail), "$jemail added as a user");
$usersArrPtr=_listallusers();
ok( print @$usersArrPtr, " printed\n");
ok( userexists($jemail), "experiment on $jemail");

note "
################ bioinfo of $jemail : Tests 19-25
";

ok( !bioiscomplete($jemail), "$jemail 's bio is incomplete");
ok( dies { userenroll($course,$jemail) } and (scalar (keys %{courselistenrolled($jemail)})==0), "can't enroll student with incomplete bio");

ok( !defined(bioread($jemail)), "no bio for junk yet, so undef");
my %biojunk = ( uniname => 'ucla', regid => 'junk_regid', firstname => 'junk', lastname => 'junk', birthyear => 1999, email => $jemail, zip => 90024, country => 'US', cellphone => '(123) 456-7890', email2 => $jemail, tzi => 20, optional => '' );
ok( biosave($jemail,\%biojunk), "Can email2 be the same as email1? invaild tzi?"); ############
$biojunk{email2}="junk_\@junk.com";
ok( biosave($jemail,\%biojunk), "Update bio");
ok( tzi($jemail)==$biojunk{tzi}, "timezone is $biojunk{tzi}");
ok( bioread($jemail) && bioiscomplete($jemail), "can read $jemail\'s bio");

note '
################ also create bio for instructor@gmail.com : Tests 26-29
';

# tested: empty uniname/regid are not accepted; invaild birthyear or tzi can't be identified; email2 repetes another user's email but not stopped
my %bioinstructor = ( uniname => 'ucla anderson', regid => 'insturctor_regid', firstname => 'instructor', lastname => 'instructor', birthyear => 2018, email => $jemail, zip => 90024, country => 'US', cellphone => '(123) 456-7890', email2 => $jemail, tzi => -7, optional => '' );
#ok( !defined(bioread($iemail) && !bioiscomplete($iemail)), "same bio tests for instructor bio");
ok( dies {biosave($iemail,\%bioinstructor)}, "primary email should match");
$bioinstructor{email}=$iemail;
ok( biosave($iemail,\%bioinstructor), "actually this shouldn't pass because email2 is some other user");
ok( bioread($iemail) && bioiscomplete($iemail) && tzi($iemail)==$bioinstructor{tzi});
## bioiscomplete under construction....

note '
################ Creating course info for one test course : Test 30-32
';

ok( !cioiscomplete($course) && !cioiscomplete($coursenocio) && !defined(cioread($course)) && !defined(cioread($coursenocio)), "cio undefined yet for both courses");

my %ciorequired = ( uniname => 'ucla', unicode => '', coursesecret => '', cemail => $aemail, anothersite => '', department => '', subject => '', meetroom => '', meettime => '', domainlimit => '', hellomsg => 'test message for hellomsg' );
ok( ciosave($course,\%ciorequired), "Shouldn't pass!!!!!cemail does not match");
print "@{instructorlist($course)}\n";   ## is not affected by cio
ok( cioread($course) && !defined(cioread($coursenocio)) && cioiscomplete($course), "read cio of $course");

ok( !defined(hassyllabus($course)) && !defined(hassyllabus($coursenocio)), "no syllabus yet");
## Uploadsave is for updating syllabus, remember to test hassyllabus and ciobuttonsave later

note '
################ Test enrollment with student bio lacked
';

ok( my $courseHaPtr=courselistenrolled($iemail));
print "$iemail is enrolled in ";
foreach $_ (keys %$courseHaPtr) {
	print "$_".' ';
}
print '\n';
ok( userenroll($course,$iemail) && scalar @{studentlist($course)}==1 && @{studentlist($course)}[0] eq $iemail && isinstructor($course,$iemail), "won\'t count $iemail repeatedly");
#ok( userdisroll($course,$iemail) && isinstructor($course,$iemail) && isenrolled($course,$iemail),"can't userdisroll instructor, so $iemail survives as instructor and keeps enrolled");

#print "@{instructorlist($course)}\n";

#ok( dies { instructordel($course,$iemail,$iemail) }," shouldn't replace someone with himself");
#ok( isinstructor($course,$iemail));
#ok( dies { instructordel($course,$jemail,"invalid") });
#ok( instructordel($course,$iemail,$jemail) && (@{instructorlist($course)} eq $iemail));	## the parameter is in wrong order, right?


#like( dies{ instructoradd($course,$jemail) }, " good death");	# Why get undef?
#ok( userdisroll($course,$s1email), "not enrolled but can call disroll?");	# Why fail?





note '
################ Test enrollment with course info lacked
';

note '
################ enroll or disroll student or instructor : 
';
ok( $courseHaPtr=courselistenrolled($iemail));
ok( print keys %$courseHaPtr, " <- enrolled into \n");

ok( userdisroll($course,$iemail) && isinstructor($course,$iemail) && isenrolled($course,$iemail),"can't userdisroll instructor, so $iemail survives as instructor and keeps enrolled");

print "@{instructorlist($course)}\n";

ok( dies { instructordel($course,$iemail,$iemail) }," shouldn't replace someone with himself");
ok( isinstructor($course,$iemail));
ok( dies { instructordel($course,$jemail,"invalid") });
#ok( instructordel($course,$iemail,$jemail) && (@{instructorlist($course)} eq $iemail));	## the parameter is in wrong order, right?


#like( dies{ instructoradd($course,$jemail) }, " good death");	# Why get undef?
#ok( userdisroll($course,$s1email), "not enrolled but can call disroll?");	# Why fail?

# how do I know all students of a course


note '
################ Courses and students linkage test
';

note '
################ Instructor and Student status test
';

note '
################ Remove test courses and users
';
ok( _webcourseremove($coursenocio), "$coursenocio removed");
ok( _webcourseremove($course), "$course removed");

system 'rm /var/sylspace/users/junk@junk.com -rf';  # delete virtual user
#system 'rm /var/sylspace/courses/test.no.cio -rf';
#system 'rm /var/sylspace/courses/test.model.course -rf';


done_testing();

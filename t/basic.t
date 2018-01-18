use Mojo::Base -strict;

use Test::More;
use Test::Mojo;
use strict;
use common::sense;
use utf8;
use warnings;
use warnings FATAL => qw{ uninitialized };
use autodie;


note '
################ There are 6 paths to files in this test, please change them to your own files!
################ About 530 tests in total, takes 2-3 mins
';

# change these one parameters to 0 to disable some tests and save time(the whole test < 2 min)
my $onlyonce = 0; # test some outside links only once, takes about 1-2 min
my $onetime = 1;

my $mailto = '<a href="mailto:ivo.welch@gmail.com"';
my $email = 'ivo.welch@gmail.com';
my $semail = 'student@gmail.com';
my $domain = 'http://auth.syllabus.test';
my $cdomain = 'http://corpfin.syllabus.test';

# will be using the follwing test files
my $equiz = '1simple.equiz';
my $hw = 'hwsample.junk';
my $hwcontent = "---content of test file $hw---";
my $hwanswer = 'hwsample.junk-student-answer.sometype';
my $epoch = Mojo::Date->new("2019-01-01T23:59:00-08:00")->epoch;
my $syllabus = 'syllabus-sophisticated.html';

#system 'perl initsylspace.pl -f;cd Model/;perl mkstartersite.t;cd ..;';

my $t = Test::Mojo->new('SylSpace');  # test object for instructor
my $ts = Test::Mojo->new('SylSpace');  # test object for student
$t->ua->max_redirects(20);	# Allow 20 redirects
$ts->ua->max_redirects(20);	# Allow 20 redirects


if (!$onlyonce) {
note '
################ Testing /aboutus page and relative links
';
$t->get_ok('/')->get_ok($t->tx->res->dom->at('main > p a')->{href})->status_is(200)
  ->element_count_is('h2',5,' ')->element_count_is('a',6,'6 links')
  ->content_like(qr/<a href="http:\/\/mojolicious.org\/">Mojolicious<\/a>/,' ')->content_like(qr/<a href="http:\/\/getbootstrap.com">Bootstrap<\/a>/,' ')->content_like(qr/<a href="http:\/\/fontawesome.io\/">fontawesome icons<\/a>/,' ')->content_like(qr/<a href="ivo.welch\@gmail.com">ivo.welch\@gmail.com<\/a>/,' ')->content_like(qr/<a href="\/faq">FAQ<\/a>/,' ')->content_like(qr/<a href="https:\/\/choosealicense.com\/licenses\/agpl-3.0\/">GNU AGPLv3<\/a>/,' ');

$t->get_ok('http://mojolicious.org/')->status_is(200)->content_like(qr/Documentation/,' ')->get_ok('http://getbootstrap.com/')->status_is(200)->content_like(qr/Bootstrap/,' ')->get_ok('http://fontawesome.io/')->status_is(200)->get_ok('ivo.welch@gmail.com')->status_is(200)->get_ok('https://choosealicense.com/licenses/agpl-3.0/')->status_is(200)->content_like(qr/GNU Affero General Public License/,'5 outside links OK');


note '
################ Testing /faq page and relative links
';
$t->get_ok('/faq')->status_is(200)->element_count_is('img',3,'3 images')->element_count_is('h2',4,'4 subtitles')->element_count_is('a',6,' ')
  ->content_like(qr/<a href="http:\/\/syllabus.space">syllabus.space<\/a>/,"\n!!!The test for this link fails, but it actually works!!!\n")->content_like(qr/<a href="syllabus.test">syllabus.test<\/a>/,' ')->content_like(qr/<a href="http:\/\/book.ivo-welch.info\/">Corporate Finance<\/a>/,' ')
  ->get_ok('syllabus.test')->status_is(200)->get_ok('http://book.ivo-welch.info/')->status_is(200)->content_like(qr/<a class="btn btn-default" href="\/read\/">read<\/a>/,'link to textbook OK');


note '
################ Testing /auth/authenticator page and relative links
';
$t->get_ok('/auth/authenticator')->status_is(200)->text_is('.btn-xs',' X do not show again',' ')
  ->text_is('.btn-block','','next in real is :->text_is(\'h2\',\'Google\')')
  #->text_is('.input-group .btn-default','Send Authorization Email')  # only in real
  ->text_is('main > p a','about us',' ')->content_like(qr/<a href="\/auth\/magic">magic<\/a> is only useful to the cli site admin<\/p>/)
  ->content_like(qr/<a href="\/aboutus">about us<\/a>/,' ')->content_like(qr/<a href="\?msgid=0" class="btn btn-default btn-xs"/,' ')->content_like(qr/<a href="\/aboutus">About Us<\/a>/,' ')->content_like(qr/<a href="\/html\/eqsample02a.html">this rendering<\/a>/,' ')->content_like(qr/<a href="http:\/\/auth.syllabus.test\/faq">screenshots<\/a>/,' ')->content_like(qr/$mailto>email to request<\/a>/,' ')->content_like(qr/$mailto>me<\/a>/,' ');


note '
################ Testing sample non-functional equiz /html/eqsample02a.html and relative buttons
';
$t->get_ok($domain.($t->tx->res->dom->at('b+ a')->{href}))->status_is(200)->text_is('h1',' take an equiz ','right rendering page')->element_count_is('.qname',10,' ')->element_count_is('.qstn',10,'10 problems')->element_count_is('.foo',10,' ')->element_count_is('p.eqinputnum',10,'10 spaces')->element_count_is('.quizsubmitbutton .quizsubmitbutton',1,'1 submit button exists');

$t->get_ok('/auth/authenticator')->status_is(200)->content_like(qr/<a href="\/auth\/testsetuser" class="btn btn btn-block btn-warning btn-md" ><h3><i class="fa fa-users"><\/i> Choose Existing Listed User<\/h3><\/a>/,'Choose user button exists');


note '
################ Choosing existing user (/auth/testsetuser page)
';

$t->get_ok("$domain/auth/testsetuser")->status_is(200)
  ->text_is('h1', ' short-circuit identity '," ")
  ->content_like(qr/Make<\/a> yourself <a href="\/login\?email=$email">$email<\/a>/,"Become instructor button exists")
  ->content_like(qr/Make<\/a> yourself <a href="\/login\?email=student\@gmail.com">student\@gmail.com<\/a>/,"Become student button exists")
  ->content_like(qr/<a href="\/logout">Log out<\/a>/,' ')->content_like(qr/<a href="\/auth\/goclass" class="btn btn-default" >Choose Class<\/a>/,' ')->content_like(qr/<a href="\/auth\/authenticator" class="btn btn-default" >Real Authenticator<\/a>/,' ')->text_is('tt','no session email',' ')->get_ok('http://auth.syllabus.test/logout')->status_is(200)->text_is('h1',' register or authenticate ','right page after logout')->get_ok('/auth/goclass')->status_is(200)->text_is('h1',' register or authenticate ',' ');
}


$ts->get_ok("$domain/login?email=$semail");
$t->get_ok("$domain/login?email=$email");


note '
################ Clear residue files from last test
';

$ts->get_ok("$domain/login?email=$semail")->get_ok("$cdomain/student/hwcenter")->status_is(200);
my $s = $ts->tx->res->dom->all_text;
($s =~ m/$hw-student-answer.sometype/) and ($ts->get_ok("$cdomain/student/answerdelete?f=$hw-student-answer.sometype&task=$hw")->status_is(200)); # delete student answer
$ts->get_ok("$domain/logout");

$t->get_ok("$domain/login?email=$email")->get_ok("$cdomain/instructor/hwcenter")->status_is(200);

$s = $t->tx->res->dom->all_text;
($s =~ m/($hw-answers.\d+.zip)/) and ($t->get_ok("$cdomain/instructor/filedelete?f=$1")->status_is(200)); # delete $hw
($s =~ m/\s($hw)\s/) and ($t->get_ok("$cdomain/instructor/filedelete?f=$hw")->status_is(200)); # delete $hw

$t->get_ok("$cdomain/instructor/equizcenter")->status_is(200);  $s = $t->tx->res->dom->all_text;  
($s =~ m/1simple.equiz/) and ($t->get_ok("$cdomain/instructor/filedelete?f=1simple.equiz")->status_is(200));
# This test file will later test on 1simple.equiz heavily, so delete it here to enable tesing repetitively
($s =~ m/2medium.equiz/) and ($t->get_ok("$cdomain/instructor/filedelete?f=2medium.equiz")->status_is(200));   # delete 2medium.equiz
$t->get_ok("$domain/logout");


$t->get_ok('/')->status_is(200)
  ->element_count_is('p',9,' ')->element_count_is('dt',4,' ')
  ->text_is('main > p a'=>'about us',' ');


note '
##########################################################################
########## Logging in as sudent and testing /auth/goclass page ###########
##########################################################################

';
# whatever -> enroll
SylSpace::Model::Model::isenrolled('corpfin',$semail) or SylSpace::Model::Model::userenroll('corpfin',$semail) or die "no way I can't enroll you";
SylSpace::Model::Model::isenrolled('corpfin',$semail) or die "What?? Model.pm can\'t still be wrong!";
$ts->get_ok("$domain/login?email=$semail")->status_is(200)
  ->text_is('h1',' superhome ','right page')->text_is('h3:nth-child(2)',' Enrolled Courses ',' ')->text_is('#body .text-center~ h3',' Other Available Courses ',' ')->text_like('.input-group-addon',qr/Course Name:/,' ')->text_is('.input-group .btn-default','Select a course by its full name',' ')
  ->content_like(qr/<a href="http:\/\/corpfin.syllabus.test\/enter\?e=\w+" class="btn btn btn-block btn-default" ><h3><i class="fa fa-circle"><\/i> corpfin<\/h3><\/a><p><a href="\/auth\/userdisroll\?c=corpfin"><i class="fa fa-trash"><\/i> unenroll corpfin.syllabus.test<\/a>/,"By default $semail is enrolled in corpfin");


#if ($ts->tx->res->dom->at('main') !~ m/unenroll corpfin.syllabus.test/) { $ts->get_ok("$domain/auth/userensrollsavenopw?course=corpfin",' '); }

note '
################ Enroll in and disroll from course corpfin
';
# enrolled -> disroll
$ts->get_ok("$domain/auth/userdisroll?c=corpfin")->status_is(200)->text_is('.text-center > p','No courses enrolled yet.','disroll corpfin OK')->content_like(qr/<div class="col-xs-12 col-md-6"><a href="\/auth\/userenrollsavenopw\?course=corpfin" class="btn btn btn-block btn-default" ><h3><i class="fa fa-circle-o"><\/i> corpfin<\/h3><\/a><p>singleton<\/p><\/div>/,' ');
# disrolled -> enroll
$ts->get_ok($domain.($ts->tx->res->dom->at('a.btn.btn-block.btn-default')->{href}))->status_is(200)->content_unlike(qr/<div class="col-xs-12 col-md-6"><a href="\/auth\/userenrollsavenopw\?course=corpfin" class="btn btn btn-block btn-default" ><h3><i class="fa fa-circle-o"><\/i> corpfin<\/h3><\/a><p>singleton<\/p><\/div>/,' ')->content_like(qr/unenroll corpfin.syllabus.test/,'click to enroll OK');


if ($onetime) {
note '
################ Search for course corpfin to enroll
';
# -> enroll
$ts->get_ok("$domain/auth/userdisroll?c=corpfin",' ')
   ->content_like(qr/<form name="selectcourse" method="get" action="\/auth\/userenrollform" class="form">/,' ')
   ->content_like(qr/<input class="form-control" placeholder="coursename, e.g., welch-mfe101-2017.ucla" name="c" type="text" required \/>/,' ')->content_like(qr/<button class="btn btn-default" type="submit" value="submit">Select a course by its full name<\/button>/,'enroll form exists')
  ->get_ok("$domain/auth/userenrollform?c=corpfin")->status_is(200)
  ->text_is('#body h1',' Enrolling in Course \'corpfin\' ','right page')
  ->content_like(qr/<form  class="form-horizontal" method="POST"  action="\/auth\/userenrollsave">/,' ')
  ->content_like(qr/<input type="hidden" name="course" value="corpfin" \/>/,' ')->content_like(qr/<input class="form-control foo" id="secret" name="secret"placeholder="not required - instructor requests none" readonly \/>/,' ')->content_like(qr/<button class="btn btn-lg btn-default" type="submit" value="submit">Enroll Now<\/button>/,'enter secret form exists')
  ->get_ok('/auth/userenrollform' => form => {c => 'corpfin', name => 'selectcourse'})
  ->post_ok("$domain/auth/userenrollsave" => {Accept => '*/*'} => form => {course=>'corpfin',secret=>''})->status_is(200)
  ->content_like(qr/<a href="http:\/\/corpfin.syllabus.test\/enter\?e=\w+" class="btn btn btn-block btn-default" ><h3><i class="fa fa-circle"><\/i> corpfin<\/h3><\/a><p><a href="\/auth\/userdisroll\?c=corpfin"><i class="fa fa-trash"><\/i> unenroll corpfin.syllabus.test<\/a>/,'search to enroll OK')->text_is('.alert-success','you are now enrolled in course \'corpfin\'',' ');
}


note "
################ Entering course corpfin as $semail (corpfin.syllabus.test/student page)
";
my $coursebuttons_s = '<div class="col-xs-12 col-md-3"><a href="/student/quickinfo" class="btn btn btn-block btn-default" ><h2><i class="fa fa-info-circle"></i> Quick</h2></a><p>Location, Instructor</p></div>
     <div class="col-xs-12 col-md-3"><a href="/student/equizcenter" class="btn btn btn-block btn-default" ><h2><i class="fa fa-pencil"></i> Equizzes</h2></a><p>Test Yourself</p></div>
     <div class="col-xs-12 col-md-3"><a href="/student/hwcenter" class="btn btn btn-block btn-default" ><h2><i class="fa fa-folder-open"></i> HWork</h2></a><p>Assignments</p></div>
     <div class="col-xs-12 col-md-3"><a href="/student/filecenter" class="btn btn btn-block btn-default" ><h2><i class="fa fa-files-o"></i> Files</h2></a><p>Old Exams, etc</p></div>

     <div class="col-xs-12 col-md-3"><a href="/student/gradecenter" class="btn btn btn-block btn-default" ><h2><i class="fa fa-star"></i> Grades</h2></a><p>Saved Scores</p></div>
     <div class="col-xs-12 col-md-3"><a href="/student/msgcenter" class="btn btn btn-block btn-default" ><h2><i class="fa fa-paper-plane"></i> Messages</h2></a><p>From Instructor</p></div>

     <div class="col-xs-12 col-md-3"><a href="/showseclog" class="btn btn btn-block btn-default" ><h2><i class="fa fa-lock"></i> Sec Log</h2></a><p>Security Records</p></div>
     <div class="col-xs-12 col-md-3"><a href="/showtweets" class="btn btn btn-block btn-default" ><h2><i class="fa fa-rss"></i> Class</h2></a><p>Activity Monitor</p></div>

     <div class="col-xs-12 col-md-3"><a href="/student/faq" class="btn btn btn-block btn-default" ><h2><i class="fa fa-question-circle"></i> Help</h2></a><p>FAQ and More</p></div>

     <div class="col-xs-12 col-md-3"><a href="/auth/bioform" class="btn btn btn-block btn-default" ><h2><i class="fa fa-cog"></i> Bio <i class="fa fa-link"></i></h2></a><p>Set My Profile</p></div>';

$ts->get_ok("$domain/login?email=$semail")->status_is(200)->get_ok($ts->tx->res->dom->at('.text-center:nth-child(3) .btn-default')->{href})->status_is(200)->text_is('.alert-success',"$semail logs into corpfin",' ')->text_is('h1',' student ','right course page')->content_like(qr/$coursebuttons_s/,'10 course buttons')->element_count_is('.text-center+ .text-center .btn-default h2',3,'3 buttons below')->element_count_is('.col-md-3 p',13,' ');


# if default msg #1233 is not deleted, it should be like this:
$ts->get_ok("$cdomain/student"); 
if ($ts->tx->res->dom->at('#body') =~ m/1233/) {
  $ts->element_exists('#1233','msg 1233 exists')->element_count_is('#1233 dt',4,' ')->text_like('#1233 .msgid-msg',qr/Welcome to the testing site/,'right msg content')->content_like(qr/ <a href="\/msgmarkasread\?msgid=1233" class="btn btn-default btn-xs" style="font-size:x-small;color:black" > X do not show again<\/a>/,'read msg');



# Student message center check
$ts->get_ok("$cdomain/student/msgcenter")->text_is('h2',' All Previously Posted Messages ',' ');
if ($ts->tx->res->dom->find('.dl-horizontal') == 1) {
   $ts->text_like('.msgid-msgid',qr/\s*\d+\s*/,' ')->text_isnt('.msgid-msgid','1233',' ')
   ->text_like('.msgid-date',qr/\d+ [a-z]+ ago/,' ')->text_like('.msgid-subject',qr/\s*testSubject\s*/,' ')->text_like('.msgid-msg',qr/\s*testBody\s*/,' ');}

$ts->get_ok("$cdomain/msgmarkasread?msgid=1233")->get_ok("$cdomain/student")->element_exists_not('#1233','hide msg 1233 OK');

}

if ($onetime) {
note '
################ For now no file has been posted by the instructor
';
my $topback = '<a class="navbar-brand" href="/"><b>http://corpfin.syllabus.test/student/quickinfo -- syllabus.test: student@gmail.com </b></a>';

$ts->get_ok("$cdomain/student/quickinfo")->element_count_is('th',8,' ')->element_count_is('#body td',8,' ')
  ->content_like(qr/Instructor\(s\) <\/th> <td> $email/,' ')->content_like(qr/<tr\> <th> Course Code <\/th> <td> na <\/td> <\/tr\>/,' ')->content_like(qr/<tr> <th> Course Email <\/th> <td> <a href="$email">$email<\/a> <\/td> <\/tr\>\s+<tr> <th> Syllabus <\/th> <td>  <a href="\/student\/fileview\?f=syllabus-sophisticated.html">syllabus<\/a>/,'right course facts')
  ->content_like(qr/$topback/,' ');

$ts->get_ok($cdomain.($ts->tx->res->dom->at('tr:nth-child(8) a')->{href}))->status_is(200)->content_like(qr/<tr\> <th>Course Identifier<\/td> <td> UCLA Anderson Finance 430 <\/td> <\/tr\>/,' ')->content_like(qr/<dt>Textbook<\/dt> <dd>The book for this course is <a href="http:\/\/book.ivo-welch.info\/ed\d\/">Ivo Welch, <i>Corporate Finance: An Introduction<\/i>, \drd ed<\/a>/,'corpfin syllabus OK');
$t->get_ok("$cdomain/student/equizcenter");
}


note "
################ Log into corpfin as $email (corpfin.syllabus.test/instructor page)
";

my $coursebuttons_i = '<div class="col-xs-12 col-md-3"><a href="/instructor/msgcenter" class="btn btn btn-block btn-default" ><h2><i class="fa fa-paper-plane"></i> Messages</h2></a><p>Msgs to Students</p></div>
     <div class="col-xs-12 col-md-3"><a href="/instructor/equizcenter" class="btn btn btn-block btn-default" ><h2><i class="fa fa-pencil"></i> Equizzes</h2></a><p>Algorithmic Testing</p></div>
     <div class="col-xs-12 col-md-3"><a href="/instructor/hwcenter" class="btn btn btn-block btn-default" ><h2><i class="fa fa-folder-open"></i> HWorks</h2></a><p>Assignments</p></div>
     <div class="col-xs-12 col-md-3"><a href="/instructor/filecenter" class="btn btn btn-block btn-default" ><h2><i class="fa fa-files-o"></i> Files</h2></a><p>Old Exams, etc</p></div>

     <div class="col-xs-12 col-md-3"><a href="/instructor/studentdetailedlist" class="btn btn btn-block btn-default" ><h2><i class="fa fa-users"></i> Students</h2></a><p>Enrolled List</p></div>
     <div class="col-xs-12 col-md-3"><a href="/instructor/gradecenter" class="btn btn btn-block btn-default" ><h2><i class="fa fa-star"></i> Grades</h2></a><p>Saved Scores</p></div>
     <div class="col-xs-12 col-md-3"><a href="/instructor/cioform" class="btn btn btn-block btn-default" ><h2><i class="fa fa-wrench"></i> Course</h2></a><p>Set Class Parameters</p></div>
     <div class="col-xs-12 col-md-3"><a href="/instructor/instructorlist" class="btn btn btn-block btn-default" ><h2><i class="fa fa-magic"></i> TAs</h2></a><p>Set Assistants</p></div>

     <div class="col-xs-12 col-md-3"><a href="/showtweets" class="btn btn btn-block btn-default" ><h2><i class="fa fa-rss"></i> Class</h2></a><p>Activity Monitor</p></div>
     <div class="col-xs-12 col-md-3"><a href="/showseclog" class="btn btn btn-block btn-default" ><h2><i class="fa fa-lock"></i> Sec Log</h2></a><p>Security Records</p></div>
     <div class="col-xs-12 col-md-3"><a href="/instructor/faq" class="btn btn btn-block btn-default" ><h2><i class="fa fa-question-circle"></i> Help</h2></a><p>FAQ and More</p></div>
     <div class="col-xs-12 col-md-3"><a href="/instructor/sitebackup" class="btn btn btn-block btn-default" ><h2><i class="fa fa-cloud-download"></i> Backup</h2></a><p>Backup My Account</p></div>

     <div class="col-xs-12 col-md-3"><a href="/auth/bioform" class="btn btn btn-block btn-default" ><h2><i class="fa fa-cog"></i> Bio <i class="fa fa-link"></i></h2></a><p>Set My Profile</p></div>';

$t->get_ok("$domain/login?email=$email")->status_is(200)
  ->get_ok($t->tx->res->dom->at('.text-center:nth-child(3) .btn-default')->{href})->status_is(200)
  ->text_is('.alert-success',"$email logs into corpfin",' ')->text_is('h1',' instructor ','right course page')
  ->content_like(qr/$coursebuttons_i/,'13 course buttons')->element_count_is('.text-center+ .text-center .btn-default h2',3,'3 buttons below')->element_count_is('.col-md-3 p',16,' ')->text_is('.btn-primary h2','  Morph Into Student','morph button exists');


note '
################ Publish and delete messages
';
$t->get_ok("$cdomain/instructor/msgcenter")->content_like(qr/You should not delete messages that/,' ');

# post test message if not posted yet
if ($t->tx->res->dom->at('.msgarea') !~ m/testSubject/) {
  $t->post_ok("$cdomain/instructor/msgsave" => {Accept => '*/*'} => form => {priority => 1,subject => 'testSubject',body => 'testBody'})->status_is(200)
    ->content_like(qr/<dt>subject<\/dt> <dd class="msgid-subject" > testSubject<\/dd>\s+<dt><\/dt> <dd class="msgid-msg"> testBody<\/dd>/,'msg posted')->get_ok("$cdomain/instructor/msgcenter");
}
$ts->get_ok("$cdomain/student")->content_like(qr/testSubject/,'student see msg');

# delete #1233 if it's still there
if ($t->tx->res->dom->at('.msgarea') =~ m/Test Welcome/) { $t->get_ok("$cdomain/instructor/msgdelete" => {Accept => '*/*'} => form => {msgid => 1233})->status_is(200); }
$ts->get_ok("$cdomain/student")->content_unlike(qr/Test Welcome/,'welcome msg disappear OK')->content_like(qr/testBody/,' ');


if ($onetime) {
note '
################ Upload and remove sample equiz
';
$t->get_ok("$cdomain/instructor/equizcenter")->status_is(200);
$t->get_ok($cdomain.($t->tx->res->dom->at('.col-xs-6 .btn-block')->{href}))->status_is(200)
  ->get_ok($cdomain.($t->tx->res->dom->at('.col-xs-6 .btn-block')->{href}))->status_is(200); # clear nothing has no problem
$t->get_ok("$cdomain/instructor/equizcenter")->text_is('h1',' equiz center ','right page')
  ->element_exists('#taskbrowser',' ')->element_count_is('th',7,'7 columns')
  ->content_like(qr/<form action="\/uploadsave" method="post" class="dropzone" id="dropzoneform" enctype="multipart\/form-data">\s+<\/form>/,' ');

my $equizzes = $t->tx->res->dom->at('#taskbrowser');
$equizzes =~ s/.*<tbody>/<tbody>/s;
$equizzes =~ s{</tbody>.*}{</tbody>}s;
my $count = 0;
while ($equizzes =~ m/<tr class ="published">/g) { $count++; }

$t->get_ok($cdomain.($t->tx->res->dom->at('.col-xs-2:nth-child(1) .btn-block')->{href}))->status_is(200)->get_ok("$cdomain/instructor/equizcenter")->element_count_is('td:nth-child(3)',$count+6,'option: 6 equizes uploaded')
  ->get_ok($cdomain.($t->tx->res->dom->at('.col-xs-2:nth-child(2) .btn-block')->{href}))->status_is(200)->get_ok("$cdomain/instructor/equizcenter")->element_count_is('td:nth-child(3)',$count+14,'starters: 8 equizes uploaded')
  ->get_ok($cdomain.($t->tx->res->dom->at('.col-xs-2:nth-child(3) .btn-block')->{href}))->status_is(200)->get_ok("$cdomain/instructor/equizcenter")->element_count_is('td:nth-child(3)',$count+18,'tutorials: 4 equizes uploaded')
  ->get_ok($cdomain.($t->tx->res->dom->at('.col-xs-6 .btn-block')->{href}))->status_is(200)->get_ok("$cdomain/instructor/equizcenter")->element_count_is('tr > :nth-child(3)',1,'clear templates OK')
  ->get_ok($cdomain.($t->tx->res->dom->at('.col-xs-4 .btn-default')->{href}))->status_is(200,'test equiz button OK')->get_ok("$cdomain/instructor/equizcenter")->content_like(qr/please read the <a href="\/aboutus"> intro <\/a>/,' ');
}

$t->get_ok("$cdomain/instructor/equizcenter")->content_like(qr/<div class="col-xs-6"><a href="\/instructor\/rmtemplates" class="btn btn-default btn-block">remove all unchanged unpublished template files<\/a><\/div>/,' ')->text_like('.col-xs-6 .btn-block',qr/remove all unchanged unpublished template files/,' ');

# $equiz: existent -> delete
if ($t->tx->res->dom->at('#body') =~ m/$equiz/) {
  $t->get_ok("$cdomain/instructor/equizmore?f=$equiz")->get_ok("$cdomain/instructor/".($t->tx->res->dom->at('.btn-xs.btn-danger')->{href}))->status_is(200)->get_ok("$cdomain/instructor/equizcenter")->content_unlike(qr/$equiz/,"$equiz deleted successfully");
}

$t->get_ok("$cdomain/instructor/equizcenter")->get_ok($cdomain.($t->tx->res->dom->at('.col-xs-6 .btn-block')->{href}));  # clear all templates first
$t->post_ok("$cdomain/uploadsave" => {Accept => '*/*'} => form => {id => 'uploadform',enctype => 'multipart/form-data', file => {file => '/home/ni/Desktop/ss/sylspace/templates/equiz/tutorials/1simple.equiz'}})
  ->post_ok("$cdomain/uploadsave" => {Accept => '*/*'} => form => {id => 'uploadform',enctype => 'multipart/form-data', file => {file => '/home/ni/Desktop/ss/sylspace/templates/equiz/tutorials/2medium.equiz'}})->status_is(200)
  ->get_ok("$cdomain/instructor/equizcenter")->element_count_is('td:nth-child(3)',2,'2 tutorial equiz uploaded OK');

$ts->get_ok("$cdomain/student/equizcenter")->content_unlike(qr/(1simple|2medium).equiz/,'Nothing has been published yet');
$t->content_like(qr/<td class="c"> <a href="filesetdue\?f=1simple.equiz&amp;dueepoch=\d+" class="btn btn-primary btn-xs" >publish<\/a> <\/td>/,' ');



if ($onetime) {
note "
################ $email Run and Grade $equiz
";

$t->content_like(qr/<a href="\/equizrender\?f=$equiz" class="btn btn-xs btn-default" >run<\/a> <a href="view\?f=$equiz" class="btn btn-xs btn-default" >view<\/a> <a href="download\?f=$equiz" class="btn btn-xs btn-default" >download<\/a> <a href="edit\?f=$equiz" class="btn btn-xs btn-default" >edit<\/a> <\/td>\s+<td class="c"> <a href="equizmore\?f=$equiz" class="btn btn-default btn-xs">more<\/a>/,'run view download edit more, 5 buttons exist')
  ->get_ok("$cdomain/equizrender?f=$equiz")->status_is(200)->text_is('h1',' take an equiz ','right equiz page')

  ->post_ok("$cdomain/equizgrade" => {Accept => '*/*'} => form => {'q-stdnt-1' => 10, 'N-1' => "U2FsdGVkX18xNDE1MTYxN3eglqXnUaUKPtYux85UAATjr+7QUkPxL94XmYOMa/x2", 'Q-1' => "U2FsdGVkX18xNDE1MTYxN+e54ip4I+JA+WyyJUoVZFATMAoDfMfDCnQ/l5ADwWJuENMrefaI2TM8
1/OXN5zEi64VjVjY2Yh1kTxHRriaeRR6bfZCKugrhw7SqUKapMbm8tPWG/5utP+HPUNqCRPeXncA
4GZq4DrwepQNuWoOIBKyl1aa7pBhtFOuSC7FgImFi3eyQhhmcDE=", 'A-1' => "U2FsdGVkX18xNDE1MTYxNz60KxMJuLS5uaSDsDJIIW5sO/nGL34RC7SiIDgCslFH2wkbEkrVGjFN
iVovANi8fEQcR0KfwP+i8+Ekoeb3G0WKPR7lb7wM34jWVSD3LERRGdwuj/Hadgm+FJ3Qe5w6WnZa
7nrQM2mLR7rk7DG45Y29alRd2+tFtqCwgcVLndL8URzYziENAIbMV2Q+8ookynjKwsIVMKPc6yMN
H4p/wVV150jyY19+w7ERaDSNkt1J", 'S-1' => "U2FsdGVkX18xNDE1MTYxN0K+eL0bEPXc
", confidential => "U2FsdGVkX18xNDE1MTYxNw8bo849CbXkukH0RPJ/oXxYC/x/9s3OkzKuFAHPUU09nfcYCkAnx6Ip
+V8YVtU3i7qTCThcj+tuP9xY/Shb2hzbvGb5dFxrIg0I1OIqzCxY6zA8UHbhZCKQCMYhgBTsiRLB
rv8Fj65Hl8viY0hOrhga7Mx670OtSEClkCgcE11ExHf1pDOkq4uTx/QveaeM5mPmIWKDJ9FuR4Lr
nnqY+FXKuz11wCtt0AxxRbAsJF9r+qY8LkhTljBpkgXLqEMTARXqDZwvI2xemABhGPspp2JwNuKZ
xEO+Ed7CY3oItgGb5kWP8otopdNRUwEddPqGp0liOEAbyKWiwtVpjW5oP5w=
", ntime => "1515359438"})->status_is(200)
  ->text_is('h1',' show equiz results ','right equiz grade page')->text_is('.qstnstudentsays',' 10 ',' ')->text_is('.qstnscore',' Incorrect  ','right equiz grading')
  ->get_ok("$cdomain/instructor/equizmore?f=$equiz")->content_like(qr/<tr> <td>1<\/td> <td>$email<\/td> <td>0 \/ 1<\/td> <td><span class="epoch0">\d+\s+<\/span> \d+ [a-z]+ ago<\/td> <\/tr>/,'right equiz record')
  ->get_ok("$cdomain/instructor/equizcenter");


note '
################ Test remain 4 equiz buttons: view, download, edit and more
';

 $t ->get_ok("$cdomain/instructor/view?f=$equiz")->status_is(200)->content_like(qr/X=\$x is a random integer number between 10 and 20/,'right equiz content')
  ->get_ok("$cdomain/instructor/download?f=$equiz")->status_is(200)->text_is('h1',' download a file ',' ')->content_like(qr/click <a href="silentdownload\?f=1simple.equiz">silentdownload\?f=1simple.equiz<\/a>/,'download OK')
  ->get_ok("$cdomain/instructor/edit?f=$equiz")->status_is(200)->content_like(qr/::GRADENAME::\s+equiz1/,' ')->text_is('h1',' edit a file ','right edit page');
my $oldcontent = $t->tx->res->dom->at('#textarea')->val;
$t->post_ok("$cdomain/instructor/editsave" => {Accept => '*/*'} => form => {fname => $equiz, content => "$oldcontent\nTest object added one more line", fingerprint => Digest::MD5::md5_hex($oldcontent)})->status_is(200)->get_ok("$cdomain/instructor/view?f=$equiz")->status_is(200)->content_like(qr/added one more line/,'edit equiz OK');
$t->get_ok("$cdomain/instructor/equizmore?f=$equiz")->status_is(200)->text_is('h2',' Student Performance ','right equiz page')->element_count_is('th',12,' ')
  ->content_like(qr/<tr> <th> file name <\/th> <td> $equiz <\/td> <\/tr>\s+<tr> <th> file size<\/th> <td> \d+ bytes <\/td> <\/tr>\s+/,' ')
  ->content_like(qr/\d secs* ago<\/td> <\/tr><\/table> <\/td> <\/tr>\s+<tr> <th> action <\/th> <td>  <a href="\/equizrender\?f=$equiz" class="btn btn-xs btn-default" >run<\/a> <a href="view\?f=$equiz" class="btn btn-xs btn-default" >view<\/a> <a href="download\?f=$equiz" class="btn btn-xs btn-default" >download<\/a> <a href="edit\?f=$equiz" class="btn btn-xs btn-default" >edit<\/a> <\/td> <\/tr>/,'right equizmore format');
}


if ($onetime) {
note "
################ instructor publish $equiz, student answer it
";

$t->get_ok("$cdomain/instructor/filesetdue" => form => {f => $equiz,duedate => "2019-01-01", duetime => "23:59"} )
  ->get_ok("$cdomain/instructor/equizmore?f=$equiz")
  ->text_is('span:nth-child(1) .btn-default','publish for 6 Months',' ')->text_is('span+ span .btn-default','unpublish',' ')->text_is('.btn-xs.btn-danger','delete',' ')
  ->get_ok("$cdomain/instructor/".($t->tx->res->dom->at('span:nth-child(1) .btn-default')->{href}))
  ->get_ok("$cdomain/instructor/equizmore?f=$equiz")->text_is('td:nth-child(1) .btn-default','back to equizcenter','back button exists')
  ->get_ok("$cdomain/instructor/".($t->tx->res->dom->at('td:nth-child(1) .btn-default')->{href}))->status_is(200)->content_like(qr/equiz center/,' ')->content_like(qr/in 6 months<\/a> <a href="filesetdue\?f=$equiz&amp;dueepoch=\d+" class="btn btn-info btn-xs" >unpub/,"published $equiz OK");

$ts->get_ok("$cdomain/student/equizcenter")->element_count_is('.btn-block',1,"student can only see $equiz")->text_like('.col-md-3:nth-child(1) p',qr/due in 6 months\s*\w{3}\s+\w{3}\s+\d+\s+\d\d:\d\d:\d\d\s+20\d\d/,'right equiz info')
   ->get_ok("$cdomain".($ts->tx->res->dom->at('.col-md-3:nth-child(1) .btn-default')->{href}))->status_is(200)
   ->text_like('#TXT1',qr/X=\d+ is a random integer number between 10 and 20/,' ')->text_unlike('#TXT1', qr/X=\$x is a random integer/,'right equiz content');

# scrape the equiz attributes
my $question = $ts->tx->res->dom->at('#TXT1')->text;
$question =~ m/X=(\d+)/; my $answer = $1+1;

$question = $ts->tx->res->dom->at('#SPC1');
$question =~ m{name="N-1".*value="([^"]+)"}; my $N_1 = $1;
$question =~ m{name="Q-1".*value="([^"]+)"}; my $Q_1 = $1;
$question =~ m{name="A-1".*value="([^"]+)"}; my $A_1 = $1;
$question =~ m{name="S-1".*value="([^"]+)"}; my $S_1 = $1;
$question = $ts->tx->res->dom->at('main');
$question =~ m{name="confidential".*value="([^"]+)"}; my $confi = $1;
$question =~ m{name="ntime".*value="(\d+)"}; my $ntime = $1;

$ts->post_ok("$cdomain/equizgrade" => {Accept => '*/*'} => form => {'q-stdnt-1' => $answer, 'N-1' => $N_1, 'Q-1' => $Q_1, 'A-1' => $A_1, 'S-1' => $S_1, confidential => $confi, ntime => $ntime})->status_is(200)
   ->text_is('h1',' show equiz results ','right equiz grade page')->text_is('p.qstnstudentsays'," $answer ",' ')->text_is('p.qstnscore',' Correct  ','right equiz grading');
$t->get_ok("$cdomain/instructor/equizmore?f=$equiz")->content_like(qr/<tr> <td>\d+<\/td> <td>$semail<\/td> <td>1 \/ 1<\/td> <td><span class="epoch0">\d+\s+<\/span> \d+ [a-z]+ ago<\/td> <\/tr>/,'right equiz record');
}


if ($onetime) {
note "
################ instructor publish $hw
";

$t->get_ok("$cdomain/instructor/hwcenter")->text_is('h1',' homework center ','right hwcenter page')->element_count_is('th',7,' ');

# if $hw havn't been uploaded yet
if ($t->tx->res->dom->all_text !~ m/>$hw</) {
$t->post_ok("$cdomain/uploadsave" => {Accept => '*/*'} => form => {id => 'uploadform',enctype => 'multipart/form-data', file => {file => '/home/ni/Desktop/hwsample.junk'}})->status_is(200)
  ->content_like(qr/<td class="c"> <a href="filesetdue\?f=$hw&amp;dueepoch=\d+" class="btn btn-primary btn-xs" >publish<\/a> <\/td>\s+<td> <a href="hwmore\?f=$hw">$hw<\/a> <\/td>/,"upload $hw OK");
$ts->get_ok("$cdomain/student/hwcenter")->content_unlike(qr/$hw/,"$hw haven't been published yet");
$t->get_ok("$cdomain/instructor/".($t->tx->res->dom->at('td:nth-child(3) a')->{href}))->status_is(200)
  ->get_ok("$cdomain/instructor/view?f=$hw")->content_like(qr/$hwcontent/,"right $hw content")
  ->get_ok("$cdomain/instructor/filesetdue" => form => {f => $hw, duedate => "2019-01-01", duetime => "23:59"} )
  ->get_ok("$cdomain/instructor/hwmore?f=$hw");
}


note "
################ student upload, delete and re-upload answer($hwanswer) to $hw
";
$ts->get_ok("$cdomain/student/hwcenter")->content_like(qr/$hw/,"student can see $hw")
   ->text_like('.table a.btn-default',qr/$hw/,' ')->text_like('#body td:nth-child(2)',qr/due in \d+ [a-z]+\s\(\)due GMT \w{3} \w{3}\s+\d+ \d\d:\d\d:\d\d 20\d\d/,'duetime display OK')
   ->text_like('td:nth-child(4)',qr/no upload for $hw yet/,'no upload yet')
   ->content_like(qr/<form action="\/uploadsave" id="uploadform" method="post" enctype="multipart\/form-data" style="display:block">\s+<label for="idupload">Upload: <\/label>\s+<input type="file" name="file" id="idupload" style="display:inline"  >\s+<input type="hidden" name="hwtask" value="hwsample.junk"  ><br \/>\s+<button class="btn btn-default btn-block" type="submit" value="submit">Go<\/button>\s+<\/form>/,'uploadform exists')
   ->get_ok($cdomain.($ts->tx->res->dom->at('.table a.btn-default')->{href}))->content_is("$hwcontent\n","student see right $hw content")
   ->post_ok("$cdomain/uploadsave" => {Accept => '*/*'} => form => {id => 'uploadform',enctype => 'multipart/form-data', file => {file => '/home/ni/Desktop/hwsample.junk-student-answer.sometype'}, hwtask => $hw})->status_is(200)
   ->content_like(qr/<\/td><td><a href="\/student\/ownfileview\?f=$hwanswer">$hwanswer<\/a><br \/><a href="\/student\/answerdelete\?f=$hwanswer&task=$hw" class="btn btn-xs btn-danger" >delete me<\/a>/,'answer uploaded OK')
   ->post_ok("$cdomain/uploadsave" => {Accept => '*/*'} => form => {id => 'uploadform',enctype => 'multipart/form-data', file => {file => '/home/ni/Desktop/hwsample.junk-student-answer.sometype'}, hwtask => $hw})->status_is(500,'must delete old answer first')
   ->get_ok("$cdomain/student/hwcenter")->status_is(200)
   ->get_ok("$cdomain/student/answerdelete?f=$hwanswer&task=$hw")->status_is(200)->text_like('td:nth-child(4)',qr/no upload for $hw yet/,'delete answer OK')
   ->post_ok("$cdomain/uploadsave" => {Accept => '*/*'} => form => {id => 'uploadform',enctype => 'multipart/form-data', file => {file => '/home/ni/Desktop/hwsample.junk-student-answer.sometype'}, hwtask => $hw})->status_is(200)->content_like(qr/<\/td><td><a href="\/student\/ownfileview\?f=$hwanswer">$hwanswer<\/a><br \/><a href="\/student\/answerdelete\?f=$hwanswer&task=$hw" class="btn btn-xs btn-danger" >delete me<\/a>/,'answer uploaded again OK');


note "
################ instructor collects answer to $hw
";
$t->get_ok("$cdomain/instructor/hwmore?f=$hw")->text_is('h2',' 1 Student Responses ','right count')->text_is('#body li'," Submitted: $semail ",'answer from right student')->text_is('.btn-lg','collect all student answers',' ')
  ->get_ok($cdomain.($t->tx->res->dom->at('.btn-lg')->{href}))->text_is('h1',' collect student answers ','right collect answer page')->content_like(qr/click <a href="silentdownload\?f=$hw-answers-\d+.zip">silentdownload\?f=$hw-answers-\d+.zip<\/a>/,' ')
  ->get_ok("$cdomain/instructor/hwcenter")->content_unlike(qr/<td class="c"> <a href="hwmore\?f=$hw-answers-\d+.zip"> <span class="epoch0">\d+<\/span> in 6 months<\/a> <a href="filesetdue\?f=$hw-answers-\d+.zip&amp;dueepoch=\d+" class="btn btn-info btn-xs" >unpub<\/a> <\/td>/,' ')->content_like(qr/<td class="c"> <a href="filesetdue\?f=$hw-answers-\d+.zip&amp;dueepoch=\d+" class="btn btn-primary btn-xs" >publish<\/a> <\/td>\s+<td> <a href="hwmore\?f=$hw-answers-\d+.zip">$hw-answers-\d+.zip<\/a> <\/td>/,"unpublished answer.zip is in hwcenter");

############Maybe check the content of the downloaded file (let $t download and keep it)


note "
################ instructor and student file center interaction
";

$t->get_ok("$cdomain/instructor/filecenter")->status_is(200)->text_is('h1',' file center ',' ')->content_like(qr/in \d+ [a-z]+<\/a> (<a href="filesetdue\?f=$syllabus&amp;dueepoch=\d+") class="btn btn-info btn-xs" >unpub<\/a>/,"$syllabus currently published in file center")
  #->get_ok("$cdomain/instructor/filesetdue" => form => {f => $syllabus, duedate => "2019-01-01", duetime => "23:59"})->status_is(200)
  #->get_ok("$cdomain/instructor/filemore?f=$syllabus")->text_like('tr:nth-child(5) th+ td',qr/Epoch: <\/td> <td><span class="epoch14">$epoch<\/span><\/td> <\/tr>\s+<tr> <td>GMT: <\/td> <td> Tue Jan  1 23:59:00 2019<\/td><\/tr>/)
  ;

$ts->get_ok("$cdomain/student/filecenter")->status_is(200)->text_is('h1',' file center ',' ')->text_like('h3',qr/$syllabus/,'student can see syllabus')->content_like(qr/<a href="\/student\/fileview\?f=$syllabus" class="btn btn btn-block btn-default" ><h3><i class="fa fa-pencil"><\/i> syllabus-sophisticated.html<\/h3><\/a>/,' ')->get_ok("$cdomain/student/fileview?f=$syllabus")->status_is(200)->text_like('.supertitle',qr/MBA 430 syllabus/,'right syllabus')->element_count_is('h2',23,' ');

}
if ($onetime) {
note "
################ Checking if uploaded files end up in the right place
";#####################################################################


note "
################ Student grade center check
";
$ts->get_ok("$cdomain/student/gradecenter")->status_is(200)->text_like('caption',qr/^ Student\s+$semail $/,'right student')->element_count_is('thead th',2,'2 columns')->content_like(qr/<tr> <th> $equiz <\/th>\s+<td style="text-align:center">1 \/ 1<\/td><\/tr>/,"right $equiz score")->content_unlike(qr/<tr> <th> $equiz <\/th>\s+<td style="text-align:center">-<\/td><\/tr>/,' ');


$ts->get_ok("$cdomain/student/faq")->status_is(200)->text_like('dd:nth-child(4)',qr/ upload limit is 16MB\/file./,'right faq content')->element_count_is('img',3,'3 images')->text_is('h3+ p','This instructor has not added a course-specific FAQ.',' ')
   ->content_like(qr/Welch <a href="http:\/\/book.ivo-welch.info\/">Corporate Finance<\/a> introductory textbook/,' ');


note "
################ Student change biographical settings
";
$ts->get_ok("$cdomain/auth/bioform")->text_is('h1',' user bio ','right bioform page')->element_count_is('.control-label',12,'12 questions')->content_like(qr/<input class="form-control foo" id="email" name="email" value="$semail" readonly \/>/,'email read only');
is $ts->tx->res->dom->at('#email')->val, $semail,'right email1';
$ts->content_unlike(qr/name="firstname"  maxsize="32" value=""/,' ')->content_unlike(qr/name="lastname"  maxsize="32" value=""/,' ')->content_unlike(qr/name="uniname"  maxsize="32" value=""/,' ');
is $ts->tx->res->dom->at('#regid')->val,'na','course no secret';
}

$ts->get_ok("$cdomain/auth/bioform")->status_is(200);
if (!($ts->tx->res->dom->at('#email2')->val eq 'student@gmail2.com')) {
  $ts->content_like(qr/name="birthyear" type="number" maxsize="4" value="\d{4}"/,' ')->content_like(qr/name="zip"  maxsize="16" value="\d{5}(-\d{4})?"/,' ')->content_like(qr/name="country"  maxsize="16" value="(\w|\s)+"/,' ')->content_unlike(qr/name="cellphone" type="tel" maxsize="32" value=""/,' ')->content_unlike(qr/name="email2" type="email" maxsize="64" value=""/,' ')->content_like(qr/name="tzi" type="number"  value="(-|\+)*\d{1,2}"/,' ');
  $ts->post_ok("$domain/auth/biosave" => {Accept => '*/*'} => form => {email=>$semail, firstname=>'stu', lastname => 'dent', uniname => 'student', regid => 'na', birthyear => 1999, zip => '90024-0095', country => "U. S.", cellphone => '1234567890', email2 => 'student@gmail2.com', tzi => 8, optional => ''})->status_is(200)
     ->text_is('h1',' superhome ','redirected to super home')->text_is('.alert-success','Updated Biographical Settings',' ')->get_ok("$cdomain/auth/bioform");
is $ts->tx->res->dom->at('#email')->val, $semail,'right email1';
is $ts->tx->res->dom->at('#firstname')->val, 'stu',' ';
is $ts->tx->res->dom->at('#lastname')->val, 'dent', ' ';
is $ts->tx->res->dom->at('#uniname')->val, 'student',' ';
is $ts->tx->res->dom->at('#regid')->val, 'na', ' ';
is $ts->tx->res->dom->at('#birthyear')->val, 1999, ' ';
is $ts->tx->res->dom->at('#zip')->val, '90024-0095', ' ';
is $ts->tx->res->dom->at('#country')->val, 'U. S.',' ';
is $ts->tx->res->dom->at('#cellphone')->val, '1234567890',' ';
is $ts->tx->res->dom->at('#email2')->val, 'student@gmail2.com',' ';
is $ts->tx->res->dom->at('#tzi')->val, 8,' ';
is $ts->tx->res->dom->at('#optional')->val, '';
}

$ts->get_ok("$cdomain/student")->content_like(qr/<div class="row top-buffer text-center"><div class="col-xs-12 col-md-3"><a href="http:\/\/ivo-welch.info" class="btn btn btn-block btn-default" ><h2>welch<\/h2><\/a><p>go back to root<\/p><\/div><div class="col-xs-12 col-md-3"><a href="http:\/\/book.ivo-welch.info" class="btn btn btn-block btn-default" ><h2>book<\/h2><\/a><p>read book<\/p><\/div><div class="col-xs-12 col-md-3"><a href="http:\/\/gmail.com" class="btn btn btn-block btn-default" ><h2>gmail<\/h2><\/a><p>send email<\/p><\/div><\/div>/,'bottom 3 buttons OK');

if ($onetime) {
note "
################ security log and tweets check
";
$ts->get_ok("$cdomain/showseclog")->text_is('h1',' security log ',' ')->element_count_is('th',5,'5 columns')
   ->content_like(qr/<tr> <td>127.0.0.1<\/td> <td><span class="epoch0">\d+<\/span> \d+ \w+ ago<\/td> <td> \w{3} \w{3} \d+ \d\d:\d\d:\d\d 20\d\d <\/td> <td>$semail<\/td> <td>entering course site corpfin<\/td> <\/tr>/,'right log')
   ->content_unlike(qr/<tr> <td>127.0.0.1<\/td> <td><span class="epoch0">\d+<\/span> \d+ \w+ ago<\/td> <td> \w{3} \w{3} \d+ \d\d:\d\d:\d\d 20\d\d <\/td> <td>$email<\/td> <td>entering course site corpfin<\/td> <\/tr>/,' ');

$t->get_ok("$cdomain/showseclog")->text_is('h1',' security log ',' ')->element_count_is('th',5,'5 columns')
  ->content_like(qr/<tr> <td>127.0.0.1<\/td> <td><span class="epoch0">\d+<\/span> \d+ \w+ ago<\/td> <td> \w{3} \w{3} \d+ \d\d:\d\d:\d\d 20\d\d <\/td> <td>$semail<\/td> <td>entering course site corpfin<\/td> <\/tr>/,'right log');

$ts->get_ok("$cdomain/showtweets")->text_is('h1',' course activity ',' ')->element_count_is('th',5,' ')
   ->content_like(qr/<tr> <td>127.0.0.1<\/td> <td><span class="epoch0">\d+<\/span> \d+ \w+ ago<\/td> <td> \w{3} \w{3} \d+ \d\d:\d\d:\d\d 20\d\d <\/td> <td>$semail<\/td> <td> now enrolled in course corpfin<\/td>/,'student log OK')->content_like(qr/$email<\/td> <td> published $equiz, due \d+ \(GMT/,'know updates by instructor');
}

note "
################ instructor student center check
";
$t->get_ok("$cdomain/instructor/studentdetailedlist")->status_is(200)->text_is('h1',' list students ',' ')
  ->element_count_is('td',(2+1)*4,'only 1 instructor and 1 student')
  ->text_is('button.btn','Add 1 New Student',' ')
  ->get_ok("$cdomain/instructor/userenroll" => {Accept => '*/*'} => form => {newuemail => 'test@test.com'})
  ->get_ok("$cdomain/instructor/studentdetailedlist")
  ->element_count_is('td',(3+1)*4+1,'new student test@test.com added')
  ->content_like(qr/<tr> <td> test\@test.com <\/td>\s+<td>\s+<\/td>\s+<td>\s+<\/td>\s+<td>\s+<\/td>\s+<td>\s+<\/td>\s+<\/tr>/,'no bio for the new student');
system 'rm /var/sylspace/users/test@test.com -rf';  # delete new user
system 'rm /var/sylspace/courses/corpfin/test@test.com -rf';  # delete new user's course related files

note "
################ instructor grade center check, and assign hw grades
";
$t->get_ok("$cdomain/instructor/gradecenter")->status_is(200)->text_is('h1',' grade center ',' ')
  ->element_count_is('td',(2+1)*4+2*($t->tx->res->dom->all_text =~ m/attendance/),'2 persons, 4 or 5 tasks')
  ->content_like(qr/<tr> <th> $email <\/th>\s+<td style="text-align:center">-<\/td><td style="text-align:center">-<\/td><td style="text-align:center">-<\/td><td style="text-align:center">-<\/td><td style="text-align:center">0 \/ 1<\/td>/,' ')->content_unlike(qr/<tr> <th> $email <\/th>\s+<td style="text-align:center">-<\/td><td style="text-align:center">-<\/td><td style="text-align:center">-<\/td><td style="text-align:center">-<\/td><td style="text-align:center">1 \/ 1<\/td>/,"right score for $email")
  ->content_like(qr/<tr> <th> $semail <\/th>\s+<td style="text-align:center">-<\/td><td style="text-align:center">-<\/td><td style="text-align:center">-<\/td><td style="text-align:center">badfail<\/td><td style="text-align:center">1 \/ 1<\/td>/,' ')->content_unlike(qr/<tr> <th> $semail <\/th>\s+<td style="text-align:center">-<\/td><td style="text-align:center">-<\/td><td style="text-align:center">-<\/td><td style="text-align:center">badfail<\/td><td style="text-align:center">0 \/ 1<\/td>/,"right scores for $semail");

$t->get_ok("$cdomain/instructor/gradesave1" => {Accept => '*/*'} => form => {uemail => $semail, task => $equiz, grade => '0 / 1'})
  ->get_ok("$cdomain/instructor/gradecenter");

$t->element_count_is('td',(2+1)*4+2*($t->tx->res->dom->all_text =~ m/attendance/),'2 persons, 4 or 5 tasks')
  ->content_like(qr/<a href="gradeform\?taskn=$equiz">$equiz<\/a>/,'link to gradeform exists')
  ->content_like(qr/<tr> <th> $email <\/th>\s+<td style="text-align:center">-<\/td><td style="text-align:center">-<\/td><td style="text-align:center">-<\/td><td style="text-align:center">-<\/td><td style="text-align:center">0 \/ 1<\/td>/,' ')->content_unlike(qr/<tr> <th> $email <\/th>\s+<td style="text-align:center">-<\/td><td style="text-align:center">-<\/td><td style="text-align:center">-<\/td><td style="text-align:center">-<\/td><td style="text-align:center">1 \/ 1<\/td>/,"right score for $email")
  ->content_like(qr/<tr> <th> $semail <\/th>\s+<td style="text-align:center">-<\/td><td style="text-align:center">-<\/td><td style="text-align:center">-<\/td><td style="text-align:center">badfail<\/td><td style="text-align:center">0 \/ 1<\/td>/,' ')->content_unlike(qr/<tr> <th> $semail <\/th>\s+<td style="text-align:center">-<\/td><td style="text-align:center">-<\/td><td style="text-align:center">-<\/td><td style="text-align:center">badfail<\/td><td style="text-align:center">1 \/ 1<\/td>/,"right scores for $semail");

$ts->get_ok("$cdomain/student/gradecenter")->content_like(qr/<tr> <th> $equiz <\/th>\s+<td style="text-align:center">0 \/ 1<\/td><\/tr>/,' ')->content_unlike(qr/<tr> <th> $equiz <\/th>\s+<td style="text-align:center">1 \/ 1<\/td><\/tr>/,'student see the same update in score');

$t->get_ok("$cdomain/instructor/gradesave1" => {Accept => '*/*'} => form => {uemail => $semail, task => $equiz, grade => '1 / 1'});

if ($ts->tx->res->dom->all_text !~ m/attendance/) {
$t->get_ok("$cdomain/instructor/gradetaskadd" => {Accept => '*/*'} => form => {taskn => 'attendance'})
  ->get_ok("$cdomain/instructor/gradecenter")->element_count_is('td',(2+1)*5-1,'new task added OK')
  ->get_ok("$cdomain/instructor/gradeform?taskn=attendance")->text_is('main h1','Grades For Task attendance',' ')
  ->get_ok("$cdomain/instructor/gradesave" => {Accept => '*/*'} => form => {task => 'attendance', 'student@gmail.com' => '90 / 100', 'ivo.welch@gmail.com' => '100 / 100'});
}


note "
################ gradebook check
";
$t->get_ok("$cdomain/instructor/gradecenter")
  ->content_like(qr/<a href="\/instructor\/gradedownload\?f=csv&sf=l" class="btn btn-default" >Long<\/a>\s+<a href="\/instructor\/gradedownload\?f=csv&sf=w" class="btn btn-default" >Wide<\/a>\s+<a href="\/instructor\/gradedownload\?f=csv&sf=b" class="btn btn-default" >Best Only<\/a>\s+<a href="\/instructor\/gradedownload\?f=csv&sf=t" class="btn btn-default" >Latest Only<\/a>/,' ')
  
  ->get_ok("$cdomain/instructor/gradedownload?f=csv&sf=l")->content_like(qr/student,hw,grade,epoch,date\n/,'right title for Long')
  ->content_like(qr/$email,$equiz,0 \/ 1,\d+,.+\n/,' ')
  ->content_like(qr/student\@gmail.com,$equiz,1 \/ 1,\d+,.+\n$semail,$equiz,0 \/ 1,\d+,.+\n$semail,$equiz,1 \/ 1,\d+,.+/,' ')
  ->content_like(qr/$email,attendance,100 \/ 100,\d+,.+\n$semail,attendance,90 \/ 100,\d+,.+/,'all grades recorded OK')

  ->get_ok("$cdomain/instructor/gradedownload?f=csv&sf=w")->content_like(qr/Student,,hw1,hw2,midterm,$equiz,attendance\n$email,,,,,0 \/ 1,100 \/ 100\n$semail,,,,badfail,1 \/ 1,90 \/ 100\n/,' ')

  ->get_ok("$cdomain/instructor/gradedownload?f=csv&sf=b")->content_like(qr/student,task,grade\n/,'right title for Best Only')
  ->content_like(qr/$email,$equiz,\s+0\n/,' ')->content_like(qr/$email,attendance,\s+100\n/,' ')->content_like(qr/$semail,$equiz,\s+1\n/,' ')->content_like(qr/$semail,attendance,\s+90\n/,'correct best scores')

  ->get_ok("$cdomain/instructor/gradedownload?f=csv&sf=t")->content_like(qr/student,task,grade\n/,'right title for Latest Only')
  ->content_like(qr/$email,$equiz,\s+0\n/,' ')->content_like(qr/$email,attendance,\s+100\n/,' ')->content_like(qr/$semail,$equiz,\s+1\n/,' ')->content_like(qr/$semail,attendance,\s+90\n/,'correct latest scores');

note "
################ Checking course biography, instructor add, course activity
";
$t->get_ok("$cdomain/instructor/cioform")->element_count_is('input',23,' ')->text_like('h2',qr/Additional GUI Buttons/,' ')->element_count_is('button.btn.btn-default.btn-lg',2,'2 submit buttons exist');
$t->get_ok("$cdomain/instructor/instructorlist")->content_like(qr/<tr> <td> $email <\/td> <td> <a href="instructordel\?deliemail=$email">/,'the only instructor')->content_unlike(qr/<tr> <td> $semail <\/td> <td> <a href="instructordel\?deliemail=$semail"><i class="fa fa-trash" aria-hidden="true"><\/i><\/a> <\/td> <\/tr>/,' ')
  ->post_ok("$cdomain/instructor/instructoradd" => {Accept => '*/*'} => form => {newiemail => $semail})
  ->get_ok("$cdomain/instructor/instructorlist")->content_like(qr/<tr> <td> $email <\/td> <td> <a href="instructordel\?deliemail=$email"><i class="fa fa-trash" aria-hidden="true"><\/i><\/a> <\/td> <\/tr>
<tr> <td> $semail <\/td> <td> <a href="instructordel\?deliemail=$semail"><i class="fa fa-trash" aria-hidden="true"><\/i><\/a> <\/td> <\/tr>/,'2 instructors now');
$ts->get_ok("$cdomain/instructor")->status_is(200)->text_is('h1',' instructor ','status changed');
$t->get_ok("$cdomain/instructor/instructordel?deliemail=$semail")->status_is(200)->get_ok("$cdomain/insturctor/instructorlist")->content_unlike(qr/<tr> <td> $semail <\/td> <td> <a href="instructordel\?deliemail=$semail"><i class="fa fa-trash" aria-hidden="true"><\/i><\/a> <\/td> <\/tr>/,' ');
$ts->get_ok("$cdomain/instructor")->status_is(500)->get_ok("$cdomain/student")->text_is('h1',' student ','status changed back');

$t->get_ok("$cdomain/showtweets")->text_is('h1',' course activity ',' ')->element_count_is('th',5,' ')
   ->content_like(qr/<tr> <td>127.0.0.1<\/td> <td><span class="epoch0">\d+<\/span> \d+ \w+ ago<\/td> <td> \w{3} \w{3} \d+ \d\d:\d\d:\d\d 20\d\d <\/td> <td>$semail<\/td> <td> now enrolled in course corpfin<\/td>/,'know student behaviors')->content_like(qr/$email<\/td> <td> published $equiz, due \d+ \(GMT/,' ')->content_like(qr/<tr> <td>127.0.0.1<\/td> <td><span class="epoch0">\d+<\/span> \d+ \w+ ago<\/td> <td> \w{3} \w{3} \d+ \d\d:\d\d:\d\d 20\d\d <\/td> <td>instructor<\/td> <td>changed many grades: | $semail | $email | <- attendance/,' ')->content_like(qr/<tr> <td>127.0.0.1<\/td> <td><span class="epoch0">\d+<\/span> \d+ \w+ ago<\/td> <td> \w{3} \w{3} \d+ \d\d:\d\d:\d\d 20\d\d <\/td> <td>instructor<\/td> <td>completely deleted message msgid=1233<\/td>/,'well tracked');


note "
################ Checking links on instructor faq page, checking course activity
";
$t->get_ok("$cdomain/instructor/faq")->element_count_is('dt',38,'38 faqs')->element_count_is('img',3,'3 images');
my @links = $t->tx->res->dom->find('a')->map(attr => 'href')->each;
if (!$onlyonce) {
foreach(@links) {  # all the links on instructor faq page
  ($_ eq '..') and next;
  ($_ =~ m/mailto:$email[\?subject=\w+]{0,1}/) and next;
  if (($_ eq '/aboutus') or ($_ =~ m{/auth}) or ($_ =~ m{http})) { $t->get_ok($_)->status_is(200); next;}
  $t->get_ok($cdomain.$_)->status_is(200);
} 
}
$t->get_ok("$domain/login?email=$email")->get_ok("$cdomain/instructor")->content_like(qr/<a href="\/instructor\/sitebackup" class="btn btn btn-block btn-default" ><h2><i class="fa fa-cloud-download"><\/i> Backup<\/h2><\/a><p>Backup My Account<\/p>/,'backup link exists');
$t->ua->max_redirects(1);
$t->get_ok("$cdomain/instructor/sitebackup")->status_is(200)->content_like(qr/<meta http-equiv="refresh" content="1;url=silentdownload\?f=\/var\/sylspace\/tmp\/corpfin-\d+.zip">/,'silent download')
  ->content_unlike(qr/ENV\{SYLSPACE_appname\}/,' ');
$t->ua->max_redirects(10);
$t->get_ok("$cdomain/auth/bioform")->status_is(200)->element_count_is('input',11+1,'11 changealbe bio')->element_exists('form',' ');

$t->get_ok("$cdomain/instructor")->content_like(qr/<a class="btn btn-primary btn-block" href="\/instructor\/instructor2student">\s+<h2> <i class="fa fa-graduation-cap"><\/i> Morph Into Student<\/h2><\/a>/,'morph into student now')
  ->get_ok("$cdomain/instructor/instructor2student")->status_is(200)
  ->text_is('h1',' student ',' ')->element_count_is('h2',14,' ')
  ->content_like(qr/<a class="btn btn-primary btn-block" href="\/student\/student2instructor">\s+<h2> <i class="fa fa-graduation-cap"><\/i> Unmorph Back To Instructor<\/h2><\/a>/,'unmorph back now')
  ->get_ok("$cdomain/student/student2instructor")->status_is(200)
  ->text_is('h1',' instructor ',' ')->element_count_is('h2',17,' ');

$ts->get_ok("$cdomain/student/student2instructor")->status_is(500);

#system 'perl initsylspace.pl -f;cd Model/;perl mkstartersite.t;cd ..;';
done_testing();
















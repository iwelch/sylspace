#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::InstructorFaq;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo);
use SylSpace::Model::Files qw(filereadi fileexistsi);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################

get '/instructor/faq' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

  my $isfaq= (fileexistsi($course, 'faq')) ? filereadi( $course, 'faq' ) : "<p>This instructor has not added an own student FAQ.</p>\n" ;

  use Perl6::Slurp;
  my $body= slurp("public/html/faq.html");
  my $code= (length($body)<=1) ? 404 : 200;

#  my $allfaq = $c->ua->get("/html/faq.html");
#  my $code= $allfaq->res->{code};
#  my $body= $allfaq->res->{content}->{asset}->{content};
#
#  if ($code == 404) {
#    $allfaq= "<p>There is no sitewide public /html/faq.html.</p>\n";
#  } else {
#    $body =~ s{.*(<body.*)}{$1}ms;
#    $body =~ s{(.*)</body>.*}{$1}ms;
#  }

## use Mojolicious::Plugin::ContentManagement::Type::Markdown;
## ($allfaq) or $allfaq = $markdown->translate(slurp("/faq.md"));

  $c->stash( allfaq => $body, isfaq => $isfaq );
};

1;

################################################################

__DATA__

@@ instructorfaq.html.ep

%title 'instructor faq';
%layout 'instructor';

<main>

  <h1>Instructor FAQ and Info</h1>

  <dl class="dl faq">

  <dt>What is <i>not</i> intuitive using this website (SylSpace on <%= $ENV{'SYLSPACE_sitename'} %>)?  Have an idea to make it easier and better?  Found a dead link?</dt>

  <dd>Please <a href="mailto:ivo.welch@gmail.com?subject=unclear-<%= $ENV{'SYLSPACE_sitename'} %>">let me know</a>.  I cannot guarantee that I will follow it, but I will consider it.</dd>

  <dt>What is SylSpace on <%= $ENV{'SYLSPACE_sitename'} %>?</dt>

  <dd>SylSpace is a third-generation web course management system, with an intentional focus on ease-of-use and simplicity.  The software is SylSpace, the main site designed to run it is <a href="http://syllabus.space">syllabus.space</a>.  (You are currently running it on <a href="<%= "http://".$ENV{'SYLSPACE_sitename'} %>"><%= $ENV{'SYLSPACE_sitename'} %></a> right now.)  There is almost no learning curve involved in using the system.

  <p style="padding-top:1em">Its most important functionalities are:
<ul>
  <li> A messaging system from instructor to students (to avoid spam filters and emails). </li>
  <li> An equiz system to allow instructors to design and post quizzes, in which the question numbers can change with each browser refresh. </li>
  <li> A file posting system, both for tasks and homeworks [with student-uploadable responses] and for useful files (such as a syllabus, a class faq, etc). </li>
  <li> A grading platform which allows instructors to keep track of task grades and allows students to see their grades as they are entered. </li>
  </ul>
  Instructors can ignore facilities that they are not interested in.  Students can enroll in courses with an instructor-set coursesecret (or none if none set).  The typical installation has an open corporate finance course for student self-testing.
  </dd>



  <dt>Do I need to run SylSpace on my own webserver?</dt>

  <dd>No.  Instructors can get accounts on syllabus.space for their classes.  Please contact <a href="mailto:ivo.welch@gmail.com">ivo welch</a>.  The advantage is zero setup costs.  The disadvantage is <b>no</b> guarantees.   (Even google has had downtime on occasions!  Incidentally, other websites typically also do not offer guarantees.)  If you run your site on syllabus.space (rather than on your own web server), you must have some flexibility and tolerance for issues.</dd>

  

  <dt>How should I get started with the equiz language and administration to create and post equizzes?</dt>

  <dd>You can read the <a href="/aboutus">Introduction</a> first.  However, equiz should be so simple that experimentation may save you the 10 minutes reading that this introduction would take.  In the equiz center, just go to the bottom and load the existing "starter" and/or "tutorial" templates. and then look at them (they appear in the directory.

  <p>A typical equiz question would be written into a file and look as follows:

  <table class="table table-sm">
   <tr> <td> <pre> :N: my first question: how to add! </pre> </td> <td> the name of the question (printed at the top). </td> </tr>
   <tr> <td> <pre> :I: $x= rseq(1,10); $y= 2+$x       </pre> </td> <td> draw a random variable from 1 to 10, and assign it to x.  assign 2+x to y. </td> </tr>
   <tr> <td> <pre> :Q: What is 2+$x ?                 </pre> </td> <td> ask the student this question, rendered.  could be rendered as <pre>What is 2+5 ?</pre> </td> </tr>
   <tr> <td> <pre> :A: The answer to 2+$x is $y.      </pre> </td> <td> after the student has answered, explain the correct answer. </td> </tr>
   <tr> <td> <pre> :T: 1  </pre> </td> <td> Advise the student that this question should take about 1 minute to answer </td> </tr>
   <tr> <td> <pre> :P: 0.01 </pre> </td> <td> Accept answers within plus or minus 0.01 of the correct answer (optional) </td> </tr>
   <tr> <td> <pre> :E: </pre> </td> <td> End the question </td> </tr>
  </table>

  <p>A taste of how more complex algorithmic equizzes can look like, with fancy math and entire explanation pages, may be found here:
  <ul>
  <li> Question Render: here is <a href="/html/bs-sample-render.png">what students are asked</a> </li>
  <li> Solution Render:  here is <a href="/html/bs-sample-answer.png">what students are shown after.</a> </li>
  </ul>
  Now comes the quasi-complex part, the writing of the question.  If you know latex, this is much easier, because equizzes use latex syntax.
  <ul>
  <li> Source: here is the <a href="/html/blackscholes.equiz">blackscholes.equiz</a> source that you (the instructor) would write. </li>
  </ul>

  </dd>


  <dt>How should I get started with the rest of the web class management?</dt>

  <dd>Look at it.  It should be self-explanatory.  If it is not, I have failed.</dd>


  <dt>What is my "course-secret"?</dt>

  <dd>You can set it yourself in the <a href="/instructor/cioform">course settings</a>.  It allows an instructor to limit access to students who know the course secret.  Usually, the instructor tells students in the first class.</dd>


  <dt>Why does SylSpace not require or store passwords?</dt>

  <dd>Because we rely on email-address-based authentication via other services, in particular google and facebook.  If the linked google account becomes compromised, so will be the access to syllabus.space.  This is less bad than it sounds, because most websites have a password recovery feature that is also compromised when the email (google) account is compromised.  Put simply, you are toast if you lose control of your email account.</dd>


  <dt>How can I post a syllabus for my students?</dt>

  <dd>Upload a <u>syllabus.pdf</u> and/or <u>syllabus.html</u> file.  A <a href="/html/ifaq/syllabus.html">basic html syllabus is here</a>, my <a href="/html/ifaq/syllabus-sophisticated.html">more sophisticated syllabus is here</a>.  Here is a <a href="/html/ifaq/syllabus-sophisticated.png">snapshot</a> of how it looks for my students.  To start writing your own syllabus, right-click on the syllabus when it has rendered, save as (html) source, and start editing it to your like. <!-- If you want to use this, you have two format choices:  please download the html code (by clicking on view source in your browser), strip everything up to and including the <b>&lt;body&gt;</b> and after the <b>&lt;/body&gt;</b>, and upload this as syllabus.html as your file. --> </dd>


  <dt>Why can my students not see my files (or equizzes or syllabus or homeworks or ...)?</dt>

  <dd>Did you publish them?  Are the students enrolled in your course?  To see which class they are enrolled in, ask them to report to you what they see on the left top of their browser in the black bar.</dd>


  <dt>How can I post a faq (or help) for students?</dt>

  <dd>Upload a <u>faq.html</u> into your instructor directory.  Do not forget to "publish" it.  Otherwise, it will not be visible to your students.</dd>

  <dt>Why are some special files (faq.html, syllabus.html, syllabus.pdf) published immediately upon upload (by default)?</dt>

  <dd>Because this is what you want most of the time when you upload such files.  If you do not want this, just <a href="/instructor/filecenter">change it in the "more" choices.</a>.</dd>


  <dt>Why are files case-insensitive?</dt>

  <dd> Because I found out that users were often confused when they thought they had lost their files, and all they did wrong was to miscapitalize a letter.</dd>


  <dt>How can I post files without/with accepting student response uploads?</dt>

  <dd>The filename identifies the type of file.  If a file does not start with "hw", it does not facilitate student uploads.  After a homework due date expires, uploads are no longer accepted.</dd>


  <dt>Why can students not see my homeworks?</dt>

  <dd>You must choose a homework due date in the future. The default is no due date, so no upload is shown.</dd>


  <dt>Where are the student uploads?</dt>

  <dd>Click on "more" on your assignment and scroll to the bottom.</dd>


  <dt>Why won't my file upload?</dt>

  <dd>The maximum upload limit is 16MB/file.  This is about 100 times the size of this web system itself.  It should be enough.</dd>


  <dt>Is there a grace period for students to upload homeworks or complete equizzes?</dt>

  <dd>No.  But you can choose your own grade period by altering the due date.</dd>


  <dt>What is the maximum upload file size?</dt>

  <dd>1MB/file.  A 100-student class is thus limited to 100MB per assignment.  If you need more, please break it into multiple assignments.</dd>


  <dt>How can I post a help file for the students?</dt>

  <dd>Upload a <u>faq.html</u> file.  Do not forget to publish your syllabus.  Otherwise, it will not be visible to your students.</dd>


  <dt>Can I write my own equizzes?  Can I make changes?</dt>

  <dd>Yes!  This is the whole point.  We have an <a href="/aboutus">intro</a> and a lot of sample files.</dd>


  <dt>Why can my filenames not contain unusual characters?</dt>

  <dd>To avoid mischief and file confusion.  Just rename your file please.  For example, no spaces and slashes, please.</dd>


  <dt>Why must student homework answers start with the same filename as the assignment?</dt>

  <dd>To avoid student mixups.</dd>

  <dt>Why no SQL?</dt>

  <dd>
  <ul>
  <li> Because it is safer.  It removes a whole number of attack vectors. </li>
  <li> Because it allows instructors to download the entire site content in simple ascii format. </li>
  <li> Because the Unix filesystem is plenty fast enough for this kind of application.  This is <i>not</i> a site hammered on my thousands of users simultaneously updating the same files.</li>
  </ul>
  </dd>


  <dt>What file extensions should I use?</dt>

  <dd>Please use <u>.equiz</u> for equizzes.</dd>


  <dt>How do equiz templates work?</dt>

  <dd>Templates are collections of existing equiz files pre-prepared for you.  You can copy them wholesale with the buttons below the filebrowser.  You can also remove them wholesale...except that the files that you have changed or that have student responses are not removed.  (You have to remove those by hand in the "more" pages.)</dd>

  <dt>Can I create my own equiz templates?</dt>

  <dd>Yes and no.  templates are just collection of equiz files, so you can easily upload and download them.  However, we have not yet made this a website administerable button feature.  If there is demand, we will.</dd>


  <dt>Can I contributes equiz templates?</dt>

  <dd>Very much so.  Please do.  I welcome more templates.  Email me when you have done so.  You need to give me permission to redistribute them, though.</dd>

  <dt>Can I have multiple classes or accounts</dt>

  <dd>
    <p>As for me, I prefer to name each class by its own subdomain, like
      <pre>
         http://<b>mba230.welch</b>.syllabus.space<br />
         http://<b>mba230-14a.welch</b>.syllabus.space
      </pre>
     This way, I can have my one webbrowser access multiple class sites, too&mdash;each class is its own domain.</p>
  </dd>

  <dt>Can I get my logo onto the students web page instead of the equiz avatar?</dt>

  <dd>Not yet.</dd>


  <dt>How can I see exactly what my students see?</dt>

  <dd>At the bottom of the page, you can morph to turn yourself into a student.  However, it is not a bad idea to create a student test-account to have a perfect match.</dd>


  <dt>Can my students see the homework grades I assigned?</dt>

  <dd>Yes.  Each student can see her grades.  If you want to record them privately, please use an off-line spreadsheet.  (Important: Make backup copies!)</dd>


  <dt>Can I or my students see basic class activity without having to log in?</dt>

  <dd> <p> Yes and no.  They have to be authenticated as some user, but they do not need to be enrolled.  This information is rather limited.</p>

   </dd>

  <dt>What are we (quasi-)tweeting?</dt>

  <dd>It may change, but right now we are tweeting when the instructor posts a new file or message, or updates class info; and student new registration as well as (homework or equiz) response posts (but without scores).</dd>


  <dt>Can I run a survey?</dt>

  <dd>Turned off now.  This is an undocumented "feature".  If you name an equiz with ".survey", a special flag is thrown that collects student answers but does not grade them.  The syntax is pretty much the same as for an equiz.  There are questions and messages.  You can publish your survey, just like an equiz.</dd>


  <dt>I found a bug!</dt>

  <dd>Please email a precise instruction how to replicate it to <a href="mailto:ivo.welch@gmail.com?subject=bug">ivo.welch@gmail.com</a>.  I want to know about it.  There are probably some Heisenbugs in the system that we still need to simmer out.</dd>

</dl>


<hr />

<h2>Developer Info</h2>

<dl>

  <dt>How difficult is it to run my own equiz server?</dt>

  <dd>The code (on <a href="https://github.com/iwelch/sylspace">github sylspace</a>) is tight and self-contained.  There is no reliance on an sql server and everything is in ascii format.  after installing all the perl modules, run the init script and the testsite creation script.</p>

  <pre>
  # perl initsylspace.pl
  # perl mksite.pl testsite you@emailhost
  # morbo -v Sylspace  ## and now open http://localhost:3000/ on your browser  </pre>

a  <p><tt>/var/sylspace</tt> is hardcoded in 2-3 places.  If you do not want to use this, you need to fix it.  There are a very few hardcodes to syllabus.space (e.g., the SylSpace-Secrets.conf and the systemd configuration files).  I do not believe that <tt>http://*syllabus.space</tt> is hardcoded anywhere, but some of the documentation refers to it as the server on which it runs.</p>

  <p>Because all content is stored in the unix filesystem, it is easy for an instructor to view and interpret all of his/her data, too.  It also makes debugging a lot easier.</p>

  </dd>


  <dt>Is equiz not too complex to maintain?</dt>

  <dd>This v3 equiz website is focussing on essentials and is well organized.
  <ul>
  <li>The main model (backend) code is under 1,500 lines of perl code (50KB).</li>
  <li>The controller (frontend) code is under 5,000 lines of (mostly html) code (150KB).</li>
  </ul>
  </dd>


  <dt>What is the software license?</dt>

  <dd>The SylSpace software is free under the <a href="https://choosealicense.com/licenses/agpl-3.0/">GNU AGPLv3</a> license.</dd>

</dl>


<h1> Site FAQ </h1>

  <%== $allfaq %>


<h1> Student FAQ </h1>

  <%== $isfaq %>

</main>


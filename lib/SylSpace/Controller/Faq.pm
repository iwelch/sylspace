#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::Faq;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################

get '/faq' => sub {
  my $c = shift;

  use Perl6::Slurp;
  my $sitewide= slurp("public/html/faq.html");
  $sitewide =~ s{.*<sitewide>(.*)</sitewide>}{$1}ms;

  $c->stash( allfaq => $sitewide, template => 'faq' );
};

1;

################################################################

__DATA__

@@ faq.html.ep

%title 'faq';
%layout 'both';

<main>

<dl>

  <dt>What is <%= $ENV{'SYLSPACE_appname'} %> on <%= $ENV{'SYLSPACE_sitename'} %>?</dt>

  <dd>It is a third-generation web course management system, with an intentional focus on ease-of-use and simplicity.  The webapp software is <%= $ENV{'SYLSPACE_appname'} %>, the main site designed to run it is <a href="http://syllabus.space">syllabus.space</a>.  (You are currently running it on <a href="<%= $ENV{'SYLSPACE_sitename'} %>"><%= $ENV{'SYLSPACE_sitename'} %></a> right now.)  There is almost no learning curve involved in using the system.

  <p style="padding-top:1em">Its most important functionalities are:
<ul>
  <li> A messaging system from instructor to students (to avoid spam filters and emails). </li>
  <li> An equiz system to allow instructors to design and post quizzes, in which the question numbers can change with each browser refresh. </li>
  <li> A file posting system, both for tasks and homeworks [with student-uploadable responses] and for useful files (such as a syllabus, a class faq, etc). </li>
  <li> A grading platform which allows instructors to keep track of task grades and allows students to see their grades as they are entered. </li>
  <li> Addable links to further content elsewhere.
  </ul>
  Instructors can ignore facilities that they are not interested in.  Students can enroll in courses only with an instructor-set coursesecret when set (or any if none set).  The typical webapp comes with the corporate finance course for student self-testing without course password.
  </dd>

</dl>

<hr />

  <%== $allfaq %>

<hr />

  <p> More FAQ information is provided to logged-in users. </p>

</main>


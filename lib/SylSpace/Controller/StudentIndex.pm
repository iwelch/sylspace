#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::StudentIndex;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(ciobuttons msgshownotread ismorphed isenrolled bioiscomplete showlasttweet);
use SylSpace::Model::Controller qw(global_redirect  standard msghash2string);

################################################################

my $shm= sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  my $curdomainport= $c->req->url->to_abs->domainport;

  (bioiscomplete($c->session->{uemail}))
    or $c->flash( message => 'You first need to complete your bio!' )->redirect_to("http://auth.$curdomainport/usettings");

  (isenrolled($course, $c->session->{uemail})) or $c->flash( message => "first enroll in $course please" )->redirect_to('/auth/goclass');

  $c->stash(
	    msgstring => msghash2string(msgshownotread( $course, $c->session->{uemail} ), "/msgmarkasread"),
	    btnptr => ciobuttons( $course )||undef,
	    ismorphed => ismorphed( $course,$c->session->{uemail} ),
	    lasttweet => showlasttweet( $course )||"",
	    template => 'student',
	   );

};

get '/student/index.html' => $shm;
get '/student/index' => $shm;
get '/student' => $shm;

1;

################################################################

__DATA__

@@ student.html.ep

<% use SylSpace::Model::Controller qw(btnblock); %>

%title 'student';
%layout 'student';

<main>

  <%== $msgstring %>

  <nav>

   <div class="row top-buffer text-center">
     <%== btnblock("/student/quickinfo", '<i class="fa fa-info-circle"></i> Quick', 'Location, Instructor') %>
     <%== btnblock("/student/equizcenter", '<i class="fa fa-pencil"></i> Equizzes', 'Test Yourself') %>
     <%== btnblock("/student/hwcenter", '<i class="fa fa-folder-open"></i> HWork', 'Assignments') %>
     <%== btnblock("/student/filecenter", '<i class="fa fa-files-o"></i> Files', 'Old Exams, etc') %>

     <%== btnblock("/student/gradecenter", '<i class="fa fa-star"></i> Grades', 'Saved Scores') %>
     <%== btnblock("/student/msgcenter", '<i class="fa fa-paper-plane"></i> Messages', 'From Instructor') %>

     <%== btnblock("/showseclog", '<i class="fa fa-lock"></i> Sec Log', 'Security Records') %>
     <%== btnblock("/showtweets", '<i class="fa fa-rss"></i> Class', 'Activity Monitor') %>

     <%== btnblock("/student/faq", '<i class="fa fa-question-circle"></i> Help', 'FAQ and More') %>

     <%== btnblock("/auth/bioform", '<i class="fa fa-cog"></i> Bio <i class="fa fa-link"></i>', 'Set My Profile') %>

    </div>


  <%== btnstring($btnptr) %>

  <%== $ismorphed ? '<div class="row top-buffer text-center">
    <div class="col-md-10 col-md-offset-1">
          <a class="btn btn-primary btn-block" href="/student/student2instructor">
		<h2> <i class="fa fa-graduation-cap"></i> Unmorph Back To Instructor</h2></a>
      </div>
    </div>' : ""
  %>

  </nav>

  <%== $lasttweet %>

</main>

<% sub btnstring {
  my $btnptr= shift;
  my $btnstring="";
  if (defined($btnptr)) {
    $btnstring= '<div class="row top-buffer text-center">';
    my $numbuttons= scalar @{$btnptr};
    foreach (@$btnptr) { $btnstring .= btnblock($_->[0], $_->[1], $_->[2]); }
    $btnstring .= "</div>\n";
  }
  return $btnstring;
} %>

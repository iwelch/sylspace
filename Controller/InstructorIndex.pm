#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::InstructorIndex;
use Mojolicious::Lite;  ## implied strict, warnings, utf8, 5.10
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo ciobuttons msgshownotread bioiscomplete cioiscomplete showlasttweet);
use SylSpace::Model::Controller qw(global_redirect standard msghash2string global_redirect);

################################################################

my $ihm= sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

  my $curdomainport= $c->req->url->to_abs->domainport;

  (bioiscomplete($c->session->{uemail}))
    or $c->flash( message => 'You first need to complete your bio!' )->redirect_to("http://auth.$curdomainport/usettings");

  (cioiscomplete($course)) or $c->flash( message => 'You first need to complete the course settings!' )->redirect_to('/instructor/cioform');

  $c->stash(
	    msgstring => msghash2string(msgshownotread( $course, $c->session->{uemail} ), "/msgmarkasread"),
	    btnptr => ciobuttons( $course )||undef,
	    lasttweet => showlasttweet( $course )||"no tweet yet",
	    template => 'instructor',
	   );
};

get '/instructor/index.html' => $ihm;
get '/instructor/index' => $ihm;
get '/instructor' => $ihm;


1;


################################################################


__DATA__

@@ instructor.html.ep

<% use SylSpace::Model::Controller qw(btnblock); %>

%title 'instructor';
%layout 'instructor';

<main>


  <%== $msgstring %>

  <nav>

   <div class="row top-buffer text-center">
     <%== btnblock("/instructor/msgcenter", '<i class="fa fa-paper-plane"></i> Messages', 'Msgs to Students') %>
     <%== btnblock("/instructor/equizcenter", '<i class="fa fa-pencil"></i> Equizzes', 'Algorithmic Testing') %>
     <%== btnblock("/instructor/hwcenter", '<i class="fa fa-folder-open"></i> HWorks', 'Assignments') %>
     <%== btnblock("/instructor/filecenter", '<i class="fa fa-files-o"></i> Files', 'Old Exams, etc') %>

     <%== btnblock("/instructor/studentdetailedlist", '<i class="fa fa-users"></i> Students', 'Enrolled List') %>
     <%== btnblock("/instructor/gradecenter", '<i class="fa fa-star"></i> Grades', 'Saved Scores') %>
     <%== btnblock("/instructor/cioform", '<i class="fa fa-wrench"></i> Course', 'Set Class Parameters') %>
     <%== btnblock("/instructor/instructorlist", '<i class="fa fa-magic"></i> TAs', 'Set Assistants') %>

     <%== btnblock("/showtweets", '<i class="fa fa-rss"></i> Class', 'Activity Monitor') %>
     <%== btnblock("/showseclog", '<i class="fa fa-lock"></i> Sec Log', 'Security Records') %>
     <%== btnblock("/instructor/faq", '<i class="fa fa-question-circle"></i> Help', 'FAQ and More') %>
     <%== btnblock("/instructor/sitebackup", '<i class="fa fa-cloud-download"></i> Backup', 'Backup My Account') %>

     <%== btnblock("/auth/bioform", '<i class="fa fa-cog"></i> Bio <i class="fa fa-link"></i>', 'Set My Profile') %>
   </div>

  <%== btnstring($btnptr) %>

  <div class="row top-buffer text-center">
    <div class="col-md-10 col-md-offset-1">
         <a class="btn btn-primary btn-block" href="/instructor/instructor2student">
		<h2> <i class="fa fa-graduation-cap"></i> Morph Into Student</h2></a>
    </div>
  </div>

  </nav>

  <%== $lasttweet %>

</main>

<% sub btnstring {
  my $btnptr= shift;
  (defined($btnptr)) or return "";

  my $btnstring="";
  if (defined($btnptr)) {
    $btnstring= '<div class="row top-buffer text-center">';
    my $numbuttons= scalar @{$btnptr};
    foreach (@$btnptr) { $btnstring .= btnblock($_->[0], $_->[1], $_->[2]); }
    $btnstring .= "</div>\n";
  }
  return $btnstring;
} %>

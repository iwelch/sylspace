#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::InstructorEquizcenter;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use feature ':5.20';
use feature 'signatures';
no warnings qw(experimental::signatures);

use SylSpace::Model::Model qw(sudo tzi);
use SylSpace::Model::Files qw(eqlisti listtemplates eqsetdue);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################

get '/instructor/equizcenter' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

  $c->stash(
	    filelist => eqlisti($course),
	    templatelist => listtemplates(),
	    tzi => tzi( $c->session->{uemail} ) );
};

get '/instructor/equizpublishall' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);
  sudo( $course, $c->session->{uemail} );
  
  my $filelist = eqlisti($course);
  my $count = 0;
  my $future = time() + 180*24*60*60;  # 6 months from now
  foreach my $f (keys %$filelist) {
    eqsetdue($course, $f, $future);
    $count++;
  }
  $c->flash( message => "Published all $count equizzes (due date set to 6 months from now)" )->redirect_to('/instructor/equizcenter');
};

get '/instructor/equizunpublishall' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);
  sudo( $course, $c->session->{uemail} );
  
  my $filelist = eqlisti($course);
  my $count = 0;
  foreach my $f (keys %$filelist) {
    eqsetdue($course, $f, 0);
    $count++;
  }
  $c->flash( message => "Unpublished all $count equizzes (due date set to 0)" )->redirect_to('/instructor/equizcenter');
};

1;


################################################################

__DATA__

@@ instructorequizcenter.html.ep

<% use SylSpace::Model::Controller qw(ifilehash2table fileuploadform dropzoneform); %>

%title 'equiz center';
%layout 'instructor';

<main>

  <h1> Equiz Center </h1>

  <%== ifilehash2table($filelist, [ 'equizrun', 'view', 'download', 'edit' ], 'equiz', $tzi) %>

  <div class="form-group" id="narrow" style="margin-top:1em; margin-bottom:1em;">
    <div class="row" style="text-align:center;">
       <div class="col-xs-3"><a href="/instructor/equizpublishall" class="btn btn-success btn-block">Publish All</a></div>
       <div class="col-xs-3"><a href="/instructor/equizunpublishall" class="btn btn-warning btn-block">Unpublish All</a></div>
       <div class="col-xs-6"><a href="/instructor/rmtemplates" class="btn btn-default btn-block">Remove All Unchanged Unpublished Template Files</a></div>
    </div>
  </div>

  <%== dropzoneform() %>

  <%== fileuploadform() %>

<hr />

  <h3 style="margin-top:2em"> Equiz Basics </h3>

   <h4>Load Existing Templates</h4>

  <div class="form-group" id="narrow">
    <div class="row" style="text-align:center;color:black">
       <%
          my $rv= "";
          foreach (@$templatelist) {
	    $rv .= '<div class="col-xs-2" style="margin-bottom:10px;"> <a href="/instructor/cptemplate?templatename='.$_.'" class="btn btn-default btn-block">'.$_.'</a></div>'."\n";
	  }
       %>
       <%== $rv %>
    </div> <!--row-->
  </div> <!--formgroup-->


  <h4> Designing Your Own </h4>

  <div class="form-group" id="narrow">
    <div class="row" style="color:black">
      <div class="col-xs-offset-1 col-xs-4"> <a href="/testquestion" class="btn btn-default">quick test any question</a></div>
    </div> <!--row-->
  </div> <!--formgroup-->

  <p> To learn more about equizzes, please read the <a href="/aboutus"> intro </a>, and copy the set of sample templates into your directory for experimentation and examples.  </p>


</main>



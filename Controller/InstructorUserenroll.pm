#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::InstructorUserenroll;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo userenroll usernew);
use SylSpace::Model::Controller qw(standard global_redirect);

################################################################

get '/instructor/userenroll' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

  my $newstudent= $c->req->query_params->param('newuemail');
  (defined($newstudent)) or die "silly you.  I need a student!\n";

  usernew( $newstudent );
  userenroll( $course, $newstudent, 1 );

  $c->flash(message => "Added new student '$newstudent'" )->redirect_to( $c->req->headers->referrer );
};

1;

################################################################

__DATA__

@@ instructoruserenroll.html.ep

%title 'enroll a student';
%layout 'instructor';

<main>

<h1>Not Yet</h1>

</main>


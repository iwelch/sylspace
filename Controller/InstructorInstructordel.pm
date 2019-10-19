#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::InstructorInstructordel;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo instructordel);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/instructor/instructordel' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

  my $ne=$c->req->query_params->param('deliemail');

  instructordel( $course, $c->session->{uemail}, $ne );
  $c->flash( message => "unset $ne as an instructor" )->redirect_to('/instructor/instructorlist')
};

1;

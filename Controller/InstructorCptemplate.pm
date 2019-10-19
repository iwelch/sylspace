#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::InstructorCptemplate;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo);
use SylSpace::Model::Files qw(cptemplate);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/instructor/cptemplate' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

  my $templatename= $c->req->query_params->param('templatename');

  ## && ($course !~ /fin/)
  ## (($templatename eq /corpfinintro/)) and die "only fin classes are allowed to use the corpfinintro template";

  my $nc= cptemplate( $course, $templatename );

  return $c->flash( message => "copied $nc equiz files from template $templatename")->redirect_to( 'equizcenter' );
};

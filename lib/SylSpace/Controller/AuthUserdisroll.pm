#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::AuthUserdisroll;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(userdisroll tweet);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/auth/userdisroll' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  my $coursename= $c->req->query_params->param('c');
  (defined($coursename)) or die "please give good course name";

  userdisroll( $coursename, $c->session->{uemail} );

  tweet($c->tx->remote_address, $coursename, $c->session->{uemail}, " now enrolled in course $coursename\n" );

  return $c->flash( message => "you have disabled yourself in course '$coursename'" )->redirect_to('/auth/goclass');
};

1;

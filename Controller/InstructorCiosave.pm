#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::InstructorCiosave;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(ciosave sudo tweet);
use SylSpace::Model::Controller qw(standard global_redirect);

################################################################

post '/instructor/ciosave' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

  ciosave( $course, $c->req->body_params->to_hash ) or die "evil submission\n";

  tweet($c->tx->remote_address, $course, $c->session->{uemail}, "updated course settings" );
  $c->flash(message => "Updated Course Settings")->redirect_to("/instructor");
};

1;

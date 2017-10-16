#!/usr/bin/env perl
package SylSpace::Controller::Equizrate;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(equizrate tweet);
use SylSpace::Model::Controller qw(standard global_redirect);

################################################################

get '/equizrate' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  equizrate( $c->tx->remote_address, $course, $c->req->params->to_hash ) or die "evil submission\n";

  # tweet($c->tx->remote_address, $course, $c->session->{uemail}, "updated course settings" );
  $c->flash(message => "Thank you for your equiz rating")->redirect_to("/student/equizcenter");
};

1;

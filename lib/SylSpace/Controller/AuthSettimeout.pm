#!/usr/bin/env perl
package SylSpace::Controller::AuthSettimeout;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/auth/settimeout' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  my $timeout= $c->req->query_params->param('tm');

  $c->session(expiration => time()+$timeout*3600*24);

  $c->flash( message => "Set Timeout to $timeout days" )->redirect_to($c->req->headers->referrer);
};

1;

#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::AuthUserenrollsave;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(userenroll getcoursesecret tweet);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

post '/auth/userenrollsave' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  my $coursename= $c->req->body_params->param('course');
  my $secret= $c->req->body_params->param('secret');

  (defined($coursename)) or die "wtf";
  my $isecret= getcoursesecret($coursename);

  (defined($isecret)) and ((lc($isecret) eq lc($secret)) or
    return $c->flash( message => "$secret is so not the right secret for course $coursename" )->redirect_to('/auth/userenrollform?c='.$coursename));

  userenroll($coursename, $c->session->{uemail});

  tweet($c->tx->remote_address, $coursename, $c->session->{uemail}, " now enrolled in course $coursename\n" );

  return $c->flash( message => "you are now enrolled in course '$coursename'" )->redirect_to('/auth/goclass');
};

################

get '/auth/userenrollsavenopw' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  my $coursename= $c->req->query_params->param('course');

  (defined($coursename)) or die "wtf";
  my $actualsecret=getcoursesecret($coursename);
  print STDERR "UESNPW: $actualsecret\n";
  (defined($actualsecret)) and die "sorry, but this course $coursename has a secret, so you cannot enroll without it!";

  userenroll($coursename, $c->session->{uemail});

  tweet($c->tx->remote_address, $coursename, $c->session->{uemail}, " now enrolled in no-secret course $coursename\n" );

  return $c->flash( message => "you are now enrolled in course '$coursename'" )->redirect_to('/auth/goclass');
};


1;

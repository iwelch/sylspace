#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::AuthIndex;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(bioiscomplete userexists usernew);

################################################################
#  gets in /auth/: authenticator bioform goclass index.html index sendmail/callback settimeout test userenrollform;
#  posts in /auth/: biosave localverify sendmail/authenticate userenrollsave
################

my $authroot= sub {
  my $c = shift;

  (defined($c->session->{uemail})) or return $c->flash(message => "you had no identity.  please authenticate")->redirect_to('/auth/authenticator');

  (defined($c->session->{expiration})) or return $c->flash(message => $c->session->{uemail}." is now a zombie. please authenticate")->redirect_to('/auth/authenticator');
  (time()< $c->session->{expiration}) or return $c->flash(message => "you expired. please authenticate")->redirect_to('/auth/authenticator');

  my $completelynew="";
  if (!(userexists($c->session->{uemail}))) {
    usernew($c->session->{uemail});  ## a completely new user; we could use google info to prepopulate bioform
    $completelynew=", first timer.  you were just created";;
  }

  (bioiscomplete($c->session->{uemail})) or return $c->flash(message => "please complete your bio first")->redirect_to('/auth/bioform');

  return $c->flash(message => "hello ".$c->session->{uemail}."$completelynew.")->redirect_to('/auth/goclass');
};

get '/auth/index.html' =>  $authroot;
get '/auth/index' =>  $authroot;
get '/auth/' =>  $authroot;

1;

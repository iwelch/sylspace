#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::Login;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

get '/login' => sub {
  my $c = shift;

  ($ENV{'SYLSPACE_onlocalhost'}) or die "Sorry, but /Login works on localhost for testing purposes\n";

  $c->session->{uemail}= $c->req->query_params->param('email');
  $c->session->{expiration}= time()+3600*24*365;
  $c->session->{ishuman}= time().":".$c->session->{uemail};

  my $curdomainport= $c->req->url->to_abs->domainport;
  $c->flash(message => "we have made you ".$c->session->{uemail})->redirect_to("http://auth.$curdomainport/auth/goclass");
};

1;

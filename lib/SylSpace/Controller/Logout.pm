#!/usr/bin/env perl

package SylSpace::Controller::Logout;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

my $logout = sub {
  my $c = shift;
  my $logoutemail= $c->session->{uemail} || "no email yet";
  $c->session->{uemail}=undef;
  $c->session->{uexpiration}= undef;

  my $curdomainport= $c->req->url->to_abs->domainport;
  $c->flash(message => "$logoutemail logged out")->redirect_to("http://auth.$curdomainport/auth/index");
};

get '/logout' => $logout;

1;

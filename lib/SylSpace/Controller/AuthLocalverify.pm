#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::AuthLocalverify;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

post '/auth/localverify' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  my $uemail= $c->req->body_params->param('uemail');
  my $pw= $c->req->body_params->param('pw');

  $c->session->{uemailhint}= $uemail;

  my $exists= `./requestauthentication`;
  ($exists eq "we exist") or die "cannot find executable requestauthentication".($exists||"--")." in ".`pwd`."\n";

  _confirmnotdangerous($uemail, "email $uemail");
  _confirmnotdangerous($pw, "pw $pw");

  my $ask= `requestauthentication $uemail $pw`;
  ($ask eq $uemail) or die "sorry, but you provided a non-working user password combination!\n";

  $c->session->{uemail} = $uemail;

  $c->flash( message => "you have successfully authenticated as $uemail" )->redirect_to('/auth');
};

1;

sub _confirmnotdangerous {
  my ( $string, $warning )= @_;
  ($string =~ /\;\&\|\>\<\?\`\$\(\)\{\}\[\]\!\#\'/) and die "$warning fails!";  ## we allow '*'
  return $string;
}

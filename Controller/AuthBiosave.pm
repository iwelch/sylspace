#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::AuthBiosave;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(biosave);
use SylSpace::Model::Controller qw(standard global_redirect);

################################################################

post '/auth/biosave' => sub {

  my $c = shift;
print '\n\n';
	print $c;
print '\n\n';
print standard($c);
print '\n\n';
  (my $course = standard( $c )) or return global_redirect($c);

  biosave( $c->session->{uemail}, $c->req->body_params->to_hash ) or die "evil bio submission\n";

  $c->flash(message => "Updated Biographical Settings")->redirect_to("/auth/goclass");
};

1;

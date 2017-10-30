#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::InstructorFiledelete;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo);
use SylSpace::Model::Files qw(filedelete);
use SylSpace::Model::Controller qw(standard global_redirect);

################################################################

get '/instructor/filedelete' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

  my $fname= $c->req->query_params->param('f');

  filedelete( $course, $fname);

  ## we cannot go back, because the page no longer exists! return $c->redirect_to($c->req->headers->referrer);
  return $c->flash( message=> "completely deleted file $fname" )->redirect_to( ''.(($fname =~ /^hw/) ? 'hwcenter' : ($fname =~ /\.equiz$/) ? 'equizcenter' : 'filecenter'));
};

1;

#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::InstructorEquizsaveajax;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo);
use SylSpace::Model::Files qw(eqwrite);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

post '/instructor/equizsaveajax' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return $c->render(json => { ok => 0, error => 'not authorized' });

  sudo( $course, $c->session->{uemail} );

  my $fname = $c->req->params->param('fname');
  my $content = $c->req->params->param('content') // '';
  
  $content =~ s/\r\n/\r/g;
  $content =~ s/\r/\n/g;

  eval {
    eqwrite( $course, $fname, $content );
  };
  if ($@) {
    return $c->render(json => { ok => 0, error => "Save failed: $@" });
  }

  return $c->render(json => { ok => 1, message => "Saved $fname" });
};

1;

#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::InstructorView;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model  qw(sudo);
use SylSpace::Model::Files qw(filereadi);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################

plugin 'RenderFile';  ## ask viktor why $c->render_file is not seen

get '/instructor/view' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

  my $fname= $c->req->query_params->param('f');
  my $filecontent= filereadi( $course, $fname );

  (defined($filecontent)) or return $c->flash(message => "file $fname cannot be found")->redirect_to($c->req->headers->referrer);
  (length($filecontent)>0) or return $c->flash(message => "file $fname was empty")->redirect_to($c->req->headers->referrer);

  (my $extension= $fname) =~ s{.*\.}{};

  return ($fname =~ /\.(txt|html|htm|text|csv)$/i) ? $c->render(text => $filecontent, format => 'txt') :
    $c->render(data => $filecontent, format => $extension);
};

1;

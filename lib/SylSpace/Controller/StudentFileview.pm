#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::StudentFileview;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(isenrolled);
use SylSpace::Model::Files qw(filereads);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################
## this is viewing instructor files, not student's own files

plugin 'RenderFile';  ## ask viktor why $c->render_file is not seen

get '/student/fileview' => sub {
  my $c = shift;

  (my $course = standard( $c )) or return global_redirect($c);

  (isenrolled($course, $c->session->{uemail})) or $c->flash( message => "first enroll in $course please" )->redirect_to('/auth/goclass');

  my $fname= $c->req->query_params->param('f');
  my $filecontent= filereads( $course, $fname );

  (defined($filecontent)) or return $c->flash(message => "file $fname cannot be found")->redirect_to($c->req->headers->referrer);
  (length($filecontent)>0) or return $c->flash(message => "file $fname was empty")->redirect_to($c->req->headers->referrer);

  (my $extension= $fname) =~ s{.*\.}{};

  return ($fname =~ /\.(txt|text|csv)$/i) ? $c->render(text => $filecontent, format => 'txt') :
    $c->render(data => $filecontent, format => $extension);
};

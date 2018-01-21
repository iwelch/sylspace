#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::InstructorEditsave;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo);
use SylSpace::Model::Files qw(eqwrite);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################

post 'instructor/editsave' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

  my $fname= $c->req->params->param('fname');

  my $content= $c->req->params->param('content');
  $content =~ s/\r\n/\r/g;
  $content =~ s/\r/\n/g;

  use Digest::MD5 qw(md5_hex);
  use utf8;

  my $reportaction="unknown";
  my $md5hexincontent= (utf8::is_utf8($_)) ? Encode::encode_utf8($_) : $_;
  if (md5_hex($md5hexincontent) eq $c->req->params->param('fingerprint')) {
    $c->flash( message=> "file $fname was unchanged and thus not updated" );
  } else {
    eqwrite( $course, $fname, $content );
    $c->flash( message=> "file $fname was changed and thus updated" );
  }
  $c->redirect_to("/instructor/equizmore?f=$fname");
};

1;

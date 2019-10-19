#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::InstructorSilentdownload;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo);
use SylSpace::Model::Files qw(longfilename);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################

get 'instructor/silentdownload' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

  plugin 'RenderFile';  ## ask viktor why $c->render_file is not seen

  my $fname = $c->req->query_params->param('f');
  my $longfilename;
  if (($fname =~ /.zip$/) && ($fname =~ m{/tmp/})) {
    $longfilename = $fname;
  } else {
    $fname =~ s{.*/}{};
    $longfilename= longfilename( $course, $fname);
    (-e $longfilename) or die "file $longfilename is not retrievable: $!\n";
  }

  return $c->render_file('filepath' => $longfilename);
};

#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::InstructorDownload;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################

get 'instructor/download' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

  plugin 'RenderFile';  ## ask viktor why $c->render_file is not seen

  my $fname=  $c->req->query_params->param('f');
  (defined($fname)) or die "need a filename for instructordownload.pm.\n";

  $c->stash( filename => $fname );
};

1;

################################################################

__DATA__

@@ instructordownload.html.ep

%title 'download a file';
%layout 'instructor';

<main>

<meta http-equiv="refresh" content="1;url=silentdownload?f=<%=$filename%>">

Your file content will download asap.  If not, click <a href="silentdownload?f=<%=$filename%>">silentdownload?f=<%=$filename%></a>.

</main>

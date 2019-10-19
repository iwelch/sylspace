#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::InstructorFilemore;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo tzi);
use SylSpace::Model::Files qw(filelisti);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/instructor/filemore' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

  my $fname=  $c->req->query_params->param('f');
  (defined($fname)) or die "need a filename for filemore.\n";

  $c->stash( detail => filelisti($course, $fname),  ## fname is a mask
	     tzi => tzi( $c->session->{uemail} ) );
};

1;

################################################################

__DATA__

@@ instructorfilemore.html.ep

<% use SylSpace::Model::Controller qw(drawmore webbrowser); %>

%title 'more file information';
%layout 'instructor';

<main>

  <%== drawmore($detail->[0]->{sfilename}, 'file', [ 'view', 'download', 'edit' ], $detail, $tzi, webbrowser($self)); %>

</main>


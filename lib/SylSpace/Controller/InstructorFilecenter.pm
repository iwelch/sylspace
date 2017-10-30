#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::InstructorFilecenter;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use feature ':5.20';
use feature 'signatures';
no warnings qw(experimental::signatures);

use SylSpace::Model::Model qw(sudo tzi);
use SylSpace::Model::Files qw(filelisti);
use SylSpace::Model::Controller qw(global_redirect  standard);


get '/instructor/filecenter' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

  $c->stash( filelist => filelisti($course),
	     tzi => tzi( $c->session->{uemail} )  ); ## X means not hw and not equiz
};


1;

################################################################

__DATA__

@@ instructorfilecenter.html.ep

<% use SylSpace::Model::Controller qw( ifilehash2table fileuploadform); %>

%title 'file center';
%layout 'instructor';

<main>
  

  <%== ifilehash2table($filelist, [ 'view', 'download', 'edit' ], 'file', $tzi) %>

  <%== fileuploadform() %>

</main>

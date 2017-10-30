#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::InstructorHwcenter;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use feature ':5.20';
use feature 'signatures';
no warnings qw(experimental::signatures);

use SylSpace::Model::Model qw(sudo tzi);
use SylSpace::Model::Files qw(hwlisti);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################
get '/instructor/hwcenter' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

  my $tzi = tzi( $c->session->{uemail} );

  $c->stash( filetable => hwlisti($course),
	     tzi => $tzi  );
};




1;

################################################################

__DATA__

@@ instructorhwcenter.html.ep

<% use SylSpace::Model::Controller qw( ifilehash2table fileuploadform); %>

%title 'homework center';
%layout 'instructor';

<main>

  <%== ifilehash2table($filetable,  [ 'view', 'download', 'edit' ], 'hw', $tzi) %>

  <%== fileuploadform() %>

</main>

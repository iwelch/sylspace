#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::Showtweets;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(showtweets isinstructor);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/showtweets' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  $c->stash(toprightexit => '<li><a href="/auth/goclass"> <i class="fa fa-sign-out"></i> Exit Course </a></li>');

  if (isinstructor($course, $c->session->{uemail})) {
    $c->stash( bgcolor => $ENV{SYLSPACE_siteicolor}, homeurl => '/instructor' );
  } else {
    $c->stash( bgcolor => $ENV{SYLSPACE_sitescolor}, homeurl => '/student' );
  }

  ## enrollment not required
  $c->stash( tweets => showtweets($course)||undef );
};

1;

################################################################

__DATA__

@@ showtweets.html.ep

<% use SylSpace::Model::Controller qw(displaylog); %>

%title 'course activity';
%layout 'both';

<main>

  <%== defined($tweets) ? displaylog($tweets) : "(no tweets yet)" %>

</main>


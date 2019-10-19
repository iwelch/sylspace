#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::Equizgrade;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(isenrolled equizgrade equizanswerrender);
use SylSpace::Model::Grades qw(storegradeequiz);
use SylSpace::Model::Controller qw(standard global_redirect);

################################################################

post '/equizgrade' => sub {
  my $c = shift;

  (my $course = standard( $c )) or return global_redirect($c);

  (isenrolled($course, $c->session->{uemail})) or $c->flash( message => "first enroll in $course please" )->redirect_to('/auth/goclass');

  my $result= equizgrade($course, $c->session->{uemail}, $c->req->body_params->to_hash);
  ## _storegradeequiz( $course, $uemail, $gradename, $eqlongname, $time, "$score / $i" );
  storegradeequiz( $course, $c->session->{uemail}, $result->[4], $result->[5], $result->[3], $result->[1]." / ". $result->[0] );

  $c->stash( eqanswer => equizanswerrender($result) );
};

1;

################################################################

__DATA__

@@ equizgrade.html.ep

%title 'show equiz results';
%layout 'both';

<main>

<h1>Equiz Results</h1>

<%== $eqanswer %>

</main>


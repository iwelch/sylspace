#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::StudentMsgcenter;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(msglistread isenrolled msgread);
use SylSpace::Model::Controller qw(global_redirect standard  msghash2string);

################################################################

get '/student/msgcenter' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  (isenrolled($course, $c->session->{uemail})) or $c->flash( message => "first enroll in $course please" )->redirect_to('/auth/goclass');

  my @msglistread= msglistread($course, $c->session->{uemail});
  $c->stash( msgstring => msghash2string(msgread( $course ), "/msgmarkasread", \@msglistread ) );
};

1;

################################################################

__DATA__

@@ studentmsgcenter.html.ep

%title 'message center';
%layout 'student';

<main>

<h2> All Previously Posted Messages </h2>

<%== $msgstring %>

</main>


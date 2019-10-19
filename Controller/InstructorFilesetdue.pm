#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::InstructorFilesetdue;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo tweet tzi);
use SylSpace::Model::Files qw(filesetdue);
use SylSpace::Model::Controller qw(global_redirect  standard epochof epochtwo);

################################################################

use Mojo::Date;

get '/instructor/filesetdue' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

  my $params= $c->req->query_params;

  my $whendue= ($params->param('dueepoch')) ||
    epochof( $params->param('duedate'), $params->param('duetime'), tzi($c->session->{uemail}) );

  my $r= filesetdue( $course, $params->param('f'), $whendue );

  tweet($c->tx->remote_address, $course, $c->session->{uemail}, ' published '. $params->param('f'). ", due $whendue (GMT ".gmtime($whendue).')' );

  my $msg= # ($params->param('dueepoch')) ? "set due to 6 months" : 
    "set due to ".epochtwo( $whendue || 0);
  $c->flash(message => $msg)->redirect_to($c->req->headers->referrer);
};


1;

################################################################

__DATA__

@@ InstructorSetdue.html.ep

%title 'set due date';
%layout 'instructor';

<main>

<h1>Not Yet</h1>

<%== $result %>

<pre> <%= dumper $params %>

</main>


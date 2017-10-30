#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::InstructorGradesave1;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo seclog);
use SylSpace::Model::Grades qw(gradesave);
use SylSpace::Model::Controller qw(standard global_redirect);

################################################################
## enter one and only one new grade for a student
################################################################

get '/instructor/gradesave1' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

  my $uemail= $c->req->query_params->param('uemail');
  my $task= $c->req->query_params->param('task');
  my $grade= $c->req->query_params->param('grade');

  gradesave($course, $uemail, $task, $grade);

  seclog($c->tx->remote_address, $course, 'instructor', "changed grade for $uemail $task $grade" );

  $c->flash( message=> "added grade for '$uemail', task '$task': $grade" )->redirect_to("gradecenter");

};

1;

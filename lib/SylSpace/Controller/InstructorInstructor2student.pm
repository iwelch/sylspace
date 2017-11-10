#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::InstructorInstructor2student;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo morphinstructor2student ismorphed);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/instructor/instructor2student' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  ismorphed($course, $c->session->{uemail}) and return $c->flash( message => "you were already a morphed instructor" )->redirect_to('/student');

  sudo( $course, $c->session->{uemail} );

  morphinstructor2student($course, $c->session->{uemail});

  return $c->flash( message => "instructor morphed into student.  do not use the back button&mdash; as a student, you no longer have good instructor access!" )->redirect_to('/student');
};

1;


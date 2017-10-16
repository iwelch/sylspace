#!/usr/bin/env perl
package SylSpace::Controller::InstructorRmtemplates;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo);
use SylSpace::Model::Files qw(rmtemplates);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################

get '/instructor/rmtemplates' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

  my $numremoved= rmtemplates($course);

  return $c->flash( message=> "deleted $numremoved unchanged template files" )->redirect_to( 'equizcenter' );
};

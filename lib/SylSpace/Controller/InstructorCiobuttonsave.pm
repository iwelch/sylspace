#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::InstructorCiobuttonsave;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo ciobuttonsave);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/instructor/ciobuttonsave' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

  my @buttonlist;
  foreach my $i (0..9) {
    my $buttonurl= $c->req->query_params->param("url$i");
    my $titlein= $c->req->query_params->param("titlein$i");
    my $textin= $c->req->query_params->param("textin$i");

    ($buttonurl =~ /^http/i) or next;
    ($titlein) or next;
    push(@buttonlist, [ $buttonurl, $titlein, $textin ])
  }

  ciobuttonsave( $course, \@buttonlist ) or return global_redirect($c);
  $c->flash( message => 'updated buttons' )->redirect_to('/instructor');
};

1;

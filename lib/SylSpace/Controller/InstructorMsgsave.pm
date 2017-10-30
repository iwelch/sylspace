#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::InstructorMsgsave;
use Mojolicious::Lite;  ## implied strict, warnings, utf8, 5.10
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo msgsave tweet);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################

post '/instructor/msgsave' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

  my $subject= $c->req->body_params->param('subject');
  ($subject =~ /\w/) or die "you must give a message subject";
  my $priority= $c->req->body_params->param('priority');

  my $msgid= msgsave($course, $c->req->body_params->to_hash);

  my $msg= "posted new message $msgid: '$subject', priority $priority";

  tweet($c->tx->remote_address, $course, 'instructor', $msg );
  $c->flash( message => $msg )->redirect_to('/instructor');  ## usually one posts only one message
};

1;

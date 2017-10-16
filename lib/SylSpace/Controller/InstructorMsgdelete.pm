#!/usr/bin/env perl
package SylSpace::Controller::InstructorMsgdelete;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo msgdelete tweet);
use SylSpace::Model::Controller qw(global_redirect  standard);
################################################################

get '/instructor/msgdelete' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

  my $msgid= $c->req->query_params('msgid');
  my $success= msgdelete($course, $msgid );

  tweet($c->tx->remote_address, $course, 'instructor', "completely deleted message $msgid");
  $c->flash( message => "completely deleted message $msgid" )->redirect_to("/instructor/msgcenter");
};

1;

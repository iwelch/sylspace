#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::StudentAnswerdelete;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo);
use SylSpace::Model::Files qw(answerdelete);
use SylSpace::Model::Controller qw(standard global_redirect);

################################################################

get '/student/answerdelete' => sub {

  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);
  my $uemail = $c->session->{uemail};

  my $oldanswer= $c->req->query_params->param('f');
  my $task= $c->req->query_params->param('task');

  answerdelete( $course,$uemail, $task, $oldanswer);

  return $c->flash( message=> "completely deleted answer $oldanswer" )->redirect_to("/student/hwcenter");
};

1;

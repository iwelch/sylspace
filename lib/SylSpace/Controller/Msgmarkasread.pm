#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::Msgmarkasread;
use Mojolicious::Lite;  ## implied strict, warnings, utf8, 5.10
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(msgmarkasread);
use SylSpace::Model::Controller qw( standard global_redirect);

################################################################

get '/msgmarkasread' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  my $msgid= $c->req->query_params->param('msgid');
  my $uemail= $c->session->{uemail};

  msgmarkasread($course, $uemail, $msgid);
  my $subject= $c->req->body_params->param('subject')||"no subject";
  my $priority= $c->req->body_params->param('priority')||"no priority";

  my $msg= "marked message $msgid as read: '$subject', priority $priority";

  $c->flash(message => $msg)->redirect_to($c->req->headers->referrer);
};

1;

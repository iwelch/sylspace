#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::Enter;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(seclog unmorphstudent2instructor);
use SylSpace::Model::Controller qw(global_redirect standard global_redirectmsg unobscure);


get '/enter' => sub {
  my $c = shift;

  ($c->session->{uemail}) or die "you do not have an email identity yet";
  (Email::Valid->address($c->session->{uemail})) or die "email address '".$c->session->{uemail}."' could not possibly be valid\n";
  #}

  #  (($postexpiration - time()) > 60 ) or die "Sorry, but your expiration is almost here.  Please reauthorize or extend!\n";

  ## now we are ready for the rest of our work on this subdomain
  (my $course = standard( $c )) or return global_redirect($c);

  ($course eq "auth") and die "you cannot enter the /auth course --- it does not exist!\n";
  ## return $c->flash(message => 'auth likes only index')->redirect_to('/auth/index');  ## we cannot enter the auth course site

  ## unmorph if needed
  unmorphstudent2instructor( $course, $c->session->{uemail} );  ## just make sure that we morph back if we were a morphed instructor
  seclog($c->tx->remote_address, $course, $c->session->{uemail}||"no one", "entering course site $course" );

  return $c->flash( message => "hello $c->session->{uemail}" )->redirect_to('/index');
};

1;

#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::AuthTestsetuser;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Controller qw();

use SylSpace::Model::Model qw(_listallusers);  ## for testsites



################################################################

get '/auth/testsetuser' => sub {
  my $c = shift;

  ($c->subdomain =~ /auth/)
    or return $c->redirect_to($c->auth_path('/auth/testsetuser'));

  my $users = _listallusers;

  die <<NOUSERS unless @$users;
sorry, but you have not even a single user in the system.
did you run Model.t and Files.t?
NOUSERS

  $users = [
    qw( ivo.welch@gmail.com instructor@gmail.com student@gmail.com ) 
  ] unless $c->app->mode eq 'development';


  $c->render(
    template => 'authtest',
    email => $c->session->{uemail},
    allusers => $users
  );
};

1;

################################################################

__DATA__

@@ authtest.html.ep

<% use SylSpace::Model::Controller qw(btnblock btn); %>


%title 'short-circuit identity';
%layout 'auth';

<main>

  <p>This is only useful under localhost, where it is shared by all, public to anyone, and ephemeral (regularly destroyed).  Do not enter anything confidential here.</p>

<ul id="userlist">

  % for my $user (@$allusers) {
    <li style="padding:1ex; font-size:large;">
      Make yourself
        <a href="/login?email=<%= $user %>"> <%= $user %> </a>
    </li>
  % }

  <li> <a href="/logout">Log out</a> </li>
</ul>

<hr />

<p>right now, you are <tt><%= $email||"no session email" %></tt>.</p>

<hr />

<p> <%== btn("/auth/goclass", "Choose Class") %>

<p> <%== btn('/auth/authenticator', "Real Authenticator") %>

<hr />

</main>

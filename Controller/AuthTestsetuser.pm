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

  use Class::Inspector;
  use Data::Dumper;

  ### my @methods =   Class::Inspector->methods( 'Mojo::URL', 'full', 'public' );
  ###die Dumper \@methods . " ". Dumper $c->req->url->to_abs;

  my $cururl= $c->req->url->to_abs;
  ($cururl->subdomain =~ /auth/)
    or $c->redirect_to('http://auth.'.$cururl->domainport.'/auth');  ## wipe off anything beyond on url

  $c->render( template => 'authtest', email => $c->session->{uemail}, allusers => _listallusers() );
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

<ul>
  <%== makelist($allusers) %>
  <li> <a href="/logout">Log out</a> </li>
</ul>

<hr />

<p>right now, you are <tt><%= $email||"no session email" %></tt>.</p>

<hr />

<p> <%== btn("/auth/goclass", "Choose Class") %>

<p> <%== btn('/auth/authenticator', "Real Authenticator") %>

<hr />

</main>


<% sub makelist {
  my $l= shift;
  my $rs;
  (@$l < 1) and die "sorry, but you have not even a single user in the system.  did you run Model.t and Files.t?\n";

  my @ulist= ($ENV{'SYLSPACE_onlocalhost'}) ? @$l : qw( ivo.welch@gmail.com instructor@gmail.com student@gmail.com );
  foreach (@ulist) { $rs .="<li style=\"padding:1ex; font-size:large;\"> Make</a> yourself <a href=\"/login?email=$_\">$_</a> </li>\n"; }
  return $rs;
} %>

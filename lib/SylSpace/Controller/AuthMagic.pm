#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::AuthMagic;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo tokenmagic);

################################################################

get '/auth/magic' => sub {
  my $c = shift;

  my $tokenmagic=  tokenmagic($c->session->{uemail});
  if (defined($tokenmagic)) {
    $c->session->{uemail} = $tokenmagic;
    $c->session->{expiration} = time()+24*60*60;
    return $c->flash(message => "the magictoken file allowed you to turn into $tokenmagic")->redirect_to('/auth/goclass');
  }

  $c->render( template=> 'AuthMagic' );
};

1;

################################################################

__DATA__

@@ AuthMagic.html.ep

<% use SylSpace::Model::Controller qw(btnblock); %>

%title 'super magic';
%layout 'auth';

<main>

<h2>Purpose</h2>

<p>This script helps the site administrator turn into any user.  This is useful for debugging purposes&mdash;when someone sents an email to the admin that they are x and can no longer do y, the site admin can become x and replicate y.</p>

<p>Obviously this is a tightly controlled script.   It is completely useless without direct offline control on the server.</p>


<h2>Offline Instructions</h2>

<p>Please create a file <tt style="background-color:white">$var/tmp/magictoken</tt> that contains two lines:

<pre>
   ip: the IP address from which you will browse
   then: who you want to become
</pre>

<h2>What will happen</h2>

<p>When this is done, refresh this page or hit</p>

<div class="row"><%== btnblock('/auth/magic', 'magic transform', '', 'btn-danger') %></div>

<p>If the $var/tmp/magictoken file exists, and if you are the 'now', you will become the 'then', the file will be deleted, and you will be returned to /auth/goclass.  Otherwise, you will remain here at this URL.

<p>Server Time: <%= localtime() %>

</main>


#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::Showseclog;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(isenrolled showseclog isinstructor);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################

get '/showseclog' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  (isenrolled($course, $c->session->{uemail})) or $c->flash( message => "first enroll in $course please" )->redirect_to('/goclass');
  my $seclog= showseclog($course);

  $c->stash(toprightexit => '<li><a href="/auth/goclass"> <i class="fa fa-sign-out"></i> Exit Course </a></li>');

  if (!isinstructor($course, $c->session->{uemail})) {
    my @seclog=split(/\n/, $seclog);
    @seclog = grep { $_ =~ $c->session->{uemail} } @seclog;
    $seclog= join("\n", @seclog);
    $c->stash( bgcolor => $ENV{SYLSPACE_sitescolor}, homeurl => '/student' );
  } else {
    $c->stash( bgcolor => $ENV{SYLSPACE_siteicolor}, homeurl => '/instructor' );
  }

  $c->stash( seclog => $seclog );
};

1;

################################################################

__DATA__

@@ showseclog.html.ep

<% use SylSpace::Model::Controller qw(displaylog); %>


%title 'security log';
%layout 'both';

<main>

  <%== displaylog( $seclog ); %>

</main>


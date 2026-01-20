#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::AuthInstructorinfo;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Files qw(filereads fileexistss);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/auth/instructorinfo' => sub {
  my $c = shift;

  use Perl6::Slurp;

  my $sitewide= slurp("static/html/instructorinfo.html");
  $sitewide =~ s{.*<sitewide>(.*)</sitewide>}{$1}ms;

  $c->stash( allfaq => $sitewide, template => 'faq' );
};


__DATA__

@@ faq.html.ep

%title 'faq';
%layout 'both';

<main>

<dl>

%= include '_what_is_sylspace'

</dl>

<hr />

  <%== $allfaq %>

<hr />

  <p> More FAQ information is provided to logged-in users. </p>

</main>



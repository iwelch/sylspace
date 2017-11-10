#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::InstructorHwmore;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo tzi);
use SylSpace::Model::Files qw(hwlisti answerlisti);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################

get '/instructor/hwmore' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

  my $hwname=  $c->req->query_params->param('f');
  (defined($hwname)) or die "need a filename for hwmore.\n";

  $c->stash( detail => hwlisti($course, $hwname),
	     studentuploaded => answerlisti($course, $hwname),  ## please search for f=fname here below
	     fname => $hwname,
	     tzi => tzi( $c->session->{uemail} ) );
};

1;

################################################################

__DATA__

@@ instructorhwmore.html.ep

<% use SylSpace::Model::Controller qw(drawmore btn webbrowser); %>

%title 'more homework information';
%layout 'instructor';

<main>

  <%== drawmore($detail->[0]->{sfilename}, 'hw', [ 'view', 'download', 'edit' ], $detail, $tzi, webbrowser($self) ); %>

  <hr />

  <%== upl($studentuploaded) %>


<%== btn('/instructor/collectstudentanswers?f='.$fname, "collect all student answers", 'btn-lg') %>

</main>

<%
  use Data::Dumper;
  sub upl {
    (defined($_[0])) or return "<h2> No Student Responses Yet </h2>\n";

    my $rs=""; my $c=0;
    my @fl= @{$_[0]};
    foreach (@fl) {
      m{.*/([0-9a-z\_\.\-]+@[0-9a-z\_\.\-]+)/files/(.*)};
      (/\.old$/) and next;
      $rs .= "<li> Submitted: $1 </li>"; ++$c;
    }
    return "<h2> $c Student Responses </h2>\n\n<ol> $rs </ol>\n";
  }
%>

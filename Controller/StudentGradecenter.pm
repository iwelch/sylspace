#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::StudentGradecenter;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use lib '../..';

use SylSpace::Model::Model qw(isenrolled);
use SylSpace::Model::Grades qw(gradesashash);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/student/gradecenter' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  (isenrolled($course, $c->session->{uemail})) or $c->flash( message => "first enroll in $course please" )->redirect_to('/auth/goclass');

  my $allgrades= gradesashash( $course, $c->session->{uemail} );  ## just my own grades!

  $c->stash( allgrades => $allgrades );
};

1;

################################################################

__DATA__

@@ studentgradecenter.html.ep

<% use SylSpace::Model::Controller qw(mkdatatable); %>

%title 'grade center';
%layout 'student';

<main>

  <%== mkdatatable('gradebrowser') %>

  <% if (defined($allgrades)) { %>
  <table class="table" style="width: auto !important; margin:2em;" id="gradebrowser">
     <%== showmygrades($allgrades) %>
  </table>
  <% } else { %>
      <p> No grade data posted just yet </p>
  <% } %>

</main>

  <%
  sub showmygrades {
    my $allgrades= shift;
    my $rs= "";
    $rs.= "<caption> Student ".$allgrades->{uemail}->[0]." </caption>
           <thead> <tr> <th>Task</th> <th>Grade</th> </tr> </thead>\n";

    $rs .= "<tbody>\n";
    foreach my $hw (@{$allgrades->{hw}}) {
      foreach my $st (@{$allgrades->{uemail}}) {
	$rs.= "<tr> <th> $hw </th> \n";
	$rs.= "<td style=\"text-align:center\">".($allgrades->{grade}->{$st}->{$hw}||"-")."</td>";
      }
      $rs.= "</tr>\n";
    }
    $rs .= "</tbody>\n";

    #my $rr="<select name=\"task\" class=\"form-control\">";
    #foreach (@{$allgrades->{hw}}) { $rr .= qq(<option value="$_">$_</option>); }
    ##$$rr .= "</select>\n";
    return $rs;
  }
  %>


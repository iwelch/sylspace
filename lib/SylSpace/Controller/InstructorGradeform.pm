#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::InstructorGradeform;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo studentlist);
use SylSpace::Model::Grades qw(gradesashash);
use SylSpace::Model::Controller qw(standard global_redirect);

################################################################

get '/instructor/gradeform' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

  my $taskname= $c->req->query_params->param('taskn');
  my $studentlist= studentlist($course);
  my $sgl; foreach (@$studentlist) { $sgl->{$_}=""; }
  my $gah= gradesashash( $course );
  foreach (@{$gah->{uemail}}) {
    $sgl->{$_}= ($gah->{grade}->{$_}->{$taskname}) || "";
  }

  $c->stash( formname => $taskname, sgl => $sgl );
};

1;

################################################################

__DATA__

@@ instructorgradeform.html.ep

%title 'enter many grades';
%layout 'instructor';

<% use SylSpace::Model::Controller qw(mkdatatable); %> <%== mkdatatable('gradebrowser') %>

<main>

<h1>Grades For Task <%= $formname %></h1>

<form action="gradesave">
  <input type="hidden" name="task" value="<%= $formname %>" />

  <table class="table" id="gradebrowser">
     <thead> <th class="col-md-1"> # </th> <th class="col-md-3"> Student </th> <th class="col-md-1"> Grade </th> </tr> </thead>
     <tbody>
        <%== tcontent($sgl) %>
     </tbody>
  </table>

  <div class="col-xs-1">
      <button class="btn" type="submit" value="submit">Update All Grades</button>
   </div>

</form>

</main>

  <%
  sub tcontent {
    my $sgl= shift;
    my $rv="";
    my $i=0;
    foreach (keys %{$sgl}) {
      ++$i;
      $rv .= qq(\t<tr> <td>$i</td> <td> $_ </td> <td> <input type="text" name="$_" value="$sgl->{$_}" /> </tr>\n);
    }
    return $rv;
  }
  %>

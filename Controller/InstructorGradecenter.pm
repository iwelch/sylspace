#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::InstructorGradecenter;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use lib '../..';

use SylSpace::Model::Model qw(sudo);
use SylSpace::Model::Grades qw(gradesashash);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################

get '/instructor/gradecenter' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

  my $all= gradesashash( $course );

  $c->stash( all => $all );
};

1;

################################################################

__DATA__

@@ instructorgradecenter.html.ep

<% use SylSpace::Model::Controller qw(btn mkdatatable); %>

%title 'grade center';
%layout 'instructor';

<main>

 <%== mkdatatable('gradebrowser') %>

  <table class="table" id="gradebrowser">
     <%== showgrades($all) %>
  </table>

  <p style="font-size:x-small">Click on the column name to enter <em>many</em> student grades for this one task.  If it is a new task, you must first add it.<br /> To enter just one grade for one student, use the following form.</p>

  <hr />

  <form method="GET" action="/instructor/gradesave1">
  <div class="row">

    <div class="col-md-3">
      <div class="input-group">
        <span class="input-group-addon"><i class="fa fa-user"></i></span>
        <!-- input type="text" class="form-control" placeholder="student email" name="uemail" -->
        <%== studentselector($all) %>
      </div>
    </div>

    <div class="col-md-2">
      <div class="input-group">
        <span class="input-group-addon"><i class="fa fa-file"></i></span>
            <%== hwselector($all) %>
      </div>
    </div>

    <div class="col-md-2">
      <div class="input-group">
        <span class="input-group-addon"><i class="fa fa-thermometer-half"></i></span>
        <input type="text" class="form-control" placeholder="grade" name="grade" />
      </div>
    </div>

    <div class="col-md-1">
      <div class="input-group">
         <button class="btn btn-default" type="submit" value="submit">Submit 1 New Grade</button>
      </div>
    </div>

  </div>
  <span style="font-size:x-small">For entering many student grades, please click on the column header name instead.</span>
  </form>

<hr />

<form action="/instructor/gradetaskadd">
  <div class="row">

    <div class="col-md-2">
      <div class="input-group">
        <span class="input-group-addon"><i class="fa fa-file"></i></span>
         <input type="text" class="form-control" placeholder="task name" name="taskn" />
      </div>
    </div>

    <div class="col-md-1">
       <div class="input-group">
          <button class="btn btn-default" type="submit" value="submit">Add 1 New Task Category</button>
       </div>
    </div>
  </div>
          <span style="font-size:x-small">Warning: Categories, once entered, cannot be undone.  Just ignore empty column then.</span>
</form>


<hr />

  <form action="studentdetailedlist">
  <button class="btn btn-default" value="add students"> Add 1 New Student </button>
  </form>

  <hr />


  <div class="row">
  <b>CSV Downloads</b> <br />
  <%== btn('/instructor/gradedownload?f=csv&sf=l', 'Long') %>
  <%== btn('/instructor/gradedownload?f=csv&sf=w', 'Wide') %>
  <%== btn('/instructor/gradedownload?f=csv&sf=b', 'Best Only') %>
  <%== btn('/instructor/gradedownload?f=csv&sf=t', 'Latest Only') %>
  </div>

  <p style="font-size:x-small">The long view also contains repeated entries, changes, time stamps, etc.  The wide view gives only the latest score.  The best and latest views are in long format, but give -99 for non-numerical grades.  (For complete information and clarification, use the long view.)</p>

</main>



<%
  sub showgrades {
    my $all = shift;
    my $rs= "<thead> <tr> <th>Student</th>";
    foreach (@{$all->{hw}}) { $rs.= "<th> <a href=\"gradeform?taskn=$_\">$_</a> </th>"; }
    $rs.= "</tr> </thead>\n<tbody>\n";

    foreach my $st (@{$all->{uemail}}) {
      $rs.= "<tr> <th> $st </th> \n";
      foreach my $hw (@{$all->{hw}}) {
	$rs.= "<td style=\"text-align:center\">".($all->{grade}->{$st}->{$hw}||"-")."</td>";
      }
    $rs.= "</tr>\n";
    }
    $rs .= "</tbody>\n";
    return $rs;
  }

  sub studentselector {
    my $all = shift;
    my $studentselector="<select name=\"uemail\" class=\"form-control\">\n";
    $studentselector .= qq(<option value=""></option>);
    foreach (@{$all->{uemail}}) { $studentselector .= qq(<option value="$_">$_</option>); }
    $studentselector .= "</select>\n";
    return $studentselector;
  }

  sub hwselector {
    my $all = shift;
    my $hwselector="<select name=\"task\" class=\"form-control\">\n";
    $hwselector .= qq(<option value=""></option>);
    foreach (@{$all->{hw}}) { $hwselector .= qq(<option value="$_">$_</option>); }
    $hwselector .= "</select>\n";
    return $hwselector;
  }
%>


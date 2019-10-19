#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::InstructorInstructorlist;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo instructorlist);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/instructor/instructorlist' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

  $c->stash( instructors => instructorlist( $course ) );
};

1;

################################################################

__DATA__

@@ instructorinstructorlist.html.ep

%title 'current course instructors';
%layout 'instructor';

<main>

  <div class="alert alert-danger"><i class="fa fa-exclamation-triangle" aria-hidden="true"></i>  Warning: This page allows you to give full control to anyone to administer the website.  They can even remove you as the instructor.</div>

  <table class="table" style="width: auto !important; margin:2em; font-size:large;" id="insbrowser">
    <thead> <tr> <th> Instructors </th> </tr> </thead>
    <tbody>
      <%== ilist($instructors) %>
    </tbody>
  </table>

<form action="/instructor/instructoradd" method="POST">
  <div class="row">

    <div class="col-xs-4">
      <div class="input-group">
        <span class="input-group-addon"><i class="fa fa-user"></i></span>
         <input type="text" class="form-control" placeholder="enrolled user email" name="newiemail" />
      </div>
    </div>

    <div class="col-xs-1">
       <div class="input-group">
          <button class="btn btn-danger" type="submit" value="submit">Add New Instructor</button>
       </div>
    </div>
  </div>
</form>

</main>


  <%
    sub ilist {
      my $instructors= shift;
      my $rs="";
      foreach (@{$instructors}) {
	$rs .= "<tr> <td> $_ </td> <td> <a href=\"instructordel?deliemail=$_\"><i class=\"fa fa-trash\" aria-hidden=\"true\"></i></a> </td> </tr>\n";
      }
      return $rs;
    }
  %>

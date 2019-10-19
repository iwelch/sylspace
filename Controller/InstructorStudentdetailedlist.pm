#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::InstructorStudentdetailedlist;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo studentdetailedlist );
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################

get '/instructor/studentdetailedlist' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

  my $studentdetailedlist = studentdetailedlist( $course );

  $c->stash(studentdetailedlist => $studentdetailedlist);
};

1;

################################################################

__DATA__

@@ instructorstudentdetailedlist.html.ep

%title 'list students';
%layout 'instructor';

<main>

  <% use SylSpace::Model::Controller qw(mkdatatable); %> <%== mkdatatable('namebrowser') %>

  <table class="table" id="namebrowser">
    <thead>
      <tr> <th> Email </th> <th> First </th> <th> Last </th> <th> RegId </th> <th> Cellphone </th> </tr>
    </thead>
    <tbody>
      <%== torowlist($studentdetailedlist) %>
    </tbody>
  </table>

    <hr />

    <h3> Adding Students </h3>

    <p> Please note that when you add students, they will be added to the entire system (all courses).  If an added user does not control the email you are entering, then you have created a useless orphan that will hang around forever.  Please use sparingly.  For the most part, your students should add themselves. </p>

    <form method="GET" action="/instructor/userenroll">
    <div class="row">

    <div class="col-xs-4">
      <div class="input-group">
        <span class="input-group-addon"><i class="fa fa-user"></i></span>
        <input type="text" class="form-control" placeholder="student email" name="newuemail">
      </div>
    </div>

    <div class="col-xs-1">
      <div class="input-group">
         <button class="btn" type="submit" value="submit">Add 1 New Student</button>
      </div>
    </div>
  </div>
   </form>

</main>


<%
  sub torowlist {
     my $content;
     foreach (@{$_[0]}) {
       $content .= "<tr> <td> $_->{email} </td>  <td> $_->{firstname} </td>  <td> $_->{lastname} </td>   <td> $_->{regid} </td> <td> $_->{cellphone} </td> </tr>\n\t";
     }
     return $content;
  }
%>


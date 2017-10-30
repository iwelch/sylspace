#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::InstructorCioform;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(readschema sudo cioread ciobuttons);
use SylSpace::Model::Controller qw(global_redirect  standard drawform);

################################################################

get '/instructor/cioform' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

  $c->stash( udrawform=> drawform( readschema('c'), cioread($course) ), udrawbuttons => ciobuttons($course) );
};


1;

################################################################

__DATA__

@@ instructorcioform.html.ep

%title 'course settings';
%layout 'instructor';

<main>

  <p>If you want to restrict enrollment, then use the 'coursesecret'.  (For open enrollment, just leave blank.)  Only the uniname (your institution) is required.  The other fields merely make it easier for your students to find you, your class, your room, or TAs, but they are not required.  You can also add them later on your class page.</p>

  <form class="form-horizontal" method="POST" action="/instructor/ciosave">

    <%== $udrawform %>

    <div class="form-group">
         <button class="btn btn-default btn-lg" type="submit" value="submit">Submit These Course Settings</button>
    </div>

  </form>


  <p> <b>*</b> means required (red if not yet provided).</p>

  <hr />

  <h2>Additional GUI Buttons for Student Shortcuts</h2>

  <form class="form-horizontal" method="GET" action="/instructor/ciobuttonsave">

    <table class="table">
      <tr> <th> URL </th> <th> Title </th> <th> More Explanation </th> </tr>
      <%== makebuttontable( $udrawbuttons ) %>
    </table>

     <div class="form-group">
        <button class="btn btn-default btn-lg" type="submit" value="submit">Submit Buttons</button>
     </div>

  </form>


</main>


  <%
  sub makebuttontable {
    my $rs="";
    my $count=0;
    if (defined($_[0])) {
      foreach(@{$_[0]}) {
	$rs.= "<tr> ".
	  "<td> <input class=\"urlin\" id=\"url$count\" name=\"url$count\" value=\"$_->[0]\" readonly size=\"64\" maxsize=\"128\" /> </td>".
	  "<td> <input class=\"titlein\" id=\"titlein$count\" name=\"titlein$count\" value=\"$_->[1]\" size=\"12\" maxsize=\"12\" /></td>".
	  "<td> <input class=\"textin\" id=\"textin$count\" name=\"textin$count\" value=\"$_->[2]\" size=\"48\" maxsize=\"48\" /></td>".
	  "</tr>";
	++$count;
      }
    }

    $rs.= "<tr> ".
      "<td> <input class=\"urlin\" id=\"url$count\" name=\"url$count\" placeholder=\"e.g., http://google.com\" size=\"64\" maxsize=\"128\" /> </td>".
      "<td> <input class=\"titlein\" id=\"titlein$count\" name=\"titlein$count\" placeholder=\"e.g., google\" size=\"12\" maxsize=\"12\" /></td>".
      "<td> <input class=\"textin\" id=\"textin$count\" name=\"textin$count\" placeholder=\"e.g., learn more\" size=\"48\" maxsize=\"48\" /></td>".
      "</tr>";
    return $rs;
  }
  %>



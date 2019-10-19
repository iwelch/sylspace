#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::StudentQuickinfo;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(isenrolled cioread hassyllabus instructorlist);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/student/quickinfo' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  (isenrolled($course, $c->session->{uemail})) or $c->flash( message => "first enroll in $course please" )->redirect_to('/auth/goclass');

  my $instructorlist= instructorlist( $course );

  (defined($instructorlist)) or $instructorlist= [ "no instructor defined" ];

  $c->stash( cioread => cioread($course), requestsyllabus => hassyllabus($course), instructorlist => $instructorlist  );
};

1;

################################################################

__DATA__

@@ studentquickinfo.html.ep

%title 'quick info';
%layout 'student';

<main>

<h1>Quick Course Facts</h1>

  <table class="table" style="width: auto !important; margin: 2em;">
    <tr> <th> Instructor(s) </th> <td> <%= join(" ", @{$instructorlist}) %> </td> </tr>
    <tr> <th> Subject Matter </th> <td> <%= $cioread->{subject} %> </td> </tr>
    <tr> <th> Course Code </th> <td> <%= $cioread->{unicode} %> </td> </tr>
    <tr> <th> Department </th> <td> <%= $cioread->{department} %> </td> </tr>
    <tr> <th> University </th> <td> <%= $cioread->{uniname} %> </td> </tr>
    <tr> <th> Meets </th> <td> <%= $cioread->{meetroom}." : ".$cioread->{meettime} %> </td> </tr>
    <tr> <th> Course Email </th> <td> <a href="<%= $cioread->{cemail} %>"><%= $cioread->{cemail} %></a> </td> </tr>
    <tr> <th> Syllabus </th> <td> <% my $s=$requestsyllabus; %> <%== (defined($s)) ? qq(<a href="/student/fileview?f=$s">syllabus</a>): 'n/a' %> </td> </tr>
  </table>

</main>


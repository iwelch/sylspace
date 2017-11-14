#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::StudentHwcenter;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw( isenrolled );
use SylSpace::Model::Files qw(hwlists answerlists answerhashs);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/student/hwcenter' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  (isenrolled($course, $c->session->{uemail})) or $c->flash( message => "first enroll in $course please" )->redirect_to('/auth/goclass');

  $c->stash( filelist => hwlists($course),
	     answerhashs => answerhashs( $course, $c->session->{uemail} ),
	   );
};

1;


################################################################

__DATA__

@@ studenthwcenter.html.ep

<% use SylSpace::Model::Controller qw(timedelta btn); %>

%title 'homework center';
%layout 'student';

<main>

  <h2> Upload Your Answers </h2>

   <div class="row top-buffer text-center">
    <table class="table" style="width: auto !important">
      <thead>  <tr> <th> Assignment </th> <th>Due</th> <th> Upload </th> <th> Uploaded </th> </tr> </thead>

      <tbody>
          <%== filehash2string( $filelist, $answerhashs ) %>
      </tbody>

     </table>
  </div>

  <p>You should name your answer file to start with the homework file name, too.  For example, if the homework is named 'hwa1.txt', name your answer file something like 'hwa1-johndoe-answer.pdf' (no spaces or weird characters, please).</p>
</main>


<%
  sub filehash2string {
    my ($filehashptr, $answerhashs)= @_;
    (defined($filehashptr)) or return "";

    my $counter=0;
    my $filestring= '';

    foreach (@$filehashptr) {
      my $duetime= $_->{duetime};  my $fname= $_->{sfilename};

      ($duetime<time()) and next;
      ++$counter;
      my $duein= timedelta($duetime , time());
      my $pencil= '<i class="fa fa-pencil"></i>';

      my $uploadform=
	qq(<form action="/uploadsave" id="uploadform" method="post" enctype="multipart/form-data" style="display:block">
          <label for="idupload">Upload: </label>
          <input type="file" name="file" id="idupload" style="display:inline"  >

          <input type="hidden" name="hwtask" value="$_->{sfilename}"  ><br />
          <button class="btn btn-default btn-block" type="submit" value="submit">Go</button>
      </form>);


      my $answer= $answerhashs->{$fname};

	my $uploaded;
	if (defined($answer)) {
	print "\n\nerror after this?\n\n";
	$uploaded= qq(<a href="/student/ownfileview?f=$answer">$answer</a><br />).btn("/student/answerdelete?f=$answer&task=$fname", 'delete me', 'btn-xs btn-danger');
	print "\n\n$answer answer \n\n$fname  task\n\n";
	#$uploaded=qq(<a href="/student/ownfileview?f=$answer">$answer</a><br /><input type="button" value="delete" onClick="deleteoldanswer(1)" class="btn btn-xs btn-danger">);
	print "\n\n$uploaded\n\n";
	#$uploaded .= qq(<br />second line  );
	#print "\n\n$uploaded\n\n";
}
	else {
	$uploaded="no upload for $fname yet";
}




      $filestring .= "<tr>"
	. "<td> ". btn("/student/fileview?f=$fname", "$pencil $fname") . "</td>"
	. "<td style=\"text-align:left\"> due $duein (<span class=\"epoch0\">$duetime</span>)<br />due GMT ". localtime($_->{duetime})."<br />now GMT ".localtime()."</td>"
	. "<td> $uploadform </td>"
	. '<td>'.$uploaded.' </td>'
	."</tr>";
    }
    ($counter) or return "<tr colspan=\"3\"><td>$counter publicly posted homeworks at the moment</td> </tr>";

    return $filestring;
  }

  %>

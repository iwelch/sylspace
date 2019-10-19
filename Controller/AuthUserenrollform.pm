#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::AuthUserenrollform;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(getcoursesecret);
use SylSpace::Model::Controller qw(standard global_redirect);

################################################################

get '/auth/userenrollform' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  my $coursename= $c->req->query_params->param('c');
  $coursename =~ s/syllabus\.space$//;
  my $secret= getcoursesecret($coursename);

  (defined($secret)) or $secret="";

  $c->stash( asecret => $secret, coursename => $coursename );
};

1;

################################################################

__DATA__

@@ authuserenrollform.html.ep

%title 'enroll in a course';
%layout 'auth';

<main>

  <h1> Enrolling in Course '<%= $coursename %>' </h1>

  <p></p>

  <%== enrollform( $asecret, $coursename ) %>

  <p>Instructors can choose arbitrary registration numbers.</p>

</main>


  <% sub enrollform {
    my ($secret,$coursename)= @_;

    my $q= '<input class="form-control foo" id="secret" name="secret"'
      .(($secret ne "") ?
	'placeholder="usually instructor provided"' :
	'placeholder="not required - instructor requests none" readonly').' />';

    return qq(
	<form  class="form-horizontal" method="POST"  action="/auth/userenrollsave">
	<input type="hidden" name="course" value="$coursename" />
	<input type="hidden" name="c" value="$coursename" />
	  <div class="form-group">
	    <label class="col-sm-2 control-label col-sm-2" for="secret">secret*</label>
	    <div class="col-sm-6">
		$q
	    </div>
          </div>

          <div class="form-group">
             <label class="col-sm-2 control-label col-sm-2" for="submit"></label>
	     <button class="btn btn-lg btn-default" type="submit" value="submit">Enroll Now</button>
	  </div>
	</form>
       );
  }
   %>

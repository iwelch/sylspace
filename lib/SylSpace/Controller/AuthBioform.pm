#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.


package SylSpace::Controller::AuthBioform;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(readschema bioread userexists);
use SylSpace::Model::Controller qw(standard global_redirect  drawform);

################################################################

get '/auth/bioform' => sub {
  my $c = shift;
  # (my $course = standard( $c )) or return global_redirect($c);

  userexists($c->session->{uemail}) or die "internal error: you were never created";

  $c->stash( udrawform=> drawform( readschema('u'), bioread($c->session->{uemail}) ) );
};


1;

################################################################

__DATA__

@@ authbioform.html.ep

%title 'user bio';
%layout 'auth';

<main>

  <form class="form-horizontal" method="POST" action="/auth/biosave">

  <div class="form-group">
    <label class="col-sm-2 control-label" for="email">email*</label>
       <div class="col-sm-6">[public unchangeable]
          <input class="form-control foo" id="email" name="email" value="<%= $self->session->{uemail} %>" readonly />
       </div>
  </div>

  <%== $udrawform %>

  <!-- div class="form-group" style="padding-top:2em">
    <label class="col-sm-2 control-label" for="directlogincode">[c] directlogincode</label>
    <div class="col-sm-6">[Super-Confidential, Not Changeable, Ever]<br />  <a href="auth/showdirectlogincode">click here to play with knives</a><br /> </div>
  </div -->

  <div class="form-group">
     <button class="btn btn-lg btn-default" type="submit" value="submit">Submit These Settings</button>
  </div>

  <script>
      var clientDate = new Date(); //Get date on current client machine
      var clientDateTimeOffset = (clientDate.getTimezoneOffset() * -1); //account for the offset
      var convertToHours = clientDateTimeOffset/60; //Convert it to hours
      $("#tzi").val(convertToHours); //Update the input control
  </script>

  </form>

  <p> <b>*</b> means required (red if not yet provided).</p>

  <p> <b>tzi</b> is your timezone.  Typically, this will be filled in correctly by your browser.  It helps SylSpace render time expiration notices not in UTC, but in your local timezone.  If you want to tinker with it:  0 = UTC.  -7 = PST(Summer), -8 = PST(Winter).  +8 = China.</p>



</main>


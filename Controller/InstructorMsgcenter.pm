#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::InstructorMsgcenter;
use Mojolicious::Lite;  ## implied strict, warnings, utf8, 5.10
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo msgread msglistread tzi);
use SylSpace::Model::Controller qw(global_redirect  standard msghash2string);
################################################################

get '/instructor/msgcenter' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

  my @msglistread=msglistread($course, $c->session->{uemail});
  $c->stash( msgstring => msghash2string( msgread( $course ), "/msgmarkasread", \@msglistread, tzi($c->session->{uemail}) ) );
};

1;


################################################################


__DATA__

@@ instructormsgcenter.html.ep

%title 'message center';
%layout 'instructor';

<main>

	<div class="row">
		<div class="col-sm-12">
			<form class="form-horizontal" method="POST" action="msgsave">
				<input type="hidden" name="formposted" value="<%= time %>" />

				<div class="form-group">
					<label for="priority">Priority:</label>
					<select name="priority" class="form-control" id="priority">
					<option value="10">High</option>
					<option value="5" selected="selected">Normal</option>
					<option value="1">Low</option>
					</select>
				</div>


				<div class="form-group">
					<label for="to">To:</label>
					<input type="text" class="form-control" id="msgto" value="my students" readonly />
				</div>

				<div class="form-group">
					<label for="subject">Subject:</label>
					<input type="text" name="subject" class="form-control" id="msgsubject" />
				</div>

				<div class="form-group">
					<label for="body">Message (&lt;16KB characters):</label>
					<textarea name="body" class="form-control" rows="5" id="msgbody"></textarea>
				</div>

				<div class="form-group">
					<button class="btn btn-lg btn-default"  type="submit" value="submit">Submit This Message</button>
				</div>
			</form>
		</div> <!-- col-sm-12 -->
	</div> <!-- row -->

<hr />

<h2> All Previously Posted Messages </h2>

<%== $msgstring %>

<hr />

<p>You should not delete messages that some students have seen, but others have not.  If you absolutely need to do this, please type the message id here.  There will be no warning.</p>

<script type="text/javascript" src="/js/confirm.js"></script>

<form action="msgdelete">
  <div class="row">

    <div class="col-xs-3">
      <div class="input-group">
        <span class="input-group-addon"><i class="fa fa-paper-plane"></i></span>
         <input type="text" class="form-control" placeholder="msgid" name="msgid" />
      </div>
    </div>

    <div class="col-xs-1">
       <div class="input-group">
          <button class="btn btn-danger" type="submit" value="submit"> <i class="fa fa-trash" aria-hidden="true"></i> &nbsp;&nbsp; Destroy Message </button>
       </div>
    </div>
  </div>
          <span style="font-size:x-small">Warning: Categories, once entered, cannot be undone.  Just ignore empty column then.</span>
</form>

</main>

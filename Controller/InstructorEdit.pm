#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::InstructorEdit;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo);
use SylSpace::Model::Files qw(filereadi);
use SylSpace::Model::Controller qw(global_redirect  standard);

################################################################

get 'instructor/edit' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

  my $filename= $c->req->query_params->param('f');
  my $filecontent= filereadi( $course, $filename );
  my $filelength= length($filecontent);

  $filecontent =~ s/\r\n/\r/g;
  $filecontent =~ s/\r/\n/g;

  use Digest::MD5 qw(md5_hex);
  $c->stash( filelength => $filelength, filename => $filename, filecontent => $filecontent, fingerprint => md5_hex($filecontent) );
};

1;

################################################################

__DATA__

@@ instructoredit.html.ep

%title 'edit a file';
%layout 'instructor';

<style> textarea.textarea {  font-family: monospace;  display:block;  height:80vh;  width:100%;  line-height:16px;  padding:5px;  margin:0px auto;    }</style>


<main>

  <form method="POST" action="editsave">

  <input type="hidden" name="fname" value="<%= $filename %>" />
  <input type="hidden" name="fingerprint" value="<%= $fingerprint %>" />
  <input type="hidden" name="filelength" value="<%= $filelength %>" />

  <textarea name="content" id="textarea" spellcheck="false" class="textarea"><%= $filecontent %></textarea>

  <script type="text/javascript" src="/js/confirm.js"></script>

  <div class="row top-buffer text-center">
  <div class="col-md-12">
     <button class="btn btn-lg btn-default btn-block btn-danger" name="submitbutton"  type="submit" value="combine" style="font-size:x-large"  onclick="show_alert();">Save Changes</button>
  <p>This will overwrite the original!</p>
  </div> <!--col-md-12-->
  </div> <!--row-->

  </form>

</main>


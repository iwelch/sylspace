#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::InstructorSitebackup;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sitebackup sudo isvalidsitebackupfile);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

get '/instructor/sitebackup' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

  my $filename= sitebackup( $course );
  (-e $filename) or die "internal error: zip file $filename vanished";

  (isvalidsitebackupfile($filename)) or die "internal error: '$filename' is not a good site backup file\n";

  $c->render( filename => $filename, template => 'InstructorSitebackup' );
};

1;

################################################################

__DATA__

@@ InstructorSitebackup.html.ep

%title 'course site backup';
%layout 'instructor';

<main>

<meta http-equiv="refresh" content="1;url=silentdownload?f=<%=$filename%>">

  <p>Your zipped backup file has been created and will download in a moment.</p>

  <p>Naturally, if the <%= $ENV{'SYLSPACE_appname'} %> webapp dies or the server is compromised, only your local backup will survive.  So please make sure to keep it in a safe place!</p>

</main>

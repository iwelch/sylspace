#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::InstructorEquizeditsaveview;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo);
use SylSpace::Model::Files qw(eqwrite);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

post 'instructor/equizeditsaveview' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

  my $fname = $c->req->params->param('fname');
  my $content = $c->req->params->param('content') // '';
  
  $content =~ s/\r\n/\r/g;
  $content =~ s/\r/\n/g;

  # Step 1: Syntax check
  my $syntax_error = _check_syntax($content);
  if ($syntax_error) {
    $c->stash(error => $syntax_error, fname => $fname);
    return;
  }

  # Step 2: Save
  eval { eqwrite($course, $fname, $content); };
  if ($@) {
    $c->stash(error => "Save failed: $@", fname => $fname);
    return;
  }

  # Step 3: Redirect to view
  $c->redirect_to("/instructor/equizview?f=$fname");
};

sub _check_syntax {
  my $content = shift;
  
  # Basic validation
  return "Missing ::EQVERSION:: header" unless $content =~ /::EQVERSION::/m;
  return "Missing ::START:: marker" unless $content =~ /::START::/m;
  return "Missing ::END:: marker" unless $content =~ /::END::/m;

  # Write to temp file and run syntax check
  use File::Temp qw(tempfile);
  my ($fh, $tmpfile) = tempfile(SUFFIX => '.equiz', UNLINK => 1);
  print $fh $content;
  close $fh;

  use Cwd qw(getcwd);
  my $executable = getcwd() . "/lib/SylSpace/Model/eqbackend/eqbackend.pl";
  
  my @cmd = ($executable, $tmpfile, 'fullsyntax');
  my $output;
  my $exitcode;
  {
    local $SIG{CHLD} = 'DEFAULT';
    open(my $ph, '-|', @cmd) or return "Cannot run syntax checker: $!";
    local $/;
    $output = <$ph>;
    close($ph);
    $exitcode = $? >> 8;
  }

  unlink $tmpfile;

  if ($exitcode == 0 && $output =~ /successful/i) {
    return undef;  # no error
  }

  # Clean up error message
  $output =~ s/\s+$//;
  $output =~ s/^\s+//;
  return $output || "Syntax check failed";
}

1;

################################################################

__DATA__

@@ instructorequizeditsaveview.html.ep

%title 'syntax error';
%layout 'instructor';

<main>

<div class="alert alert-danger">
  <h3><i class="fa fa-exclamation-triangle"></i> Syntax Error</h3>
  <p style="font-family: monospace; white-space: pre-wrap; margin-top: 1em;"><%= $error %></p>
</div>

<p>Please close this window and fix the error in the editor.</p>

<p><strong>File:</strong> <%= $fname %></p>

<button onclick="window.close();" class="btn btn-primary">Close This Window</button>

</main>



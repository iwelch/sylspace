#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::InstructorEquizsyntax;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo);
use SylSpace::Model::Controller qw(global_redirect standard);

################################################################

post '/instructor/equizsyntax' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return $c->render(json => { error => 'not authorized' });

  sudo( $course, $c->session->{uemail} );

  my $content = $c->req->params->param('content') // '';
  
  # Basic validation
  unless ($content =~ /::EQVERSION::/m) {
    return $c->render(json => { ok => 0, error => "Missing ::EQVERSION:: header", line => 1 });
  }
  unless ($content =~ /::START::/m) {
    return $c->render(json => { ok => 0, error => "Missing ::START:: marker", line => 1 });
  }
  unless ($content =~ /::END::/m) {
    return $c->render(json => { ok => 0, error => "Missing ::END:: marker", line => 1 });
  }

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
    open(my $ph, '-|', @cmd, '2>&1') or return $c->render(json => { ok => 0, error => "Cannot run syntax checker: $!" });
    local $/;
    $output = <$ph>;
    close($ph);
    $exitcode = $? >> 8;
  }

  unlink $tmpfile;

  if ($exitcode == 0 && $output =~ /successful/i) {
    return $c->render(json => { ok => 1 });
  }

  # Try to extract line number from error
  my $line = 1;
  if ($output =~ /line\s+(\d+)/i) {
    $line = $1;
  } elsif ($output =~ /question\s+(\d+)/i) {
    # Try to find the line of that question
    my $qnum = $1;
    my @lines = split /\n/, $content;
    my $count = 0;
    for (my $i = 0; $i < @lines; $i++) {
      if ($lines[$i] =~ /^:N:/) {
        $count++;
        if ($count == $qnum) {
          $line = $i + 1;
          last;
        }
      }
    }
  }

  # Clean up error message
  $output =~ s/\s+$//;
  $output =~ s/^\s+//;

  return $c->render(json => { ok => 0, error => $output, line => $line });
};

1;

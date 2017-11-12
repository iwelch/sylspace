#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::InstructorGradedownload;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(sudo);
use SylSpace::Model::Grades qw(gradesashash gradesasraw);
use SylSpace::Model::Controller qw(global_redirect  standard);

use Data::Dumper;

################################################################

get '/instructor/gradedownload' => sub {
  my $c = shift;
  (my $course = standard( $c )) or return global_redirect($c);

  sudo( $course, $c->session->{uemail} );

  sub wide {
    my $all= gradesashash( $_[0] );
    my $rs= "";
    $rs.= "Student";
    foreach (@{$all->{hw}}) { $rs.= ",$_"; }
    $rs.= "\n";

    foreach my $st (@{$all->{uemail}}) {
      $rs.= "$st";
      foreach my $hw (@{$all->{hw}}) {
	$rs.= ",".($all->{grade}->{$st}->{$hw}||"");
      }
      $rs.= "\n";
    }
    return $rs;
  }

  sub flong {
    my $s="student,hw,grade,epoch,date\n".gradesasraw( $_[0] );
    $s =~ s/\t/\,/gm;
    $s =~ s/(.*\,)(1\d+)/"$1$2,".localtime($2)/ge;
    return $s;
  }

  ## the following two functions should be refactored, and potentially also output the full line (unused info)
  
  sub fbestscore {
    my @lines=split(/\n/, gradesasraw( $_[0] ) );

    my %best;
    foreach (@lines) {
      my @fields= split(/\t/, $_);
      my $id = $fields[0].",".$fields[1];
      my $score = ($fields[2] =~ /([0-9]+)\s*\/\s*[0-9]+/) ? $1 : (-99);
      ((!exists($best{$id})) || ($best{$id} < $score)) and $best{$id}= $score;
    }
    my $s="student,task,grade\n";
    foreach (sort keys %best) { $s .= $_.",   ".$best{$_}."\n"; }
    return $s;
  }

  sub ftimescore {
    my @lines=split(/\n/, gradesasraw( $_[0] ) );

    my %best;
    foreach (@lines) {
      my @fields= split(/\t/, $_);
      my $id = $fields[0].",".$fields[1];
      my $score = ($fields[2] =~ /([0-9]+)\s*\/\s*[0-9]+/) ? $1 : (-99);
      $best{$id}= $score;
    }
    my $s="student,task,grade\n";
    foreach (sort keys %best) { $s .= $_.",   ".$best{$_}."\n"; }
    return $s;
  }

  my $sf= $c->req->query_params->param('sf');
  return ($sf eq "w") ? $c->render(text => wide( $course ), format => 'csv') :
    ($sf eq "l") ? $c->render(text => flong( $course ), format => 'csv') :
    ($sf eq "b") ? $c->render(text => fbestscore( $course ), format => 'csv') :
    ($sf eq "t") ? $c->render(text => ftimescore( $course ), format => 'csv') : $c->render(text => "fatal format error in IGD.  what is $sf?");
  die "sorry, what format is $sf supposed to be?";
};

1;

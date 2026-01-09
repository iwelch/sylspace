#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package RenderEquizTxt;
use strict;
use warnings;
use warnings FATAL => qw{ uninitialized };

=pod

=head1 NAME

  RenderEquizTxt --- render a version much simpler to STDOUT

=cut

################################################################################################################################
sub renderequiztxt {
  my $qz= shift;

  my $spcnt=0; my $qcnt=0;

  foreach my $q (@{$qz->{q}}) {
    if ($q->{'M'}) {
      next;
    }
    (defined($q->{'S'})) or die "perl $0: error: question $q->{'N'} must have an S field!: \n";
      ++$qcnt;
      $q->{'QCNT'}= $qcnt;

      my $mC= (defined($q->{'C'})) ? "<p><b> Choices: </b>".$q->{'C'}."</p>" : "";

      $q->{'Q'} =~ s/\n/  |  /smg;
      $q->{'A'} =~ s/\n/  |  /smg;

      print qq(

---------------- C$qcnt: ID = I$qcnt=$q->{'QCNT'} : NAME = N$qcnt=$q->{'N'}:

LOCAL INITS:
 	$q->{'I'}

QUESTION:
        $q->{'Q'}\n);

      print qq(
ANSWER ($q->{'S'}):
	A: $q->{'A'}

);

      if (defined($q->{'DUMPED'})) {
	print $q->{'DUMPED'};
      } else {
	print "[DUMPED to help debug stored variables is currently not enabled in EvalOneQuestion.pm]\n";
      }

      ## $subpagelist .= qq(\t\t<option value="$qcnt"> Choose page $qcnt : $q->{'N'} </option>\n);
    }


  print STDERR "[RenderEquizTxt exit ok]\n";

}

################################################################################################################################

($0 =~ /RenderEquizTxt\.pm$/i) and die "perl $0: Sorry, RenderEquizTxt does not have a test.\n";

################################################################################################################################

1;

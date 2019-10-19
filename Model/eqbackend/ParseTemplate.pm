#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package ParseTemplate;
use strict;
use warnings;
use warnings FATAL => qw{ uninitialized };

################################################################################################################################

=pod

=head1 NAME

  ParseTemplate.pm --- create an equiz hash-object from an equiz template file

=head1 USE

  my $object= parsetemplate( slurp( "tutorial.equiz" ) );

to see the full contents of the object, run this program as

  # perl ./ParseTemplate.pm < tutorial.equiz

the program breaks the file into the preamble and the main file.  then each is parsed by its own routine.

=cut

  use Data::Dumper;

################################################################

sub parsetemplate {
  my $issolo=$_[1];
  $_= $_[0]. (($issolo)?"":"\n::END::\n");  ## can work with a string that is not ::END:: terminated


  (s/^\#.*$//gm);  ## wipe out all comments --- at the start of a line, we need 1
  (s/^:\#.*$//gm);  ## wipe out all comments --- at the start of a line, we need 1
  (s/\#\#.*$//gm);  ## wipe out all comments --- in the middle of a line, we need 2

  ($issolo) and return { q => parsemain($_) };

  (/^\s*::EQVERSION::/m) or die "perl $0: Equiz must start with ::EQVERSION::, not '$_'\n";
  (/^::START::/m) or die "perl $0: equiz does not contain a proper start in <pre>$_</pre>";
  (/(.*)^::START::(.*?)^::END::/ms) or die "perl $0: Equiz does not contain a ::START:: ... ::END:: segment\n";

  return { h => parsepreamble($1), q => parsemain($2) };
}


################
sub parsepreamble {
  my $preamble= $_[0];
  my %qzhdr;

  ## allowed ::START:: fields with default values
  my @validkeys= qw/name* instructor* gradename area subarea license created version render comment intro ps comment eqversion sharing paging email shuffle finish_page/;

  foreach my $v (@validkeys) {
    my $VKF= lc($v);
    my $VKFDEF = ($VKF =~ s/\*$//) ? 2 : 1;
    $qzhdr{$VKF} = ""; ## default contents are empty
  }

  $qzhdr{randgenerated} = localtime() . " = " . time();

  my @preamble = split(/\n\:\:/, $preamble);

  foreach my $p (@preamble) {
    if ($p =~ /^([\w]+)\:\:(.*)/smi) {
      my $tag=lc($1); my $content=$2;
      ($tag =~ /comment/i) and next;
      $qzhdr{$tag} = returnsuperchomp($content);  ## remove leading and trailing spaces
      $tag =~ s/\*$//;  ## we also remove trailing spaces from the tag
      (exists($qzhdr{$tag})) or die "perl $0: Sorry, but second header key '$tag' is invalid in ".(join(" ",@validkeys))."\n";
    }
  }

  foreach my $k (@validkeys) {
    ($k =~ /([\w]+)\*/) or next;
    (defined($qzhdr{$1})) or die "perl $0: Required header key '$1' ($k) is missing in equiz file.".Dumper(\%qzhdr)."\n";
  }

  return \%qzhdr;
}



################
sub parsemain {
  my @pages= split(/\n\:N\:/, "\n\n$_[0]");
  shift(@pages);  ## skip the front

  foreach my $po (@pages) {
    $po = ":N: $po";
    ($po =~ s/^:E:\s*$//ms) or die "\nperl $0: Syntax Error: question '".returnsuperchomp($po)."' does not end with :E:\n";
  }

  my @result;
  foreach my $po (@pages) { push(@result, parse1subpage($po)); }
  return \@result;
}



sub parse1subpage {
  (/\:S\:/) and die "perl $0: equiz language has been updated to V2;  please convert all short tags to ANS in :I:";
  my $validtags = "[NQICATDMP]"; # Name, Question, Init, Choice, Answer, Time, Difficulty, Message, Precision.  (must not be a regex).
  my @fields = split(/^\:($validtags)\:/ms, $_[0]);
  shift(@fields);  ## the split maintains the alternating order, but has one header before the first tag
  my $qname="qname not yet defined";
  my %x= @fields;
  foreach my $k (keys %x) {
    ($k =~ /$validtags/) or die "perl $0: Parsing Error:  Question $_[0] has unknown or multi-letter field '$k'\n";
    $x{$k} = returnsuperchomp($x{$k});
  }

  (exists($x{N})) or die "perl $0: Sorry, but $_[0] contains no name :N: tag\n";
  ($x{N} =~ /\w/) or die "perl $0: Sorry, but $_[0] contains an empty or nonsensible name :N: tag\n";
  $x{N}= returnsuperchomp($x{N});

  if (exists($x{M})) {
     # it is not a question, but a message
     foreach (qw(Q I C A T D P)) {
       (exists($x{$_})) and die "perl $0: message $x{N} ('$_[0]') contains both :M: and :$_: tags.  if you mean this to be part of the message, then please indent the :$_: tag.\n";
     }
     return \%x;
  }
  foreach (qw(Q I A)) {
  	  (exists($x{$_})) or die "perl $0: question $x{N} ('$_[0]') must have a '$_' tag\n";
  	  ($x{$_} =~ /\w/) or die "perl $0: question $x{N} ('$_[0]') must have a nonempty '$_' tag\n";
  }
  ($x{'I'} =~ /\$ANS\s*\=/) or die "perl $0: question $x{N} ('$_[0]') must have an ANS in its :I: tag\n";


  return \%x;
}



sub returnsuperchomp { my $content= $_[0]; $content =~ s/^[\s\n]*//gms; $content =~ s/[\s\n]+$//gms; return $content; }

################################################################################################################################
if ($0 =~ "ParseTemplate.pm") {
  print STDERR "debug mode: parsing from stdin\n";
  $_ = do { local $/=undef; <STDIN> };

  my $quiz= parsetemplate($_);

  print Dumper($quiz);
}

1;

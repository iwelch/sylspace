#!/usr/bin/env perl
use strict;
use warnings;
use warnings FATAL => qw{ uninitialized };

use FindBin qw($Bin);
use lib "$Bin";


*STDERR = *STDOUT;

################################################################################################################################

=pod

=head1 NAME

  eqbackend.pl --- the first line are command and controls.  the remainder must be an equiz file.
		it renders the template from stdin (or a file), customizes (i.e., evaluate) the template,
 		and produce an html form to stdout

=head1 MODES

  $ eqbackend.pl inputfile.equiz ask encryptionsecret callbackhtml

  $ eqbackend.pl inputfile.equiz answers

	---the following is the main debug mode: fullsyntax comes after the equiz
  $ eqbackend.pl inputfile.equiz fullsyntax   ## one question, only syntax check; does require ::EQVERSION::

  $ eqbackend.pl inputfile.equiz solo     ## one question, useful in designer;  does not require ::EQVERSION:: etc

  $ eqbackend.pl inputfile.equiz solosyntax   ## one question, syntax check, but does not require ::EQVERSION::

=head1 DOCS

  run this with the tutorial.equiz, e.g.,

     $ eqbackend.pl tutorial.equiz

=head1 FUTURE

  it would not be difficult to wrap this into a socket.  The only global and static variables in the backend should be here.

  we may need to use 'use File::Basename qw/dirname/';

=head1 Revisions

=cut

################################################################################################################################

my $usage= "usage: eqbackend.pl equizname-first.equiz mode=[ask=normal|answers|fullsyntax|solosyntax] secret callbackurl user";

(defined(my $equizfilename= shift(@ARGV))) or die $usage;

if ($equizfilename =~ /solo/) {
  my $equizcontent= slurp(\*STDIN);
  my $qz= ParseTemplate::parsetemplate($equizcontent, 1);

  foreach my $q (@{$qz->{q}}) {
    ($q->{M}) or $q = EvalOneQuestion::evaloneqstn($q);  ## messages are already parsed and not evaluated
  }

  my %h = ( gradename => 'na', name => 'na', ntime => time(), callbackurl => '/testquestion', shuffle => 0, HTMLQALL => 'na' );
  $qz->{h}= \%h;

  print RenderEquiz::renderequiz($qz, 'stdin', 'solo');
  exit 0;
}

($equizfilename =~ /\.equiz$/i) or die "sorry, your file must end with extension 'equiz', not $equizfilename.";

(-e $equizfilename) or die "sorry, no file $equizfilename to be seen. ".`ls`;
(-r $equizfilename) or die "sorry, file $equizfilename exists but is not readable";

use Perl6::Slurp;
my $equizcontent= slurp($equizfilename);
(length($equizcontent)>0) or die "your equiz $equizfilename is empty\n";

my $mode= $ARGV[0];  ## leave on stack
(defined($mode)) or die "need an operating mode.\n$usage";
($mode =~ /^ask|normal|answers|solo|fullsyntax|solosyntax$/) or die "unknown mode '$mode'";
($mode eq "normal") and $mode="ask";

if ($mode !~ /solo/) {
  ($equizcontent =~ /^\s*::EQVERSION::/m) or die "I suspect that your file $equizfilename does not start with ::EQVERSION::, so it is probably not a proper equiz.";
  ($equizcontent =~ /::END::/) or die "I cannot see an ::END:: in your file, so it is probably not a proper equiz.";
}

use ParseTemplate;
my $qz= ParseTemplate::parsetemplate($equizcontent, ($mode =~ /solo/) );


if ($mode eq "mode=solo") {
  my %h = ( gradename => 'na', name => 'na', ntime => time(), callbackurl => '/testquestion', shuffle => 0, HTMLQALL => 'na' );
  $qz->{h}= \%h;
}


use EvalOneQuestion;
foreach my $q (@{$qz->{q}}) {
  ($q->{M}) or $q = EvalOneQuestion::evaloneqstn($q);  ## messages are already parsed and not evaluated
}

if ($mode=~/^syntax/) { print "syntax check on $equizfilename was successful. skipping render";  exit 0; }

if ($mode =~ /ask/) {
  ($#ARGV >= 3) or die "not enough arguments for mode 'ask'/'normal':\n$usage";
    ## (length($ARGV[1])>=4) or die "sorry, but your secret '$ARGV[1]' is too short";
  (($ARGV[2] =~ /^http/)||($ARGV[2] =~ m{/instructor/equizcollectanswer})) or die "sorry, but your callbackurl must begin with http or be hardcoded";
  ($ARGV[3] =~ /\@/) or die "sorry, but your user must be email identified";
} else {
  @ARGV= ( $mode, "", "", 'testuser@test.com', "anything else to be passed" );
}

use RenderEquiz;
print RenderEquiz::renderequiz($qz, $equizfilename, @ARGV);

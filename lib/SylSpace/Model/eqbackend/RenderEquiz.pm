#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package RenderEquiz;
use strict;
use warnings;
use warnings FATAL => qw{ uninitialized };

=pod

=head1 NAME

  RenderEquiz --- render a single html output file that contains the form, questions, encrypted answers, etc.

=head1 USE

  OUTDATED print renderequiz( $object );

=head1 NOTES

  The main HTML template appears at the end of this file as a HEREDOC.

=cut


## not used any longer because numbers can be inside a mathjax question
## my $makenumslooknicer = 1;	# cuts numbers off after 3 digits
## my $mathminus = '-';  ## if '\&minus;', we will substitute in to make this look nicer on HTML.

#my $MAGIC = 'MAGIC';

################################################################################################################################
my $unhide=0;

use Encode;
use HTML::Entities;

my $cipherhandle;
sub encryptencode {
  use Crypt::CBC;
  use MIME::Base64;

  (defined($cipherhandle)) and return encode_base64($cipherhandle->encrypt($_[0]));
  return "(ENCRYPTED:) '$_[0]'";
}

################################################################################################################################
sub renderequiz {
  my $qz= shift;

  my ($equizfilename, $mode, $secret, $callbackurl, $user) = @_;  ## just pass back
  my $time= time();

  ## if we are in a non standard mode, we need not encrypt
  (defined($mode)) or die "internal backend error: you have no mode. invoked with $equizfilename".join(" ", @ARGV)."\n";

  if ($mode eq "ask") {
    $cipherhandle = Crypt::CBC->new( -key => $secret, -cipher => 'Blowfish', -salt => '14151617' );
  } else {
    $unhide=1;
  }

# name* instructor* gradename area subarea license created version render comment intro ps comment eqversion sharing paging email shuffle finish_page

  $qz->{h}->{confidential} = encryptedhidden( "confidential", "confidential|".join('|', @_).'|'.$time.'|'.hostname().'|'.($qz->{h}->{gradename}).'|'.($qz->{h}->{name}).'|'.rand());
  $qz->{h}->{ntime}= $time;
  $qz->{h}->{callbackurl}= $callbackurl;

  my @LOQ= @{$qz->{q}};
  if ($qz->{h}->{shuffle}) {
    @LOQ = shuffle(@LOQ);
    if ($qz->{h}->{shuffle} =~ /^[1-9]/) {
      $#LOQ= $qz->{h}->{shuffle};  ## truncates to this number of questions
    }
  }

  my $subpagelist .= "";

  #### prerender all members of $q->{q}
  my $qcnt=0; my $spcnt=0;

  foreach my $q (@{$qz->{q}}) {
    ++$spcnt; $q->{'SPCNT'}= $spcnt;
    $subpagelist .= qq( "$spcnt" : ($q->{'N'}||"no page title"), );

    if ($q->{'M'}) {
      $q->{'M'} = qq(
	     <div class="qmsg">
                $q->{'M'}
              </div><!--qmsg-->
            );
      next;
    } else {
      (defined($q->{'S'})) or die "perl $0: error: question $q->{'N'} must have an S field!: \n";
      ++$qcnt;
      $q->{'QCNT'}= $qcnt;

      my $mC= (defined($q->{'C'})) ? "<p><b> Choices: </b>".$q->{'C'}."</p>" : "";

      $q->{'M'} = qq(
              <div class="qstn" id="C$qcnt">
                <p class="qstnid" id="I$qcnt" style="hidden">$q->{'QCNT'}</p>
                <p class="qstnname" id="N$qcnt">$q->{'N'}</p>
                <p class="qstntext" id="TXT$qcnt">$q->{'Q'}</p>\n)
	  # now come all the input elements
	.(($q->{'C'}) ? (hidden('C', $qcnt, $q->{'C'})) : "")
	.(hidden('N', $qcnt, $q->{'N'}))
	.(hidden('Q', $qcnt, $q->{'Q'}))
	.(encryptedhidden('A', $qcnt, $mC.$q->{'A'}))
	.(encryptedhidden('S', $qcnt, $q->{'S'}))
	.(($q->{'P'}) ? encryptedhidden('P', $qcnt, $q->{'P'}) : '')
	.(defined($q->{'C'}) ? drawinputmultchoice($qcnt, $q->{'C'}) : drawinputtextfield($qcnt))
	.(($q->{'P'}) ? qq(\t\t<p class="qstnprec" id="P$qcnt">&plusmn;$q->{'P'}</p>\n) : "")
	.(($q->{'D'}) ? qq(\t\t<p class="qstndiff" id="D$qcnt">$q->{'D'}</p>\n) : "")
	.(($q->{'T'}) ? qq(\t\t<p class="qstntime" id="T$qcnt">$q->{'T'}</p>\n) : "")

	.qq(\t\t</div> <!-- qstn $qcnt -->);

      ## $subpagelist .= qq(\t\t<option value="$qcnt"> Choose page $qcnt : $q->{'N'} </option>\n);
    }
  }

  ## ok --- we are prerendered.  now just do the quiz.

  $qz->{h}->{HTMLQALL}="";  ## start with this

  foreach my $qc (@{$qz->{q}}) {
    $qz->{h}->{HTMLQALL} .= "\n\n<!-- - - - - - - - - - - - - - - SUBPAGE $qc->{SPCNT} - - - - - - - - - - - - - - --> \n";
    $qz->{h}->{HTMLQALL} .= "\t\t\<div class=\"subpage\" id=\"SPC$qc->{SPCNT}\"> <div class=\"qname\"><span class=\"qnum\" id=\"qcSPC$qc->{SPCNT}\">$qc->{SPCNT}</span> $qc->{N}</div>$qc->{M}\n\n\t\t<\/div> <!--subpage--> \n";
    $qz->{h}->{HTMLQALL} .= "\n\n<!-- - - - - - - - - - - - - - -  SUBPAGE $qc->{SPCNT} - - - - - - - - - - - - - - --> \n";
  }


  if (!defined($cipherhandle)) {
    ## no title info and submit button
    print qq(
           $qz->{h}->{HTMLQALL}
   );
    return;
  }

  use Sys::Hostname;

  use Data::Dumper;
my $xcc= "<b>DUMPER: ".(Dumper $qz->{h});

  my $template= q(

    <!-- created by eqbackend.pl:RenderEquiz.pm -->

    <div class="eqheader">
      <div class="eqauthor"> [+ $instructor +] </div>
      <div class="eqname"> [+ $name +] </div>
      <div class="eqversion"> [+ $version +] </div>
      <div class="eqgenerated"> [+ $randgenerated +] </div>
      <div class="eqintro"> [+ $intro +]
      <p style="font-size:small">(Always quote percents as decimal [unless specifically requested otherwise].  That is, for 5%, please answer 0.05 and not 5.)</p> </div> <!-- eqintro -->
    </div> <!--eqheader-->

    <!-- now come the equiz questions -->

    <div class="equiz">

      <div class="container">

        <form method="post" class="quizform" action="[+ $callbackurl +]">

         [+ $HTMLQALL +]

         [+ $confidential +]
         <input type="hidden" name="ntime" value="[+ $ntime +]" />

           <div class="quizsubmitbutton">
              <input type="submit" class="quizsubmitbutton" name="submit" value="Submit and Grade my Answers" /><br />
           </div><!--quizsubmitbutton-->

        </form>

       </div><!--container-->

    <hr />

    [+ $ps +]

    </div><!--class="equiz"-->
);

  $qz->{h}->{ps}= ($qz->{h}->{ps} =~ /\w/) ? '<div class="eqps"> '.($qz->{h}->{ps}).'</div>' : '';
  foreach my $subout (qw/name title author intro ps HTMLQALL callbackurl confidential ntime instructor secret randgenerated version/) {
    (defined($qz->{h}->{$subout})) and $template =~ s/\[\+\s*\$$subout\s*\+\]/$qz->{h}->{$subout}/gms;
  }

  return $template;
}


################################################################
sub hidden {
  my $value= pop(@_);  ## the last value is always the value; everything else is concat-ed to the name
  my $name= join("-", @_);
  (defined($value)) or die "perl $0: need value in hidden";
  (defined($name)) or die "perl $0: need key in hidden for value $value";
  ($unhide) and return nothidden($value, $name);
  $value= encryptencode($value);
  return qq(<input type="hidden" name="$name" value="$value" />\n);
}

sub encryptedhidden {
  my $value= pop(@_);  ## the last value is always the value; everything else is concat-ed to the name
  my $name= join("-", @_);
  (defined($value)) or die "perl $0: need value in encryptedhidden";
  (defined($name)) or die "perl $0: need key in hidden for value $value";
  ($unhide) and return nothidden($value, $name);
  $value= encode_entities(encryptencode($value));
  return qq(<input type="hidden" class="encrypted" name="$name" value="$value" />\n);
}


sub nothidden {
  my ($value, $name)= @_;
  return "\t\t<div class=\"unhide\">\n<span class=\"unhidename\"><b> Key</b> \"$name\": </span>\n<span class=\"unhidevalue\"><b>Value</b>: \"" . encode_entities($value) ."\"</span> </div>\n";
}

################################################################
sub drawinputmultchoice {
    my ($qcntname,$choices)= @_;

    my @choices= split(/\|/, $choices);
    my $rv= qq(\t\t<fieldset> <legend>Please Choose One</legend>\n\t\t<ol class="eqchoice" id="MC$qcntname">\n);
    for (my $i=0; $i<= $#choices; ++$i) {
      $rv .= qq(\t\t<li> <input class="eqchoice foo" type="radio" required value=").($i+1).qq(" name=\"q-stdnt-$qcntname\" />&nbsp;&nbsp; $choices[$i] </li>\n);
    }
    $rv .= "\t\t\t</ol>\n\t\t\t</fieldset>\n";
    return $rv;
  }

sub drawinputtextfield {
  my ($qcntname) = @_;

  return qq(\t\t<p class="eqinputnum" id="NC$qcntname">Your Answer:&nbsp;&nbsp;&nbsp; <input class="eqinputnum foo" required type="number" step="any" size="8" name="q-stdnt-$qcntname" /><br />\n\t\t\t<span style="font-size:smaller">(enter only numbers [digits, minus, period])</span></p>\n);
}


################################################################################################################################

($0 =~ /RenderEquiz\.pm$/i) and die "perl $0: Sorry, RenderEquiz does not have a test.\n";

################################################################################################################################

1;

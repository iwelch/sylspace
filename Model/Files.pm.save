#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Model::Files;

use base 'Exporter';
@ISA = qw(Exporter);

our @EXPORT_OK=qw(
  eqsetdue hwsetdue
  collectstudentanswers

  eqsetdue eqlisti eqlists eqwrite eqreads eqreadi
  filesetdue filelisti filelists filereadi filereads filewritei filedelete fileexistsi fileexistss
  hwsetdue hwlisti hwlists hwreadi hwreads hwwrite hwdelete
  answerlists answerread answerwrite answerlisti answercollect answerhashs answerdelete

  finddue ispublic

  longfilename

  cptemplate rmtemplates listtemplates
);

################
use strict;
use common::sense;
use utf8;
use warnings;
use warnings FATAL => qw{ uninitialized };
use autodie;

use feature ':5.20';
use feature 'signatures';
no warnings qw(experimental::signatures);

use Data::Dumper;
use Perl6::Slurp;
use File::Copy;
use File::Glob qw(bsd_glob);
use File::Touch;
use Email::Valid;

use Scalar::Util::Numeric qw(isint);


use lib '../..';
use SylSpace::Model::Utils qw( _getvar _confirmsudoset _checksfilenamevalid _checkemailvalid _burpnew);

my $var= _getvar();

################################################################################################################################

=pod

=head2 File interface. 

instructors can store and read all files.  students can only read
published instructor files, plus own files that they have uploaded.

=cut

################################################################

sub longfilename( $course, $sfilename ) {
  $course= _checksfilenamevalid( $course );
  $sfilename= _checksfilenamevalid( $sfilename );
  return "$var/courses/$course/instructor/files/$sfilename";
}





################################################################
sub filelisti( $course, $filename='!other' ) { return _baselisti($course, $filename); }
sub filelists( $course ) { return _baselists($course, '!other'); }
sub filereadi( $course, $filename ) { return _basereadi( $course, $filename ); }
sub filereads( $course, $filename ) { return _basereads( $course, $filename ); }
sub filewritei( $course, $filename, $filecontents ) { return _basewritei( $course, $filename, $filecontents ); }
sub filedelete( $course, $filename ) { return _basedelete( $course, $filename ); }


################################################################
sub hwsetdue( $course, $hwname, $epoch ) { return filesetdue( $course, $hwname, $epoch ); }
sub hwlisti( $course, $hwname="hw*" ) { return _baselisti( $course, $hwname ); }
sub hwlists( $course ) { return _baselists( $course, "hw*" ); }  ## from the students
sub hwreadi( $course, $hwname ) { ($hwname =~ /^hw/) or die "hwreadi: '$hwname' must start with hw\n"; return _basereadi( $course, $hwname ); }
sub hwreads( $course, $hwname ) { ($hwname =~ /^hw/) or die "hwreads: '$hwname' must start with hw\n"; return _basereads( $course, $hwname ); }
sub hwwrite( $course, $hwname, $hwcontents ) { ($hwname =~ /^hw/) or die "hwwrite: '$hwname' must start with hw\n"; return _basewritei( $course, $hwname, $hwcontents ); }
sub hwdelete( $course, $hwname ) { ($hwname =~ /^hw/) or die "hwdelete: '$hwname' must start with hw\n"; return _basedelete( $course, $hwname ); }
#sub hwrate( $course, $hwname, $rating ) { ($hwname =~ /^hw/) or die "hwrate: '$hwname' must start with hw\n"; return _baserate( $course, $hwname, $rating ); }

################################################################################################################################

sub eqsetdue( $course, $eqsymname, $epoch ) { ($eqsymname=~ /\.equiz[\~]*/) or die "eqsymsetdue: $eqsymname must end with .equiz"; return filesetdue( $course, $eqsymname, $epoch ); }
sub eqlisti( $course ) { return _baselisti( $course, "*.equiz" ); }
sub eqlists( $course ) { return _baselists( $course, "*.equiz" ); }
sub eqreadi( $course, $eqsymname ) { ($eqsymname=~ /\.equiz[\~]*/) or die "eqsymreadi: $eqsymname must end with .equiz"; return _basereadi( $course, $eqsymname );  }
sub eqreads( $course, $eqsymname ) { ($eqsymname=~ /\.equiz[\~]*/) or die "eqsymreads: $eqsymname must end with .equiz"; return _basereads( $course, $eqsymname, 1 ); }
sub eqwrite( $course, $eqsymname, $eqsymcontents ) { ($eqsymname=~ /\.equiz[\~]*/) or die "eqsymreads: $eqsymname must end with .equiz"; return _basewritei( $course, $eqsymname, $eqsymcontents ); }
sub eqdelete( $course, $eqsymname ) { ($eqsymname =~ /^eqsym/) or die "eqsymdelete: $eqsymname must end with .equiz\n"; return _basedelete( $course, $eqsymname ); }

################################################################################################################################



## note: returns not a list, but a listptr
sub _baselisti( $course, $mask="*") {
  $course= _checksfilenamevalid( $course );
  my $ilist= _deeplisti("$var/courses/$course/instructor/files/", $mask);
  (rlc($ilist)>0) or return $ilist;
  my @slist; foreach (@{$ilist}) { push(@slist, $_); }  ## always open!
  return \@slist;
}


## note: returns not a list, but a listptr
sub _baselists( $course, $mask="*") {
  $course= _checksfilenamevalid( $course );
  my $ilist= _deeplisti("$var/courses/$course/instructor/files/", $mask);

  (rlc($ilist)>0) or return $ilist;

  my @slist; foreach (@{$ilist}) {
    if ($mask ne '*.equiz') { ($_->{sfilename} =~ /.equiz$/) and next; } ## unless specifically requested, we do not display equizzes in the _base list
    if ($mask ne 'hw*') { ($_->{sfilename} =~ /^hw$/) and next; } ## or homeworks
    (time() <= ($_->{duetime})) and push(@slist, $_);
  }
  return \@slist;
}

sub _basereadi( $course, $filename) {
  $course= _confirmsudoset( $course );  ## lc()
  _checksfilenamevalid($filename);
  my $lfnm="$var/courses/$course/instructor/files/$filename";

  (-l $lfnm) and $lfnm= readlink($lfnm);
  return slurp $lfnm;  ## does not like symlinked _bases
}


sub _basereads( $course, $filename, $equizspecial=0) {
  $course= _checksfilenamevalid($course);
  _checksfilenamevalid($filename);
  my $lfnm="$var/courses/$course/instructor/files/$filename";
  (time() >= finddue( $lfnm )) and die "sorry, but there is no (longer) $lfnm";
  if (!$equizspecial) { ($filename =~ /\.equiz/) and die "sorry, but we never show off equiz source to students"; }
  (-l $lfnm) and $lfnm= readlink($lfnm);
  return slurp $lfnm;
}


sub _basewritei( $course, $filename, $filecontents ) {
  $course= _confirmsudoset( $course );  ## lc()
  _checksfilenamevalid($filename);
  return _maybeoverwrite( "$var/courses/$course/instructor/files/$filename", $filecontents );
}


sub _basedelete( $course, $sfilename ) {
  $course= _confirmsudoset( $course );  ## lc()
  $sfilename =~ s{$var/courses/$course/instructor/files/}{};
  _checksfilenamevalid($sfilename);
  my $lfilename = "$var/courses/$course/instructor/files/$sfilename";
  (-e $lfilename) or die "cannot delete non-existing $lfilename";
  unlink($lfilename);
  (-e $lfilename.'~') and unlink($lfilename.'~');
  my @duefile = bsd_glob("$lfilename\~due\=*");
  foreach (@duefile) { unlink($_); }
}

################################################################################################################################

sub answerhashs( $course, $uemail ) {
  my @list= bsd_glob("$var/courses/$course/$uemail/files/*\~answer\=*");
  my %rh;
  foreach (@list) {
    m{$var/courses/$course/$uemail/files/(.*)\~answer\=(.*)};
    (defined($2)) or next;  # or error
    $rh{$2}=$1;
  }
  return \%rh;
}

sub answerlists( $course, $uemail, $mask="*" ) {
  $course= _checksfilenamevalid( $course );
  $uemail= _checkemailvalid($uemail);
  (-e "$var/courses/$course/$uemail/") or die "answerlists: $uemail is not enrolled in $course";
  my $ilist= _deeplisti("$var/courses/$course/$uemail/files/", $mask);
}

sub answerread( $course, $uemail, $ansname ) {
  $course= _checksfilenamevalid( $course );
  $uemail= _checkemailvalid($uemail);
  (-e "$var/courses/$course/$uemail/") or die "answerread: $uemail is not enrolled in $course";
  _checksfilenamevalid($ansname);
  return slurp( (bsd_glob("$var/courses/$course/$uemail/files/*$ansname*"))[0] );
}

sub answerwrite( $course, $uemail, $hwname, $ansname, $anscontents ) {

  $course= _checksfilenamevalid( $course );
  $uemail= _checkemailvalid($uemail);

  (-e "$var/courses/$course/$uemail/") or die "answerwrite: $uemail is not enrolled in $course";

  _checksfilenamevalid($ansname);  ## will die!
  _checksfilenamevalid($hwname);

  # the F@#! perl bsd_glob does not understand that it should return undef if file does not exist
  # it does so only if the filename contains '*'.  so, we test with -e
  (-e bsd_glob("$var/courses/$course/instructor/files/$hwname"))
    or die "instructor has not posted a homework starting with $hwname";
  
  ########################################
  #my @existing= bsd_glob("$var/courses/$course/$uemail/files/*\=$hwname");

#  if (defined($existing[0])) {
	#my $oldanswer = $existing[0];
	#$oldanswer =~ s{.*\/}{}g;
	#$oldanswer =~ s{\~.*$}{};
	#answerdelete($course, $uemail, $hwname, $oldanswer);
#}
   
####die "you already have an uploaded homework named '$existing[0]' for homework '$hwname'.  please delete first.";
##########################################
  my $existing= bsd_glob("$var/courses/$course/$uemail/files/*\=$hwname");
  (defined($existing)) and
   die "you already have an uploaded homework named '$existing' for homework '$hwname'.  please delete first.";

  my $rv= _maybeoverwrite( "$var/courses/$course/$uemail/files/$ansname", $anscontents );

  touch( "$var/courses/$course/$uemail/files/$ansname~answer=$hwname" );

  return $rv;
}


sub answerdelete( $course, $uemail, $hwname, $answername ) {
  $course= _checksfilenamevalid( $course );
  $uemail= _checkemailvalid($uemail);
  _checksfilenamevalid($hwname);
  _checksfilenamevalid($answername);  ## will die!

  ($hwname =~ /^hw/) or die "hwdelete: '$hwname' must start with hw\n";
  my $existing1=bsd_glob("$var/courses/$course/$uemail/files/$answername\~answer\=$hwname");
  (-e $existing1) or die "you cannot delete a nonexisting file '$existing1'\n".`ls $var/courses/$course/$uemail/files/`;
  my $existing2=bsd_glob("$var/courses/$course/$uemail/files/$answername");
  (-e $existing2) or die "you cannot delete a nonexisting file '$existing2'\n".`ls $var/courses/$course/$uemail/files/`;

  unlink($existing1) or die "failed to delete file $existing1.\n";
  unlink($existing2) or die "failed to delete file $existing2.\n";

  return 0;
}



sub answerlisti( $course, $hwname ) {
  $course= _checksfilenamevalid( $course );
  _checksfilenamevalid($hwname);

  my $retrievepattern="$var/courses/$course/*@*/files/*answer=$hwname";
  my @filelist= bsd_glob($retrievepattern);
  (@filelist) or return undef;  ## no files yet;
  return \@filelist;
}

sub answercollect( $course, $hwname ) {
  $course= _checksfilenamevalid( $course );
  _checksfilenamevalid($hwname);

  my $retrievepattern="$var/courses/$course/*@*/files/*answer=$hwname";
  my @filelist= bsd_glob($retrievepattern);
  (@filelist) or return "";  ## no files yet;

  my $zip= Archive::Zip->new();
  my $ls=`ls -lt $retrievepattern`;
  $zip->addString( $ls, '_MANIFEST_' ); ## contains date info

  my $archivednames="";
  foreach (@filelist) {
    my $fname= $_; $fname=~ s{$var/courses/$course/}{};  $fname=~ s{/files/}{-};
    $_=~ s{~answer=$hwname}{};  ## now $fname is 'blah~answer=$hwname' and is empty
    				## $_ is 'blah' which has content
    $zip->addFile( $_, $fname );  $archivednames.= " $fname ";
  }

  my $ofname="$var/courses/$course/instructor/files/$hwname-answers-".time().".zip";
  $zip->writeToFileNamed( $ofname );
  return $ofname;
}



################################################################
## TEMPLATES
################################################################

sub listtemplates( ) {
  my @list= bsd_glob("$var/templates/*");
  foreach (@list) { s{$var/templates/}{}; }
  return \@list;
}


sub cptemplate( $course, $templatename ) {
  $course= _confirmsudoset( $course );

  (-e "$var/templates/") or die "templates not yet installed.";
  (-e "$var/templates/$templatename") or die "no template $templatename";

  my $count=0;
  foreach (bsd_glob("$var/templates/$templatename/*.equiz")) {
    (my $sname= $_) =~ s{.*/}{};
    (-e "$var/courses/$course/instructor/files/$sname") and next;  ## skip if already existing
    symlink($_, "$var/courses/$course/instructor/files/$sname") or die "cannot symlink $_ to $var/courses/$course/instructor/files/$sname: $!\n";
    ++$count;
  }
  return $count+1; ## not to give an error!
}

sub rmtemplates( $course ) {
  $course= _confirmsudoset( $course );

  my $count=0;
  foreach (bsd_glob("$var/courses/$course/instructor/files/*")) {
    (-l $_) or next;
    my $pointsto = readlink($_);
    if ($pointsto =~ m{$var/templates/}) { 
unlink($_) or die "cannot remove template link: $!\n"; ++$count; }
  }
  _cleanalldeadlines($course); # still needs to be written below --- yanni!
  return $count;
}




################################################################

=pod

=head2 Deadline interface.

deadlines are (empty) filenames in the filesystem

=cut

################################################################

sub fileexistsi( $course, $fname ) {
  return (-e "$var/courses/$course/instructor/files/$fname");
}

sub fileexistss( $course, $fname ) {
  return (-e "$var/courses/$course/instructor/files/$fname");  ## bug
}

sub filesetdue( $course, $filename, $when ) {
  $course= _confirmsudoset( $course );
  _checksfilenamevalid($filename);
  return _deepsetdue( $when, "$var/courses/$course/instructor/files/$filename");
}

sub _cleanalldeadlines( $course ) {
  $course= _confirmsudoset( $course );
    # to be written and tested
  foreach (bsd_glob("$var/courses/$course/instructor/files/*")) {
    if (/~due=\d+/) {
      my $lfilename = $_;
      s/$var\/courses\/$course\/instructor\/files\///;
      s/~due=\d+//;
      fileexistsi($course,$_) or unlink($lfilename); 
    }
  }
   # --- yanni
}

#

sub ispublic( $course, $sfilename ) {
  (-e "$var/courses/$course/public/$sfilename") or return 0;
  return (finddue("$var/courses/$course/public/$sfilename")>time());
}

# 
# 
# sub publicfiles( $course, $uemail, $mask ) {
#   _cleandeadlines($course);
# 
#   my @files= _glob2last( "$var/courses/$course/public/".(($mask eq "X") ? "*" : "$mask").".DEADLINE.*" );
#   if ($mask eq "X") {  ## special!!!
#     @files = grep { $_ !~ /^hw/i } @files;
#     @files = grep { $_ !~ /\.equiz\.DEADLINE/i } @files;
#   }
#   foreach (@files) { s{\.DEADLINE\.[0-9]+$}{}; }
#   return \@files;
# }
# 
# ## remove expired files
# sub _cleandeadlines( $course, $basename="*" ) {
#   foreach ( bsd_glob("$var/courses/$course/public/$basename.DEADLINE.*") ) {
#     (-e $_) or next;  ## weird race condition; the link had already disappeared
#     (my $deadtime=$_) =~ s{.*DEADLINE\.([0-9]+)}{$1};  # wipe everything before the deadline
#     ($deadtime+0 == $deadtime) or die "internal error: deadline is not a number\n";
#     if ($deadtime <= time()) { unlink($_); next; }  ## we had just expired
#   }
# }
#



################################################################################################################################
## files utility subroutines
################################################################
sub _deeplisti( $globdir, $globfilename ) {
  ## does not check whether you are an su.  so don't return carelessly
  my $nothwequiz= ($globfilename eq '!other');
  ($nothwequiz) and $globfilename='*';

  my @filelist;
  foreach (bsd_glob("$globdir/$globfilename")) {
    my %parms;
    ($_ =~ /\~/) and next;  ## these are meta files!
    if ($nothwequiz) {
      ($_ =~ /\.equiz$/) and next;
      ($_ =~ m{$var\/.*\/hw}i) and next;
    }
    $parms{lfilename}= $_;
    ($parms{sfilename}= $_) =~ s{.*/}{};
    $parms{filelength}= -s $_;
    $parms{mtime}= ((stat($_))[9]);
    $parms{duetime}= finddue($_);
    (_findanswer($_)) and $parms{answer}= _findanswer($_);
    push(@filelist, \%parms);
  }
  return \@filelist;
}


sub _deepsetdue( $epoch, $lfilename ) {
  isint($epoch) or die "cannot set due date to non-int epoch $epoch";
  (($epoch==0)||($epoch>=time()-10)) or die "useless to set expiration to the past ($epoch) now=".time().".  use 0 for notpublic.";
  ((-l $lfilename) || (-e $lfilename)) or die "cannot set due date for non existing file $lfilename";
  foreach (bsd_glob("$lfilename\~due=*")) { unlink($_); }
  touch("$lfilename\~due=$epoch");
  return $epoch||1;  ## to signal non-failure if epoch is 0!
}


sub finddue( $lfilename ) {
  ((-l $lfilename) || (-e $lfilename)) or die "cannot read due date for non-existing file $lfilename";

  my @duelist= bsd_glob("$lfilename\~due=*");
  (@duelist) or return 0;
  (my $f= $duelist[0]) =~ s{.*\~due=}{};
  (isint($f)) or die "invalid due date $f for $lfilename";
  return $f;
}

sub _findanswer( $lfilename ) {
  ((-l $lfilename) || (-e $lfilename)) or die "cannot read due date for non-existing file $lfilename";

  my @duelist= bsd_glob("$lfilename\~answer=*");
  (@duelist) or return 0;
  (my $f= $duelist[0]) =~ s{.*\~answer=}{};
  return $f;
}


## this is a safe backup-and-replace function
sub _maybeoverwrite( $lfilename, $contents ) {
  (-e $lfilename) or return _burpnew( $lfilename, $contents );
  _burpnew( "$lfilename.new", $contents );

  use File::Compare;
  if (compare($lfilename, "$lfilename.new") == 0) {
    unlink("$lfilename.new");
    return 0;  ## signal that no replacement was necessary
  }

  copy($lfilename, "$lfilename\~") or die "cannot rename existing file $lfilename to $lfilename~: $!";
  rename("$lfilename.new", "$lfilename") or die "cannot rename new file $lfilename.new to become $lfilename: $!";
  return length($contents);
}



sub rlc { return scalar @{$_[0]}; }

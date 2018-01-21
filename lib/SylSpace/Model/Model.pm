#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Model::Model;

use base 'Exporter';
@ISA = qw(Exporter);

@EXPORT_OK=qw(
	       sudo tzi tokenmagic

	       isinstructor ismorphed
	       instructorlist instructoradd instructordel

		instructornewenroll

	       usernew userenroll userdisroll isenrolled morphinstructor2student unmorphstudent2instructor userexists getcoursesecret throttle
	       _listallusers

	       sitebackup isvalidsitebackupfile courselistenrolled courselistnotenrolled

	       readschema bioread biosave bioiscomplete cioread ciosave cioiscomplete

	       ciobuttonsave ciobuttons hassyllabus
	       studentlist studentdetailedlist

	       msgsave msgdelete msgread msgmarkasread msglistread msgshownotread

	       tweet showtweets showlasttweet seclog showseclog superseclog

	       equizrender equizgrade equizanswerrender   	       equizrate

	       _msglistnotread

	       paypallog
	    );

use lib '../..';
use SylSpace::Model::Files qw(eqreadi eqreads longfilename finddue);

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

################

use lib '../..';
use SylSpace::Model::Utils qw(  _getvar _checkemailvalid _checkcname _saferead _safewrite _confirmsudoset _setsudo _confirmnotdangerous _glob2lastnoyaml  _glob2last _burpapp _burpnew);


my $var= _getvar();

################

=pod

=head1 Title

  Model.pm --- the model driving SylSpace

=head1 Description

  although some output is provided in html format, the code is controller independent.

  all data is saved in the filesystem and only in ASCII format.  this makes it easy to debug actions.

  a site is organized as follow

	/var/sylspace/
		secrets.txt  <- a set of random strings, generated at site initiation
		templates/  <- equiz templates containing collections of (algorithmic) questions
		users/  <- this is shared across all sites. 
			email/ <- primarily contains a bio.yml file, plus a user tzi (timezone)
		sites/  <- individual courses
			<nameofcourse>/
				buttons.yml  <- user interface extra buttons
				cinfo.yml <- course info
				tasklist <- for what grades can be assigned
				grades <- log of grades assigned
				instructor/ <- file storage for the instructor that can be made public
				public/ <- (empty) files posting with expiration dates
				msgs/ <- messages for the class from the instructor
				secret= <- whether the course requires an entry secret
				security.log <- obvious
				...enrolled user emails...

  instructors are identified by having a file in their subdomain user directory that says instructor=1.  An instructor
  has an instructor directory, which is used to store files as an instructor (and publish them), and a directory as
  a user, which is used when the instructor has morphed into a student and/or to store the bio, etc.

=head1 Versions

  0.0: Sat Apr  1 10:55:38 2017

=cut

################################################################

use File::Temp;
use File::Path;
use File::Touch;
use File::Copy;
use Email::Valid;
use Perl6::Slurp;
use Data::Dumper;
use YAML::Tiny;
use File::Glob qw(bsd_glob);
use Archive::Zip;

use Scalar::Util qw(looks_like_number);
use Scalar::Util::Numeric qw(isint);

## user email information should not leak, either, so please use it only during debugging.
sub _listallusers() {
  my @users;
  foreach (glob("$var/users/*")) {
    chomp;
    s{.*/}{};
    push(@users, $_);
  }
  return \@users;
}


## create a zip file of the site, place it in the user directory, and return the filename
sub sitebackup( $course ) {
  $course= _confirmsudoset( $course );

  (-d "$var/courses/$course") or die "bad course";
  (-r "$var/courses/$course") or die "unreadable course";
  ((-d "$var/tmp") && (-w "$var/tmp")) or die "tmp was not created";

  ($course =~ /test/) and die "sorry, no webcoursebackup for testsite allowed";

  my $zip= Archive::Zip->new();
  _confirmnotdangerous($course, "subdomain in wss");
  my $ls=`ls -Rlt $var/courses/$course/`;
  $zip->addString($ls , '_MANIFEST_' );
  $zip->addTreeMatching( "$var/courses/$course", "backup", '(?<!\.zip)$' );

  my $ofname="$var/tmp/$course-".time().".zip";
  $zip->writeToFileNamed($ofname);

  return $ofname;
}

sub isvalidsitebackupfile( $fnm ) {
  ($fnm =~ m{^$var/tmp/[\w\-\.]+\.zip}) or die "internal error: '$fnm' is not a good site backup file\n";
}

################################################################

sub courselistenrolled( $uemail ) { return _courselist( $uemail, 1 ); }
sub courselistnotenrolled( $uemail ) { return _courselist( $uemail, 0 ); }

## inefficient, but unimportantly inefficient
sub _courselist( $uemail, $enrolltype ) {
  my $fnames;  my %coursenames;
  foreach (bsd_glob("$var/courses/*")) {
    (-d $_) or next;
    if (defined($uemail)) {
      my $isenrolled= ((-d "$_/$uemail")&&(!(-e "$_/disabled=1")));
      if (defined($enrolltype)) {
	(($enrolltype) && (!$isenrolled)) and next;
	((!$enrolltype) && ($isenrolled)) and next;
      }
    }
    (my $snm=$_) =~ s{.*/}{};
    $coursenames{$snm}= defined(getcoursesecret( $snm ))?1:0; ## the hash tells us whether the course has a required secret or not
  }
  return \%coursenames;
}

################################################################

sub getcoursesecret( $course ) { 
  (defined($course)) or die "you need a secret for a course, not for nothing";
  $course =~ s{^.*/}{};
  my $sf=bsd_glob("$var/courses/$course/secret=*");
  (defined($sf)) or return undef;
  $sf =~ s{.*secret\=}{};
  return $sf;
}

sub setcoursesecret( $course, $secret ) {
  if ((!defined($secret)) || ($secret =~ /^\s*$/)) {
    unlink(bsd_glob("$var/courses/$course/secret=*"));  ## or ignore
    return;
  }
  _confirmnotdangerous( $secret, "bad secret" );
  touch("$var/courses/$course/secret=$secret");
}


sub throttle( $seconds=5 ) {
  my @timestamps;
  ## each unique second throttle shares the same semaphore
  foreach ( bsd_glob("$var/tmp/throttle$seconds=*") ) {
    (defined($_)) or next;
    push(@timestamps, $_);
    (my $timestamp= $_) =~ s{.*throttle$seconds=}{};
    ($timestamp > 1000000) or die "non-sensible timestamp $timestamp in file system";
    ($timestamp + $seconds <= time()) or sleep($seconds);  ## conservative
  }
  touch("$var/tmp/throttle$seconds=".time());
  foreach (@timestamps) { unlink($_); }  ## files may have disappeared already, but noone cares
}

################
## creates a new user.  users can register themselves

sub usernew( $uemail ) {
  $uemail= _checkemailvalid($uemail);
  (-e "$var/users/$uemail") and return (-1);  ## this is a forgivable mistake, but signaled
  mkdir("$var/users/$uemail") or die "cannot create user name $uemail";

  # my $randomcode= join'', map +(0..9,'a'..'z','A'..'Z')[rand(10+26*2)], 1..15;
  # touch("$var/users/$uemail/code.$randomcode") or die "cannot create a unique randomcode for $uemail";
  return 1;
}

sub userexists( $uemail ) { defined($uemail) or return 0; return (-e "$var/users/$uemail"); }

sub _checkemailexists( $uemail ) {
  _checkemailvalid( $uemail );
  (userexists($uemail)) or die "sorry, email $uemail is valid, but user is not registered!\n";  ## basically, this function is userexists
  return $uemail;
}

sub _checkemailenrolled( $uemail, $course ) {
  _checkemailexists( $uemail );
  ## ($course eq 'auth') and return 1;  ## always ok;
  $course= _checkcname($course);
  (-e "$var/courses/$course/$uemail") or die "user $uemail is not enrolled in course $course\n";
  return $uemail;
}


################
## users cannot enroll themselves unless they know the course secret
sub userenroll( $course, $uemail, $iswebcoursecreator=0 ) {
  (-e "$var/courses/$course") or die "no such course $course.\n";
  (-e "$var/users/$uemail") or die "no such user $uemail yet.  please register bio info first\n";
  if (!$iswebcoursecreator) {
    (-e "$var/users/$uemail/bio.yml") or die "cannot enroll user who has no bio info (except for instructor)";
    (-e "$var/courses/$course/instructor") or die "why is there no instructor for $course yet?";
    (-e "$var/courses/$course/instructor/files") or die "why does instructor for $course not have any files?";
  }

  if (-e "$var/courses/$course/$uemail") {
    my $disabled= "$var/courses/$course/disabled=1";
    (-e $disabled) and unlink($disabled); ## in case...
    return _checkemailenrolled($uemail, $course);  ## mild error-- we already exist
  }

  mkdir("$var/courses/$course/$uemail") or die "could not make $course/$uemail: $!\n";
  mkdir("$var/courses/$course/$uemail/msgs") or die "could not make $course/$uemail/msgs: $!\n";
  mkdir("$var/courses/$course/$uemail/files") or die "could not make $course/$uemail/files: $!\n";
  ## we want to keep user information when we do webcoursebackup, so don't symlink:
  symlink("$var/users/$uemail/bio.yml", "$var/courses/$course/$uemail/bio.yml")
    or die "cannot store bio info for $uemail in class $course";
  copy("$var/users/$uemail/bio.yml", "$var/courses/$course/$uemail/static-bio.yml");  ## one time copy from auth.  will not be updated.
  return _checkemailenrolled($uemail, $course);
}


sub instructornewenroll( $course, $instructoremail ) {
  _checkemailvalid($instructoremail);
  (-e "$var/users/$instructoremail") or usernew($instructoremail);
  userenroll($course, $instructoremail, 1);
  touch("$var/courses/$course/$instructoremail/instructor=1");
}




sub isenrolled( $course, $uemail ) {
  ## if you were enrolled but are now disabled, we still call you enrolled
  ## effectively, you could still access course pages, but because the course no longer
  ## appears in your list of enrolled courses, getting there would require entering the URL by hand
  ## rather than entering via button press
  ($course =~ /^[\w][\w\-\.]*[\w]/) or die "bad subdomain name $course";
  ($course eq "auth") and return 0;
  (-e "$var/courses/$course") or die "no such course $course.\n";
  return (-e "$var/courses/$course/$uemail");
}

sub userdisroll( $course, $uemail ) {
  (-e "$var/courses/$course") or die "no such course $course.\n";
  (-e "$var/courses/$course/$uemail") and touch("$var/courses/$course/disabled=1");
}

################################################################

sub bioread( $uemail ) {
  $uemail=_checkemailexists($uemail);
  return _saferead("$var/users/$uemail/bio.yml");
}

sub biosave( $uemail, $biodataptr ) {
  $uemail=_checkemailexists($uemail);
  _checkvalidagainstschema( $biodataptr, 'u' );
  ($biodataptr->{email} eq $uemail) or die "you better have the same primary email in biowrite, not $uemail and $biodataptr->{email}";

  my $udir="$var/users/$uemail";
  (defined($biodataptr->{tzi})) or die "need a timezone";
  unlink(bsd_glob("$udir/tzi=*"));  ## remove any old timezones
  touch("$udir/tzi=".$biodataptr->{tzi}) or die "cannot set user timezone to ".$biodataptr->{tzi};
  ## print STDERR "[update biowrite: on save percolate into existing user directories, too --- or do it backup time and keep link]"
  return _safewrite( $biodataptr, "$udir/bio.yml" );
}

sub tzi( $uemail ) {
  my $f=bsd_glob("$var/users/$uemail/tzi=*");
  (defined($f)) or die "user $uemail has no timezone info";
  (-e $f) or die "user $uemail has no timezone info";
  $f =~ s{.*tzi\=(.*)}{$1};
  return $f;
}

sub bioiscomplete( $uemail ) {
  $uemail=_checkemailexists($uemail);
  (-e "$var/users/$uemail/bio.yml") or return 0;
  return ((-s "$var/users/$uemail/bio.yml")>10);  ## ok, not a full check, I admit.
}

################################################################

sub cioread( $course ) {
  $course= _checkcname($course);
  return _saferead("$var/courses/$course/cinfo.yml");
}

sub ciosave( $course, $ciodataptr ) {
  $course= _confirmsudoset( $course );
  _checkvalidagainstschema( $ciodataptr, 'c' );

  setcoursesecret($course, $ciodataptr->{coursesecret});
  return _safewrite( $ciodataptr, "$var/courses/$course/cinfo.yml" )
}

sub cioiscomplete( $course ) {
  $course= _confirmsudoset( $course );
  (-e "$var/courses/$course/cinfo.yml") or return 0;
  return ((-s "$var/courses/$course/cinfo.yml")>10);  ## ok, not a full check, I admit.
}

sub ciobuttonsave( $course, $list ) {
  $course= _confirmsudoset( $course );
  return _safewrite($list, "$var/courses/$course/buttons.yml" );
}

sub ciobuttons( $course ) {
  $course= _checkcname($course);
  return _saferead( "$var/courses/$course/buttons.yml" )|| ();
}


sub hassyllabus( $course ) {
  my $s= (bsd_glob("$var/courses/$course/instructor/files/syllabus.*"));
  (defined($s)) or $s= (bsd_glob("$var/courses/$course/instructor/files/syllabus*.*"));
  (defined($s)) or return undef;
  $s =~ s{\~due=.*}{};   ## remove ~due=... and give finddue the full path to find the removed due
  finddue($s) or return undef;
  $s =~ s{$var/courses/$course/instructor/files/}{};   ## Previously /fileview~f=$s will be /fileview~f=/var/courses/... It should be /fileview?f=syllabus-sophisticated.html.
  return $s;    ## still needs to be tested checked --- yanni!  should be one function, working on both long names and course/shortnames
}



################################################################

sub studentdetailedlist( $course ) {
  $course= _confirmsudoset( $course );
  my @list;
  foreach (_glob2last("$var/courses/$course/*@*")) {
    (my $ename=$_) =~ s{$var/courses/$course}{};
    my $thisuser= _saferead( "$var/users/$ename/bio.yml" );
    ($thisuser->{email}) or $thisuser->{email}= $ename;  ## instructor added may lack
    push(@list, $thisuser);
  }
  return \@list;
}

sub studentlist( $course ) {
  $course= _confirmsudoset( $course );
  my @list= _glob2last("$var/courses/$course/*@*");
  return \@list;
}



################################################################

=pod

=head2 SUDO (Instructor)-related functionality

=cut

################################################################

sub tokenmagic( $uemail ) {
  (-e "$var/tmp/magictoken") or return undef;
  my @lines= slurp("$var/tmp/magictoken");
  $lines[0] =~ s{^ip\:\s*}{}; chomp($lines[0]); # =~ s{\s*[\r\n]*}{}ms;
  $lines[1] =~ s{^(then|user|uemail)\:\s*}{}; chomp($lines[1]); # =~ s{\s*[\r\n]*}{}ms;

  my $browserip= $ENV{SYLSPACE_siteip} || "99.99.99.99";

  ($browserip eq $lines[0]) or die "bad site ip.  you are on ip $browserip, and not on '$lines[0]'";
  _checkemailexists( $lines[1] );  ## will complain if the user does not exist

  unlink("$var/tmp/magictoken");
  return $lines[1];
}


sub morphinstructor2student( $course, $uemail) {
  $course= _confirmsudoset( $course );  ## ok, we are the instructor!
  $uemail= _checkemailenrolled($uemail, $course);
  return touch("$var/courses/$course/$uemail/morphed=1");
}

sub unmorphstudent2instructor( $course, $uemail) {
  $uemail= _checkemailenrolled($uemail, $course);
  # (ismorphed($course,$uemail)) or die "you cannot unmorph $uemail in $course";
  (-e "$var/courses/$course/$uemail/morphed=1") and unlink("$var/courses/$course/$uemail/morphed=1");
}

sub ismorphed($course, $uemail) {
  ## ahhh, here we need to just check for morphing, not for instructor
  ((-e "$var/courses/$course/$uemail/morphed=1")&&(-e "$var/courses/$course/$uemail/instructor=1")) and return 1;
  return 0;
}


sub sudo( $course, $uemail ) {
  (defined($course)) or die "Model sudo: need a class name";
  (defined($uemail)) or die "Model sudo: need some uemail --- who are you?";
  (-e "$var/users/$uemail") or die "Model sudo: '$uemail' is not even enrolled in $course";

  (isinstructor($course, $uemail)) or die "Model sudo: you $uemail are not among valid instructors for $course\n";
  _setsudo();

  return $course;
}




sub isinstructor( $course, $uemail, $ignoremorph=0 ) {
   $course= _checkcname($course);
   ($course eq "auth") and return 0;  ## there are no instructors in auth
   ## ($amsudo) and return 1;  ## already checked
   (defined($uemail)) or die "isinstructor without uemail!\n";

   (-e "$var/courses/$course/$uemail/instructor=1") or return 0;  ## for sure we are not
   (-e "$var/courses/$course/$uemail/morphed=1") and return 0;
   return 1;
}

sub instructorlist( $course ) {
  $course= _checkcname($course);
  ## students and instructors can find out who is in charge
  my @l= bsd_glob("$var/courses/$course/*@*/instructor=1");
  foreach (@l) { s{$var/courses/$course/([^\/]+)/instructor\=1}{$1}; }
  return \@l;
}

sub instructoradd( $course, $newiemail ) {
  $course= _checkcname($course);
  _confirmsudoset( $course );

  (defined($newiemail)) or die "setinstructors without uemail!\n";
  (-e "$var/courses/$course/$newiemail") or die "you can only make users enrolled in $course your new instructors";
  return touch("$var/courses/$course/$newiemail/instructor=1");
}

sub instructordel( $course, $uemail, $newiemail ) {
  $course= _checkcname($course);
  _confirmsudoset( $course );
  ($uemail eq $newiemail) and die "you cannot delete yourself as an instructor";
  unlink("$var/courses/$course/$newiemail/instructor=1");
}


################################################################

=pod

=head2 Bio and Course Info : Input and Validation

=cut

################################################################

#### the main routine to make sure that our inputs validate
sub readschema( $metaschemafletter ) {
  use FindBin;
  use lib "$FindBin::Bin/../lib";

  my $fname= $metaschemafletter."settings-schema.yml";
  (!(-e $fname)) and $fname="Model/$fname";
  (!(-e $fname)) and $fname="SylSpace/$fname";
  my $metaptr= _saferead($fname);  ## needs to be external, so that form controller and viewer know it, too
  (defined($metaptr)) or die "schema '$metaschemafletter' ($fname) is not readable from ".`pwd`."!\n";
  return $metaptr;
}


sub _checkvalidagainstschema( $dataptr, $metaschemafletter, $verbose =0 ) {
  sub _ishashptr( $x ) { (ref($x) eq ref({})) or die "bad internal input\n" };
  _ishashptr($dataptr);

  my $metaptr= readschema($metaschemafletter); ## needs to be external, so that form controller and viewer know it, too
  (defined($metaptr)) or die "schema for '$metaschemafletter' is not readable by _checkvalidagainstschema\n";

  my @validmetas = qw( required regex maxsize htmltype placeholder public value readonly );
  my %validmetas; foreach( @validmetas ) { $validmetas{$_} = 1; }

  my %metas;
  foreach (@{$metaptr}) {
    my $field= $_;
    ($verbose) and print STDERR Dumper($field)."\n";
    my $fieldname= (keys %$field)[0];
    my $d= $dataptr->{$fieldname};
    ($fieldname eq 'defaults') and next;  ## this one is special and not checked
    (defined($d)) or die "sorry, but I really wanted a field named $fieldname\nyou only gave ".Dumper($dataptr)."\n";

    my $constraints= $field->{$fieldname};
    foreach (keys %{$constraints}) { ($validmetas{$_}) or die "in meta-scheme file, Field $fieldname contains invalid fieldinfo '$_'"; }

    if ($constraints->{required}) {
      ($verbose) and print STDERR "REQUIRED: $fieldname ";
      (defined($d)) or die "required field '$fieldname' is not even seen\n";
      ($d =~ /[a-zA-Z0-9\-]/) or die "required field '$fieldname' has no data\n";
      ($verbose) and print STDERR " w/ content = '$dataptr->{$fieldname}'\n";
    }
    if (my $regex=$constraints->{regex}) {
      ($verbose) and print STDERR "testing $fieldname data $d against regex $regex ";
      ## empty only validates against regex if not empty
      if (defined($d) && ($d ne "")) {
	($d =~ m{$regex}) or die "field $fieldname: '$d' does not satisfy regex $regex\n";
      }
      ($verbose) and print STDERR "passed.\n";
    }
    if (my $maxsize=$constraints->{maxsize}) {
      ($verbose) and print STDERR "testing $fieldname data $d against maxsize $maxsize\n\n";
      (length($d)<=$maxsize) or die "$d is longer than $maxsize characters\n";
    }
    if (my $htmltype=$constraints->{htmltype}) {
      ($verbose) and print STDERR "testing $fieldname data $d against htmltype $htmltype  ";
      if (($d)&&($d ne '')) {
	if ($htmltype eq "number") { ($d+0 == $d) or die "Sorry, but $htmltype is not a number\n"; }
	if ($htmltype eq "email") { _checkemailvalid($d) or die "Sorry, but $htmltype is not an email\n"; }
	if ($htmltype eq "url") { ($d=~/^http/) or die "Sorry, but $htmltype is not a url\n"; }
      }
    }

    $metas{$fieldname}=1;
  }
  foreach (keys %{$dataptr}) {
    ($metas{$_}) or die "Sorry, but data point '$_' was not in list of allowed metas: ".Dumper(\%metas)."\n";
  }

  return 1;
}



################################################################

=pod

=head2 Messaging System (from instructors to notify students)

=cut

################################################################

sub msgsave( $course, $msgin, $optmsgid =undef ) {
  $course= _confirmsudoset( $course );
  (defined($msgin)) or die "no message was provided";
  $msgin->{time}= time();
  $msgin->{msgid}= $optmsgid||($msgin->{time});
  (-e "$var/courses/$course/msgs/$msgin->{msgid}") and die "message with id $msgin->{msgid} already exists";
  (defined($msgin->{priority})) or $msgin->{priority}=0;
  my $msg;
  foreach (qw(priority subject body msgid time)) {
    (exists($msgin->{$_})) or die "message lacks required field $_ (".Dumper($msgin).")\n";
    $msg->{$_} = $msgin->{$_};
  }
  foreach (qw(priority msgid time)) { (($msg->{$_}+0)==($msg->{$_})) or die "message $_ must be an int, not $_\n"; }
  (length($msg->{body})<= 16384) or die "message is ".(length($msg->{body})-16384)." characters too long\n";
  (length($msg->{subject})<= 512) or die "subject header is ".(length($msg->{subject})-512)." characters too long\n";

  _safewrite( $msg, "$var/courses/$course/msgs/".$msg->{msgid}.".yml" ) or return 0;
  return $msgin->{msgid};
}

sub msgdelete( $course, $msgid ) {
  $course= _confirmsudoset( $course );
  $msgid =~ s/^msgid=//;
  ($msgid =~ /^[0-9]+$/) or die "need reasonable message id to delete, not '$msgid'!\n";

  (-e "$var/courses/$course") or die "no such course";
  (-e "$var/courses/$course/msgs") or die "no course messages";
  (-e "$var/courses/$course/msgs/$msgid.yml") or die "message $msgid.yml does not exist in $var/courses/$course/msgs";

  foreach (bsd_glob("$var/courses/$course/*@*/msgs/$msgid.yml")) { unlink($_); }  ## any user who thinks he has seen this now no longer has
  unlink("$var/courses/$course/msgs/$msgid.yml");  ## and the original message, too, of course
  return 1;
}

## msg read can work with an array of or a single msgid, or a pointer to an array of msgid
sub msgread( $course, @msgid ) {
  $course= _checkcname($course);
  (@msgid) or @msgid= _glob2last("$var/courses/$course/msgs/*");
  (ref $msgid[0] eq 'ARRAY') and @msgid= @{$msgid[0]};

  my @allmsgs;
  foreach my $msgid (@msgid) {
    $msgid =~ s/\.yml$//;
    ($msgid =~ /^[0-9]+$/) or die "need reasonable message id to read, not '$msgid'!\n";
    push( @allmsgs, _saferead( "$var/courses/$course/msgs/$msgid.yml" ));
  }
  return \@allmsgs;
}

## iterate messages
sub msgmarkasread( $course, $uemail, $msgid ) {
  $course= _checkcname( $course );
  $uemail= _checkemailenrolled($uemail,$course);
  $msgid =~ s/^msgid=//;
  ($msgid =~ /^[0-9]+$/) or die "need reasonable message id to mark read, not '$msgid'!\n";
  touch("$var/courses/$course/$uemail/msgs/$msgid.yml");
}


## the following three return lists of msgid.yml
sub _msglist( $course ) {
  $course= _checkcname($course);
  return _glob2lastnoyaml("$var/courses/$course/msgs/*.yml");
}

sub msglistread( $course, $uemail ) {
  $uemail= _checkemailenrolled($uemail,$course);
  return _glob2lastnoyaml("$var/courses/$course/$uemail/msgs/*.yml");
}

## iterate messages; returns a pointer to an array of msgids
sub _msglistnotread( $course, $uemail ) {
  my @r= msglistread( $course, $uemail );  ## will check cname and uemail
  my @a= _msglist( $course );
  my %r; foreach (@r) { $r{$_}=1; }
  my @m= grep { !$r{$_} } @a;
  return \@m;
}

## iterate all unread messages and put it into a full structure
sub msgshownotread( $course, $uemail ) {
  return msgread( $course, _msglistnotread( $course, $uemail ) ); } ## ->[0] dereferences



################################################################

=pod

=head2 Logging and Tweeting interface.

=cut

################################################################

sub _logany( $ip, $course, $who, $msg, $file, $destdir=undef ) {
  (defined($who)) or die "please give a user name.  you gave undef at ".((caller(1))[3]);
  (($who =~ /instructor/)||($who =~ /\@/)) or die "who needs to identify user?  not ".($who||"nowho");
  # let's keep the full email address  $who =~ s/\@.*\b//;
  $msg =~ s{\t}{ }g;  $msg=~ s/[\n\r]//g;
  (defined($destdir)) or $destdir="$var/courses/$course";
  _burpapp("$destdir/$file", $ip."\t".time()."\t".gmtime()."\t".$who."\t$msg\n");
}

sub superseclog( $ip, $who, $msg ) {
  _logany( $ip, 'auth', $who, $msg, 'auth.log', "$var/" );
}

sub seclog( $ip, $course, $who, $msg ) {
  _logany($ip, $course, $who, $msg, 'security.log');
}

sub tweet( $ip, $course, $who, $msg ) {
  sub randstring {
    my @chars = ("a".."z", "0".."9");
    $_=""; foreach my $i (1..8) { $_ .= $chars[rand @chars]; } return $_;
  }

  my $tweetfile= bsd_glob("$var/courses/$course/tweet.*")||("$var/courses/$course/tweet.log");
  (-e $tweetfile) or touch($tweetfile);
  $tweetfile =~ s{.*/}{};
  _logany($ip, $course, $who, $msg, $tweetfile);
  _burpnew("$var/courses/$course/lasttweet", "GMT ".gmtime()." $who $msg");
}

sub showlasttweet( $course ) {
  (-e "$var/courses/$course/lasttweet") or return "";
  return "<div class=\"ltweet\">Last Tweet: ".slurp("$var/courses/$course/lasttweet")."</div>";
}


sub showtweets( $course ) {
  (my $tweetfile=bsd_glob("$var/courses/$course/tweet.*")) or return undef;
  return scalar slurp($tweetfile);
}

sub showseclog( $course ) {
  my $seclogfile= "$var/courses/$course/security.log";
  (-e $seclogfile) or return join("\t", ('noip',time(),scalar gmtime(),'system', 'no security log just yet'))."\n";
  return scalar slurp($seclogfile);
}


################################################################

=pod

=head2 Equiz Backend Interface

=cut

################################################################

sub equizrender( $course, $email, $equizname, $callbackurl ) {
  _checkemailenrolled($email, $course);
  (_confirmnotdangerous($equizname, "equizrender")) or die "sorry, but user $email cannot post $equizname, because it is bloody";

  (defined($equizname)) or die "need a filename for equizmore.\n";

  my $equizcontent= (isinstructor($course, $email)) ? eqreadi( $course, $equizname ) : eqreads( $course, $equizname );  ## quizzes always belong to the instructor

  my $fullequizname= longfilename( $course, $equizname );
  my $equizlength= length($equizcontent);

  my $executable= sub {
    my $loc=`pwd`; chomp($loc); $loc.= "/Model/eqbackend/eqbackend.pl";
    return $loc;
  } ->();

  my $secret= md5_base64( (-e "/usr/local/var/lib/dbus/machine-id") ? "/usr/local/var/lib/dbus/machine-id" : "/etc/machine-id" );
  ## must be same secret as in equizgrade()
  ## instead of this secret, we could use a line from /var/sylgrade/secrets.txt

  my $fullcommandline= "$executable $fullequizname ask $secret $callbackurl $email";
  ## _confirmnotdangerous($fullcommandline, "executable to render equiz");  ## maybe uncomment

  my $r= `$fullcommandline`;
  return $r;
}


################
## grading an equiz entails unencrypting it, counting up the score, saving the score, and presenting the correct solutions

sub equizgrade( $course, $uemail, $posttextashash ) {
  sub decryptdecode {
    use Crypt::CBC ;
    use MIME::Base64;
    use HTML::Entities;

    use Digest::MD5 qw(md5_base64);
    my $secret= md5_base64( (-e "/usr/local/var/lib/dbus/machine-id") ? "/usr/local/var/lib/dbus/machine-id" : "/etc/machine-id" );
    ## must be same secret as in renderequiz()
    ## instead of this secret, we could use a line from /var/sylgrade/secrets.txt

    my $cipherhandle = Crypt::CBC->new( -key => $secret, -cipher => 'Blowfish', -salt => '14151617' );

    my $step1 = decode_entities($_[0]);
    my $step2 = decode_base64($step1);
    my $step3= $cipherhandle->decrypt($step2);
    return $step3;
  }

  sub decodeall( $posttextashash ) {
    ## A S P are encrypted
    foreach ( keys %$posttextashash ) {
      (/^confidential$/) and $posttextashash->{$_} = decryptdecode($posttextashash->{$_});
      (/^[ASPQN]\-[0-9]+/) and $posttextashash->{$_} = decryptdecode($posttextashash->{$_});
    }
    return $posttextashash;
  }

  $posttextashash= decodeall($posttextashash);
  my ($conf, $fname, undef, undef, $referrer, $qemail, $time, $browser, $ignoredgradename, $eqlongname)= split(/\|/, $posttextashash->{confidential});
  ($conf eq 'confidential') or die "oh well, you don't know what confidential means";

  (my $gradename = $fname) =~ s{.*/}{};
  #  $gradename =~ s{\.equiz$}{};  ## an equiz is always named by its filename

  (lc($qemail) eq lc($uemail)) or die "Sorry, but $uemail cannot look at answers from $qemail";

  my $i=0; my $score=0; my @qlist;
  while (++$i) {
    my $ia= $posttextashash->{"S-$i"};
    (defined($ia)) or last;
    (looks_like_number($ia)) or
      die "sorry, but instructor answer S-$i is not numeric, but '$ia'";
    my $sa= $posttextashash->{"q-stdnt-$i"};
    (defined($sa)) or die "there is no student answer field for $i";
    (looks_like_number($sa)) or die "sorry, but student answer q-stdnt-$i is not numeric, but '$ia'";
    my $answerdelta= abs($sa - $ia);
    my $precision= ($posttextashash->{"P-$i"})||0.01;

    ## the actual grading:
    $posttextashash->{'iscorrect'}= ($answerdelta < $precision);
    $score += $posttextashash->{'iscorrect'};
    push( @qlist, [ $posttextashash->{"N-$i"}, $posttextashash->{"Q-$i"}, $posttextashash->{"A-$i"}, $ia, $sa, $precision,
		    $posttextashash->{'iscorrect'}?"Correct <i class=\"fa fa-check fa-2x\" style=\"color:green\"></i>":"Incorrect <i class=\"fa fa-close fa-2x\" style=\"color:red\"></i>" ])
  }
  --$i;

  ## instructor quiz results are never stored
  ## [1] we store the answered full hash to "$var/courses/$course/$uemail/files/$fname.$time.eanswer.yml"
  ## [2a] we store plain info to the student, $var/subdomain/$semail/equizgrades
  ##   [2b] we store grades via gradetaskadd, too.

  if (!(isinstructor($course, $uemail))) {
    my $ofname= "$var/courses/$course/$uemail/files/$gradename.$time.eanswer.yml";
#    (-e $ofname) and die "please do not answer the same equiz twice.  instead go back, refresh the browser to receive fresh questions, and submit then\n";
    _safewrite( $posttextashash, $ofname );  ## the content
  }

  ## to be read by equizanswerrender()
  return [ $i, $score, $uemail, $time, $gradename, $eqlongname, $fname, $posttextashash->{confidential}, \@qlist ];
}



##
sub equizanswerrender( $decodedarray ) {
  ## from equizgrade()
  my ($numq, $ans, $uemail, $time, $gradename, $eqlongname, $fname, $confidential, $detail) = @$decodedarray;

  my $rv= "<p>Quiz <b>$eqlongname</b> results for $uemail.
           <p><b>Overall Result:</b> $ans correct responses for $numq questions</p>";
  $rv .= '

    <script type="text/javascript" async src="https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.1/MathJax.js?config=TeX-MML-AM-CHTML"></script>
    <script type="text/javascript"       src="https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.1/MathJax.js?config=TeX-AMS_HTML-full"></script>

    <script type="text/javascript" src="/js/eqbackend.js"></script>
    <link href="/css/eqbackend.css" media="screen" rel="stylesheet" type="text/css" />
    <link href="/css/input.css" media="screen" rel="stylesheet" type="text/css" />

<script type="text/x-mathjax-config">
  MathJax.Hub.Register.StartupHook("TeX Jax Ready",function () {
    MathJax.InputJax.TeX.Definitions.number =
      /^(?:[0-9]+(?:,[0-9]{3})*(?:\.[0-9]*)*|\.[0-9]+)/
  });
</script>

    <style>
      p.qstntext::before {  content: "Question: "; font-weight: bold;  }
      p.qstntext::before {  content: "Question: "; font-weight: bold;  }
      p.qstnlong::before {  content: "Detailed: "; font-weight: bold;  }
      p.qstnshort::before {  content: "Correct Answer: "; font-weight: bold;  }
      p.qstnstudentsays::before {  content: "Your Answer: "; font-weight: bold;  }
      p.qstnscore::before {  content: "Counted As: "; font-weight: bold;  }
    </style>
    ';

  foreach (@{$detail}) {
    my $precision= $_->[5] || "0.01";
    my $youranswer = $_->[4];
    ($youranswer < 0) and $youranswer =~ s/^\s*\-/ &ndash;/;
    my $correctanswer = $_->[3];
    ($correctanswer < 0) and $correctanswer =~ s/^\s*\-/ &ndash;/;
    $rv .= qq(
       <div class="subpage">
          <div class="qname">$_->[0]</div>
          <div class="qstn">
           <p class="qstntext"> $_->[1] </p>
           <p class="qstnlong"> $_->[2] </p>
           <p class="qstnshort"> $correctanswer (&plusmn;$precision)</p>
           <p class="qstnstudentsays"> $youranswer </p>
           <p class="qstnscore"> $_->[6] </p>
       </div>
     </div>
);
  }

  $rv .= '
<p>The numeric solutions above are typically approximations.  The correct answer carries the full interim precision, and is shown with many significant digits.  After you have examined both the correct and your own answers, please help us improve this quiz for the future by giving us your opinion.  You will then be redirected to the equiz center after you click on <em>Opine</em>.

<form method="GET" action="equizrate" class="form-inline">
    <input type="hidden" name="equizrate" value="'.$fname.'" />
    <input type="hidden" name="equizgradename" value="'.$gradename.'" />
    <input type="hidden" name="equizuemail" value="'.$uemail.'" />

	<div class="form-group">
		<label for="difficulty">Difficult:</label>
		<select name="difficulty" class="form-control" id="difficulty">
		<option value="none" selected="selected"></option>
		<option value="hard">Too Hard</option>
		<option value="right">Just Right</option>
		<option value="easy">Too Easy</option>
		</select>
	</div>

	<div class="form-group">
		<label for="clarity">Clarity:</label>
		<select name="clarity" class="form-control" id="clarity">
		<option value="none" selected="selected"></option>
		<option value="very">Answers Clear Now</option>
		<option value="somewhat">Answers Stil Not Clear</option>
		<option value="wrong">Answers Seem Wrong</option>
		</select>
	</div>

	<div class="form-group">
		<label for="comments">Comments:</label>
                <input type="text" size="80" maxsize="80" name="comments" />
        </div>

      <button class="btn btn-default" type="submit" value="submit">Opine</button>

   </form>
';

  return $rv;
}


sub equizrate( $ip, $course, $hash ) {
  (my $comments= $hash->{comments}) =~ s/[:\n]/;/g;
  my $errmsg= "$hash->{equizrate} : $hash->{equizgradename} : $hash->{clarity} : $hash->{difficulty} : $comments ";
  _logany( $ip, $course, $hash->{equizuemail}, $errmsg, 'equizratings.txt', $var );
}

################################################################

sub paypallog( $type, $email, $ip, $referer, $msg ) {
  $referer= $referer || "noreferer";
  $ip= $ip || "noip";

  open(my $TMP, ">>", "/tmp/debugpaypal.log");
  print $TMP time()."\n";
  print $TMP "hello: ".join(" | ", $ip, 'na', $email, "referer $referer | $msg", 'paypal.log', $var)."\n";
  close($TMP);

  _logany( $ip, 'na', $email, "referer $referer | $msg", 'paypal.log', $var );
}

1;


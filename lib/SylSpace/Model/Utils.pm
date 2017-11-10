#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Model::Utils;

use base 'Exporter';
## @ISA = qw(Exporter);

@EXPORT_OK= qw( 
		    _getvar
		    _checkemailvalid
		    _unsetsudo _setsudo _confirmsudoset _savesudo _restoresudo
		    _burpnew _burpapp
		    _confirmnotdangerous _checkcname
		    _saferead _safewrite _glob2last _glob2lastnoyaml  _checksfilenamevalid
		    _decryptdecode _encodeencrypt
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

use File::Glob qw(bsd_glob);
use Email::Valid;
################################################################

=pod

=head2 Utility Routines: 

* safe writing into the filesystem (with backup and yaml understanding)

* globbing

* checking filenames and filepaths

* checking email / enrollment

=cut

################################################################

my $var= $ENV{'SylSpacePath'} || '/var/sylspace'; ## this should be hardcoded and unchanging

sub _getvar() {
  (-e "$var") or die "$0: please create the $var directory for the site first.  then run mksite.pl, Model.t, or Test.t\n";
  return $var;
}


################################################################
## must be our, because it is shared!

our $amsudo=0;  ## after setting it to 1, you no longer have to give the email to check capabilities
our $tempsudo;

## NOTE: THIS IS NOT CONTINGENT ON COURSE ANYMORE.  THIS MUST BE CHECKED BEFORE!!

sub _savesudo { $tempsudo= $amsudo; }
sub _restoresudo { $amsudo= $tempsudo; }
sub _getsudo { return $amsudo; }
sub _setsudo { $amsudo=1; } ## ok, we are set for confirmsudoset and isinstructor
sub _unsetsudo { $amsudo=0; } ## ok, we are set for confirmsudoset and isinstructor
sub _suundo { $amsudo=0; }  ## needed for debug and testing only

# sub utype( $course, $uemail ) { return (isinstructor($course, $uemail)) ? 'i' : 's'; }

## a local helper,  works only after an sudo() has been called, because email has been checked; also does _checkcname
sub _confirmsudoset( $course ) {
  $course= _checkcname($course);  ## lowercases!!
  ($amsudo) or die "insufficient privileges: you are not a confirmed instructor for $course!  did you ever call sudo?\n";
  return $course;
}


################################################################################################################################

## safewrite will first write a temporary file with the new content,
## then rename any old file to a backup first (including useless
## symlinks), and finally rename the two files appropriately.  if the
## file ends with yml, the content is written and read through
## yaml::tiny.  otherwise, it is just a plain file.   files that would
## remain unchanged are *not* updated.


sub _safewrite( $contentinfo, $sfilename ) {

  $sfilename= _checkfilepath($sfilename);

  (defined($contentinfo)) or die "need contentinfo to write!\n";

  my $sfilenamenew= $sfilename.".new";

  if ($sfilename =~ /\.yml$/) {
    my $yamlofinfo= YAML::Tiny->new($contentinfo);
    $yamlofinfo->write($sfilenamenew) or die "cannot write replacement: $! --- aborted update/write\n";
  } else {
    _burpnew($sfilenamenew, $contentinfo);
  }

  if (-e $sfilename) {

    if ((-s $sfilenamenew) == (-s $sfilename)) {
      use Digest::MD5::File qw(dir_md5_hex file_md5_hex url_md5_hex);
      if (file_md5_hex($sfilename) eq file_md5_hex($sfilenamenew)) {
	unlink($sfilenamenew); return 123; ## nothing was really changed!
      }
    }

    if ($sfilename =~ /\.equiz$/) {
      (my $newfilename= $sfilename) =~ s{(.*)/(.*)}{$1/old-$2};
      rename($sfilename, $newfilename) or die "cannot rename existing file $sfilename to $newfilename: $!";
    } else {
      rename($sfilename, $sfilename.".old") or die "cannot rename existing file $sfilename to $sfilename.old: $!";
    }
  }
  return rename($sfilename.".new", $sfilename); ## this better work
}

sub _saferead( $sfilename ) {
  ## problem: the below will change Model/filename to model/filename, which
  ## works under osx, but not under linux;

  $sfilename= ($sfilename =~ m{^Model/[ubc]settings-schema\.yml}) ? $sfilename : _checkfilepath($sfilename);  ## do not uppercase

  ## the .yml extension is hardcoded
  if ($sfilename =~ /\.ya?ml$/) {
    (-e $sfilename) or return;
    return (YAML::Tiny->read($sfilename))->[0];
  }

  ## we will try to see if any of the following work, in order
  foreach my $ext ("", ".html", ".htm", ".pdf", ".txt", ".text", ".csv", ".doc") {
    (-e "$sfilename$ext") and return slurp("$sfilename$ext");
  }

  return (-e $sfilename);  ## not found
}


sub _glob2last( $globstring ) {
  return map { (my $foo = $_) =~ s{.*/}{}; $foo; } bsd_glob($globstring);
}

sub _glob2lastnoyaml( $globstring ) {
  return map { (my $foo = $_) =~ s{.*/}{}; $foo =~ s{\.ya?ml$}{}; $foo; } bsd_glob($globstring);
}

sub _checksfilenamevalid( $sfilename ) {
  defined($sfilename) or die "please provide a filename";
  ($sfilename eq "") and die "please provide a filename";
  ($sfilename =~ /^[\w\-\ ][\@\w\.\-\ ]*$/) or die "filename $sfilename contains bad characters; use only words, dashes, dots";
  return lc($sfilename);
}

sub _checkfilepath( $filepath ) {
  $filepath =~ s{/+}{/};
  ($filepath =~ m{[^\w]\.\.}) and die "filepath $filepath can have double dots only after a word character\n";
  return lc($filepath);
}


##
## validation of names and sites
##

sub _checkemailvalid( $uemail ) {
  (defined($uemail)) or die "I have no idea who you are!\n";
  (length($uemail)<128) or die "email $uemail too long\n";
  (Email::Valid->address($uemail)) or die "email address '$uemail' could not possibly be valid\n";
  ($uemail =~ m{/}) and die "email $uemail cannot have slash in it!\n";
  ($uemail =~ m{\.\.}) and die "email $uemail cannot have consecutive dots!\n";
  ($uemail =~ m{^\.}) and die "email $uemail cannot start with dot!\n";
  $uemail= lc($uemail);
  return $uemail;
}

sub _checkcname( $course ) {
  ($course =~ /^[\w][\w\.\-]*[\w]$/) or die "bad webcourse name '$course'!\n";
  (-e "$var/courses/$course") or ($course eq "auth") or die "subdomain $course in $var/courses is unknown.\n";
  return lc($course);
}


## stuff we may pass into a system or backquote call
sub _confirmnotdangerous( $string, $warning ) {
  ($string =~ /^\w[\w\_\-\.]*$/) or die "_confirmnotdangerous:\n\n'$warning'\n\nfails on string\n\n'$string'\n\n!";  ## we allow '*'
  ## ($string =~ /\;\&\|\>\<\?\`\$\(\)\{\}\[\]\!\#\'/) and die "too dangerous: $warning fails!";  ## we allow '*'
  return $string;
}

################################################################################################################################

sub rlc { return scalar @{$_[0]}; }


################################################################
# generics
################
sub _burpnew( $lfilename, $contents ) {
  $lfilename= ($lfilename || "$var/general.log");
  open( my $FOUT, ">", $lfilename ) or die "cannot write to $lfilename: $!\n"; print $FOUT $contents; close($FOUT); return length($contents);
}

sub _burpapp( $lfilename, $contents ) {
  $lfilename= ($lfilename || "$var/general.log");
  open( my $FOUT, ">>", $lfilename ) or die "cannot write to $lfilename: $!\n"; print $FOUT $contents; close($FOUT); return length($contents);
}


################################################################

use Encode;
use Crypt::CBC ;
use MIME::Base64;
use HTML::Entities;
use Digest::MD5 qw(md5_base64);

  ## instead of this secret, we could use a line from /var/sylgrade/secrets.txt

sub _decryptdecode {
  my $secret= md5_base64( (-e "/usr/local/var/lib/dbus/machine-id") ? "/usr/local/var/lib/dbus/machine-id" : "/etc/machine-id" );
  my $cipherhandle = Crypt::CBC->new( -key => $secret, -cipher => 'Blowfish', -salt => '14151617' );

  my $step1 = decode_entities($_[0]);
  my $step2 = decode_base64($step1);
  my $step3= $cipherhandle->decrypt($step2);
  return $step3;
}

sub _encodeencrypt {
  my $secret= md5_base64( (-e "/usr/local/var/lib/dbus/machine-id") ? "/usr/local/var/lib/dbus/machine-id" : "/etc/machine-id" );
  my $cipherhandle = Crypt::CBC->new( -key => $secret, -cipher => 'Blowfish', -salt => '14151617' );
  (defined($cipherhandle)) and return encode_base64($cipherhandle->encrypt($_[0]));
  die "bad encryptor!\n";
}


1;

#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Model::Webcourse;

use base 'Exporter';
@ISA = qw(Exporter);

@EXPORT_OK= qw( _webcoursemake _webcourseshow _webcourseremove _webcourselist );

################################################################

=pod

=head2 website-related, course, and user-related functionality

=cut

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
use File::Touch;

################################################################

use SylSpace::Model::Utils qw( _getvar _checkemailvalid _checkcname );
use SylSpace::Model::Model qw( userenroll );

my $var= _getvar();


################################################################

sub _webcoursemake($course) {
  (-e "$var") or die "[wbm:1a] usually, you would fist run 'initsylspace.pl' to create basic website info in $var before creating webcourses\n";
  (-w "$var") or die "[wbm:1b] please make $var writable\n";
  (-e "$var/users") or die "[wbm:2a] please create the $var/users directory for everyone first\n";
  (-w "$var/users") or die "[wbm:2b] please make $var/users writable\n";
  (-e "$var/templates") or die "[wbm:3a]please create the $var/templates directory\n";
  (-e "$var/templates/starters") or die "[wbm:3b]please create the $var/templates/starters directory (templates are copied by hand)\n\tusually, ln -s .../templates/equiz/* $var/templates/";

  ($course =~ /^[\w][\w\.\-]*[\w]$/) or die "bad webcourse name '$course'!\n"; ## need to check without triggering existence check
  (-e "$var/courses/$course") and die "webcourse $course already exists\n";

  mkdir("$var/courses/$course") or die "cannot make $course course webcourse: $!\n";
  $course= _checkcname($course); ## we are not yet the instructor, so checking makes no sense

  mkdir("$var/courses/$course/msgs") or die "cannot make webcourse messages: $!\n";
  mkdir("$var/courses/$course/public") or die "cannot make webcourse published: $!\n";  ## will contain links
  mkdir("$var/courses/$course/instructor") or die "cannot make webcourse instructor: $!\n";  ## will contain links
  mkdir("$var/courses/$course/instructor/files") or die "cannot make webcourse instructor files: $!\n";  ## will contain links

  touch("$var/courses/$course/grades");
  touch("$var/courses/$course/tasks");
  touch("$var/courses/$course/tasklist");
}


## used for debugging in .t files
sub _webcourseshow($course) {
  (-e "$var") or die "please create the $var directory for the site first\n";
  (-e "$var/users") or die "please create the $var/users directory for everyone first\n";
  (-e "$var/courses/$course") or die "please create the $var/courses/$course directory for everyone first\n";

  _checkcname($course);
  return `find $var/users $var/courses/$course`;
}


## for drastic debugging, this removes all webcourses!  it should never be called from the web.  it's ok if the course does not exist
sub _webcourseremove($course) {
  ## can we add a test whether we are running under Mojolicious and abort if we are?
  ($course =~ m{\.\.}) and die "ok, wcremove is not safe, but '$course' is ridiculous";
  ($course =~ m{/}) and die "ok, wcremove is not safe, but '$course' is ridiculous";
  ( ($course =~ /\*/) && ($0 !~ /mk.*site\.t/) ) and die "ok, wcrm is not safe, but '$course' is ridiculous.  only allowed in mkstartersite.t";

  system("rsync -avz $var /tmp/sylspace");

  my $nremoved=0;
  foreach (bsd_glob("$var/courses/$course")) {
    $_= lc($_);
    (-e $_) or next;
    system("rm -rf $_");
    (-e $_) and die "wth?  $_ could not be removed!\n";
    ++$nremoved;
  }

  #if ($course eq "*") {
    # system("rm -rf $var/categories/list $var/categories/*/list $var/categories/*/*/list $var/categories/*/*/*/list $var/categories/*/*/*/*/list");
    # system("rm -rf $var/users/*/posted/*");
    # system("rm -rf $var/users/*/balance=*");
    # system("rm -rf $var/users/*/transactions.txt");
  #}

  return $nremoved;
}

sub _webcourselist() {
  my @list;
  foreach (bsd_glob("$var/courses/*")) {
    $_= lc($_);
    (-e $_) or next;
    s{^$var/courses/}{};
    push(@list, $_);
  }
  return \@list;
}

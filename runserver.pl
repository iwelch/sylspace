#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

use strict;
use warnings;
use common::sense;
use utf8;
use feature ':5.20';
use warnings FATAL => qw{ uninitialized };
use autodie;

($> == 0) or die "you must run this as root, because even for testing, we occupy not localhost but syllabus.test:80\n";

my $isproduction= (`hostname` =~ /syllabus/m);
my $isosx= (-d "/Users/ivo");

my @apphome;
if ($isosx) {
  ($isproduction && $isosx) and die "iaw: please do not run the syllabus.space domain on an osx host.\n";
  ((-e 'SylSpace') && (-x 'SylSpace')) or die "on macos, you must be in the local directory in which SylSpace lives!";
  @apphome= (`pwd`);
} else {
  @apphome= grep { $_ =~ /SylSpace$/ } `locate sylspace/SylSpace`;  ## locate sylspace/SylSpace works on linux, but not macos

  @apphome = grep { $_ !~ m{\/\.[a-z]}i } @apphome;  ## a hidden directory in path, e.g., .sync or .git
  @apphome = grep { $_ !~ m{\bold\b}i } @apphome;  ## an "old" somewhere
  ## @apphome = grep { $_ =~ m{sylspace\/SylSpace$} } @apphome;  ## we have very specific ideas of how we like this one

  ((scalar @apphome)>1) and die "Ambiguous SylSpace locations:\n\t".join(" ", @apphome).
    "\nPlease test on non-production servers, not on the same server.\n";
  ((scalar @apphome)<1) and die "Cannot locate executable SylSpace on $^O:: '".`locate sylspace/SylSpace`."'.  did you run updatedb? \n";
}


chomp($apphome[0]);
(my $workdir= $apphome[0]) =~ s{\/SylSpace$}{};

print STDERR "running $apphome[0] in $workdir\n";

(-e $workdir) or die "$0: internal weird error.  no $workdir!\n";
(-d $workdir) or die "$0: internal weird error.  no $workdir!\n";
chdir($workdir) or die "failed to change directory to $workdir: $!\n";

if ($isproduction) {

  print STDERR "$0: Running full production hypnotoad server for sylspace.  To stop:
	kill -QUIT `cat hypnotoad.pid` gracefully (or -TERM), or
	/usr/local/bin/hypnotoad -s ./SylSpace)\n\t\tPS: morbo -v -m production ./SylSpace -l http://syllabus.space for testing\n";
  echosystem("/usr/local/bin/hypnotoad -f ./SylSpace");  ## do not '&', or it fails in systemd SylSpace.service !

} else {

  (`grep syllabus.test /etc/hosts` =~ /\.syllabus\.test/mi) or die "in non-production, please add *.syllabus.test to your /etc/hosts\n";
  my $mode= ((@ARGV) && (defined($ARGV[0])) && ($ARGV[0] =~ /^p/i)) ? "production" : "development";

  print STDERR "$0: running morbo for syllabus.test in $mode mode.\n";

  my $executable= (-x "/usr/local/bin/morbo") ? "/usr/local/bin/morbo" : "/usr/local/ActivePerl-5.24/site/bin/morbo";
  (-x $executable) or die "cannot find suitable morbo executable.\n";

  echosystem("$executable -v -m $mode ./SylSpace -l http://syllabus.test:80");
}

sub echosystem {
  print STDERR "\nEXECUTING SYSTEM: '$_[0]'\n";
  system $_[0];
}

#!/usr/bin/env perl
use strict;
use warnings;
use common::sense;
use utf8;
use feature ':5.20';
use warnings FATAL => qw{ uninitialized };
use autodie;

($> == 0) or die "you must run this as root, because even for testing, we occupy not localhost but syllabus.test:80\n";

my $isproduction= (`hostname` =~ /syllabus-space/m);
my $isosx= (-d "/Users/ivo");

($isproduction && $isosx) and die "iaw: please do not run the syllabus.space domain on an osx host.\n";

my @apphome= grep { $_ =~ /SylSpace$/ } `locate sylspace/SylSpace`;
## flunks somehow:
##  @apphome = grep { (-x $_) } @apphome;
@apphome = grep { $_ !~ m{\/\.[a-z]}i } @apphome;  ## a hidden directory in path, e.g., .sync or .git

((scalar @apphome)>1) and die "Ambiguous SylSpace locations:\n\t".join(" ", @apphome).
  "\nPlease test on non-production servers, not on the same server.\n";
((scalar @apphome)<1) and die "Cannot locate executable SylSpace.\n";

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

  (`grep syllabus.test /etc/hosts` =~ /\.syllabus\.test/mi) or die "please add *.syllabus.test to your /etc/hosts\n";
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

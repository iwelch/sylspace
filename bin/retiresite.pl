#!/usr/bin/env perl
## 2026-01-19 09:00 https://claude.ai/chat/...
## retiresite.pl - retire a sylspace course by moving it to courses/old/
## can be invoked from any directory

use strict;
use common::sense;
use utf8;
use warnings FATAL => qw{ uninitialized };
use autodie;

use feature ':5.20';
use feature 'signatures';
no warnings qw(experimental::signatures);

################################################################

use Mojo::File qw(curfile path);
use File::Copy qw(move);

## Determine SylSpace root directory (parent of bin/)
my $sylspace_root = curfile->dirname->sibling('.')->to_abs->to_string;

## Change to SylSpace root so modules can find their resources
chdir $sylspace_root or die "Cannot chdir to $sylspace_root: $!\n";

use lib curfile->dirname->sibling('lib')->to_string;
use lib curfile->dirname->sibling('local/lib/perl5')->to_string;

################################################################

## Protected sites that cannot be retired
my %PROTECTED = map { $_ => 1 } qw(corpfin syllabus);

## Default paths (can be overridden via SYLSPACE_PATH env var)
my $sylspace_path = $ENV{SYLSPACE_PATH} // '/var/sylspace';
my $courses_dir   = "$sylspace_path/courses";
my $old_dir       = "$courses_dir/old";

################################################################

my $usage = "usage: $0 sitename [sitename ...]

  sitename    : course identifier(s) to retire

Retires course sites by moving them from:
  $courses_dir/<sitename>/
to:
  $old_dir/<sitename>/

Protected sites that cannot be retired: " . join(', ', sort keys %PROTECTED) . "
";

die $usage unless @ARGV >= 1;

## Ensure old/ directory exists
unless (-d $old_dir) {
    print "Creating archive directory: $old_dir\n";
    mkdir $old_dir or die "Cannot create $old_dir: $!\n";
}

my $errors = 0;

for my $sitename (@ARGV) {
    $sitename = lc($sitename);
    
    print "Processing '$sitename'...\n";
    
    ## Check if protected
    if ($PROTECTED{$sitename}) {
        warn "  ERROR: '$sitename' is a protected site and cannot be retired.\n";
        $errors++;
        next;
    }
    
    my $src = "$courses_dir/$sitename";
    my $dst = "$old_dir/$sitename";
    
    ## Verify source exists
    unless (-d $src) {
        warn "  ERROR: Course directory does not exist: $src\n";
        $errors++;
        next;
    }
    
    ## Check destination doesn't already exist
    if (-e $dst) {
        warn "  ERROR: Destination already exists: $dst\n";
        warn "         (previously retired? remove manually if you want to re-retire)\n";
        $errors++;
        next;
    }
    
    ## Perform the move
    print "  Moving $src -> $dst\n";
    if (rename($src, $dst)) {
        print "  Successfully retired '$sitename'\n";
    } else {
        ## rename() may fail across filesystems; try File::Copy::move
        if (move($src, $dst)) {
            print "  Successfully retired '$sitename' (cross-device move)\n";
        } else {
            warn "  ERROR: Failed to move '$sitename': $!\n";
            $errors++;
        }
    }
}

if ($errors) {
    print "\nCompleted with $errors error(s).\n";
    exit 1;
} else {
    print "\nAll sites retired successfully.\n";
    exit 0;
}

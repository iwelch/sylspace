#!/usr/bin/env perl
## 2026-01-19 09:00 https://claude.ai/chat/...
## addsite.pl - create a new sylspace site with an instructor
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

use Mojo::File qw(curfile);

## Determine SylSpace root directory (parent of bin/)
my $sylspace_root = curfile->dirname->sibling('.')->to_abs->to_string;

## Change to SylSpace root so modules can find their resources
chdir $sylspace_root or die "Cannot chdir to $sylspace_root: $!\n";

use lib curfile->dirname->sibling('lib')->to_string;
use lib curfile->dirname->sibling('local/lib/perl5')->to_string;

use SylSpace::Model::Webcourse qw(_webcoursemake _webcourseremove _webcourseshow);
use SylSpace::Model::Model qw(:DEFAULT instructornewenroll);

use Email::Sender::Simple qw(sendmail);
use Email::MIME;
use Try::Tiny;

################################################################
## Configuration

my $ADMIN_EMAIL = $ENV{SYLSPACE_ADMIN_EMAIL} // 'ivo.welch@gmail.com';
my $SITE_DOMAIN = $ENV{SYLSPACE_DOMAIN}      // 'syllabus.space';
my $FROM_EMAIL  = $ENV{SYLSPACE_FROM_EMAIL}  // "noreply\@$SITE_DOMAIN";

################################################################

my $usage = "usage: $0 sitename instructoremail

  sitename    : lowercase course identifier (e.g., finc3600-2024-fall)
  email       : instructor's email address

Creates a new sylspace course site and enrolls the instructor.
Sends notification email to instructor (cc: admin).

Environment variables:
  SYLSPACE_ADMIN_EMAIL  - admin CC address (default: $ADMIN_EMAIL)
  SYLSPACE_DOMAIN       - site domain (default: $SITE_DOMAIN)
  SYLSPACE_FROM_EMAIL   - sender address (default: $FROM_EMAIL)
";

die $usage unless @ARGV == 2;

my ($subdomain, $iemail) = @ARGV;

$subdomain = lc($subdomain);
$iemail    = lc($iemail);

## Basic validation
$subdomain =~ /^[a-z0-9][a-z0-9\-]*[a-z0-9]$|^[a-z0-9]$/
    or die "Error: sitename '$subdomain' must be lowercase alphanumeric (hyphens allowed internally)\n";

$iemail =~ /^[^@]+@[^@]+\.[^@]+$/
    or die "Error: '$iemail' does not look like a valid email address\n";

print "Creating site '$subdomain' with instructor '$iemail'...\n";

_webcoursemake($subdomain);

## Defensive: ensure course directory is world-writable for web server
my $course_dir = ($ENV{SYLSPACE_PATH} // '/var/sylspace') . "/courses/$subdomain";
chmod 0777, $course_dir or warn "Warning: Could not chmod $course_dir: $!\n";

instructornewenroll($subdomain, $iemail);

print "Successfully created website '$subdomain' with instructor '$iemail'\n";

## Send notification email
print "Sending notification email to '$iemail' (cc: $ADMIN_EMAIL)...\n";

my $site_url = "https://$subdomain.$SITE_DOMAIN";

my $email_body = <<"END_EMAIL";
Dear Instructor,

Your new course site has been created on $SITE_DOMAIN:

  Course:  $subdomain
  URL:     $site_url
  Login:   $iemail

You can access your course at the URL above. Log in with your
registered email address to begin setting up your course materials.

If you have any questions, please contact the site administrator.

Best regards,
The SylSpace System
END_EMAIL

my $email = Email::MIME->create(
    header_str => [
        From    => $FROM_EMAIL,
        To      => $iemail,
        Cc      => $ADMIN_EMAIL,
        Subject => "Your new course site: $subdomain",
    ],
    attributes => {
        content_type => 'text/plain',
        charset      => 'UTF-8',
        encoding     => 'quoted-printable',
    },
    body_str => $email_body,
);

try {
    sendmail($email);
    print "Notification email sent successfully.\n";
} catch {
    warn "Warning: Failed to send notification email: $_\n";
    warn "The course was created successfully, but you may need to notify the instructor manually.\n";
};

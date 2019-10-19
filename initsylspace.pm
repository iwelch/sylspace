#!/usr/bin/env perl

use strict;
use warnings;
use warnings FATAL => qw{ uninitialized };
use autodie;

use Archive::Zip;
use Crypt::CBC;
use Crypt::DES;
use Crypt::Blowfish;
use Data::Dumper;
use Digest::MD5;
use Digest::MD5::File;
use Email::Valid;
use Encode;
use File::Grep;
use File::Copy;
use File::Glob;
use File::Path qw(make_path);
use File::Touch;
use FindBin;
use HTML::Entities;
use MIME::Base64;
use Math::Round;
use Perl6::Slurp;
use Safe;
use Scalar::Util;
use Scalar::Util::Numeric;
use Test2::Bundle::Extended;
use Test2::Plugin::DieOnFail;
use YAML::Tiny;

use Class::Inspector;

use Mojolicious::Lite;
use Mojolicious::Plugin::RenderFile;
use Mojolicious::Plugin::Mojolyst;
use Mojolicious::Plugin::BrowserDetect;

## these are used in the authentication module
use Mojo::JWT;
use Mojolicious::Plugin::Web::Auth;
use Mojolicious::Plugin::OAuth2;
use Email::Sender::Simple;
use Email::Simple::Creator;
use Email::Sender::Transport::SMTP::TLS;

use Mojolicious::Plugin::Web::Auth;

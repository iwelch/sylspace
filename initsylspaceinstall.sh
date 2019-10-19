#!/bin/sh

sudo apt install libz-dev libssl-dev gcc make
sudo apt install emacs-nox git

sudo cpan Term::ReadKey YAML Perl6::Slurp Log::Log4perl Archive::Zip \
      Crypt::CBC Crypt::DES Crypt::Blowfish Digest::MD5::File \
      Email::Valid File::Touch Math::Round Perl6::Slurp \
      Scalar::Util::Numeric Test2::Bundle::Extended YAML::Tiny \
      Class::Inspector Email::Sender::Simple Email::Sender::Transport::SMTP::TLS File::Grep \
      common::sense

sudo cpan Mojolicious
sudo cpan Mojolicious::Plugin::Mojolyst Mojolicious::Plugin::BrowserDetect \
    Mojolicious::Plugin::Web::Auth Mojolicious::Plugin::RenderFile Mojo::JWT Mojolicious::Plugin::OAuth2

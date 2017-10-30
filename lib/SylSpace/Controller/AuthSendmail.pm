#!/usr/bin/env perl

## this file is part of sylspace, released under the AGPL, 2016, authored by ivo welch, ucla.
## one additional condition requires the prominent posting of the name (sylspace) and the author.

package SylSpace::Controller::AuthSendmail;
use Mojolicious::Lite;
use lib qw(.. ../..); ## make syntax checking easier
use strict;

use SylSpace::Model::Model qw(superseclog throttle);
use SylSpace::Model::Controller qw(global_redirect standard);
use SylSpace::Model::Utils qw( _decryptdecode _encodeencrypt _checkemailvalid _confirmnotdangerous);

################################################################

use Email::Valid;
use Email::Sender::Simple 'sendmail';
use Email::Sender::Transport::SMTP::TLS;
use Email::Simple::Creator;

post '/auth/sendmail/authenticate' => sub {
  my $c = shift;

  my $name = $c->param('name');
  ($name eq 'no name') or die "we are already overloaded!\n";

  if (!$name) {
    return $c->stash(error => 'Missing required parameter name' )->render(template => 'AuthSendmail');
  }

  my $email = $c->param('outgemaildest');
  ($email) or die "Missing email\n";
  (Email::Valid->address($email)) or die "email address '$email' could not possibly be valid\n";

  if (!$email) {
    return $c->stash(error => 'Missing required parameter email' )->render(template => 'AuthSendmail');
  }

  $c->stash(email => $email);

  if (_send_email($c, $email, $name)) {
    return $c->stash(error => '')->render(template => 'AuthSendmail');
  }

  die "Failed to send email to '$email' with name '$name', for some unknown reason without a useful error message";
  $c->stash(error => 'Failed to send email')->render(template => 'AuthSendmail');
};

################
get '/auth/sendmail/callback' => sub {
  my $c = shift;

  my $string= _decryptdecode( $c->param('jwt') );
  my ($time, $name, $email) = split(/\|/, $string );

  ($time+3600 > time()) or die "sorry, but on '$string' and $time;$name;$email your authorization request ($time) is already expired (".($time+3600 - time())." sec)\n";
  ($email) or die "internal error: our callback to authenticate you failed because we have no email";
  (_checkemailvalid($email)) or die "bad email '$email'.";
  ($name =~ /[a-z]/i) or die "name makes no sense to me\n";
  # _confirmnotdangerous($name, "bad user name in callback for sendmail");

  superseclog( $c->tx->remote_address, $email, "got email callback for $name and $email" );

  $c->session(uemail => $email, name => $name, expiration => time()+60*60, ishuman => time())->redirect_to('/index');
};

################
sub _send_email {
  my ($c, $email, $name) = @_;
  my $config = $c->app->plugin('Config');

  my $jwt = _encodeencrypt( time() . "|" . $name . "|" . $email ); 
  my $url = $c->url_for('/auth/sendmail/callback')->to_abs->query(jwt => $jwt);

  defined($email) or die "internal error---what is your email??";

  my $message = Email::Simple->create(
    header => [
      From    => $config->{email}{message}{from},
      To      => $email,
      Subject => 'Confirm your email',
    ],
    body => "Follow this link: $url\n\nMake sure that your email spam filter will not trap the email you will receive, something like:

	From: syllabus.space <syllabus.space\@gmail.com>
	Subject: Confirm your email

" );

  superseclog( $c->tx->remote_address, $email, "requesting sending email to ".$email );

  throttle();  ## to prevent nasty DDOSs on other sites

  sub _getTransport {
    my $c = shift;
    return $c->{_transport} ||= Email::Sender::Transport::SMTP::TLS->new(
									 %{ $c->app->plugin('Config')->{email}{transport} }
									);
  }

  return sendmail($message, { transport => _getTransport($c) });
}

1;

################################################################

__DATA__

@@ AuthSendmail.html.ep

%title 'email sent';
%layout 'auth';

<main>

% if ($error) {
  <h2>ERROR: Email was NOT sent</h2>
  <p>
    <%= $error %>
  </p>
% } else {
  <h2>We sent an email to '<a href="mailto:<%= $email %>"><%= $email %></a>' .</h2>
% }

  <p>
  If you typed your email address (<a href="mailto:<%= $email %>"><%= $email %></a>) correctly, you should be receiving an email from us.</p>

  <p> Please check your mailbox for a confirmation email with link.  If you do not receive an email from us within 5-10 minutes, check for any spam filters along the way.  The email should be sent by  '<%= $ENV{SYLSPACE_sitename} %>@gmail.com'.  It will be valid for about 30 minutes.</p>

  <p><b>Warning:</b> Some email spam filters may be blocking us.  Make sure to whitelist us.  Here is more information on <a href="http://onlinegroups.net/blog/2014/02/25/how-to-whitelist-an-email-address/">whitelisting</a> us (e.g., <a href="http://smallbusiness.chron.com/whitelist-domain-office-365-74321.html">office365</a> and <a href="https://support.microsoft.com/en-us/kb/2545137">office365</a>)?  If you never receive an email&mdash;even after having whitelisted us&mdash;then please try a gmail account.  We know that gmail can receive our emails.</p>

  <hr />

  <p>Note that when you click on the link in your email, it should invoke the same internet browser that you are using now.   Your authentication is browser-specific, not computer-specific!</p>

</main>


